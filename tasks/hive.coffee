# u-he Hive
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Hive   1.0 revision 3514
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/HivePack4Bitwig
#  - recycle Ableton Racks. https://github.com/jhorology/HivePack4Live
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
hiveParser  = require 'u-he-hive-meta-parser'
_           = require 'underscore'
util        = require '../lib/util'
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
  dir: 'Hive'
  vendor: 'u-he'
  magic: 'hIVE'
  
  #  local settings
  # -------------------------
  presets: '/Library/Audio/Presets/u-he/Hive'
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Hive/templates/Hive.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Hive/templates/Hive.bwpreset'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

gulp.task "#{$.prefix}-check-presets-h2p", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      relative = path.relative presets, path.dirname file.path
      hivePreset = path.join $.presets, relative, "#{basename}.h2p"
      if not fs.existsSync hivePreset
        console.info "#{relative}/#{basename}.h2p not found."

gulp.task "#{$.prefix}-check-presets-pchk", ->
  presets = "#{$.presets}"
  gulp.src ["#{$.presets}/**/*.h2p"]
    .pipe tap (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      relative = path.relative presets, path.dirname file.path
      pchkPreset = path.join "src/#{$.dir}/presets", relative, "#{basename}.pchk"
      if not fs.existsSync pchkPreset
        console.info "#{relative}/#{basename}.pchk not found."
        
# extract PCHK chunk from ableton .adg files.
gulp.task "#{$.prefix}-extract-extra-raw-presets", ->
  task.extract_raw_presets_from_adg ["#{$.Ableton.racks}/#{$.dir}/TREASURE TROVE/**/*.adg"]
  , "src/#{$.dir}/presets/TREASURE TROVE/"

# suggest mapping
gulp.task "#{$.prefix}-suggest-mapping", ->
  gulp.src ["src/#{$.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe tap (file) ->
      lastSection = undefined
      pages = []
      page = []
      fillPage = (page) ->
        while page.length < 8
          page.push
            autoname: false
            vflag: false
        page
      for param in JSON.parse file.contents.toString()
        section = (param.name.split ':')[0]
        if section isnt lastSection and (_.isArray page) and page.length
          pages.push fillPage page
          page = []
        page.push if page.length is 0
          autoname: false
          id: parseInt param.id[14..]
          name: param.name.replace "#{section}: ", ''
          section: section
          vflag: false
        else
          autoname: false
          id: parseInt param.id[14..]
          name: param.name.replace "#{section}: ", ''
          vflag: false
        if page.length is 8
          pages.push page
          page = []
        lastSection = section
      pages.push fillPage page if page.length

      file.contents = Buffer.from util.beautify ni8: pages, on
    .pipe rename basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.dir}/mappings"

# check mapping
gulp.task "#{$.prefix}-check-default-mapping", ->
  gulp.src ["src/#{$.dir}/mappings/default.json"], read: true
    .pipe tap (file) ->
      mapping = JSON.parse file.contents.toString()
      for page in mapping.ni8
        assert.ok page.length is 8, "items per page shoud be 8.\n #{JSON.stringify page}"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  hiveParser  = require 'u-he-hive-meta-parser'
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      basename = path.basename file.path, '.pchk'
      relative = path.relative presets, path.dirname file.path
      folder = relative.split path.sep
      hivePreset = path.join $.presets, relative, "#{basename}.h2p"
      hiveMeta = hiveParser.parse hivePreset
      bank = switch
        when folder[0].match /^[0-9][0-9] / then 'Hive Factory'
        when not folder[0] then 'Hive Preview'
        else folder[0]
      subBank = if folder.length is 2 then folder[1] else ''
      # meta
      meta =
        vendor: $.vendor
        uuid: util.uuid file
        types: []
        modes: []
        name: basename
        deviceType: 'INST'
        bankchain: ['Hive', bank, subBank]
      meta.types = [[folder[0][3..]]] if bank is 'Hive Factory'
      meta.author = hiveMeta.Author.trim() if hiveMeta?.Author
      meta.comment = hiveMeta.Description.trim() if hiveMeta?.Description
      meta.comment = '' if not hiveMeta?.Description and hiveMeta?.Usage
      meta.comment += '\n' if hiveMeta?.Description and hiveMeta?.Usage
      meta.comment += "Usage:\n#{hiveMeta.Usage}" if hiveMeta?.Usage
      file.contents = Buffer.from util.beautify meta, on
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
