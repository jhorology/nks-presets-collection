# Native Instruments Massive 1.0.0(R116)
#
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
first       = require 'gulp-first'
tap         = require 'gulp-tap'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
_           = require 'underscore'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Massive X'
  vendor: 'Native Instruments'
  magic: 'Ni$H'
  
  #  local settings
  # -------------------------
  nksPresets: "/Volumes/Media/Music/Native Instruments/Massive X Factory Library/Presets"
  # Ableton Live 10.1
  abletonRackTemplate: 'src/Massive X/templates/Massive X.adg.tpl'
  # Bitwig Studio 2.5.1 preset file
  bwpresetTemplate: 'src/Massive X/templates/Massive X.bwpreset'

# register common gulp tasks
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
      file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
    .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ->
  exporter = bwExporter $.bwpresetTemplate
  gulp.src ["#{$.nksPresets}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe tap (file) ->
      # edit file path
      dirname = path.dirname file.path
      file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState()
    .pipe exporter.gulpRewriteMetadata (nisi) ->
      meta = bwExporter.defaultMetaMapper nisi
      meta.tags.push 'massive_x_factory'
      meta
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
