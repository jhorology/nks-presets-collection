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
data     = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename   = require 'gulp-rename'
_        = require 'underscore'
del      = require 'del'
util     = require '../lib/util'
commonTasks = require '../lib/common-tasks'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'theRiser'
  vendor: 'AIR Music Technology'
  magic: "rsRt"
  releaseExcludes: [ "Expansions/**" ]

  #  local settings
  # -------------------------

  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/theRiser/templates/theRiser.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/theRiser/templates/theRiser.bwpreset'

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
