const { Readable } = require('stream'),
  promisify = require('util').promisify,
  fs = require('fs'),
  fsOpen = promisify(fs.open),
  fsClose = promisify(fs.close),
  fsRead = promisify(fs.read),
  { readUInt64LE, createReadStreamFromBuffer } = require('./utils')

/**
 * Readable object stream for .vstpreset
 * @class
 */
module.exports = class VstPresetReadObjectStream extends Readable {
  /**
   * Read formatting information from file.
   * @static
   * @param {string|Buffer} file - a file path or Buffer of file content.
   * @return {Promise<object>}
   */
  static async readFileInfo(file) {
    const vstpreset = new VstPresetReadObjectStream(file)
    try {
      await vstpreset._openInput()
      const fileInfo = await vstpreset._readFileInfo()
      return fileInfo
    } finally {
      vstpreset._closeInput()
    }
  }

  /**
   * Constructor.
   * @param {string|Buffer} file - a file path or Buffer of file content.
   * @param {object} options
   * @param {boolean} options.contentsAsStream -  if true, data.contents is a Stream, otherwise Buffer. default = true.
   * @param {object} [options.objectStreamOpts] - options for this {stream.Redable}.
   * @param {object} [options.byteStreamOpts] - options for each chunk's byte stream {fs.ReadStream}.
   */
  constructor(file, options) {
    super(
      Object.assign({}, options ? options.objectStreamOpts || {} : {}, {
        objectMode: true
      })
    )
    // instance variable
    this.file = file
    this.isBuffer = Buffer.isBuffer(file)
    this.options = Object.assign(
      {
        // default options
        contentsAsStream: false
      },
      options
    )
    this.initial = true
    this.fd = undefined
    this.fileInfo = undefined
    this.chunkList = []
    this.requestCount = 0
    this.readCount = 0
  }

  /**
   * An implementation of Radable#_read()
   * @override
   * @private
   * @param side {integer}
   */
  _read(size) {
    this.requestCount += size
    this._processRead().catch(err => {
      this.destroy(err)
    })
  }

  async _processRead() {
    if (this.__processing) {
      return
    }
    this.__processing = true
    try {
      if (this.initial) {
        this.initial = false
        await this._openInput()
        this.fileInfo = await this._readFileInfo()
      }
      await this._pushObjects()
    } finally {
      this.__processing = false
    }
  }

  /**
   * An implementation of Radable#_destroy()
   * @override
   * @private
   * @param err {Error} A possible error.
   * @param callback {Function} A callback function that takes an optional error argument.
   */
  _destroy(err, callback) {
    this._closeInput()
      .then(() => callback())
      .catch(e => callback(e))
  }

  /**
   * Read formatting information.
   * @private
   * @async
   * @return {Promise<object>}
   */
  async _readFileInfo() {
    // read file header
    let buffer = await this._readSource(0, 48)
    const fileId = buffer.toString('ascii', 0, 4),
      version = buffer.readUInt32LE(4),
      classId = buffer.toString('ascii', 8, 40),
      chunkListOffset = readUInt64LE(buffer, 40)
    if (fileId !== 'VST3') {
      throw new Error(`Unknown file ID:${fileId}.`)
    }
    // read chunk entry header
    buffer = await this._readSource(chunkListOffset, 8)
    const chunkListId = buffer.toString('ascii', 0, 4),
      chunkEntryCount = buffer.readUInt32LE(4)
    if (chunkListId !== 'List') {
      throw new Error(`Unknown chunk list ID:${chunkListId}.`)
    }
    // read chunk entry list
    buffer = await this._readSource(chunkListOffset + 8, 20 * chunkEntryCount)
    const chunkList = []
    for (let i = 0; i < chunkEntryCount; i++) {
      const offset = i * 20,
        chunk = {
          id: buffer.toString('ascii', offset, offset + 4),
          offset: readUInt64LE(buffer, offset + 4),
          size: readUInt64LE(buffer, offset + 12)
        }
      chunkList.push(chunk)
      // clone for post processes
      this.chunkList.push({
        id: chunk.id,
        offset: chunk.offset,
        size: chunk.size,
        end: false
      })
    }
    return {
      fileId: fileId,
      version: version,
      classId: classId,
      chunkListOffset: chunkListOffset,
      chunkListId: chunkListId,
      chunkEntryCount: chunkEntryCount,
      chunkList: chunkList
    }
  }

  /**
   * Push chunk objects into this stream.
   * @private
   * @return {Promise<object>}
   */
  async _pushObjects() {
    while (
      this.readCount < this.requestCount &&
      this.readCount < this.fileInfo.chunkEntryCount
    ) {
      const chunk = this.chunkList[this.readCount]
      if (this.options.contentsAsStream) {
        // chunk contents is a readable byte stream.
        this._pushObjectAsStream(chunk)
      } else {
        // chunk contents is a buffer.
        await this._pushObjectAsBuffer(chunk)
      }
      this.readCount++
    }
  }

  /**
   * Push chunk object into this stream.
   * @private
   * @param {object} chunk - The definition of chunk
   */
  _pushObjectAsStream(chunk) {
    const stream = this.isBuffer
      ? createReadStreamFromBuffer(
          this.file.slice(chunk.offset, chunk.offset + chunk.size),
          this.options.byteStreamOpts
        )
      : fs.createReadStream(
          null,
          Object.assign({}, this.options.byteStreamOpts || {}, {
            fd: this.fd,
            autoClose: false,
            start: chunk.offset,
            end: chunk.offset + chunk.size
          })
        )
    stream
      .on('error', err => {
        this.destroy(err)
      })
      .on('end', () => {
        chunk.end = true
        if (this.chunkList.every(c => c.end)) {
          // push EOF
          this.push(null)
        }
      })
    this.push({
      fileInfo: this.fileInfo,
      id: chunk.id,
      size: chunk.size,
      contents: stream
    })
  }

  /**
   * Push chunk object into this stream.
   * @private
   * @async
   * @param {object} chunk - The definition of chunk
   */
  async _pushObjectAsBuffer(chunk) {
    const buffer = await this._readSource(chunk.offset, chunk.size)
    this.push({
      fileInfo: this.fileInfo,
      id: chunk.id,
      size: chunk.size,
      contents: buffer
    })
    chunk.end = true
    if (this.chunkList.every(c => c.end)) {
      // push EOF
      this.push(null)
    }
  }

  /**
   * Open the file input source.
   * @private
   * @async
   */
  async _openInput() {
    if (!this.isBuffer) {
      this.fd = await fsOpen(this.file)
    }
  }

  /**
   * Close the file input source.
   * @private
   * @async
   */
  async _closeInput() {
    if (!this.isBuffer && typeof this.fd === 'number') {
      await fsClose(this.fd)
    }
  }

  /**
   * A primitive read function.
   * @private
   * @async
   * @param {integer} position - The offset from beginning of file where shuld be read.
   * @param {integer} length - The byte length to read.
   */
  async _readSource(position, length) {
    if (this.isBuffer) {
      // input is a buffer
      if (this.file.length < position + length) {
        throw new Error('Buffer postion + length is out of bounds.')
      }
      return this.file.slice(position, position + length)
    } else {
      // input is a file
      const buffer = Buffer.alloc(length)
      const ret = await fsRead(this.fd, buffer, 0, length, position)
      if (ret.bytesRead !== length) {
        throw new Error(
          `Wrong bytesRead count. expect length:${length} bytesRead:${ret.bytesRead}`
        )
      }
      return buffer
    }
  }
}
