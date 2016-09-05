# AIR Music Technology Velvet
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Velvet  2.0.6.18983
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
rename   = require 'gulp-rename'

util     = require '../lib/util.coffee'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config.coffee'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Velvet'
  vendor: 'AIR Music Technology'
  magic: "tvlV"
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

# extract PCHK chunk from .nksf files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      basename = path.basename file.path, '.pchk'
      folder = path.relative presets, path.dirname file.path
      # meta
      file.contents = new Buffer util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [["Piano/Keys", "Electric Piano"]]
        modes: ['Sample Based']
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Velvet', folder, '']
        author: ''
      . on   # print on/off
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
