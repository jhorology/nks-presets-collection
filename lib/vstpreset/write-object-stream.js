const { Readable, Writable } = require('stream'),
  promisify = require('util').promisify,
  fs = require('fs'),
  fsOpen = promisify(fs.open),
  fsClose = promisify(fs.close),
  fsWrite = promisify(fs.write),
  { writeUInt64LE, createReadStreamFromBuffer } = require('./utils')

/**
 * Writable object stream class for .vstpreset
 * @private
 * @class
 */
module.exports = class VstPresetWriteObjectStream extends Writable {
  /**
   * Constructor.
   * @param {string} classId  - vst plugin class id. 32byte hex string or uuid {8}-{4}-{4}-{4}-{12}
   * @param {string} [file] - The path for output file. if not specified, output buffer.
   * @param {object} [options] - options.
   * @param {integer} [options.version] - The version of vstpreset format. default = 1
   * @param {object} [options.objectStreamOpts] - options for this {stream.Writable}.
   * @param {object} [options.byteStreamOpts] - options for each chunk's byte stream {fs.ReadStream}.
   */
  constructor(classId, fileOrOptions, options) {
    const file =
        arguments.length >= 2 && typeof fileOrOptions === 'string'
          ? fileOrOptions
          : undefined,
      opts =
        arguments.length >= 3
          ? options
          : typeof fileOrOptions === 'object'
          ? fileOrOptions
          : undefined

    super(
      Object.assign(opts ? opts.objectStreamOpts || {} : {}, {
        objectMode: true
      })
    )

    if (
      !(
        typeof classId === 'string' &&
        (classId.match(
          /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i
        ) ||
          classId.match(/^[0-9A-F]{32}$/i))
      )
    ) {
      throw new Error(`Wrong format or value of classId. [${classId}]`)
    }
    this.file = file
    this.classId = classId.replace(/\-/g, '').toUpperCase()
    this.options = Object.assign(
      {
        version: 1
      },
      opts
    )
    this.initial = true
    this.fd = undefined
    this.buffer = undefined
    this.position = 0
    this.chunkList = []
  }

  /**
   * An implementation of Writable#_write()
   * @private
   * @override
   * @param {object} chunkObject
   * @param {string} chunkObject.id - The chunk id. 4 characters string.
   * @param {string|Buffer|Readable} chunkObject.contents - The contents of chunk.
   *   file path or Buffer or readable byte stream.
   * @param {string} encoding - not use for this class.
   * @param callback {Function} A callback function that takes an optional error argument.
   */
  _write(chunkObject, encoding, callback) {
    // validate object
    if (
      typeof chunkObject.id !== 'string' ||
      !chunkObject.id.match(/^[\u0020-\u007f]{4}$/)
    ) {
      callback(new Error('The chnuk id shoud be 4 characters string.'))
      return
    }
    if (
      !(
        chunkObject.contents instanceof Readable ||
        Buffer.isBuffer(chunkObject.contents) ||
        typeof chunkObject.contents === 'string'
      )
    ) {
      callback(
        new Error(
          'The chnuk contents shoud be readable stream or Buffer or file path.'
        )
      )
      return
    }
    this._asyncWrite(chunkObject, callback).catch(callback)
  }

  /**
   * An implementation of Radable#_destroy()
   * @private
   * @override
   * @param err {Error} A possible error.
   * @param callback {Function} A callback function that takes an optional error argument.
   */
  _destroy(err, callback) {
    this._closeOutput()
      .then(() => callback())
      .catch(e => callback(e))
  }

  /**
   * An implementation of Radable#_final()
   * @private
   * @override
   * @param {Function} callback - A callback function that takes an optional error argument.
   */
  _final(callback) {
    this._flushContents()
      .then(() => this._outputChunkList())
      .then(() => callback())
      .catch(e => callback(e))
  }

  /**
   * get a buffer.
   * @override
   * @param err {Error} A possible error.
   * @param callback {Function} A callback function that takes an optional error argument.
   */
  getBuffer() {
    if (!this.buffer) {
      throw new Error('Illegal function call for file operation mode,')
    }
    return this.buffer
  }

  /**
   * async write.
   * @private
   * @async
   * @param {object} chunkObject
   * @param {Function} callback - A callback function that takes an optional error argument.
   */
  async _asyncWrite(chunkObject, callback) {
    if (this.initial) {
      this.initial = false
      await this._openOutput()
      await this._outputHeader()
    }
    const index = this.chunkList.length,
      chunk = {
        id: chunkObject.id,
        size: 0
      },
      readable = this._createReadContentsStream(chunkObject.contents)

    this.chunkList.push(chunk)
    readable.on('data', data => {
      chunk.size += data.length
      readable.pause()
      this._outputContentBytes(data, chunk, index)
        .catch(callback)
        .finally(() => readable.resume())
    })
    readable.on('end', () => {
      chunk.end = true
      callback()
    })
  }

  /**
   * open output.
   * @async
   * @private
   */
  async _openOutput() {
    if (typeof this.file === 'string') {
      this.fd = await fsOpen(this.file, 'w')
    } else {
      this.buffer = Buffer.alloc(0)
    }
  }

  /**
   * close output.
   * @async
   * @private
   */
  async _closeOutput() {
    if (typeof this.fd === 'number') {
      await fsClose(this.fd)
    }
  }

  /**
   * output file header.
   * @async
   * @private
   */
  async _outputHeader() {
    const buffer = Buffer.alloc(48)
    buffer.write('VST3', 0)
    buffer.writeUInt32LE(this.options.version, 4)
    buffer.write(this.classId, 8)
    // chunj list offset = 0 initial value
    writeUInt64LE(buffer, 0, 40)
    await this._output(buffer)
  }

  /**
   * create a readable byte stream.
   * @private
   * @return {stream.Redable} - The byte stream for content of chunk.
   */
  _createReadContentsStream(contents) {
    if (Buffer.isBuffer(contents)) {
      // contents is Buffer
      return createReadStreamFromBuffer(contents, this.options.byteStreamOpts)
    } else if (typeof contents === 'string') {
      // contents is file path
      return fs.createReadStream(contents, this.options.byteStreamOpts)
    } else if (contents instanceof Readable) {
      // readable stream
      return contents
    } else {
      throw new Error('Unsupported type of contents of chunk object.')
    }
  }

  /**
   * output bytes of content
   * @async
   * @private
   * @param {Buffer} data
   * @param {object} chunk - the cache for chunk object.
   * @param {integer} index - the index of chunk in chunkList.
   */
  async _outputContentBytes(data, chunk, index) {
    if (index === 0 || this.chunkList[index - 1].end) {
      if (chunk.cache) {
        await this._output(chunk.cache)
        chunk.cache = undefined
      }
      await this._output(data)
    } else {
      if (chunk.cache) {
        chunk.cache = Buffer.concat([chunk.cache, data])
      } else {
        chunk.cache = data
      }
    }
  }

  /**
   * flush cached contents.
   * @async
   * @private
   */
  async _flushContents() {
    for (let i = 0; i < this.chunkList.length; i++) {
      const chunk = this.chunkList[i]
      if (chunk.cache) {
        await this._output(chunk.cache)
        chunk.cache = undefined
      }
    }
  }

  /**
   * output chunk list.
   * @async
   * @private
   */
  async _outputChunkList() {
    // list id: 4byte 'List'
    // list entry count: 4byte
    // [listitem] 20byte * entry count
    //   chunk id: 4byte
    //   chunk offset: 8byte UInt64LE
    //   chunk size: 8byte UInt64LE
    let buffer = Buffer.alloc(8 + 20 * this.chunkList.length)
    buffer.write('List', 0)
    buffer.writeUInt32LE(this.chunkList.length, 4)
    let offset = 48,
      position = 8
    this.chunkList.forEach(c => {
      buffer.write(c.id, position)
      writeUInt64LE(buffer, offset, position + 4)
      writeUInt64LE(buffer, c.size, position + 12)
      offset += c.size
      position += 20
    })
    const pos = await this._output(buffer)
    buffer = Buffer.alloc(8)
    // write offset from beggining of file to header(address=40)
    writeUInt64LE(buffer, pos)
    await this._output(buffer, 40)
  }

  /**
   * A primitive output function.
   * @private
   * @async
   * @param {Buffer} data - The chunk of data.
   * @param {integer} [position] - The offset from the beginning of file or buffer where
   *                               this data should be written. if not specied, output continuously.
   * @return {integer} - The offset from the beginning of file or buffer where data was writtten.
   */
  async _output(data, position) {
    let pos = position
    if (this.buffer) {
      // buffer
      if (typeof position === 'number') {
        this.buffer.fill(data, position, position + data.length)
      } else {
        this.buffer = Buffer.concat([this.buffer, data])
        pos = this.position
        this.position += data.length
      }
    } else {
      // file
      if (typeof position === 'number') {
        const ret = await fsWrite(this.fd, data, 0, data.length, position)
      } else {
        const ret = await fsWrite(this.fd, data)
        if (ret.bytesWritten !== data.length) {
          throw new Error(
            `[fs.read] returns rong bytesWriten count. expect length:${data.length} bytesWritten:${ret.bytesWritten}`
          )
        }
        pos = this.position
        this.position += data.length
      }
    }
    return pos
  }
}
