# ---------------------------------------------------------------
# D16 LuSH-101
#
# notes
#  - Komplete Kontrol 1.6.2.5
#  - Cyclop 1.2.0
#  - Ableton Live 9.6.2
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
gzip        = require 'gulp-gzip'
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
  dir: 'Cyclop'
  vendor: 'Sugar Bytes'
  magic: 'sbcy'

  #  local settings
  # -------------------------
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Cyclop/templates/Cyclop.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Cyclop/templates/Cyclop.bwpreset'
  nksPresets: '/Library/Application Support/Sugar Bytes/Cyclop/NKS/Presets'

# regist common gulp tasks
# --------------------------------
commonTasks $, on  # nks-ready

# export
# Discontinued
#   Ableton won't restore plugin state
#   I gave up analysing plugin state. It's diffrent between Live and KK.
#   I couldn't find rules.
# --------------------------------

# # export from .nksf to .adg ableton rack
# gulp.task "#{$.prefix}-export-adg", ->
#   exporter = adgExporter $.abletonRackTemplate
#   gulp.src ["#{$.nksPresets}/**/*.nksf"]
#     .pipe exporter.gulpParseNksf()
#     .pipe exporter.gulpTemplate()
#     .pipe gzip append: off       # append '.gz' extension
#     .pipe rename extname: '.adg'
#     .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# # export from .nksf to .bwpreset bitwig studio preset
# gulp.task "#{$.prefix}-export-bwpreset", ->
#   exporter = bwExporter $.bwpresetTemplate
#   gulp.src ["#{$.nksPresets}/**/*.nksf"]
#     .pipe exporter.gulpParseNksf()
#     .pipe exporter.gulpReadTemplate()
#     .pipe exporter.gulpAppendPluginState()
#     .pipe exporter.gulpRewriteMetadata()
#     .pipe rename extname: '.bwpreset'
#     .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
