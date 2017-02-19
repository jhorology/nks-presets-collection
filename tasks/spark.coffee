# ---------------------------------------------------------------
# Arturia Spark 2
#
# notes
#  - Komplete Kontrol 1.6.2.5
#  - Spark 2.3.0 build 179(rev:f60c11b)
#  - Ableton Live 9.6.2
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Spark'
  vendor: 'Arturia'
  magic: 'ArDS'
  
  #  local settings
  # -------------------------

  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Spark/templates/Spark.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Spark/templates/Spark.bwpreset'
  nksPresets: '/Library/Arturia/Spark/Third Party/Native Instruments/presets'

# regist common gulp tasks
# --------------------------------
commonTasks $, on # NKS ready

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
      file.path = path.join dirname, file.data.nksf.nisi.types[0][1], file.relative
    .pipe gulp.dest "#{$.Ableton.drumRacks}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ->
  exporter = bwExporter $.bwpresetTemplate
  gulp.src ["#{$.nksPresets}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe tap (file) ->
      # edit file path
      dirname = path.dirname file.path
      file.path = path.join dirname, file.data.nksf.nisi.types[0][1], file.relative
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState()
    .pipe exporter.gulpRewriteMetadata()
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
