# KORG Gadget 1.5.0(build 40)
#   bitwig studio 2.2.2
#   ableton live 10.0b146
# CHANGES
#  20210320
#   - KORG Gadget 2.7.1
#   
# ---------------------------------------------------------------
fs          = require 'fs'
path        = require 'path'
gulp        = require 'gulp'
first       = require 'gulp-first'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
ignore      = require 'gulp-ignore'
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
  pluginsDir: '/Library/Application Support/KORG/Gadget/Plug-Ins'
  gadgets: [
    {plugin: 'AbuDhabi',    dir: 'Abu Dhabi (Slicer)',      type: 'Drum',       numParams: 151, uuid: '4f2adc8e-9fee-4d7d-9aa5-25de3c1f189a'}
    {plugin: 'Alexandria',  dir: 'Alexandria (Organ)',      type: 'Instrument', numParams: 12,  uuid: '24f091ef-69f4-43c6-8582-897ebea7f9d4'}
    {plugin: 'Amsterdam',   dir: 'Amsterdam (SFX)',         type: 'Drum',       numParams: 32,  uuid: 'efc26bb0-e53b-4495-af56-569ea5ac9118'}
    {plugin: 'Berlin',      dir: 'Berlin (Sync)',           type: 'Instrument', numParams: 30,  uuid: '8f267822-30e7-4318-b8db-1ce2920cff4e'}
    {plugin: 'Bilbao',      dir: 'Bilbao (Sampler)',        type: 'Drum',       numParams: 132, uuid: '0146b2d0-ee46-4663-b720-1e3043db8d02'}
    {plugin: 'Brussels',    dir: 'Brussels (Lead)',         type: 'Instrument', numParams: 12,  uuid: 'f1f373dc-2d1e-4114-b51f-00ab929f636b'}
    {plugin: 'Chiangmai',   dir: 'Chiangmai (FM)',          type: 'Instrument', numParams: 31,  uuid: '7c420371-c7e0-4680-b319-9c4d0d64a282'}
    {plugin: 'Chicago',     dir: 'Chicago (Acid)',          type: 'Instrument', numParams: 22,  uuid: '2b28f0f6-fd4f-4fa3-8c0c-289945b170dc'}
    {plugin: 'Darwin',      dir: 'Darwin (M1)',             type: 'Instrument', numParams: 13,  uuid: '4fa57b0c-cc11-4786-a4e8-5f93d285883d'}
    {plugin: 'Dublin',      dir: 'Dublin (Semi-modular)',   type: 'Instrument', numParams: 38,  uuid: 'e1e0f3d1-1336-4766-b37a-b5d73214d3da'}
    # Durban doesn't have NKS Presets
    # {plugin: 'Durban',      dir: 'Durban (B.Amp)',          type: 'Audio Effect', numParams: 17}
    {plugin: 'Ebina',       dir: 'Ebina (Taito)',           type: 'Instrument', numParams: 43}
    {plugin: 'Fairbanks',   dir: 'Fairbanks (Hybrid)',      type: 'Instrument', numParams: 16}
    {plugin: 'Firenze',     dir: 'Firenze (Clav)',          type: 'Instrument', numParams: 14,  uuid: '0d734bc9-e36d-426e-9097-d6d96df9cbde'}
    {plugin: 'Gladstone',   dir: 'Gladstone (Drum)',        type: 'Drum',       numParams: 62,  uuid: 'ee23311f-3c83-41c4-a73a-2755ea0c4b36'}
    {plugin: 'Glasgow',     dir: 'Glasgow (Keys)',          type: 'Instrument', numParams: 14,  uuid: '31f98755-eef2-47b6-90f4-0ed638c1fc59'}
    {plugin: 'Helsinki',    dir: 'Helsinki (Pad)',          type: 'Instrument', numParams: 19,  uuid: '2ab9b5a6-dfbe-4a6a-8ffd-79d5e47b1754'}
    {plugin: 'Kamata',      dir: 'Kamata (4-Bit)',          type: 'Instrument', numParams: 65,  uuid: '982be439-d428-4ce8-b42e-cc5132632d09'}
    {plugin: 'Kiev',        dir: 'Kiev (Vector)',           type: 'Instrument', numParams: 31,  uuid: '2dfb835c-fae8-4c7e-a7e7-083b99edc071'}
    {plugin: 'Kingston',    dir: 'Kingston (Arcade)',       type: 'Instrument', numParams: 17,  uuid: '0fc44d83-6b29-4782-b1aa-f11c55e89481'}
    {plugin: 'Lexington',   dir: 'Lexington (Odyssey)',     type: 'Instrument', numParams: 93,  uuid: '5f8be5f9-be65-4e51-998f-705070617c4d'}
    {plugin: 'Lisbon',      dir: 'Lisbon (Sc-Fi)',          type: 'Instrument', numParams: 67,  uuid: '0b8d1cad-ddf5-4b8b-b680-2154bd474f66'}
    {plugin: 'London',      dir: 'London (Drum)',           type: 'Drum',       numParams: 92,  uuid: '3f0f8ce8-c249-4a8f-afac-6c7588a30c50'}
    {plugin: 'Madrid',      dir: 'Madrid (Bass)',           type: 'Instrument', numParams: 19,  uuid: '416818d8-5649-479c-8337-3f8187c22606'}
    {plugin: 'Marseille',   dir: 'Marseille (Keys)',        type: 'Instrument', numParams: 13,  uuid: 'ab9080c6-e47a-4f0a-90c5-2e5845ee9df7'}
    {plugin: 'Memphis',     dir: 'Memphis (MS-20)',         type: 'Instrument', numParams: 44}
    {plugin: 'Miami',       dir: 'Miami (Wobble)',          type: 'Instrument', numParams: 18,  uuid: 'a02b8e36-f40b-4ab7-8e27-5c61233cb019'}
    {plugin: 'Milpitas',    dir: 'Milpitas (Wavestation)',  type: 'Instrument', numParams: 8,   uuid: 'd1a18c95-d7ab-41c5-96ac-c77df466c0b2'}
    {plugin: 'Montpellier', dir: 'Montpellier (Mono-Poly)', type: 'Instrument', numParams: 69,  uuid: '99f5877c-0720-4389-9cf5-ee1508709a8c'}
    {plugin: 'Montreal',    dir: 'Montreal (E.Piano)',      type: 'Instrument', numParams: 17,  uuid: '0baae08c-e48d-465d-8853-ae7b0f692076'}
    {plugin: 'Otorii',      dir: 'Otorii (SEGA)',           type: 'Drum',       numParams: 136}
    {plugin: 'Phoenix',     dir: 'Phoenix (Analog)',        type: 'Instrument', numParams: 38,  uuid: 'aef46075-102a-4ceb-b672-4425672b20d0'}
    {plugin: 'Pompei',      dir: 'Pompei (Polysix)',        type: 'Instrument', numParams: 40}
    {plugin: 'Recife',      dir: 'Recife (Drum)',           type: 'Drum',       numParams: 196, uuid: '66b4115f-5249-494b-a8bf-341639717fc3'}
    # Rosairio doesn't have NKS Presets
    # {plugin: 'Rosario',     dir: 'Rosario (G.Amp)',         type: 'Audio Effect', numParams: 18}
    {plugin: 'Salzburg',    dir: 'Salzburg (Piano)',        type: 'Instrument', numParams: 13,  uuid: '577b7cae-3c7b-4e5a-ba85-628c238fad8a'}
    # preview files exists only in presets folder. no preview files in NBPL.
    {plugin: 'Stockholm',   dir: 'Stockholm (Dr. Octorex)', type: 'Drum',       numParams: 53}
    # Taipei doesn't have NKS Presets
    # {plugin: 'Taipei',      dir: 'Taipei (Midi)',           type: 'Instrument', numParams: 22}
    {plugin: 'Tokyo',       dir: 'Tokyo (E.Perc)',          type: 'Drum',       numParams: 34,  uuid: '9834b7a8-5527-410c-96d1-a4ec3aed8ef6'}
    {plugin: 'Vancouver',   dir: 'Vancouver (Sample)',      type: 'Instrument', numParams: 32,  uuid: 'ff55f8a8-55b3-4beb-8c37-0549ad0db401'}
    {plugin: 'Warszawa',    dir: 'Warszawa (Wavetable)',    type: 'Instrument', numParams: 34}
    {plugin: 'Wolfsburg',   dir: 'Wolfsburg (Digital)',     type: 'Instrument', numParams: 52,  uuid: 'c52345eb-c65b-445a-ae2b-10ceef32945a'}
    # Zurich doesn't have NKS Presets
    # {plugin: 'Zurich',      dir: 'Zurich (Recorder)',       type: 'Audio Effect', numParams: 5}
  ]

# register each gadget tasks
# --------------------------------
$.gadgets.forEach (gadget) ->
  nksPresets = "#{$.pluginsDir}/#{gadget.plugin}Library.bundle/Contents/Resources/NKS/Presets/**/*.nksf"
  prefix = "#{$.prefix}-#{gadget.plugin.toLowerCase()}"
  gulp.task "#{prefix}-export-adg_", ->
    exporter = adgExporter "src/KORG Gadget/templates/#{gadget.dir}.adg.tpl"
    dest = switch gadget.type
      when 'Instrument'
        "#{$.Ableton.racks}/KORG Gadget/#{gadget.dir}"
      when 'Drum'
        "#{$.Ableton.drumRacks}/KORG Gadget/#{gadget.dir}"
      when 'Audio Effect'
        "#{$.Ableton.effectRacks}/KORG Gadget/#{gadget.dir}"
    gulp.src [nksPresets]
      # some of Montpellier's nksf is size 0.
      .pipe ignore (file) -> file.contents.length is 0
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
  gulp.task "#{prefix}-generate-appc_", ->
    gulp.src [nksPresets]
      .pipe first()
      .pipe appcGenerator.gulpNksf2Appc(gadget.dir)
      .pipe rename
        basename: 'Default'
        extname: '.appc'
      .pipe gulp.dest "#{$.Ableton.defaults}/#{gadget.dir}"
    
  # export from .nksf to .bwpreset bitwig studio preset
  gulp.task "#{prefix}-export-bwpreset_", ->
    exporter = bwExporter "src/KORG Gadget/templates/#{gadget.dir}.bwpreset"
    dest = "#{$.Bitwig.presets}/KORG Gadget/#{gadget.dir}"
    gulp.src [nksPresets]
      # some of Montpellier's nksf is size 0.
      .pipe ignore (file) -> file.contents.length is 0
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
  gulp.task "#{prefix}-export-fxp_", ->
    dest = "#{$.fxpPresets}/KORG Gadget/#{gadget.dir}"
    console.info dest
    gulp.src [nksPresets]
      # some of Montpellier's nksf is size 0.
      .pipe ignore (file) -> file.contents.length is 0
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
gulp.task "#{$.prefix}-export-adg", ("#{$.prefix}-#{gadget.plugin.toLowerCase()}-export-adg_" for gadget in $.gadgets)

# generate ableton default plugin parameterconfiguration
gulp.task "#{$.prefix}-generate-appc", ("#{$.prefix}-#{gadget.plugin.toLowerCase()}-generate-appc_" for gadget in $.gadgets)

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ("#{$.prefix}-#{gadget.plugin.toLowerCase()}-export-bwpreset_" for gadget in $.gadgets)

# export from .nksf to .fxp
gulp.task "#{$.prefix}-export-fxp", ("#{$.prefix}-#{gadget.plugin.toLowerCase()}-export-fxp_" for gadget in $.gadgets)
