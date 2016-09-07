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
  prefixes = [
    'Morph'
    'Chorus'
    'Delay'
    'Reverb'
    'PartA Filter 1'
    'PartA Filter 2'
    'PartA Filter'
    'PartA Oscillator1'
    'PartA Oscillator2'
    'PartA Oscillator3'
    'PartA Env1'
    'PartA Env2'
    'PartA EnvF'
    'PartA EnvA'
    'PartA LFO1'
    'PartA LFO2'
    'PartA LFO3'
    'PartA Pumper'
    'PartA SSeq'
    'PartA Gate'
    'PartA Note'
    'PartA Velocity'
    'PartA CtrlSeq1'
    'PartA CtrlSeq2'
    'PartA'
    'PartB Filter 1'
    'PartB Filter 2'
    'PartB Filter'
    'PartB Oscillator1'
    'PartB Oscillator2'
    'PartB Oscillator3'
    'PartB Env1'
    'PartB Env2'
    'PartB EnvF'
    'PartB EnvA'
    'PartB LFO1'
    'PartB LFO2'
    'PartB LFO3'
    'PartB Pumper'
    'PartB SSeq'
    'PartB Gate'
    'PartB Note'
    'PartB Velocity'
    'PartB CtrlSeq1'
    'PartB CtrlSeq2'
    'PartB'
    ]
  gulp.src ["src/#{$.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe data (file) ->
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
          c++
          if c is 8
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
      json = beautify (JSON.stringify mapping), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      mapping
    .pipe rename
      basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.dir}/mappings"

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
  # TODO create image files
  # task.dist_image $.dir, $.vendor

# copy database resources to dist folder
gulp.task "#{$.prefix}-dist-database", ->
  task.dist_database $.dir, $.vendor

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  # TODO create mapping file
  # task.dist_presets $.dir, $.magic

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
  # TODO unfinished
  # task.release $.dir
