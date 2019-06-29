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
  # @param func {function} - function to modifying embed params.
  # @return {TransformStream}
  # --------------------------------
  gulpTemplate: (func) ->
    _this = @
    tap (nksf) ->
      nksf.contents = Buffer.from _this.build nksf.data.nksf.pluginState, nksf.data.nksf.nica, nksf, func

  # convert NKSF file to adg XML string
  #
  # @param pluginState {Buffer}
  # @param nica {Object} - Object NICA ni8 object
  # @param func {function} - function to modifying embed params.
  # @return xml string
  # --------------------------------
  build: (pluginState, nica, nksf, func) ->
    embed =
      params: []
      bufferLines: []
    if nica.ni8
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
    func nksf, embed if _.isFunction func
    @template embed
