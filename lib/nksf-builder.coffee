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
  # @magic required String
  #   plugin id
  # @nica optional String or Buffer or vinyl file or JSON object
  # --------------------------------
  constructor: (magic, nica) ->
    @plid = _serializeMagic magic
    @nica = _chunk nica

  gulp: ->
    tap (f) =>
      f.contents = @build f.data.nksf.pchk, f.data.nksf.nisi, f.data.nksf.nica
      
  # @pchk required PCHK chunk - plugin state
  # @nisi required NISI chunk - metadata
  # @nica optional NICA chunk - mapping
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
    riff.pushChunk 'PCHK', _chunk pchk
    # output file contents
    riff.buffer()

_chunk = (arg) ->
  switch
    when not arg
      undefined
    when Buffer.isBuffer arg
      # chunk contents
      arg
    when arg.contents and Buffer.isBuffer arg.contents
      # vinyl file contents
      arg.contents
    when _.isString arg
      # JSON file path
      _serialize JSON.parse fs.readFileSync arg, "utf8"
    when _.isString arg.path
      # vinyl file path
      _serialize JSON.parse fs.readFileSync arg.path, "utf8"
    when _.isObject arg
      # JSON object
      _serialize arg
    else
      throw new Error 'unsupported argument format.'

# esrilize to PLID chunk
_serializeMagic = (magic) ->
  buffer = new Buffer 4
  buffer.write magic, 0, 4, 'ascii'
  _serialize "VST.magic": buffer.readUInt32BE 0

# srilize to chunk
_serialize = (obj) ->
  ver = new Buffer 4
  ver.writeUInt32LE $.chunkVer
  Buffer.concat [ver, msgpack.encode obj]
