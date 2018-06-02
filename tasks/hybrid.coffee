# AIR Music Technology Hybrid
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Hybrid  3.0.0.18468
#  - recycle bitwig presets. https://github.com/jhorology/HybridPack4Bitwig
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
  dir: 'Hybrid'
  vendor: 'AIR Music Technology'
  magic: "drbH"
  releaseExcludes: [
    "Expansions/**"
  ]
  
  #  local settings
  # -------------------------

  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Hybrid/templates/Hybrid.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Hybrid/templates/Hybrid.bwpreset'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = (path.relative presets, path.dirname file.path).split path.sep
      # meta
      meta = switch
        when folder[0] is 'Expansions' and folder[1] is 'Prime Loops'
          vendor: $.vendor
          uuid: util.uuid file
          types: [ [folder[3]] ]
          modes: []
          name: basename
          deviceType: 'INST'
          comment: ''
          bankchain: ['Hybrid', "#{folder[1]} - #{folder[2]}", '']
          author: ''
        when folder[0] is 'Expansions' and folder[1] is 'Toolroom'
          vendor: $.vendor
          uuid: util.uuid file
          types: switch folder[2]
            when 'DEEP HOUSE - Mark Knight'
              [[(basename.split ' ')[0]]]
            when 'TECH HOUSE - D.Ramirez'
              words = basename.split ' '
              word = words.pop()
              if word.match /\d+/
                word = words.pop()
              [[word]]
            when 'TECH HOUSE - Marco Lys'
              words = basename.split ' '
              word = words.pop()
              if word.match /\d+/
                word = words.pop()
              [[word]]
            when 'TECH HOUSE - Rene Amesz'
              [[(basename.split ' ')[0]]]
            when 'TECH HOUSE - Tocadisco'
              []
          modes: []
          name: basename
          deviceType: 'INST'
          comment: ''
          bankchain: ['Hybrid', "#{folder[1]} - #{folder[2]}", '']
          author: "#{folder[2].replace /^.* \- (.*)$/, '$1'}"
        else
          vendor: $.vendor
          uuid: util.uuid file
          types: [[if folder.length is 1 then 'Default' else folder[1][3..]]]
          modes: []
          name: basename
          deviceType: 'INST'
          comment: ''
          bankchain: ['Hybrid', folder[0], '']
          author: ''
      file.contents = Buffer.from util.beautify meta, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

# suggest mapping
gulp.task "#{$.prefix}-suggest-mapping", ->
  gulp.src ["src/#{$.dir}/mappings/default.json"], read: true
    .pipe tap (file) ->
      mapping = JSON.parse file.contents.toString()
      for page in mapping.ni8
        for param in page
          param.id += 319 if param.id
      util.beautify mapping, on

# check mapping
gulp.task "#{$.prefix}-check-default-mapping", ->
  gulp.src ["src/#{$.dir}/mappings/default.json"], read: true
    .pipe tap (file) ->
      mapping = JSON.parse file.contents.toString()
      for page in mapping.ni8
        assert.ok page.length is 8, "items per page shoud be 8.\n #{JSON.stringify page}"

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
