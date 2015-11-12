# RIFF builder
#
# @ref https://msdn.microsoft.com/en-us/library/windows/desktop/dd798636(v=vs.85).aspx


assert = require 'assert'
_      = require 'underscore'

# function(file, formType)
#
# - file      String filepath or content buffer
# - fileType  4 characters id
# - return    instance of builder
module.exports = (formType) ->
  new RIFFBuilder formType

class RIFFBuilder
  # new RIFFBuilder(file, formType)
  #
  # - file      String filepath or content buffer
  # - fileType  4 characters id
  constructor: (formType) ->
    @buf = new Buffer 0
    # file headder
    @_pushId 'RIFF'     # magic
    @_pushUInt32 4      # size
    @_pushId formType   # file type


  # pushChunk(chunkId, data)
  #
  # - chunkId  4 characters id
  # - data     chunk data buffer.
  # - return this instance.
  pushChunk: (chunkId, data) ->
    @_pushId chunkId
    @_pushUInt32 data.length
    @_push data if data.length
    
    # padding for 16bit boundary
    if data.length & 0x01
      @_padding()
    @

  # buffer()
  #
  # - return current buffer of RIFF file content
  buffer: ->
    # set file size = buffer size - 8 (magic + size)
    @buf.writeUInt32LE (@tell() - 8), 4
    @buf

  # tell()
  #
  # - return current buffer size.
  tell: ->
    @buf.length

  _push: (buf, start, end) ->
    b = buf
    if _.isNumber start
      if _.isNumber end
        b = buf.slice start, end
      else
        b = buf.slice start
    @buf = Buffer.concat [@buf, b]
    @

  _pushUInt32: (value) ->
    b = new Buffer 4
    b.writeUInt32LE value, 0
    @_push b
    @

  _pushId: (value) ->
    assert.ok (_.isString value), "Id msut be string. id:#{value}"
    b = new Buffer value, 'ascii'
    assert.ok (b.length is 4), "Id msut be 4 characters string. id:#{value}"
    @_push b
    @

  _padding: (value) ->
    @_push new Buffer [0]
    @
