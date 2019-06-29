# u-he Diva 1.4.1.4078
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
  dir: 'Repro-5'
  vendor: 'u-he'
  magic: 'uR_5'
  
  #  local settings
  # -------------------------
  nksPresets: '/Library/Application Support/u-he/Repro-1/NKS/Repro-5'
  # Ableton Live 10.1 beta12
  abletonRackTemplate: 'src/Repro-5/templates/Repro-5.adg.tpl'
  # Bitwig Studio 2.5.0 beta 5 preset file
  bwpresetTemplate: 'src/Repro-5/templates/Repro-5.bwpreset'

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

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-appc", ->
  gulp.src ["#{$.nksPresets}/**/*.nksf"]
    .pipe first()
    .pipe appcGenerator.gulpNksf2Appc()
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.defaults}/#{$.dir}"
