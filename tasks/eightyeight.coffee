# SONiVOX EightyEight
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - EightyEight Twin Version 2.3 Build 2.5.0.15
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
data     = require 'gulp-data'
rename   = require 'gulp-rename'
sqlite3  = require 'sqlite3'

util     = require '../lib/util'
task     = require '../lib/common-tasks'

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

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task "#{$.prefix}-print-default-meta", ->
  task.print_default_meta $.dir

# print mapping of _Default.nksf
gulp.task "#{$.prefix}-print-default-mapping", ->
  task.print_default_mapping $.dir

# print plugin id of _Default.nksf
gulp.task "#{$.prefix}-print-magic", ->
  task.print_plid $.dir

# generate default mapping file from _Default.nksf
gulp.task "#{$.prefix}-generate-default-mapping", ->
  task.generate_default_mapping $.dir

# extract PCHK chunk from .bwpreset files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

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

# copy dist files to dist folder
gulp.task "#{$.prefix}-dist", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
  "#{$.prefix}-dist-presets"
]

# copy image resources to dist folder
gulp.task "#{$.prefix}-dist-image", ->
  task.dist_image $.dir, $.vendor

# copy database resources to dist folder
gulp.task "#{$.prefix}-dist-database", ->
  task.dist_database $.dir, $.vendor

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  task.dist_presets $.dir, $.magic

# check
gulp.task "#{$.prefix}-check-dist-presets", ->
  task.check_dist_presets $.dir

#
# deploy
# --------------------------------

gulp.task "#{$.prefix}-deploy", [
  "#{$.prefix}-deploy-resources"
  "#{$.prefix}-deploy-presets"
]

# copy resources to local environment
gulp.task "#{$.prefix}-deploy-resources", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
], ->
  task.deploy_resources $.dir

# copy database resources to local environment
gulp.task "#{$.prefix}-deploy-presets", [
  "#{$.prefix}-dist-presets"
] , ->
  task.deploy_presets $.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task "#{$.prefix}-release", ["#{$.prefix}-dist"], ->
  task.release $.dir

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  # TODO ableton won't restore plugin state
  # 
  # task.export_adg "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  # , "#{$.Ableton.racks}/#{$.dir}"
  # , $.abletonRackTemplate
