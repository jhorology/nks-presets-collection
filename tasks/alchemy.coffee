# Camel Audio Alchemy
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Alchemy(Player)  1.55.0P
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
rename      = require 'gulp-rename'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
sqlite3     = require 'sqlite3'
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
  dir: 'Alchemy'
  vendor: 'Camel Audio'
  magic: 'CaAl'
  # relative paths from dist/#{$.dir}/User Content/#{$.dir}
  releaseExcludes: ["**", "!", "!Factory/**"]
  
  #  local settings
  # -------------------------
  presets: '/Library/Application Support/Camel Audio/Alchemy/Presets'
  db: '/Library/Application Support/Camel Audio/Alchemy/Alchemy_Preset_Ratings_And_Tags'
  mappingTemplateFile: "src/Alchemy/mappings/default.json.tpl"
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Alchemy/templates/Alchemy.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Alchemy/templates/Alchemy.bwpreset'
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

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

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
      file.contents = Buffer.from mapping
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
      file.contents = Buffer.from util.beautify file.data, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

#
# build
# --------------------------------

# build presets
gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"], read: on
    .pipe data (pchk) ->
      nksf:
        pchk: pchk
        nisi: "#{pchk.path[..-5]}meta"
        nica: "src/#{$.dir}/mappings/#{pchk.relative[..-5]}json"
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
