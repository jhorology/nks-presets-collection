#
# appc (ableton plugin parameter configuration) generator
#
#  note
#  - it seems parameters are sorted by value (x-slot * 4 + y-slot) and dosen't support absolute slot positioning.
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
  #  - pluginId   required 4 characters String or int32
  #  - pluginName required String
  #  - isAudioFX  optional default = off
  #  - isVst3  vst3 or not default = off
  # --------------------------------
  nica2appc: (nica, pluginId, pluginName, isAudioFX, isVst3) ->
    if not isVst3 and _.isString pluginId
      pluginId = (Buffer.from pluginId).readUInt32BE(0)
    appc =
      id: 'application/vnd.ableton.plugin-configuration'
      version: '1.0'
      "device-id": "device:vst#{if isVst3 then '3' else ''}:#{if isAudioFX then 'audiofx' else 'instr'}:#{pluginId}?n=#{encodeURIComponent(pluginName)}"
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
        if param.id?
          param.slot = pageIndex * 8 + slotIndex
          params.push param
        slotIndex++
      pageIndex++
    appc.groups.push group section, params if params.length
    appc

  #
  #  gulp plugin for .nksf to .appc
  #  - pluginName optional String default = bankchanin[0]
  #  - isAudioFX  optional boolean default = off
  # --------------------------------
  gulpNksf2Appc: (pluginName, isAudioFX) ->
    chunks = ['NICA', 'PLID']
    unless pluginName and _.isBoolean(isAudioFX)
      chunks.push 'NISI'
    tap (file) =>
      nica = pluginId = undefined
      (riffReader file.contents or file.path, 'NIKS').readSync (id, chunk) ->
        switch id
          when 'NISI'
            nisi = msgpack.decode chunk.slice 4
            pluginName ?= nisi.bankchain[0]
            isAudioFX ?= nisi.deviceType is 'FX'
          when 'NICA'
            nica = msgpack.decode chunk.slice 4
          when 'PLID'
            pluginId = (msgpack.decode chunk.slice 4)['VST.magic']
      , chunks
      file.contents = Buffer.from (util.beautify @nica2appc nica, pluginId, pluginName, isAudioFX), 'utf8'

  #
  #  gulp plugin for .nksf to .appc
  #  - pluginName optional String default = bankchanin[0]
  #  - isAudioFX  optional boolean default = off
  # --------------------------------
  gulpNksf2Vst3Appc: (classId, pluginName, isAudioFX) ->
    chunks = ['NICA']
    unless pluginName and _.isBoolean(isAudioFX)
      chunks.push 'NISI'
    tap (file) =>
      nica = pluginId = undefined
      (riffReader file.contents or file.path, 'NIKS').readSync (id, chunk) ->
        switch id
          when 'NISI'
            nisi = msgpack.decode chunk.slice 4
            pluginName ?= nisi.bankchain[0]
            isAudioFX ?= nisi.deviceType is 'FX'
          when 'NICA'
            nica = msgpack.decode chunk.slice 4
      , chunks
      file.contents = Buffer.from (util.beautify @nica2appc nica, classId, pluginName, isAudioFX, on), 'utf8'
  #
  #  gulp plugin for NICA json file to .appc
  #  - pluginId   required 4 characters String or int32
  #  - pluginName required String
  #  - isAudioFX  optional boolean default = off
  # --------------------------------
  gulpNica2Appc: (pluginId, pluginName, isAudioFX, isVst3) ->
    tap (file) =>
      nica = if file.contents
        JSON.parse file.contents.toString 'utf8'
      else
        util.readJson file.path
      appc = @nica2appc nica, pluginId, pluginName, isAudioFX, isVst3
      file.contents = Buffer.from (util.beautify appc), 'utf8'
