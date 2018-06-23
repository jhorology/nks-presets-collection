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
fxpExporter = require '../lib/fxp-exporter'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  gadgets: [
    {plugin: 'AbuDhabi',    dir: 'Abu Dhabi (Slicer)',      type: 'Drum',       numParams: 151}
    {plugin: 'Alexandria',  dir: 'Alexandria (Organ)',      type: 'Instrument', numParams: 12}
    {plugin: 'Amsterdam',   dir: 'Amsterdam (SFX)',         type: 'Drum',       numParams: 32}
    {plugin: 'Berlin',      dir: 'Berlin (Sync)',           type: 'Instrument', numParams: 30}
    {plugin: 'Bilbao',      dir: 'Bilbao (Sampler)',        type: 'Drum',       numParams: 132}
    {plugin: 'Brussels',    dir: 'Brussels (Lead)',         type: 'Instrument', numParams: 12}
    {plugin: 'Chiangmai',   dir: 'Chiangmai (FM)',          type: 'Instrument', numParams: 31}
    {plugin: 'Chicago',     dir: 'Chicago (Acid)',          type: 'Instrument', numParams: 22}
    {plugin: 'Darwin',      dir: 'Darwin (M1)',             type: 'Instrument', numParams: 13}
    {plugin: 'Dublin',      dir: 'Dublin (Semi-modular)',   type: 'Instrument', numParams: 38}
    {plugin: 'Firenze',     dir: 'Firenze (Clav)',          type: 'Instrument', numParams: 14}
    {plugin: 'Gladstone',   dir: 'Gladstone (Drum)',        type: 'Drum',       numParams: 62}
    {plugin: 'Glasgow',     dir: 'Glasgow (Keys)',          type: 'Instrument', numParams: 14}
    {plugin: 'Helsinki',    dir: 'Helsinki (Pad)',          type: 'Instrument', numParams: 19}
    {plugin: 'Kamata',      dir: 'Kamata (4-Bit)',          type: 'Instrument', numParams: 65}
    {plugin: 'Kiev',        dir: 'Kiev (Vector)',           type: 'Instrument', numParams: 31}
    {plugin: 'Kingston',    dir: 'Kingston (Arcade)',       type: 'Instrument', numParams: 17}
    {plugin: 'Lexington',   dir: 'Lexington (Odyssey)',     type: 'Instrument', numParams: 93}
    {plugin: 'Lisbon',      dir: 'Lisbon (Sc-Fi)',          type: 'Instrument', numParams: 67}
    {plugin: 'London',      dir: 'London (Drum)',           type: 'Drum',       numParams: 92}
    {plugin: 'Madrid',      dir: 'Madrid (Bass)',           type: 'Instrument', numParams: 19}
    {plugin: 'Marseille',   dir: 'Marseille (Keys)',        type: 'Instrument', numParams: 13}
    {plugin: 'Miami',       dir: 'Miami (Wobble)',          type: 'Instrument', numParams: 18}
    {plugin: 'Milpitas',    dir: 'Milpitas (Wavestation)',  type: 'Instrument', numParams: 8}
    # KORG failed packaging, half of montpellier's nksfs are size 0.
    # I will activate after update
    # {plugin: 'Montpellier', dir: 'Montpellier (Mono-Poly)', type: 'Instrument', numParams: 69}
    {plugin: 'Montreal',    dir: 'Montreal (E.Piano)',      type: 'Instrument', numParams: 17}
    {plugin: 'Phoenix',     dir: 'Phoenix (Analog)',        type: 'Instrument', numParams: 38}
    {plugin: 'Recife',      dir: 'Recife (Drum)',           type: 'Drum',       numParams: 196}
    # Rosairio doesn't have NKS Presets
    # {plugin: 'Rosario',     dir: 'Rosario (G.Amp)',         type: 'Audio Effect', numParams: 18}
    {plugin: 'Salzburg',    dir: 'Salzburg (Piano)',        type: 'Instrument', numParams: 13}
    {plugin: 'Tokyo',       dir: 'Tokyo (E.Perc)',          type: 'Drum',       numParams: 34}
    {plugin: 'Vancouver',   dir: 'Vancouver (Sample)',      type: 'Instrument', numParams: 32}
    {plugin: 'Wolfsburg',   dir: 'Wolfsburg (Digital)',     type: 'Instrument', numParams: 52}
    # Zurich doesn't have NKS Presets
    # {plugin: 'Zurich',      dir: 'Zurich (Recorder)',       type: 'Audio Effect', numParams: 5}
  ]

adgTasks = []
appcTasks = []
bwpresetTasks = []
fxpTasks = []

# register each gadget tasks
# --------------------------------
$.gadgets.forEach (gadget) ->
  nksPresets = "/Library/Application Support/KORG/Gadget/Plug-Ins/#{gadget.plugin}Library.bundle/Contents/Resources/NKS/Presets/**/*.nksf"
  adgTask = "#{$.prefix}-#{gadget.plugin.toLowerCase()}-export-adg_"
  appcTask = "#{$.prefix}-#{gadget.plugin.toLowerCase()}-generate-appc_"
  bwpresetTask = "#{$.prefix}-#{gadget.plugin.toLowerCase()}-export-bwpreset_"
  fxpTask = "#{$.prefix}-#{gadget.plugin.toLowerCase()}-export-fxp_"
  adgTasks.push(adgTask)
  appcTasks.push(appcTask)
  bwpresetTasks.push(bwpresetTask)
  fxpTasks.push(fxpTask)
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
    gulp.src [nksPresets]
      .pipe first()
      .pipe appcGenerator.gulpNksf2Appc(gadget.dir)
      .pipe rename
        basename: 'Default'
        extname: '.appc'
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

  # export from .nksf to .fxp
  gulp.task fxpTask, ->
    dest = "#{$.fxpPresets}/KORG Gadget/#{gadget.dir}"
    console.info dest
    gulp.src [nksPresets]
      .pipe fxpExporter.gulpNksf2Fxp(gadget.numParams)
      .pipe tap (file) ->
        # edit file path
        dirname = path.dirname file.path
        file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
      .pipe rename extname: '.fxp'
      .pipe gulp.dest dest

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", adgTasks

# generate ableton default plugin parameterconfiguration
gulp.task "#{$.prefix}-generate-appc", appcTasks

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", bwpresetTasks

# export from .nksf to .fxp
gulp.task "#{$.prefix}-export-fxp", fxpTasks
