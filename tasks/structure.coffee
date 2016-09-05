# AIR Music Technology Structure
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Structure  2.06.18983
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
extract  = require 'gulp-riff-extractor'
data     = require 'gulp-data'
rename   = require 'gulp-rename'
xpath    = require 'xpath'
_        = require 'underscore'

util     = require '../lib/util.coffee'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config.coffee'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Structure'
  vendor: 'AIR Music Technology'
  magic: 'urtS'
  
  #  local settings
  # -------------------------
  libs: '/Applications/AIR Music Technology/Structure/Structure Factory Libraries'


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
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

# generate per preset mappings
gulp.task "#{$.prefix}-generate-mappings", ->
  # read default mapping template
  template = _.template util.fileRead "src/#{$.dir}/mappings/default.json.tpl"
  gulp.src ["#{$.libs}/**/*.patch"], read: on
    .pipe tap (file) ->
      doc = util.xmlString file.contents.toString()
      data  = {}
      for key in ['Edit1','Edit2','Edit3','Edit4','Edit5','Edit6']
        data[key] = (xpath.select "/H3Patch/H3Assign[@Source=\"#{key}\"]/@Name", doc)[0].value
      mapping = template data
      # set buffer contents
      file.contents = new Buffer mapping
    .pipe rename
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  # read default mapping template
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      basename = path.basename file.path, '.pchk'
      folder = path.relative presets, path.dirname file.path
      patchFile = path.join $.libs, folder, "#{basename}.patch"
      patch = new xmldom().parseFromString _readFile patchFile
      metaxml = (xpath.select "/H3Patch/MetaData/text()", patch).toString().replace /&lt;/mg, '<'
      meta = new xmldom().parseFromString metaxml
      file.contents = new Buffer util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [(xpath.select "/DBValueMap/category/text()", meta).toString().trim().split ': ']
        name: basename.trim()
        modes: (xpath.select "/DBValueMap/keywords/text()", meta).toString().trim().split ' '
        deviceType: 'INST'
        comment: (xpath.select "/H3Patch/Comment/text()", patch).toString().trim()
        bankchain: ['Structure', 'Structure Factory', '']
        author: (xpath.select "/DBValueMap/manufacturer/text()", meta).toString().trim().split ': '
      , on    # print
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
  task.dist_presets $.dir, $.magic, (file) ->
    # per preset mapping file
    "./src/#{$.dir}/mappings/#{file.relative[..-5]}json"

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
