# Novation BassStation
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - BassStation  2.1
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/BassStationPack4Bitwig
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
  dir: 'BassStationStereo'
  vendor: 'Novation'
  # magic: 'NvB2'        # BassStation - not work on KK
  magic: 'Nvb2'        # BassStationStreo

  #  local settings
  # -------------------------

  # Ableton Live 9.6.2
  abletonInstrumentRackTemplate: 'src/BassStationStereo/templates/BassStationStereo.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/BassStationStereo/templates/BassStationStereo.bwpreset'


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
      type = switch
        when basename.match /Bass/ then 'Bass'
        when basename.match /Lead/ then 'Lead'
        else "Other"
      file.contents = new Buffer util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [[type]]
        modes: []
        name: path.basename file.path, '.pchk'
        deviceType: 'INST'
        comment: ''
        bankchain: ['BassStationStereo', 'BassStation Factory', '']
        author: ''
      , on
    .pipe rename extname: '.meta'
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
# gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
#   exporter = adgExporter $.abletonRackTemplate
#   gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
#     .pipe exporter.gulpParseNksf()
#     .pipe exporter.gulpTemplate()
#     .pipe gzip append: off       # append '.gz' extension
#     .pipe rename extname: '.adg'
#     .pipe tap (file) ->
#       # edit file path
#       dirname = path.dirname file.path
#       file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
#     .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
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
