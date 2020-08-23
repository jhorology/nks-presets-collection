const VstPresetReadObjectStream = require('./read-object-stream'),
  VstPresetWriteObjectStream = require('./write-object-stream')

module.exports = {
  /**
   * read format information of specified file or buffer.
   * @public
   * @async
   * @param {string|Buffer} file - a file path or Buffer of file content.
   * @retun {Promise<object>}
   */
  readFileInfo: async function (file) {
    return await VstPresetReadObjectStream.readFileInfo(file)
  },

  /**
   * create a readable object stream.
   * @public
   * @param {string|Buffer} file - a file path or Buffer of file content.
   * @param {object} [options]
   * @param {boolean} [options.contentsAsStream] {boolean} if true, data.contents is a Stream, otherwise Buffer.
   * @param {object} [options.objectStreamOpts] - options for this {stream.Writable}.
   * @param {object} [options.byteStreamOpts] - options for each chunk's byte stream {fs.ReadStream}.
   */
  createReadObjectStream: function (file, options) {
    return new VstPresetReadObjectStream(file, options)
  },

  /**
   * create a writable object stream.
   * @public
   * @param {string} classId  - The vst plugin class id.
   *   16 byte hex coded string(32 characters) or uuid string {8}-{4}-{4}-{4}-{12}.
   * @param {string} [file] - The path for output file. if not specified, output buffer.
   * @param {object} [options]
   * @param {integer} [options.version] - The version of vstpreset format. default = 1
   * @param {object} [options.objectStreamOpts] - options for this object stream {stream.Writable}.
   * @param {object} [options.byteStreamOpts] - options for each chunk's byte stream {fs.ReadStream}.
   */
  createWriteObjectStream: function (classId, file, options) {
    return new VstPresetWriteObjectStream(classId, file, options)
  }
}
