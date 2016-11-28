# u-he Diva 1.4.1.4078
#
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
_        = require 'underscore'
util     = require '../lib/util'
task     = require '../lib/common-tasks'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Diva'
  vendor: 'u-he'
  magic: 'DiVa'
  
  #  local settings
  # -------------------------
  nksPresets: '/Library/Application Support/u-he/Diva/NKS/Diva'
  # Ableton Live 9.7.0
  abletonRackTemplate: 'src/Diva/templates/Diva.adg.tpl'
  # Bitwig Studio 1.3.14 preset file
  bwpresetTemplate: 'src/Diva/templates/Diva.bwpreset'

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

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ->
  task.export_adg "#{$.nksPresets}/**/*.nksf"
  , "#{$.Ableton.racks}/#{$.dir}"
  , $.abletonRackTemplate
  , (file, meta) ->
    # edit file path
    dirname = path.dirname file.path
    file.path = path.join dirname, meta.types[0][0], file.relative

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-bwpreset", ->
  task.export_bwpreset "#{$.nksPresets}/**/*.nksf"
  , "#{$.Bitwig.presets}/#{$.dir}"
  , $.bwpresetTemplate
  , (file) ->
    # edit file path
    dirname = path.dirname file.path
    file.path = path.join dirname, file.data.meta.types[0][0], file.relative
