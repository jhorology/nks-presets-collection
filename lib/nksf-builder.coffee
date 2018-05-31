_           = require 'underscore'
fs          = require 'fs'
msgpack     = require 'msgpack-lite'
riffBuilder = require './riff-builder'
tap         = require 'gulp-tap'
 
module.exports = (magic, nica) ->
  new NksfBuilder magic, nica

$ =
 chunkVer: 1

class NksfBuilder
  # @magic required String - 4 charcter string
  # @nica optional String  - mapping
  #   Buffer or vinyl file    - NICA chunk contents
  #   String                  - JSON file path
  #   Object                  - JSON object
  # --------------------------------
  constructor: (magic, nica) ->
    @plid = _serializeMagic magic
    @nica = _chunk nica if nica

  gulp: ->
    _this = @
    tap (f) ->
      f.contents = _this.build f.data.nksf.pchk, f.data.nksf.nisi, f.data.nksf.nica

  # @pchk required PCHK chunk - plugin state
  #   Buffer or vinyl file    - PCHK file contents
  #   String                  - PCHK file path
  # @nisi required NISI chunk - metadata
  #   Buffer or vinyl file    - NISI chunk contents
  #   String                  - JSON file path
  #   Object                  - JSON object
  # @nica optional NICA chunk - mapping
  #   Buffer or vinyl file    - NICA chunk contents
  #   String                  - JSON file path
  #   Object                  - JSON object
  # --------------------------------
  build: (pchk, nisi, nica) ->
    riff = riffBuilder 'NIKS'
    # NISI chunk -- metadata
    riff.pushChunk 'NISI', _chunk nisi
    # NACA chunk -- mapping
    riff.pushChunk 'NICA',  if nica then (_chunk nica) else @nica
    # PLID chunk -- plugin id
    riff.pushChunk 'PLID', @plid
    # PCHK chunk -- raw preset (pluginstates)
    riff.pushChunk 'PCHK', _pchk pchk
    # output file contents
    riff.buffer()

# MessagePacked chunk
_chunk = (arg) ->
  switch
    when not arg
      throw new Error "argument can not be empty."
    when Buffer.isBuffer arg
      # chunk contents
      arg
    when arg.contents and Buffer.isBuffer arg.contents
      # vinyl file contents
      arg.contents
    when arg.path and _.isString arg.path
      # vinyl file path
      fs.readFileSync arg.path
    when _.isString arg
      # JSON file path
      _serialize JSON.parse fs.readFileSync arg, "utf8"
    when _.isObject arg
      # JSON object
      _serialize arg
    else
      throw new Error "unsupported argument format. type:#{typeof arg}"

# MessagePacked chunk
_pchk = (arg) ->
  switch
    when not arg
      throw new Error "argument can not be empty."
    when Buffer.isBuffer arg
      # chunk contents
      arg
    when arg.contents and Buffer.isBuffer arg.contents
      # vinyl file contents
      arg.contents
    when arg.path and _.isString arg.path
      # vinyl file path
      fs.readFileSync arg.path
    when _.isString arg
      # file path
      fs.readFileSync arg
    else
      throw new Error "unsupported argument format. type:#{typeof arg}"

# esrilize to PLID chunk
_serializeMagic = (magic) ->
  buffer = Buffer.alloc 4
  buffer.write magic, 0, 4, 'ascii'
  _serialize "VST.magic": buffer.readUInt32BE 0

# srilize to chunk
_serialize = (obj) ->
  ver = Buffer.alloc 4
  ver.writeUInt32LE $.chunkVer
  Buffer.concat [ver, msgpack.encode obj]
