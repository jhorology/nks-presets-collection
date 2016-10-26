# AIR Music Technology Hybrid
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Hybrid  3.0.0.18468
#  - recycle bitwig presets. https://github.com/jhorology/HybridPack4Bitwig
# ---------------------------------------------------------------
path       = require 'path'
gulp       = require 'gulp'
tap        = require 'gulp-tap'
data       = require 'gulp-data'
rename     = require 'gulp-rename'
hiveParser = require 'u-he-hive-meta-parser'
_          = require 'underscore'
del        = require 'del'

util       = require '../lib/util'
task       = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Hybrid'
  vendor: 'AIR Music Technology'
  magic: "drbH"
  
  #  local settings
  # -------------------------

  # Ableton Live 9.6.2
  abletonInstrumentRackTemplate: 'src/Hybrid/templates/Hybrid.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Hybrid/templates/Hybrid.bwpreset'

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

# generate default mapping file from _Default.nksf
gulp.task "#{$.prefix}-generate-default-mapping", ->
  task.generate_default_mapping $.dir

# extract PCHK chunk from .bwpreset files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets_from_bw ["#{$.Bitwig.presets}/#{$.dir}/**/*.bwpreset"], "src/#{$.dir}/presets"

# extract PCHK chunk from .nksf files.
gulp.task "#{$.prefix}-extract-expansions-raw-presets", ->
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

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
      file.contents = new Buffer util.beautify meta, on
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

# copy dist files to dist folder
gulp.task "#{$.prefix}-dist", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
  "#{$.prefix}-dist-presets"
]

# copy image resources to dist folder
gulp.task "#{$.prefix}-dist-image", ->
  task.dist_image $.dir, $.vendor

# copy database resources to dist folder
gulp.task "#{$.prefix}-dist-database", ->
  task.dist_database $.dir, $.vendor

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  task.dist_presets $.dir, $.magic

# check
gulp.task "#{$.prefix}-check-dist-presets", ->
  task.check_dist_presets $.dir

#
# deploy
# --------------------------------

gulp.task "#{$.prefix}-deploy", [
  "#{$.prefix}-deploy-resources"
  "#{$.prefix}-deploy-presets"
]

# copy resources to local environment
gulp.task "#{$.prefix}-deploy-resources", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
], ->
  task.deploy_resources $.dir

# copy database resources to local environment
gulp.task "#{$.prefix}-deploy-presets", [
  "#{$.prefix}-dist-presets"
] , ->
  task.deploy_presets $.dir

#
# release
# --------------------------------

# delete third-party expansions
gulp.task "#{$.prefix}-delete-expansions",  ["#{$.prefix}-dist"], (cb) ->
  del [
    "dist/#{$.dir}/User Content/#{$.dir}/Expansions/**"
  ]
  , force: true, cb

# release zip file to dropbox
gulp.task "#{$.prefix}-release", ["#{$.prefix}-delete-expansions"], ->
  task.release $.dir

# export
# --------------------------------

# export from .nksf to .adg ableton drum rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  task.export_adg "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Ableton.racks}/#{$.dir}"
  , $.abletonInstrumentRackTemplate

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
  task.export_bwpreset "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Bitwig.presets}/#{$.dir}"
  , $.bwpresetTemplate
