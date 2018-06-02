# KORG Gadget 1.5.0(build 40)
#   bitwig studio 2.2.2
#   ableton live 10.0b146
# ---------------------------------------------------------------
fs          = require 'fs'
path        = require 'path'
gulp        = require 'gulp'
first       = require 'gulp-first'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
commonTasks = require '../lib/common-tasks'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  gadgets: [
    {plugin: 'AbuDhabi',    dir: 'Abu Dhabi (Slicer)',      type: 'Drum'}
    {plugin: 'Alexandria',  dir: 'Alexandria (Organ)',      type: 'Instrument'}
    {plugin: 'Amsterdam',   dir: 'Amsterdam (SFX)',         type: 'Drum'}
    {plugin: 'Berlin',      dir: 'Berlin (Sync)',           type: 'Instrument'}
    {plugin: 'Bilbao',      dir: 'Bilbao (Sampler)',        type: 'Drum'}
    {plugin: 'Brussels',    dir: 'Brussels (Lead)',         type: 'Instrument'}
    {plugin: 'Chiangmai',   dir: 'Chiangmai (FM)',          type: 'Instrument'}
    {plugin: 'Chicago',     dir: 'Chicago (Acid)',          type: 'Instrument'}
    {plugin: 'Darwin',      dir: 'Darwin (M1)',             type: 'Instrument'}
    {plugin: 'Dublin',      dir: 'Dublin (Semi-modular)',   type: 'Instrument'}
    {plugin: 'Firenze',     dir: 'Firenze (Clav)',          type: 'Instrument'}
    {plugin: 'Gladstone',   dir: 'Gladstone (Drum)',        type: 'Drum'}
    {plugin: 'Glasgow',     dir: 'Glasgow (Keys)',          type: 'Instrument'}
    {plugin: 'Helsinki',    dir: 'Helsinki (Pad)',          type: 'Instrument'}
    {plugin: 'Kamata',      dir: 'Kamata (4-Bit)',          type: 'Instrument'}
    {plugin: 'Kiev',        dir: 'Kiev (Vector)',           type: 'Instrument'}
    {plugin: 'Kingston',    dir: 'Kingston (Arcade)',       type: 'Instrument'}
    {plugin: 'Lexington',   dir: 'Lexington (Odyssey)',     type: 'Instrument'}
    {plugin: 'Lisbon',      dir: 'Lisbon (Sc-Fi)',          type: 'Instrument'}
    {plugin: 'London',      dir: 'London (Drum)',           type: 'Drum'}
    {plugin: 'Madrid',      dir: 'Madrid (Bass)',           type: 'Instrument'}
    {plugin: 'Marseille',   dir: 'Marseille (Keys)',        type: 'Instrument'}
    {plugin: 'Miami',       dir: 'Miami (Wobble)',          type: 'Instrument'}
    {plugin: 'Milpitas',    dir: 'Milpitas (Wavestation)',  type: 'Instrument'}
    # KORG failed packaging, half of montpellier's nksfs are size 0.
    # I will activate after update
    # {plugin: 'Montpellier', dir: 'Montpellier (Mono-Poly)', type: 'Instrument'}
    {plugin: 'Montreal',    dir: 'Montreal (E.Piano)',      type: 'Instrument'}
    {plugin: 'Phoenix',     dir: 'Phoenix (Analog)',        type: 'Instrument'}
    {plugin: 'Recife',      dir: 'Recife (Drum)',           type: 'Drum'}
    # Rosairio doesn't have NKS Presets
    # {plugin: 'Rosario',     dir: 'Rosario (G.Amp)',         type: 'Audio Effect'}
    {plugin: 'Salzburg',    dir: 'Salzburg (Piano)',        type: 'Instrument'}
    {plugin: 'Tokyo',       dir: 'Tokyo (E.Perc)',          type: 'Drum'}
    {plugin: 'Vancouver',   dir: 'Vancouver (Sample)',      type: 'Instrument'}
    {plugin: 'Wolfsburg',   dir: 'Wolfsburg (Digital)',     type: 'Instrument'}
    # Zurich doesn't have NKS Presets
    # {plugin: 'Zurich',      dir: 'Zurich (Recorder)',       type: 'Audio Effect'}
  ]

adgTasks = []
appcTasks = []
bwpresetTasks = []

# regist each gadget tasks
# --------------------------------
$.gadgets.forEach (gadget) ->
  nksPresets = "/Library/Application Support/KORG/Gadget/Plug-Ins/#{gadget.plugin}Library.bundle/Contents/Resources/NKS/Presets/**/*.nksf"
  adgTask = "#{$.prefix}-#{gadget.plugin.toLowerCase()}-export-adg_"
  appcTask = "#{$.prefix}-#{gadget.plugin.toLowerCase()}-generate-appc_"
  bwpresetTask = "#{$.prefix}-#{gadget.plugin.toLowerCase()}-export-bwpreset_"
  adgTasks.push(adgTask)
  appcTasks.push(appcTask)
  bwpresetTasks.push(bwpresetTask)
  gulp.task adgTask, ->
    exporter = adgExporter "src/KORG Gadget/templates/#{gadget.dir}.adg.tpl"
    dest = switch gadget.type
      when 'Instrument'
        "#{$.Ableton.racks}/KORG Gadget/#{gadget.dir}"
      when 'Drum'
        "#{$.Ableton.drumRacks}/KORG Gadget/#{gadget.dir}"
      when 'Audio Effect'
        "#{$.Ableton.effectRacks}/KORG Gadget/#{gadget.dir}"
    gulp.src [nksPresets]
      .pipe exporter.gulpParseNksf()
      .pipe exporter.gulpTemplate()
      .pipe gzip append: off       # append '.gz' extension
      .pipe rename extname: '.adg'
      .pipe tap (file) ->
        # edit file path
        dirname = path.dirname file.path
        file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
      .pipe gulp.dest dest

  # generate ableton default plugin parameter configuration
  gulp.task appcTask, ->
    isFirst = true
    gulp.src [nksPresets]
      .pipe first()
      .pipe appcGenerator.gulpNksf2Appc(gadget.dir)
      .pipe gulp.dest "#{$.Ableton.defaults}/#{gadget.dir}"
    
  # export from .nksf to .bwpreset bitwig studio preset
  gulp.task bwpresetTask, ->
    exporter = bwExporter "src/KORG Gadget/templates/#{gadget.dir}.bwpreset"
    dest = "#{$.Bitwig.presets}/KORG Gadget/#{gadget.dir}"
    gulp.src [nksPresets]
      .pipe exporter.gulpParseNksf()
      .pipe tap (file) ->
        # edit file path
        dirname = path.dirname file.path
        file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
      .pipe exporter.gulpReadTemplate()
      .pipe exporter.gulpAppendPluginState()
      .pipe exporter.gulpRewriteMetadata()
      .pipe rename extname: '.bwpreset'
      .pipe gulp.dest dest

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", adgTasks

# generate ableton default plugin parameterconfiguration
gulp.task "#{$.prefix}-generate-appc", appcTasks

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", bwpresetTasks
