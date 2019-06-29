# UVI Sparkverb
#
# notes
#  - Komplete Kontro 2.0.2(R2)
#  - Thorus 1.0.0
# ---------------------------------------------------------------
fs          = require 'fs'
path        = require 'path'
uuid        = require 'uuid'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
riff        = require 'gulp-riff-extractor'
gulpif      = require 'gulp-if'
msgpack     = require 'msgpack-lite'
_           = require 'underscore'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  # dir: 'UVIWorkstationVST'
  dir: 'Europa by Reason'
  vendor: 'Propellerhead Software'
  magic: "Euro"

  #  local settings
  # -------------------------
  # Ableton Live 10.1 Audio Effect Rack
  abletonRackTemplate: 'src/Europa by Reason/templates/Europa.adg.tpl'
  # Bitwig Studio 2.5.1 preset file
  bwpresetTemplate: 'src/Europa by Reason/templates/Europa.bwpreset'

# register common gulp tasks
# --------------------------------
commonTasks $


# preparing tasks
# --------------------------------

# https://www.native-instruments.com/forum/threads/nks-user-library.262959/page-54
# https://www.dropbox.com/sh/ursh7y1bz8dx0c3/AADXO4Zoq5gw1DpijjZeQk9ga?dl=0
gulp.task "#{$.prefix}-extract-meta-and-pchk", ->
  gulp.src ["temp/#{$.dir}/**/*.nksf"]
    .pipe riff chunk_ids: ['NISI', 'PCHK']
    .pipe gulpif (file) ->
      (path.extname file.path) is '.nisi'
    , tap (file) ->
      file.extname = '.meta'
      meta = msgpack.decode file.contents.slice 4
      basename = path.basename file.path, '.meta'
      meta.bankchain = [$.dir, 'Europa Factory', '']
      meta.uuid = util.uuid "src/#{$.dir}/presets/#{file.relative}"
      meta.name = basename
      meta.types = for type in meta.types
        type.map (t) -> if t.match /\w\/\w/ then t.replace '/', ' / ' else t
      file.contents = Buffer.from util.beautify meta, on
    .pipe gulp.dest "src/#{$.dir}/presets"


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
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpTemplate()
    .pipe gzip append: off       # append '.gz' extension
    .pipe rename extname: '.adg'
    .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-appc", ->
  gulp.src "src/#{$.dir}/mappings/default.json"
    .pipe appcGenerator.gulpNica2Appc $.magic, $.dir
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.defaults}/#{$.dir}"
    
# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
  exporter = bwExporter $.bwpresetTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState()
    .pipe exporter.gulpRewriteMetadata()
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
