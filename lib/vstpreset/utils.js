const { Readable, Writable } = require('stream'),
  MAX_INTEGER_HIGH32_MASK = ~Math.floor(Number.MAX_SAFE_INTEGER / 0x100000000)

module.exports = {
  readUInt64LE: function (buffer, position) {
    const lo = buffer.readUInt32LE(position),
      hi = buffer.readUInt32LE(position === undefined ? 4 : position + 4)

    // maximum 31bit(2GB) file addressing
    // there is no preset file that's over 2GB in practical.
    if (hi & MAX_INTEGER_HIGH32_MASK) {
      throw new Error('file addressing exceeded the Number.MAX_SAFE_INTEGER.')
    }
    return lo
  },

  writeUInt64LE: function (buffer, value, position) {
    // maximum 31bit(2GB) file addressing
    // there is no preset file that's over 2GB in practical.
    if (value > Number.MAX_SAFE_INTEGER) {
      throw new Error('file addressing exceeded the Number.MAX_SAFE_INTEGER.')
    }
    if (value > 0xffffffff) {
      buffer.writeUInt32LE(value & 0xffffffff, position)
      buffer.writeUInt32LE(
        Math.floor(value / 0x100000000),
        position === undefined ? 4 : position + 4
      )
    } else {
      buffer.writeUInt32LE(value, position)
      buffer.writeUInt32LE(0, position === undefined ? 4 : position + 4)
    }
  },

  createReadStreamFromBuffer: function (buffer, opts) {
    const stream = new Readable(opts)
    stream.push(buffer)
    stream.push(null)
    return stream
  }
}
