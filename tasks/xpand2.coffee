# AIR Music Technology Xpand!2
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Xpand!2  2.2.4.18852
#  - recycle bitwig presets. https://github.com/jhorology/Xpand2Pack4Bitwig
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
fxpExporter  = require '../lib/fxp-exporter'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Xpand!2'
  vendor: 'AIR Music Technology'
  magic: "2dpX"

  #  local settings
  # -------------------------

  # number of parameters, mrswaton -p Kyespcape --display-info
  numParams: 148
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Xpand!2/templates/Xpand!2.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Xpand!2/templates/Xpand!2.bwpreset'

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
    .pipe data (file) ->
      basename = path.basename file.path, '.pchk'
      folder = path.relative presets, path.dirname file.path
      bank = if basename[0] is '+'
        'Xpand!2 Factory+'
      else
        'Xpand!2 Factory'
      file.contents = Buffer.from util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [[folder[3..]]]
        modes: ["Sample Based"]
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: [resourceDir, bank, '']
        author: ''
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

# export from .nksf to .fxp
gulp.task "#{$.prefix}-export-fxp", ["#{$.prefix}-dist-presets"], ->
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe fxpExporter.gulpNksf2Fxp $.numParams
    .pipe rename extname: '.fxp'
    .pipe gulp.dest "#{$.fxpPresets}/#{$.dir}"
