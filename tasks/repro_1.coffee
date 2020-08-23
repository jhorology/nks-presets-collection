# u-he Diva 1.4.1.4078
#
# ---------------------------------------------------------------
path        = require 'path'
stream      = require 'stream'
gulp        = require 'gulp'
first       = require 'gulp-first'
tap         = require 'gulp-tap'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
data        = require 'gulp-data'
_           = require 'underscore'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'
parseNksf   = require '../lib/gulp-parse-nksf'
vstpreset   = require '../lib/vstpreset'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Repro-1'
  vendor: 'u-he'
  magic: 'uR_1'
  vst3ClassId: 'd39d5b69-d6af-42fa-1234-567875525f31'
  
  #  local settings
  # -------------------------
  nksPresets: '/Library/Application Support/u-he/Repro-1/NKS/Repro-1'
  # Ableton Live 10.1 beta12
  abletonRackTemplate: 'src/Repro-1/templates/Repro-1.adg.tpl'
  # Bitwig Studio 2.5.0 beta 5 preset file
  bwpresetTemplate: 'src/Repro-1/templates/Repro-1.bwpreset'
  abletonMetaInfo: '''
<?xml version='1.0' encoding='utf-8'?>
<MetaInfo>
  <Attribute id='MediaType' value='VstPreset' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInCategory' value='Instrument|u-he' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInName' value='Repro-1' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInVendor' value='u-he' type='string' flags='writeProtected'></Attribute>
</MetaInfo>
'''

# regist common gulp tasks
# --------------------------------
commonTasks $, on  # nks-ready

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src ["#{$.nksPresets}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpTemplate()
    .pipe gzip append: off       # append '.gz' extension
    .pipe rename extname: '.adg'
    .pipe tap (file) ->
      # edit file path
      dirname = path.dirname file.path
      type = file.data.nksf.nisi.types[0][0].replace 'Piano/Keys', 'Piano & Keys'
      file.path = path.join dirname, type, file.relative
    .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ->
  exporter = bwExporter $.bwpresetTemplate
  gulp.src ["#{$.nksPresets}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe tap (file) ->
      # edit file path
      dirname = path.dirname file.path
      type = file.data.nksf.nisi.types[0][0].replace 'Piano/Keys', 'Piano & Keys'
      file.path = path.join dirname, type, file.relative
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState()
    .pipe exporter.gulpRewriteMetadata()
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"

# export from .nksf to .vstpreset
gulp.task "#{$.prefix}-export-vstpreset", ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src ["#{$.nksPresets}/**/*.nksf"]
    .pipe parseNksf()
    .pipe rename extname: '.vstpreset'
    .pipe tap (file) ->
      # edit file path
      dirname = path.dirname file.path
      type = file.data.nksf.nisi.types[0][0].replace 'Piano/Keys', 'Piano & Keys'
      file.path = path.join dirname, type, file.relative
    .pipe data (file, done) ->
      # Comp, Cont chunk contents
      #  - size = 4 byte  UInt32LE
      #  - plugin-states
      size = file.data.nksf.pluginState.length
      contents = Buffer.concat [
        Buffer.alloc 4
        file.data.nksf.pluginState
      ]
      contents.writeUInt32LE(size)
      readable = new stream.Readable objectMode: on
      writable = vstpreset.createWriteObjectStream $.vst3ClassId
      readable
        .pipe writable
      writable.on 'finish', ->
        file.contents = writable.getBuffer()
        done()
      readable.push
        id: 'Comp'
        contents: contents
      readable.push
        id: 'Cont'
        contents: contents
      readable.push
        id: 'Info'
        contents: Buffer.from $.abletonMetaInfo
      readable.push null
    .pipe gulp.dest "#{$.Ableton.vstPresets}/#{$.vendor}/#{$.dir}"


# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-appc", ->
  gulp.src ["#{$.nksPresets}/**/*.nksf"]
    .pipe first()
    .pipe appcGenerator.gulpNksf2Appc()
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.defaults}/#{$.dir}"

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-vst3-appc", ->
  gulp.src ["#{$.nksPresets}/**/*.nksf"]
    .pipe first()
    .pipe appcGenerator.gulpNksf2Vst3Appc $.vst3ClassId
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.vst3Defaults}/#{$.vendor}/#{$.dir}"
