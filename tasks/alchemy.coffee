# Camel Audio Alchemy
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Alchemy(Player)  1.55.0P
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
rename   = require 'gulp-rename'
data     = require 'gulp-data'
del      = require 'del'
sqlite3  = require 'sqlite3'
_        = require 'underscore'
util     = require '../lib/util.coffee'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config.coffee'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Alchemy'
  vendor: 'Camel Audio'
  magic: 'CaAl'
  
  #  local settings
  # -------------------------
  presets: '/Library/Application Support/Camel Audio/Alchemy/Presets'
  db: '/Library/Application Support/Camel Audio/Alchemy/Alchemy_Preset_Ratings_And_Tags'
  mappingTemplateFile: "src/Alchemy/mappings/default.json.tpl"
  query_items: '''
select
  t0.ITEM_NAME as name
  ,t3.ATTRIBUTE_TYPE_NAME as key
  ,t2.ATTRIBUTE_NAME as value
  ,t4.ATTRIBUTE_NAME as parentValue
from
  items as t0
  left join attributes_map t1 on t0.ITEM_ID = t1.ITEM_ID
  left join attributes t2 on t1.ATTRIBUTE_ID = t2.ATTRIBUTE_ID
  left join ATTRIBUTE_TYPES t3 on t2.ATTRIBUTE_TYPE_ID = t3.ATTRIBUTE_TYPE_ID
  left join attributes t4 on t2.ATTRIBUTES_TREE_PARENT = t4.ATTRIBUTE_ID
where
  t0.STORAGE_PATH = $preset
order by
  t2.ATTRIBUTE_ID
'''

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

# extract PCHK chunk from .nksf files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

# generate per preset mappings
#
# *.acp is text file, contain control assignmnets as follow:
# Cont1Lbl = VibratOo
# Cont2Lbl = FltDecay
# Cont3Lbl = SymReZ
# Cont4Lbl = EVF1depth
# Cont5Lbl = Comp On
# Cont6Lbl = CompRel
# Cont7Lbl = CoffSet--
# Cont8Lbl = Amp
# XyPad1x = Curved
# XyPad1y = EQ
# XyPad2x = Thinner
# XyPad2y =
gulp.task "#{$.prefix}-generate-mappings", ->
  # read default mapping template
  template = _.template util.readFile $.mappingTemplateFile
  gulp.src ["#{$.presets}/**/*.acp"], read: on
    .pipe tap (file) ->
      preset = file.contents.toString()
      match = /(Cont1Lbl =[\s\S]*?XyPad2y = [\s\S]*?\n)/.exec preset
      # convert json style
      regexp = / = (.*$)/gm
      assignments = match[1].replace regexp, ": \"$1\","
      # some presets heading '_' e.g '_XyPad1x'
      assignments = assignments.replace /_XyPad/g, 'XyPad'
      # string to object
      console.info "({#{assignments}})"
      assignments = eval "({#{assignments}})"
      mapping = template assignments
      # set buffer contents
      file.contents = new Buffer mapping
    .pipe rename
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"


# generate metadata from alchemy's sqlite database
gulp.task "#{$.prefix}-generate-meta", ->
  # open database
  db = new sqlite3.Database $.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      bank = file.relative.replace /(\/.*$)/, ''
      # execute query
      db.all $.query_items, $preset: "Alchemy/Presets/#{file.relative[..-5]}acp", (err, rows) ->
        unless rows and rows.length
          return done "record not found in database. preset:#{file.relative}"
        author = ''
        types = []
        modes = []
        for row in rows
          switch row.key
            when 'Category'
              types.push [row.value]
            when 'Subcategory'
              types.push [row.parentValue, row.value]
            when 'Timber'
              modes.push row.value
            when 'Genre'
              modes.push row.value
            when 'Articulation'
              modes.push row.value
            when 'Sound Designer'
              author = row.value
            else
        done undefined,
          vendor: $.vendor
          types: types
          name: rows[0].name
          modes: _.uniq modes
          deviceType: 'INST'
          comment: ''
          bankchain: ['Alchemy', bank, '']
          author: author
    .pipe tap (file) ->
      file.data.uuid = util.uuid file
      file.contents = new Buffer util.beautify file.data, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

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

# delete third-party presets
gulp.task "#{$.prefix}-delete-thirdparty-presets",  ["#{$.prefix}-dist"], (cb) ->
  del [
    "dist/#{$.dir}/User Content/#{$.dir}/**"
    "!dist/#{$.dir}/User Content/#{$.dir}"
    "!dist/#{$.dir}/User Content/#{$.dir}/Factory/**"
    ]
  , force: true, cb

# release zip file to dropbox
gulp.task "#{$.prefix}-release", ["#{$.prefix}-delete-thirdparty-presets"], ->
  task.release $.dir
