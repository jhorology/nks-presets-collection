# Novation V-Station
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - V-Station  2.3
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  dir: 'VStation'
  vendor: 'Novation'
  magic: 'NvS0'

  #  local settings
  # -------------------------

  # Ableton Live 9.6.2
  abletonInstrumentRackTemplate: 'src/VStation/templates/VStation.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/VStation/templates/VStation.bwpreset'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      basename = path.basename file.path, '.pchk'
      type = basename.replace /^[0-9]+ /, ''
      type = type.replace /[ ,0-9]+$/, ''
      file.contents = new Buffer util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [[type]]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['VStation', 'VStation Factory', '']
        author: ''
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

#
# build
# --------------------------------

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic, "src/#{$.dir}/mappings/default.json"
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"], read: on
    .pipe data (pchk) ->
      nksf:
        pchk: pchk
        nisi: "#{pchk.path[..-5]}meta"
    .pipe builder.gulp()
    .pipe rename extname: '.nksf'
    .pipe gulp.dest "dist/#{$.dir}/User Content/#{$.dir}"

# export
# --------------------------------

# export from .nksf to .adg ableton rack
# TODO ableton won't restore plugin state.
# gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
#   exporter = adgExporter $.abletonRackTemplate
#   gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
#     .pipe exporter.gulpParseNksf()
#     .pipe exporter.gulpTemplate()
#     .pipe exporter.gulp()
#     .pipe gzip append: off       # append '.gz' extension
#     .pipe rename extname: '.adg'
#     .pipe tap (file) ->
#       # edit file path
#       dirname = path.dirname file.path
#       file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
#     .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
# TODO bitwig won't restore plugin state.
# gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
#   exporter = bwExporter $.bwpresetTemplate
#   gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
#     .pipe exporter.gulpParseNksf()
#     .pipe tap (file) ->
#       # edit file path
#       dirname = path.dirname file.path
#       file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
#     .pipe exporter.gulpReadTemplate()
#     .pipe exporter.gulpAppendPluginState()
#     .pipe exporter.gulpRewriteMetadata()
#     .pipe rename extname: '.bwpreset'
#     .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"

