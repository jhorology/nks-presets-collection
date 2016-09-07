# ---------------------------------------------------------------
# D16 LuSH-101
#
# notes
#  - Komplete Kontrol 1.6.2.5
#  - Cyclop 1.2.0
#  - Ableton Live 9.6.2
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'

util     = require '../lib/util'
task     = require '../lib/common-tasks'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Mini V2'
  vendor: 'Arturia'
  magic: '\u0000MIN'
  
  #  local settings
  # -------------------------
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Mini V2/templates/Mini V2.adg.tpl'
  nksPresets: '/Library/Arturia/Mini V2/Third Party/Native Instruments/presets'

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
    basename = path.basename file.path
    file.path = path.join dirname, meta.types[0][1], file.relative
