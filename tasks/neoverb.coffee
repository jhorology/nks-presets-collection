# iZotope Neoverb 1.0.0
# ---------------------------------------------------------------
fs            = require 'fs'
path          = require 'path'
{ Readable }  = require 'stream'
zlib          = require 'zlib'
msgpack       = require 'msgpack-lite'
gulp          = require 'gulp'
tap           = require 'gulp-tap'
data          = require 'gulp-data'
rename        = require 'gulp-rename'
uuid          = require 'uuid'
vstpreset     = require '../lib/vstpreset'

$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  dir: 'Neoverb'
  vendor: 'iZotope, Inc.'
  magic: 'ZMR1'
  vst3ClassId: '5653545a-4d52-314e-656f-766572620000'

  #  local settings
  # -------------------------
  izotopePresets: [
    '/Library/Application Support/iZotope/Neoverb/Presets/**/*.preset'
  ]
  # Bitwig Studio 3.2.8 preset file
  bwpresetTemplate: 'src/Neoverb/templates/Neoverb.bwpreset'
  # vstpreset meta info
  metaInfo: '''
<?xml version='1.0' encoding='utf-8'?>
<MetaInfo>
  <Attribute id='MediaType' value='VstPreset' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInCategory' value='Fx|Reverb' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInName' value='Neoverb' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInVendor' value='iZotope, Inc.' type='string' flags='writeProtected'></Attribute>
</MetaInfo>
'''

###
 VST3 component state
  - A. header                       | 8 byte, always b0e5 8800 0000 0000
  - B. size of (C + D)              | 4 byte UInt32LE
  - C. uncompessed size of D        | 4 byte UInt32LE
  - D. zlib compressed content      | JSON pluginUUID is differnt from VST2
###
vst3ComponentState = (file) ->
  initialState = require '../src/Neoverb/presets/INIT - Neoverb.vst3.json'
  obj = if file
    preset = JSON.parse file.contents
    initialState['Context State'].Value['Current Preset'] =
      Type: 'Base64'
      Value: (
        msgpack.encode
          path: (path.dirname file.relative).split '/'
          leafName: path.basename file.relative, '.preset'
      ).toString 'base64'
    initialState['Context State'].Value['PluginUUID'].Value = uuid.v4()
    Object.keys(preset.data.Value).reduce (obj, key) ->
      keys = key.split '.'
      unless keys[0] is 'dsp'
        throw new Error "Unknown parameter key prefix:#{keySplit[0]}"
      unless keys.length is 3
        throw new Error "Unexpected parameter key depth:#{keySplit}"
      param = obj['DSP State'].Value['DSP Elements'].Value[keys[1]]?.Value[keys[2]]
      unless param
        throw new Error "Not found parameter. key: [#{key}]"
      param.Type = preset.data.Value[key].Type
      param.Value = preset.data.Value[key].Value
      obj
    , initialState
  else
    initialState
  json = JSON.stringify obj, null, '  '
  content = Buffer.from json + '\n'
  uncompressedSize = Buffer.alloc 4
  uncompressedSize.writeUInt32LE content.length
  content = zlib.deflateSync content
  contentSize = Buffer.alloc 4
  contentSize.writeUInt32LE content.length + 4
  Buffer.concat [
    Buffer.from 'b0e5880000000000', 'hex'
    contentSize
    uncompressedSize
    content
  ]


# export izotope .preset to .vstpreset
gulp.task "#{$.prefix}-export-vstpreset", ->
  gulp.src $.izotopePresets
    .pipe data (file, done) ->
      contents = vst3ComponentState file
      readable = new Readable objectMode: on
      writable = vstpreset.createWriteObjectStream $.vst3ClassId
      readable
        .pipe writable
      writable.on 'finish', ->
        file.contents = writable.getBuffer()
        done()
      # component state
      readable.push
        id: 'Comp'
        contents: contents
      # controller state
      readable.push
        id: 'Cont'
        contents: contents
      # meta info
      readable.push
        id: 'Info'
        contents: Buffer.from $.metaInfo
      readable.push null
    .pipe rename extname: '.vstpreset'
    .pipe gulp.dest path.join $.Ableton.vstPresets, $.vendor, $.dir
