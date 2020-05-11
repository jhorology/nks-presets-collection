# Xfer Record Serum
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Serum  1.073 Oct 5 2015
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
sqlite3     = require 'sqlite3'
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
  dir: 'Serum'
  vendor: 'Xfer Records'
  magic: 'XfsX'
  
  #  local settings
  # -------------------------
  # serum factory prestes folder
  serumPresets: '/Library/Audio/Presets/Xfer Records/Serum Presets/Presets'
  # Ableton Live 10.0.1
  abletonRackTemplate: 'src/Serum/templates/Serum.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Serum/templates/Serum.bwpreset'
  db: '/Library/Audio/Presets/Xfer\ Records/Serum\ Presets/System/presetdb.dat'
  query: '''
select
  PresetDisplayName
  ,PresetRelativePath
  ,Author
  ,Description
  ,Category
from
  SerumPresetTable
where
  PresetDisplayName = $name
  and PresetRelativePath = $folder
'''

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  # open database
  db = new sqlite3.Database $.db, sqlite3.OPEN_READONLY
  gulp.src ["#{$.serumPresets}/**/*.fxp"]
    .pipe data (file, done) ->
      console.info path.dirname file.relative
      # SQL bind parameters
      params =
        $name: path.basename file.path, '.fxp'
        $folder: path.dirname file.relative
      # execute query
      db.get $.query, params, (err, row) ->
        done err,
          vendor: $.vendor
          types: [[row.Category?.trim()]]
          name: row.PresetDisplayName?.trim()
          deviceType: 'INST'
          comment: row.Description?.trim()
          bankchain: ['Serum', 'Serum Factory', '']
          author: row.Author?.trim()
    .pipe tap (file) ->
      file.data.uuid = util.uuid file
      file.contents = Buffer.from util.beautify file.data, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

#
# build
# --------------------------------

# build .nksf files to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic, "src/#{$.dir}/mappings/default.json"
  gulp.src ["#{$.serumPresets}/**/*.fxp"], read: on
    .pipe data (file) ->
      # fxp header 60 byte - PCHK header 4 byte
      file.contents = file.contents.slice 56
      # write PCHK header
      file.contents.writeUInt32LE 1, 0
      nksf:
        pchk: file
        nisi: "src/#{$.dir}/presets/#{file.relative[..-4]}meta"
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
