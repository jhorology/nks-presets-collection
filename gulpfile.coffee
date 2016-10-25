gulp       = require 'gulp'
coffeelint = require 'gulp-coffeelint'
del        = require 'del'
requireDir = require 'require-dir'
dir        = requireDir './tasks'


allTasks = Object.keys gulp.tasks

# coffeelint
# --------------------------------
gulp.task 'coffeelint', ->
  gulp.src [
    '*.coffee'
    'lib/*.coffee'
    'tasks/*.coffee'
  ]
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
  del [
    './**/*~'
    './**/*.log'
    './**/.DS_Store'
  ]

# clean-all
# --------------------------------
gulp.task 'clean-all', ['clean'], ->
  del [
    'dist'
    'temp'
    'node_modules'
  ]

# dist
#  - execute all *-dist tasks
# --------------------------------
gulp.task 'dist', (("#{prefix}-dist" for prefix of dir).filter (task) -> task in allTasks)

# deploy
#  - execute all *-deploy tasks
# --------------------------------
gulp.task 'deploy', (("#{prefix}-deploy" for prefix of dir).filter (task) -> task in allTasks)

# release
#  - execute all *-release tasks
# --------------------------------
gulp.task 'release', (("#{prefix}-release" for prefix of dir).filter (task) -> task in allTasks)

# export-adg
# export from .nksf to ableton rack (.adg)
#  - execute all *-export-adg tasks
# --------------------------------
gulp.task 'export-adg', (("#{prefix}-export-adg" for prefix of dir).filter (task) -> task in allTasks)

# export-bwpreset
# export from .nksf to bitwig preset (.bwpreset)
#  - execute all *-export-adg tasks
# --------------------------------
gulp.task 'export-bwpreset', (("#{prefix}-export-bwpreset" for prefix of dir).filter (task) -> task in allTasks)


