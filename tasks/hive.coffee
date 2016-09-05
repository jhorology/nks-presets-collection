# u-he Hive
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Hive   1.0 revision 3514
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/HivePack4Bitwig
#  - recycle Ableton Racks. https://github.com/jhorology/HivePack4Live
# ---------------------------------------------------------------
path       = require 'path'
gulp       = require 'gulp'
tap        = require 'gulp-tap'
data       = require 'gulp-data'
rename     = require 'gulp-rename'
exec       = require 'gulp-exec'
hiveParser = require 'u-he-hive-meta-parser'
_          = require 'underscore'

util       = require '../lib/util.coffee'
task       = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config.coffee'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Hive'
  vendor: 'u-he'
  magic: 'hIVE'
  
  #  local settings
  # -------------------------
  presets: '/Library/Audio/Presets/u-he/Hive'


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

# generate default mapping file from _Default.nksf
gulp.task "#{$.prefix}-generate-default-mapping", ->
  task.generate_default_mapping $.dir

# extract PCHK chunk from .bwpreset files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  gulp.src ["#{$.Bitwig.presets}/#{$.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      basename = path.basename file.path, '.bwpreset'
      dirname = path.join "src/#{$.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# extract PCHK chunk from .nksf files.
gulp.task "#{$.prefix}-extract-raw-presets-nksf", ->
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

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
  gulp.src ["#{$.Ableton.racks}/#{$.dir}/TREASURE TROVE/**/*.adg"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.dir}/presets/TREASURE TROVE/", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'echo "now converting file:<%= file.relative %>"'
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/adg2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts


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

      file.contents = new Buffer util.beautify ni8: pages, on
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
      file.contents = new Buffer util.beautify meta, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

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

# release zip file to dropbox
gulp.task "#{$.prefix}-release", ["#{$.prefix}-dist"], ->
  task.release $.dir
