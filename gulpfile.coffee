path        = require 'path'
fs          = require 'fs'
sqlite3     = require 'sqlite3'
gulp        = require 'gulp'
coffeelint  = require 'gulp-coffeelint'
coffee      = require 'gulp-coffee'
del         = require 'del'
watch       = require 'gulp-watch'
beautify    = require 'js-beautify'
rewrite     = require 'gulp-nks-rewrite-meta'

# paths, misc settings
$ =
  userContentDir: "#{process.env.HOME}/Documents/Native Instruments/User Content"
  NIResourcesDir: '/Users/Shared/NI Resources'
  serumPresetDB: '/Library/Audio/Presets/Xfer\ Records/Serum\ Presets/System/presetdb.dat'
  serumQuery: '''
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
  
gulp.task 'coffeelint', ->
  gulp.src ['./*.coffee']
    .pipe coffeelint './coffeelint.json'
    .pipe coffeelint.reporter()

gulp.task 'default', [
  'coffeelint'
]

gulp.task 'watch', ->
  gulp.watch './*.coffee', ['default']
 
gulp.task 'clean', (cb) ->
  del ['./**/*~'], force: true, cb

# deploy all presets and resources
gulp.task 'deploy', [
  'deploy-velvet'
  'deploy-serum'
  'deploy-resources'
]
  
# Air Music Technology Velvet
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Velvet  2.0.6.18983
# ---------------------------------------------------------------
gulp.task 'parse-velvet', ->
  gulp.src ['User Content/Velvet/**/*.nksf'], read: true
    .pipe rewrite (file, data) ->
      console.info beautify (JSON.stringify data), indent_size: 2
      undefined
gulp.task 'parse-deployed-velvet', ->
  gulp.src ["#{$.userContentDir}/Velvet/**/*.nksf"], read: true
    .pipe rewrite (file, data) ->
      console.info beautify (JSON.stringify data), indent_size: 2
      undefined

gulp.task 'deploy-velvet', ->
  gulp.src ['User Content/Velvet/**/*.nksf'], read: true
    .pipe rewrite (file, data) ->
      folder = path.relative 'User Content/Velvet', path.dirname file.path
      # meta
      bankchain: ['Velvet', folder, '']
      modes: ['Sample Based']
      types: [
        ["Piano/Keys"]
        ["Piano/Keys", "Electric Piano"]
      ]
    .pipe gulp.dest "#{$.userContentDir}/Velvet"

# Xfer Record Serum
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Serum  1.073 Oct 5 2015
# ---------------------------------------------------------------
gulp.task 'parse-serum', ->
  gulp.src ['User Content/Serum/**/*.nksf'], read: true
    .pipe rewrite (file, data) ->
      console.info beautify (JSON.stringify data), indent_size: 2
      undefined
gulp.task 'parse-deployed-serum', ->
  gulp.src ["#{$.userContentDir}/Serum/**/*.nksf"], read: true
    .pipe rewrite (file, data) ->
      console.info beautify (JSON.stringify data), indent_size: 2
      undefined

gulp.task 'deploy-serum', ->
  # open database
  db = new sqlite3.Database $.serumPresetDB, sqlite3.OPEN_READONLY
  gulp.src ['User Content/Serum/**/*.nksf'], read: true
    .pipe rewrite (file, data, done) ->
      # SQL bind parameters
      params =
        $name: path.basename file.path, '.nksf'
        $folder: path.relative 'User Content/Serum', path.dirname file.path
      # execute query
      db.get $.serumQuery, params, (err, row) ->
        done undefined, {
          author: row.Author?.trim()
          bankchain: ['Serum', 'Serum Factory', '']
          comment: row.Description?.trim()
          types: [[row.Category?.trim()]]
        }
    .pipe gulp.dest "#{$.userContentDir}/Serum"
    .on 'end', ->
      # colse database
      db.close()


# NI Resources
# ---------------------------
gulp.task 'deploy-resources', ->
  gulp.src ['NI Resources/**/*.png','NI Resources/**/*.meta'], read: true
    .pipe gulp.dest "#{$.NIResourcesDir}"

