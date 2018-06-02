#
# appc (ableton plugin parameter configuration) generator
#
#  note
#  - it seems parameters are sorted by value (x-slot * 4 + y-slot) and couldn't define empty slot.
#  - parameter name property does not affect at all.
#  - group name property and grouping does not affect at all.
# --------------------------------

data       = require 'gulp-data'
tap        = require 'gulp-tap'
riffReader = require 'riff-reader'
_          = require 'underscore'
msgpack    = require 'msgpack-lite'
util       = require './util'

module.exports =
  #
  #  nica object to appc object
  #  - nica NICA object
  #  - pluginId 4 character String or int32
  #  - pluginName String
  # --------------------------------
  nica2appc: (nica, pluginId, pluginName) ->
    if _.isString pluginId
      pluginId = (Buffer.from pluginId).readUInt32BE(0)
    appc =
      id: 'application/vnd.ableton.plugin-configuration'
      version: '1.0'
      "device-id": "device:vst:instr:#{pluginId}?n=#{encodeURIComponent(pluginName)}"
      groups: []
    group = (name, params) ->
      name: name || "Undefined"
      parameters: for p in params
        name: p.name || ""
        id: p.id
        'x-slot': p.slot / 4 | 0
        'y-slot': p.slot % 4

    unless nica and nica.ni8
      return undefined
    section = nica.ni8[0][0].section
    params = []
    pageIndex = 0
    for page in nica.ni8
      slotIndex = 0
      for param in page
        if param.section and param.section isnt section
          appc.groups.push group section, params if params.length
          params = []
          section = param.section
        if param.id
          param.slot = pageIndex * 8 + slotIndex
          params.push param
        slotIndex++
      pageIndex++
    appc.groups.push group section, params if params.length
    appc

  #
  #  gulp plugin for .nksf to .appc
  #  - pluginName optional String
  # --------------------------------
  gulpNksf2Appc: (pluginName) ->
    chunks = ['NICA', 'PLID']
    unless pluginName
      chunks.push 'NISI'
    _this = @
    tap (file) ->
      nica = pluginId = undefined
      (riffReader file.contents or file.path, 'NIKS').readSync (id, chunk) ->
        switch id
          when 'NISI'
            pluginName = (msgpack.decode chunk.slice 4).bankchain[0]
          when 'NICA'
            nica = msgpack.decode chunk.slice 4
          when 'PLID'
            pluginId = (msgpack.decode chunk.slice 4)['VST.magic']
      , chunks
      file.contents = Buffer.from (util.beautify _this.nica2appc nica, pluginId, pluginName), 'utf8'

  #
  #  gulp plugin for NICA json file to .appc
  #  - pluginId required 4 characters String or int32
  #  - pluginName required String
  # --------------------------------
  gulpNica2Appc: (pluginId, pluginName) ->
    _this = @
    tap (file) ->
      nica = if file.contents
        JSON.parse file.contents.toString 'utf8'
      else
        util.readJson file.path
      appc = _this.nica2appc nica, pluginId, pluginName
      file.contents = Buffer.from (util.beautify appc), 'utf8'
