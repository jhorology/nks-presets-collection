# Reveal Sound Spire 1.1.x
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Spire    1.1.0
#  - Spire    1.1.8 Bank 6, Bank 7
#  - Komplete Kontrol 1.6.2.5
#  - Spire    1.1.9 Bank 6
#  - 2018-06-01
#      Spire  1.1.14
#        - Update Factory Bank 6,7
#        - add free banks
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Spire-1.1'
  vendor: 'Reveal Sound'
  magic: "Spr2"

  #  local settings
  # -------------------------

  # Ableton Live 10.0.2
  abletonRackTemplate: 'src/Spire-1.1/templates/Spire-1.1.adg.tpl'
  # Bitwig Studio 2.3.4 preset file
  bwpresetTemplate: 'src/Spire-1.1/templates/Spire-1.1.bwpreset'

# register common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  resourceDir = util.normalizeDirname $.dir
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      extname = path.extname file.path
      basename = (path.basename file.path, extname).trim()
      folder = (path.relative presets, path.dirname file.path).split path.sep
      bank = folder[0]
      type = switch
        when (basename.indexOf ' Kick ') > 0  then 'Kick'
        when basename[0..3] is 'ATM '  then 'Atmosphere'
        when basename[0..2] is 'AR '   then 'Arpeggiated'
        when basename[0..3] is 'ARP '  then 'Arpeggiated'
        when basename[0..2] is 'BA '   then 'Bass'
        when basename[0..2] is 'BS '   then 'Bass'
        when basename[0..3] is 'BSQ '  then 'Bass Sequence'
        when basename[0..2] is 'CD '   then 'Chord'
        when basename[0..3] is 'CHD '  then 'Chord'
        when basename[0..2] is 'DR '   then 'Drum'
        when basename[0..2] is 'FX '   then 'FX'
        when basename[0..3] is 'SFX '  then 'FX'
        when basename[0..2] is 'GT '   then 'Gated'
        when basename[0..3] is 'KEY '  then 'Keyboard'
        when basename[0..2] is 'LD '   then 'Lead'
        when basename[0..2] is 'LV '   then 'Instrument'
        when basename[0..2] is 'OR '   then 'Organ'
        when basename[0..3] is 'ORG '  then 'Organ'
        when basename[0..2] is 'PD '   then 'Pad'
        when basename[0..3] is 'PAD '  then 'Pad'
        when basename[0..2] is 'PA '   then 'Pad'
        when basename[0..2] is 'PL '   then 'Pluck'
        when basename[0..3] is 'PLK '  then 'Pluck'
        when basename[0..3] is 'STR '  then 'Strings'
        when basename[0..2] is 'SQ '   then 'Sequnce'
        when basename[0..3] is 'SEQ '  then 'Sequnce'
        when basename[0..2] is 'SY '   then 'Synth'
        when basename[0..3] is 'VOC '  then 'Vocal'
        when basename[0..4] is 'WIND ' then 'Winds'
        when basename[0..2] is 'SN '   then 'Siren'
        when basename[0..4] is 'Bass ' then 'Bass'
        when basename[0..4] is 'Lead ' then 'Lead'
        when basename[0..4] is 'Chord' then 'Chord'
        when basename[0..3] is 'BRS'   then 'Brass'
        when basename[0..4] is 'INST'  then 'Instruments'
        when (basename.indexOf ' BS ') > 0  then 'Bass'
        when (basename.indexOf ' LD ') > 0  then 'Lead'
        when (basename.indexOf ' PD ') > 0  then 'Pad'
        when (basename.indexOf ' PL ') > 0  then 'Pluck'
        when basename[-3..] is ' FX'   then 'FX'
        when basename[0..1] is '--'    then 'Default'
        else 'Non-Category'

      author = switch
        when bank is 'Factory Bank 1'   then 'Reveal Sound'
        when bank is 'Factory Bank 5'   then folder[1]
        # when bank is 'Factory Bank 6' and basename[-4..] is ' HFM' then 'HFM'  # couldn't find author name
        when bank is 'Factory Bank 6'   then 'Reveal Sound'
        when bank is 'Factory Bank 7'   then 'Reveal Sound'
        when bank is 'Factory Bank 0'   then 'Reveal Sound'
        when bank.match /^EDM Remastered/  then 'Derrek'
        when bank.match /^Andi Vax/     then 'Andi Vax'
        when bank.match /^AURAII/       then 'Bellatrix Audio'
        when bank.match /^Avicii Remastered/ then 'Derrek'
        when bank.match /^Rewind 2016/  then 'Derrek'
        when bank.match /^Spire Factory Bank 2016 by Function Loops/  then 'Function Loops'
        when basename[-3..] is ' AS'    then 'Adam Szabo'
        when basename[-3..] is ' AZ'    then 'Aiyn Zahev Sounds'
        when basename[-4..] is ' IPM'   then 'Ice Planet Music'
        when basename[-2..] is ' I'     then 'Invader!'
        when basename[-4..] is ' JRM'   then 'Julian Ray'
        when basename[-3..] is ' HJ'    then 'Joseph Hollo'
        when basename[-4..] is ' LUF'   then 'Luftrum'
        when basename[-3..] is ' DP'    then 'Dallaz Project'
        when basename[-4..] is ' BJP'   then 'Braian John Porter'
        when basename[-3..] is ' SK'    then 'Serhiy Klimenkov'
        when basename[-2..] is ' V'     then 'Vullcan'
        when basename[-4..] is ' VTL'   then 'Vi Ta Lee'
        when basename[-4..] is ' MLM'   then 'Mathieu Le Manson'
        when basename[-6..] is ' AL&RS' then 'Alex Larichev & Rusty Spica'
        when basename[-3..] is ' eX'    then 'E.SoX'
        else ''

      # HFM is 'Hard FM', not author name :)
      mode = 'Hard FM' if bank is 'Factory Bank 6' and basename[-4..] is ' HFM'

      # meta
      file.contents = Buffer.from util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [[type]]
        modes: if mode then [mode] else []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: [resourceDir, bank, '']
        author: author
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

#
# build
# --------------------------------

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic, "src/#{$.dir}/mappings/default.json"
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"], read: on
    .pipe data (pchk) ->
      nksf:
        pchk: pchk
        nisi: "#{pchk.path[..-5]}meta"
    .pipe builder.gulp()
    .pipe rename extname: '.nksf'
    .pipe gulp.dest "dist/#{$.dir}/User Content/#{$.dir}"

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpTemplate()
    .pipe gzip append: off       # append '.gz' extension
    .pipe rename extname: '.adg'
    .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-appc", ->
  gulp.src "src/#{$.dir}/mappings/default.json"
    .pipe appcGenerator.gulpNica2Appc $.magic, $.dir
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.defaults}/#{$.dir}"
    
# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
  exporter = bwExporter $.bwpresetTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState()
    .pipe exporter.gulpRewriteMetadata()
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"

