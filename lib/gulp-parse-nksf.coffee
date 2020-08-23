data       = require 'gulp-data'
riffReader = require 'riff-reader'
msgpack    = require 'msgpack-lite'

module.exports = ->
  data (file) ->
    obj = {}
    (riffReader file.contents or file.path, 'NIKS').readSync (id, chunk) ->
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
    if file.data
      Object.assign file.data, nksf: obj
    else
      nksf: obj
