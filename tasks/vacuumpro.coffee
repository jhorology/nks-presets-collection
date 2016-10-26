# AIR Music Technology VacuumPro
#
# notes
#  - factory presets
#    - Komplete Kontrol  1.5.0(R3065)
#    - VacuumPro         1.0.3.18538
#    - recycle bitwig presets. https://github.com/jhorology/HybridPack4Bitwig
#  - expansions
#    - Komplete Kontrol  1.6.2.5
#    - VacuumPro         1.0.7.19000
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
extract  = require 'gulp-riff-extractor'
data     = require 'gulp-data'
rename   = require 'gulp-rename'
_        = require 'underscore'
del        = require 'del'

util     = require '../lib/util'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'VacuumPro'
  vendor: 'AIR Music Technology'
  magic: "rPcV"

  #  local settings
  # -------------------------

  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/VacuumPro/templates/VacuumPro.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/VacuumPro/templates/VacuumPro.bwpreset'

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
    .pipe data (file) ->
      basename = path.basename file.path, '.pchk'
      folder = (path.relative presets, path.dirname file.path).split path.sep
      # meta
      meta = if folder[0] is 'Expansions'
        vendor: $.vendor
        uuid: util.uuid file
        types: [[folder[2][3..]]]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['VacuumPro', folder[1], '']
        author: ''
      else
        vendor: $.vendor
        uuid: util.uuid file
        types: [[folder[0][3..]]]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['VacuumPro', 'VacuumPro Factory', '']
        author: ''
      file.contents = new Buffer util.beautify meta, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

# suggest mapping
gulp.task "#{$.prefix}-suggest-mapping", ->
  prefixes = [
    'Smart'
    'Master'
    'Delay'
    'A Glide'
    'A VTO 1'
    'A VTO 2'
    'A HPF'
    'A LPF'
    'A Env 1'
    'A Env 2'
    'A Env 3'
    'A Env 4'
    'A Env'
    'A LFO 1'
    'A LFO 2'
    'A Mod 1'
    'A Mod 2'
    'A Velocity'
    'A'
    'B Glide'
    'B VTO 1'
    'B VTO 2'
    'B HPF'
    'B LPF'
    'B Env 1'
    'B Env 2'
    'B Env 3'
    'B Env 4'
    'B Env'
    'B LFO 1'
    'B LFO 2'
    'B Mod 1'
    'B Mod 2'
    'B Velocity'
    'B'
    ]
  gulp.src ["src/#{$.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe tap (file) ->
      flatList = JSON.parse file.contents.toString()
      mapping =
        ni8: []
      groups = _.groupBy flatList, (param) ->
        group = _.find prefixes, (prefix) ->
          (param.name.indexOf prefix) is 0
        group ?= 'undefined'
      console.info beautify (JSON.stringify groups), indent_size: $.json_indent
      makepages = (section, del) ->
        c = 0
        pages = []
        page = []
        for param in groups[section]
          page.push if c is 0
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section} ", '' else param.name
            section: section
            vflag: false
          else
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section} ", '' else param.name
            vflag: false
          if c++ is 8
            pages.push page
            page = []
            c = 0
        if c
          for i in [c...8]
            page.push
              autoname: false
              vflag: false
          pages.push page
          pages
      Array.prototype.push.apply mapping.ni8, makepages 'undefined', false
      for prefix in prefixes
        Array.prototype.push.apply mapping.ni8, makepages prefix, true
      file.contents = new Buffer util.beautify mapping, on
    .pipe rename
      basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.dir}/mappings"

# check mapping
gulp.task "#{$.prefix}-check-default-mapping", ->
  gulp.src ["src/#{$.dir}/mappings/default.json"], read: true
    .pipe data (file) ->
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

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  task.export_adg "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Ableton.racks}/#{$.dir}"
  , $.abletonRackTemplate

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
  task.export_bwpreset "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Bitwig.presets}/#{$.dir}"
  , $.bwpresetTemplate
