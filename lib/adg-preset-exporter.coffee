_          = require 'underscore'
fs         = require 'fs'
data       = require 'gulp-data'
tap        = require 'gulp-tap'
riffReader = require 'riff-reader'
msgpack    = require 'msgpack-lite'

# @templateFilePath required String
#    template file path
# --------------------------------
module.exports = (templateFilePath) ->
  new AdgPresetExporter templateFilePath

class AdgPresetExporter
  constructor: (templateFilePath) ->
    @template = _.template fs.readFileSync templateFilePath, "utf8"

  # gulp phase 1 parse nksf
  # --------------------------------
  gulpParseNksf: ->
    data (nksf) ->
      obj = {}
      (riffReader nksf.contents or nksf.path, 'NIKS').readSync (id, chunk) ->
        switch id
          when 'NISI'
            obj.nisi = msgpack.decode chunk.slice 4
          when 'NICA'
            obj.nica = msgpack.decode chunk.slice 4
          when 'PLID'
            obj.plid = msgpack.decode chunk.slice 4
          when 'PCHK'
            obj.pluginState = chunk.slice 4
      , ['NISI', 'NICA', 'PLID', 'PCHK']
      nksf: obj
      
  # gulp phase 2 template
  #
  # @file vinyl file or file path
  # @return xml string
  # --------------------------------
  gulpTemplate: ->
    _this = @
    tap (nksf) ->
      nksf.contents = new Buffer _this.build nksf.data.nksf.pluginState, nksf.data.nksf.nica

  # convert NKSF file to adg XML string
  #
  # @pluginState Buffer
  # @nica        Object NICA ni8 object
  # @return xml string
  # --------------------------------
  build: (pluginState, nica) ->
    embed =
      params: []
      bufferLines: []
    for page, pageIndex in nica.ni8
      for param, paramIndex in page
        if _.isNumber param.id
          embed.params.push
            id: param.id
            name: param.name
            visualIndex: pageIndex * 8 + paramIndex
        break if embed.params.length >= 128
      break if embed.params.length >= 128
    lines = []
    size = pluginState.length
    offset = 0
    while offset < size
      end = offset + 40
      end = size if end > size
      embed.bufferLines.push pluginState.toString 'hex', offset, end
      offset += 40
    @template embed
