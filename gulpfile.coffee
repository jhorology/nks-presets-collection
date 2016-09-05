gulp       = require 'gulp'
coffeelint = require 'gulp-coffeelint'
del        = require 'del'
requireDir = require 'require-dir'
dir        = requireDir './tasks'

# coffeelint
# --------------------------------
gulp.task 'coffeelint', ->
  gulp.src ['*.coffee', 'lib/*.coffee', 'tasks/*.coffee']
    .pipe coffeelint 'coffeelint.json'
    .pipe coffeelint.reporter()

# watch
# --------------------------------
gulp.task 'watch', ->
  gulp.watch [
    './*.coffee'
    './lib/*.coffee'
    './tasks/*.coffee'
  ]
  , ['coffeelint']

# clean
# --------------------------------
gulp.task 'clean', ->
  del ['./**/*~', './**/*.log', './**/.DS_Store']

# clean-all
# --------------------------------
gulp.task 'clean-all', ['clean'], ->
  del ['dist', 'temp', 'node_modules']

# dist
#  - execute all *-dist tasks
# --------------------------------
gulp.task 'dist', ("#{prefix}-dist" for prefix of dir)

# deploy
#  - execute all *-deploy tasks
# --------------------------------
gulp.task 'deploy', ("#{prefix}-deploy" for prefix of dir)

# deploy
#  - execute all *-release tasks
# --------------------------------
gulp.task 'release', ("#{prefix}-deploy" for prefix of dir)
