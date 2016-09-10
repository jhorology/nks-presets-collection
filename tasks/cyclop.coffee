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
extract     = require 'gulp-riff-extractor'

util     = require '../lib/util'
task     = require '../lib/common-tasks'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Cyclop'
  vendor: 'Sugar Bytes'
  magic: 'sbcy'
  
  #  local settings
  # -------------------------
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Cyclop/templates/Cyclop.adg.tpl'
  nksPresets: '/Library/Application Support/Sugar Bytes/Cyclop/NKS/Presets'

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

# for analysing plugin state on Live
gulp.task "#{$.prefix}-adg-test-data", ->
  task.extract_raw_presets_from_adg ["#{$.Ableton.racks}/8-*.adg"], 'test/ableton'

# for analysing plugin state on KK
gulp.task "#{$.prefix}-nks-test-data", ->
  gulp.src ["/Library/Application Support/Sugar Bytes/Cyclop/NKS/Presets/XS/8-*.nksf"], read: true
    .pipe extract {}
    .pipe gulp.dest 'test/nks'

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ->
  # Discontinued
  #   Ableton won't restore plugin state
  #   I gave up analysing plugin state. It's diffrent between Live and KK.
  #   I couldn't find rules.
  # 
  # task.export_adg "#{$.nksPresets}/**/*.nksf"
  # , "#{$.Ableton.racks}/#{$.dir}"
  # , $.abletonRackTemplate
    
