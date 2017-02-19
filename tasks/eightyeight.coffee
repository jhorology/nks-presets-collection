# SONiVOX EightyEight
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - EightyEight Twin Version 2.3 Build 2.5.0.15
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

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  dir: 'EightyEight 2_64'
  vendor: 'SONiVOX'
  magic: 'eit2'

  #  local settings
  # -------------------------
  db: '/Library/Application Support/SONiVOX/EightyEight 2/EightyEight.svxdb'
  characters: [
    'Compressed'
    'Warm'
    'Bright'
    'Solo'
    'Hard'
    'Soft'
    'With Release Samples'
    'Without Release Samples'
  ]
  query: '''
select
  patch.name as patch,
  tag.name as tag
from
  patch
  join patch_tag on patch.id = patch_tag.patch_id
  join tag on patch_tag.tag_id = tag.id
where
  patch.name = $PatchName
'''
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/EightyEight 2_64/templates/EightyEight 2_64.adg.tpl'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  # open database
  db = new sqlite3.Database $.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      # SQL bind parameters
      patchName = path.basename file.path, '.pchk'
      folder = path.relative "src/#{$.dir}/presets", path.dirname file.path
      # execute query
      db.all $.query, $PatchName: "#{patchName}.svx", (err, rows) ->
        done err if err
        unless rows and rows.length
          return done "row unfound. $PatchName:#{patchName}"
        types = rows.filter (row) ->
          row.tag not in $.characters and row.tag isnt 'Empty'
        chars = rows.filter (row) ->
          row.tag in $.characters
        done undefined,
          vendor: $.vendor
          types: ['Piano/Keys', row.tag] for row in types
          name: patchName
          modes: ['Sample Based'].concat (row.tag for row in chars)
          deviceType: 'INST'
          bankchain: [$.dir, 'EightyEight 2 Factory', '']
    .pipe tap (file) ->
      file.data.uuid = util.uuid file
      file.contents = new Buffer util.beautify file.data, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

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
# 
# TODO ableton won't restore plugin state
# --------------------------------

# # export from .nksf to .adg ableton rack
# gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
#   exporter = adgExporter $.abletonRackTemplate
#   gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
#     .pipe exporter.gulpParseNksf()
#     .pipe exporter.gulpTemplate()
#     .pipe gzip append: off       # append '.gz' extension
#     .pipe rename extname: '.adg'
#     .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# # export from .nksf to .bwpreset bitwig studio preset
# gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
#   exporter = bwExporter $.bwpresetTemplate
#   gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
#     .pipe exporter.gulpParseNksf()
#     .pipe exporter.gulpReadTemplate()
#     .pipe exporter.gulpAppendPluginState()
#     .pipe exporter.gulpRewriteMetadata()
#     .pipe rename extname: '.bwpreset'
#     .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
