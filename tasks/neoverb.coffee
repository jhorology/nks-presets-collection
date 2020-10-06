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
commonTasks   = require '../lib/common-tasks'
vstpreset     = require '../lib/vstpreset'
nksfBuilder   = require '../lib/nksf-builder'
bwExporter    = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'
bwMetaRewrite = require 'gulp-bitwig-rewrite-meta'

$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  dir: 'Neoverb'
  vendor: 'iZotope, Inc.'
  # TODO what's encoding method? '939ccee2f3f4075de5d40af6aaf5c5c7'
  vendor_sanitized: 'izotope inc_939ccee2f3f4075de5d40af6aaf5c5c7'
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

# register common gulp tasks
# --------------------------------
commonTasks $

###
 VST2 plugin state
  - A. size of B + C + D + E        | 4 bytes UInt32LE
  - B. header                       | 8 bytes, always b0e5 8800 0000 0000
  - C. size of (C + D)              | 4 bytes UInt32LE
  - D. uncompessed size of D        | 4 bytes UInt32LE
  - E. zlib compressed content      | JSON pluginUUID is differnt from VST2
  - F. size of G                    | 4 bytes UInt32LE = 7
  - G. 'Default'                    | 7 bytes 'Default'
  @param file {Vinyl} preset file
###
vst2PluginState = (file) ->
  content = componentState file, '../src/Neoverb/presets/INIT - Neoverb.vst2.json'
  contentSize = Buffer.alloc 4
  contentSize.writeUInt32LE content.length
  Buffer.concat [
    contentSize
    content
    Buffer.from [7,0,0,0]
    Buffer.from 'Default'
  ]

###
 VST3 component state
  - A. header                       | 8 bytes, always b0e5 8800 0000 0000
  - B. size of (C + D)              | 4 bytes UInt32LE
  - C. uncompessed size of D        | 4 bytes UInt32LE
  - D. zlib compressed content      | JSON pluginUUID is differnt from VST2
  @param file {Vinyl} preset file
###
vst3ComponentState = (file) ->
  componentState file, '../src/Neoverb/presets/INIT - Neoverb.vst3.json'

componentState = (file, initJson) ->
  initialState = require initJson
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
        throw new Error "Unknown parameter key prefix:#{keys[0]}"
      unless keys.length is 3
        throw new Error "Unexpected parameter key depth:#{keys}"
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


#
# build
# --------------------------------

gulp.task "#{$.prefix}-dist-presets",  ->
  builder = nksfBuilder $.magic, require "../src/#{$.dir}/mappings/default.json"
  gulp.src $.izotopePresets
    .pipe data (file) ->
      nksf:
        pchk: Buffer.concat [
          Buffer.from [1,0,0,0]
          vst2PluginState file
        ]
        nisi:
          bankchain: [$.dir, 'Neoverb Factory', '']
          deviceType: 'FX'
          name: path.basename file.path, '.preset'
          types: [['Reverb'].concat (path.dirname file.relative).split '/']
          uuid: uuid.v4()
          vendor: $.vendor
    .pipe rename
      extname: '.nksfx'
    .pipe builder.gulp()
    .pipe gulp.dest "dist/#{$.dir}/User Content/#{$.dir}"

#
# export
# --------------------------------

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

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-vst3-appc", ->
  gulp.src ["src/#{$.dir}/mappings/default.json"]
    .pipe tap (file) ->
      object = appcGenerator.nica2appc JSON.parse file.contents
      , $.vst3ClassId
      , true # is Audio FX ?
      , true # is VST3 ?
      file.contents = Buffer.from JSON.stringify object, null, '  '
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.vst3Defaults}/#{$.vendor}/#{$.dir}"


# export from izotope .preset to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ->
  exporter = bwExporter $.bwpresetTemplate, vst3: on
  gulp.src $.izotopePresets
    .pipe data (file) ->
      vst3ComponentState: vst3ComponentState file
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendVstPreset (file, done) ->
      readable = new Readable objectMode: on
      writable = vstpreset.createWriteObjectStream $.vst3ClassId
      readable.pipe writable
      writable.on 'finish', ->
        done undefined,
          uuid: uuid.v4()
          contents: writable.getBuffer()
      readable.push
        id: 'Comp'
        contents: file.data.vst3ComponentState
      # 'Cont' chunk size = 0
      readable.push
        id: 'Cont'
        contents: file.data.vst3ComponentState
      readable.push null
    .pipe bwMetaRewrite (file) ->
       preset_category: ((path.dirname file.relative).split '/')[0]
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
