# AIR Music Technology Structure
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Structure  2.06.18983
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
xpath       = require 'xpath'
_           = require 'underscore'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Structure'
  vendor: 'AIR Music Technology'
  magic: 'urtS'
  
  #  local settings
  # -------------------------
  libs: '/Applications/AIR Music Technology/Structure/Structure Factory Libraries'

  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Structure/templates/Structure.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Structure/templates/Structure.bwpreset'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate per preset mappings
gulp.task "#{$.prefix}-generate-mappings", ->
  # read default mapping template
  template = _.template util.readFile "src/#{$.dir}/mappings/default.json.tpl"
  gulp.src ["#{$.libs}/**/*.patch"], read: on
    .pipe tap (file) ->
      doc = util.xmlString file.contents.toString()
      data  = {}
      for key in ['Edit1','Edit2','Edit3','Edit4','Edit5','Edit6']
        data[key] = (xpath.select "/H3Patch/H3Assign[@Source=\"#{key}\"]/@Name", doc)[0].value
      mapping = template data
      # set buffer contents
      file.contents = Buffer.from mapping
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
      patch = util.xmlString util.readFile patchFile
      metaxml = (xpath.select "/H3Patch/MetaData/text()", patch).toString().replace /&lt;/mg, '<'
      meta = util.xmlString metaxml
      file.contents = Buffer.from util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [(xpath.select "/DBValueMap/category/text()", meta).toString().trim().split ': ']
        name: basename.trim()
        modes: (xpath.select "/DBValueMap/keywords/text()", meta).toString().trim().split ' '
        deviceType: 'INST'
        comment: (xpath.select "/H3Patch/Comment/text()", patch).toString().trim()
        bankchain: ['Structure', 'Structure Factory', '']
        author: (xpath.select "/DBValueMap/manufacturer/text()", meta).toString().trim()
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

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

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-appc", ->
  gulp.src "src/#{$.dir}/mappings/default.json"
    .pipe appcGenerator.gulpNica2Appc $.magic, $.dir
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.defaults}/#{$.dir}"

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
