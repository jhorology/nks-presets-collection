# FabFilter Twin 2
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - FabFilter Twin 2 2.23
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
extract  = require 'gulp-riff-extractor'
data     = require 'gulp-data'
rename   = require 'gulp-rename'

util     = require '../lib/util.coffee'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config.coffee'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'FabFilter Twin 2'
  vendor: 'FabFilter'
  magic: 'FT2i'

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

# generate default mapping file from _Default.nksf
gulp.task "#{$.prefix}-generate-default-mapping", ->
  task.generate_default_mapping $.dir

# extract PCHK chunk from .bwpreset files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      basename = path.basename file.path, '.pchk'
      folder = (path.relative presets, path.dirname file.path).split path.sep
      file.contents = new Buffer util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: switch
          when folder.length is 1 and folder[0] is ''
            [['Default']]
          when folder.length is 1 and folder[0] isnt ''
            type0 = folder[0]
            type0 = 'Best of' if folder[0] is '_Best of'
            [[type0]]
          when folder.length is 2
            type0 = folder[0]
            type1 = folder[1]
            type1 = 'Dance' if folder[1].match /^Dance/
            type1 = 'Soft'  if folder[1].match /^Soft/
            [[type0, type1]]
          when folder.length > 2
            throw new Error 'unexpected folder depth.'
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: [$.dir, 'Twin2 Factory', '']
        author: ''
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
    
# suggest mapping
gulp.task "#{$.prefix}-suggest-mapping", ->
  gulp.src ["src/#{$.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe tap (file) ->
      flatList = JSON.parse file.contents.toString()
      sections = []
      for param, index in flatList
        continue if param.used
        words = param.name.split ' '
        while words.length
          sectionName = words.join ' '
          i = index
          params = while i < flatList.length and (flatList[i].name.indexOf sectionName) is 0
            flatList[i++]
          if params.length >= 3 or words.length is 1
            section =  for p, index  in params
              p.used = on
              autoname: false
              id: parseInt p.id[14..]
              name: (p.name.replace "#{sectionName}", '').trim()
              vflag: false
            section[0].section = sectionName
            sections.push section
            break
          words.pop()
      mapping =
        ni8: []
      page = []
      index = 0
      sectionName = null
      for section in sections
        for param, index in section
          sectionName = param.section if index is 0
          param.section = sectionName if (page.length & 0x07) is 0
          page.push param
          if (page.length & 0x07) is 0
            mapping.ni8.push page
            page = []
      if page.length
        while page.length < 8
          page.push
            autoname: false
            vflag: false
        mapping.ni8.push page
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
  # TODO create maooinf file
  # task.dist_presets $.dir, $.magic

# check
gulp.task "#{$.prefix}-check-dist-presets", ->
  _dist_presets $.dir, $.magic, (file) ->
    "./src/#{$.dir}/mappings/#{file.relative[..-5]}json"

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
  # TODO unfinished
  # task.release $.dir
