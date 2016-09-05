# AIR Music Technology theRiser
#
# notes
#  - factory presets
#    - Komplete Kontrol  1.5.0(R3065)
#    - theRiser          *unknown
#    - recycle bitwig presets. https://github.com/jhorology/theRiserPack4Bitwig
#  - expansions
#    - Komplete Kontrol  1.6.2.5
#    - theRiser          1.0.7.19000
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
extract  = require 'gulp-riff-extractor'
data     = require 'gulp-data'
rename   = require 'gulp-rename'
_        = require 'underscore'
del      = require 'del'

util     = require '../lib/util.coffee'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config.coffee'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'theRiser'
  vendor: 'AIR Music Technology'
  magic: "rsRt"

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
      basename = path.basename file.path, '.pchk'
      folder = (path.relative presets, path.dirname file.path).split path.sep
      # meta
      meta = if folder[0] is 'Expansions'
        vendor: $.vendor
        uuid: util.uuid file
        types: [['Sound Effects']]
        # gave up auto categlizing
        # modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['theRiser', folder[1], '']
        author: ''
      else
        vendor: $.vendor
        uuid: util.uuid file
        types: [['Sound Effects']]
        modes: [folder[0][3..]]
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['theRiser', 'theRiser Factory', '']
        author: ''
      file.contents = new Buffer util.beautify meta, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

# suggest mapping
gulp.task "#{$.prefix}-suggest-mapping", ->
  prefixes = [
    'Sweep Gain'
    'Sweep Freq'
    'SweepOsc Shape'
    'Noise Gain'
    'Noise Shape'
    'Noise Tune'
    'Chord Gain'
    'Chord Shape'
    'Chord Brightness'
    'Filter Freq'
    'Filter Reso'
    'Distortion'
    'Master Gain'
    'Pan'
    'Pumper'
    'Delay'
    'Reverb'
    'Effect Mix'
    'LFO A'
    'LFO B'
    'Lock'
    'Sync'
    ]
  postfixes = [
    'Decay'
  ]
  gulp.src ["src/#{$.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe tap (file) ->
      flatList = JSON.parse file.contents.toString()
      mapping =
        ni8: []
      groups = _.groupBy flatList, (param) ->
        group = _.find prefixes, (prefix) ->
          (param.name.indexOf prefix) is 0
        group ?= _.find postfixes, (postfix) ->
          (param.name.indexOf postfix) is (param.name.length - postfix.length)
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
