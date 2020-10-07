#  Native Instruments Dirt 1.1.0 (R47) - initial commit
# ---------------------------------------------------------------
fs            = require 'fs'
path          = require 'path'
{ Readable }  = require 'stream'
gulp          = require 'gulp'
msgpack       = require 'msgpack-lite'
first         = require 'gulp-first'
gzip          = require 'gulp-gzip'
tap           = require 'gulp-tap'
rename        = require 'gulp-rename'
adgExporter   = require '../lib/adg-preset-exporter'
bwExporter    = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'

#
# buld environment & misc settings
#-------------------------------------------
$ = require '../config'
$ = Object.assign {}, $,
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Dirt'
  vendor: 'Native Instruments'
  magic: 'Ni$L'
  
  #  local settings
  # -------------------------
  nksPresets: [
    '/Library/Application Support/Native Instruments/Dirt/**/*.nksfx'
  ]
  # Ableton Live 10.1.18
  abletonRackTemplate: 'src/Dirt/templates/Dirt.adg.tpl'
  # Bitwig Studio 3.2.8 preset file
  bwpresetTemplate: 'src/Dirt/templates/Dirt.bwpreset'
  # VST2 plugin state object template
  pluginStateTemplate:
    cached_preset_state:
      component: null
      is_changed: false
      preset_info:
        filename: ''
        is_factory: true
        name: ''
    controller_maps: undefined     # -> object that's decoded from NICA chunk.
    preset_state:
      component:
        parameters: '%PARAMETERS%' # -> parameters property that's decoded from PCHK chunk.
        view_size: 125
      is_changed: false
      preset_info:
        filename: undefined        # ->  volume name + .nksf file path, delimiter = ':'
        is_factory: true
        name: undefined            # ->  preset name
    selected_preset_cache: 0

# register common gulp tasks
# --------------------------------
# commonTasks $, on  # nks-ready


# export
# --------------------------------

###
  convert NKSF pluginState -> VST2 pluginState
  DAW's plugin state is different from NKSF PCHK chunk.
### 
vst2PluginState = (file, nksf) ->
  codec = msgpack.createCodec()
  decode = codec.decode
  encode = codec.encode
  # parameters object should be type-strict.
  parametersStart = undefined
  parameters = undefined
  codec.decode = (decoder) ->
    result = decode(decoder)
    if result is 'parameters'
      parametersStart = decoder.offset
    # WTF! some nksfx has extra byte 0
    if typeof result is 'object' and result.parameters
      parameters = nksf.pluginState.slice parametersStart, decoder.offset
      if decoder.offset isnt nksf.pluginState.length
        console.warn "[#{file.relative}] has extra byte(s). packed message size:", decoder.offset, 'plugin-state size:', nksf.pluginState.length
    result
  codec.encode = (encoder, input) ->
    if input is '%PARAMETERS%'
      offset = encoder.offset
      encoder.reserve parameters.length
      encoder.buffer[offset++] = parameters[i] for i in [0...parameters.length]
    else
      encode encoder, input

  msgpack.decode nksf.pluginState, codec: codec
  # clone template
  obj = Object.assign {}, $.pluginStateTemplate
  obj.controller_maps = nksf.nica
  # TODO this may not work with windows
  obj.preset_state.preset_info.filename = 'Macintosh HD' + file.path.replace /\//g, ':'
  obj.preset_state.preset_info.name = nksf.nisi.name
  # console.log JSON.stringify obj, null, '  '
  Buffer.concat [
    # 4 bytes reversed VST2 magic
    Buffer.from $.magic.split('').reverse().join('')
    # 4 bytes unknown always 0200 0000
    Buffer.from [2,0,0,0]
    # mssagepack encoded content
    msgpack.encode obj, codec: codec
    # ZERO terminate
    Buffer.from [0]
 ]
  
# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src $.nksPresets
    .pipe exporter.gulpParseNksf()
    .pipe tap (file) ->
      file.data.nksf.pluginState = vst2PluginState(file, file.data.nksf)
    .pipe exporter.gulpTemplate()
    .pipe gzip append: off       # append '.gz' extension
    .pipe rename extname: '.adg'
    .pipe gulp.dest "#{$.Ableton.effectRacks}/#{$.dir}"

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-appc", ->
  gulp.src $.nksPresets
    .pipe first()
    .pipe appcGenerator.gulpNksf2Appc $.magic, $.dir, on
    .pipe rename
      dirname: ''
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.defaults}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ->
  exporter = bwExporter $.bwpresetTemplate
  gulp.src $.nksPresets
    .pipe exporter.gulpParseNksf()
    .pipe tap (file) ->
      file.data.nksf.pluginState = vst2PluginState(file, file.data.nksf)
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState()
    .pipe exporter.gulpRewriteMetadata()
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
