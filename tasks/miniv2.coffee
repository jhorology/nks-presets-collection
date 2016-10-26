# Arturia Mini V2
#
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
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Mini V2/templates/Mini V2.bwpreset'

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

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-bwpreset", ->
  task.export_bwpreset "#{$.nksPresets}/**/*.nksf"
  , "#{$.Bitwig.presets}/#{$.dir}"
  , $.bwpresetTemplate
  , (file) ->
    # edit file path
    dirname = path.dirname file.path
    file.path = path.join dirname, file.data.meta.types[0][0], file.relative
