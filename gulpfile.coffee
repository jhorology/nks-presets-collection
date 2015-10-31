path        = require 'path'
fs          = require 'fs'
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

gulp.task 'deploy', [
  'deploy-velvet'
  'deploy-resources'
]
  

# Air Music Technology Velvet
# ---------------------------
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
      modes: ['Sample-based']
      types: [
        ["Piano/Keys"]
        ["Piano/Keys", "Electric Piano"]
      ]
    .pipe gulp.dest "#{$.userContentDir}/Velvet"

# NI Resources
# ---------------------------
gulp.task 'deploy-resources', ->
  gulp.src ['NI Resources/**/*.png','NI Resources/**/*.meta'], read: true
    .pipe gulp.dest "#{$.NIResourcesDir}"

