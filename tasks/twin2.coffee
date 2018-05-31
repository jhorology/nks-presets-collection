# FabFilter Twin 2
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - FabFilter Twin 2 2.23
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
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
  dir: 'FabFilter Twin 2'
  vendor: 'FabFilter'
  magic: 'FT2i'

  #  local settings
  # -------------------------

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
      file.contents = Buffer.from util.beautify
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
      file.contents = Buffer.from util.beautify mapping, on
    .pipe rename
      basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.dir}/mappings"

# for analysing plugin state on Live
gulp.task "#{$.prefix}-adg-test-data", ->
  task.extract_raw_presets_from_adg ["#{$.Ableton.racks}/1 Finger*.adg"], 'test/ableton'

#
# build
# --------------------------------

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
# Discontinued
#  KK won't restore plugin state
