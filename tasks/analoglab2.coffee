# Arturia Analog Lab 2
#
# notes
#  - Komplete Kontrol 1.5.1(R3132)
#  - Analog Lab 2  2.0.1.51
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
rename      = require 'gulp-rename'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
sqlite3     = require 'sqlite3'
_           = require 'underscore'
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
  dir: 'Analog Lab 2'
  vendor: 'Arturia'
  magic: 'Ala2'
  
  #  local settings
  # -------------------------
  presets: '/Library/Arturia/Presets'
  # Analog Lab 2 is NKS ready plugin!
  nksPresets: '/Library/Arturia/Analog Lab 2/Third Party/Native Instruments/presets'
  db: '/Library/Arturia/Presets/db.db3'
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Analog Lab 2/templates/Analog Lab 2.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Analog Lab 2/templates/Analog Lab 2.bwpreset'
  query_preset: '''
select
  t0.name as name,
  t1.name as type,
  t2.name as inst,
  t3.name as author,
  t4.name as pack,
  t0.comment as comment,
  t6.name as characteristic
from
  Preset_Id t0
  join Types t1 on t0.type = t1.key_id
  join Instruments t2 on t0.instrument_key = t2.key_id
  join Sound_Designers t3 on t0.sound_designer = t3.key_id
  join Packs t4 on t0.pack = t4.key_id
  left outer join Preset_Characteristics t5 on t0.key_id = t5.preset_key
  left outer join Characteristics t6 on t5.characteristic_key = t6.key_id
where
  t0.file_path = $FilePath
'''

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate metadata from Analog Lab's sqlite database
gulp.task "#{$.prefix}-generate-meta", ->
  # open database
  db = new sqlite3.Database $.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      # SQL bind parameters
      presetName = path.basename file.path, '.pchk'
      folder = path.relative "src/#{$.dir}/presets", path.dirname file.path
      instname = path.dirname folder
      params =
        $FilePath: path.join $.presets, folder, presetName
      # execute query
      db.all $.query_preset, params, (err, rows) ->
        done err if err
        unless rows and rows.length
          return done "row unfound. $FilePath:#{params.$FilePath}"
        # replace Analog Lab => MULT
        inst = rows[0].inst
        if inst is 'Analog Lab'
          inst = 'MULTI'
        done undefined,
          vendor: $.vendor
          types: [[rows[0].type?.trim()]]
          name: presetName
          modes: if rows[0].characteristic then _.uniq (row.characteristic for row in rows) else []
          deviceType: 'INST'
          comment: rows[0].comment?.trim()
          bankchain: [$.dir, inst, rows[0].pack]
          author: rows[0].author?.trim()
    .pipe tap (file) ->
      # console.info json
      file.contents = new Buffer util.beautify file.data, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

# generate mapping per preset from sqlite database
gulp.task "#{$.prefix}-generate-mappings", [
  "#{$.prefix}-generate-single-mappings"
  "#{$.prefix}-generate-multi-mappings"
]

# generate sound preset mappings from sqlite database
gulp.task "#{$.prefix}-generate-single-mappings", ->
  # TODO
  #  - need to analyze arturia preset file
  #    - boost C++ library serialization archive

# generate multi preset mappings from sqlite database
gulp.task "#{$.prefix}-generate-multi-mappings", ->
  # TODO
  #  - need to analyze arturia preset file
  #    - boost C++ library serialization archive

#
# build
# --------------------------------

# build presets file to dist folder
# TODO
#   - per preset mapping
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

#
# deploy
# --------------------------------

# copy presets to nks presets folder
#  analog lab 2 is NKS ready plugin
gulp.task "#{$.prefix}-deploy-presets", [
  "#{$.prefix}-dist-presets"
] , ->
  gulp.src ["dist/#{$.dir}/User Content/**/*.nksf"]
    .pipe gulp.dest $.nksPresets

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
