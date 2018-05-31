# iZotope Iris 2
#
# notes
#  - Komplete Kontrol 1.7.1(R49)
#  - iris 2  v2.02.415
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
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
  dir: 'iZotope Iris 2'
  # change vender name, 'cause resource forlder name can't conatin characters ",."
  # vendor: 'iZotope, Inc.'
  vendor: 'iZotope'
  magic: "Zir2"

  #  local settings
  # -------------------------

  # Factory Patches folder
  patches: '/Library/Application Support/iZotope/Iris 2/Iris 2 Library/Patches'
  # Ableton Live 9.7 Instrument Rack
  abletonRackTemplate: 'src/iZotope Iris 2/templates/iris2.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/iZotope Iris 2/templates/Iris 2.bwpreset'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate per preset mappings
gulp.task "#{$.prefix}-generate-mappings", ->
  # read default mapping template
  template = _.template util.readFile "src/#{$.dir}/mappings/default.json.tpl"
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"], read: on
    .pipe tap (file) ->
      buf = file.contents.slice 0x00000d59
      offset = 0
      # skip sample 1 - 4
      console.info "============ #{file.path} ========================"
      for i in [1..4]
        strSize = buf.readUInt32LE offset
        offset += 4
        if strSize
          waveFile = buf.toString 'ascii', offset, offset + strSize
          offset += strSize
          # has drawing paths?
          hasDrawing = buf.readUInt8 offset
          offset += 1
          if hasDrawing
            # skip unknown data
            offset += 9
            # number of drawing blocks
            numBlocks = buf.readUInt32LE offset
            offset += 4
            for j in [0...numBlocks]
              # number of drawing paths
              numPaths = buf.readUInt32LE offset
              offset += 4
              # skip drawing paths
              offset += (16 * numPaths)
              # skip unknown data
            # skip sample parameters
            numParams = buf.readUInt32LE offset
            offset += 4
            offset += numParams * 4
            offset += numBlocks * 4
            offset += 16
          else
            # skip sample params
            offset += 16
          console.info "#### Sample #{i} wave: #{waveFile}"
        else
          # no wave data
          offset += 17
          console.info "#### Sample #{i} wave: none"
      # skip LFO 1 - 5
      for i in [1..5]
        strSize = buf.readUInt32LE offset
        offset += 4
        lfoWave = buf.toString 'ascii', offset, offset + strSize
        offset += strSize
        console.info "#### lfo #{i}: #{lfoWave}"
      # macro 1 - 8
      macroName = for i in [1..8]
        strSize = buf.readUInt32LE offset
        offset += 4
        s = buf.toString 'ascii', offset, offset + strSize
        offset += strSize
        console.info "#### macro #{i}: #{s}"
        s
      console.info "#### macroName: #{macroName}"
      mapping = template macroName: macroName
      # set buffer contents
      file.contents = Buffer.from mapping
    .pipe rename
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      basename = path.basename file.path, '.pchk'
      folder = path.relative presets, path.dirname file.path
      file.contents = Buffer.from util.beautify
        vendor: $.vendor
        uuid: util.uuid file
        types: [[folder]]
        name: basename
        deviceType: 'INST'
        bankchain: [$.dir, 'iris 2 Factory', '']
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

#
# build
# --------------------------------

# build presets file to dist folder
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
