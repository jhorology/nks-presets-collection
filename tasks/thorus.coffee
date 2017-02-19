# UVI Thorus
#
# notes
#  - Komplete Kontrol 1.7.1(R49)
#  - Thorus 1.0.0
# ---------------------------------------------------------------
fs          = require 'fs'
path        = require 'path'
uuid        = require 'uuid'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
xpath       = require 'xpath'
_           = require 'underscore'
zlib        = require 'zlib'
unzip       = require 'gulp-unzip'
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
  # dir: 'UVIWorkstationVST'
  dir: 'Thorus'
  vendor: 'UVI'
  magic: "ThRs"

  #  local settings
  # -------------------------
  resource_zip: '/Library/Audio/Plug-ins/VST/Thorus.vst/Contents/Resources/resource.zip'
  pluginStateTemplate: '''
<UVI4>
  <Engine Name=""
          Bypass="0"
          SyncToHost="1"
          GlobalTune="440"
          Tempo="120"
           AutoPlay="1"
          DisplayName="Default Multi"
          MeterNumerator="4"
          MeterDenominator="4">
  </Engine>
</UVI4>
'''
  # Ableton Live 9.7.1 Instrument Rack
  abletonRackTemplate: 'src/Thorus/templates/Thorus.adg.tpl'
  # Bitwig Studio 1.3.15 RC2 preset file
  bwpresetTemplate: 'src/Thorus/templates/Thorus.bwpreset'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src $.resource_zip
    .pipe unzip {filter: (entry) -> entry.path[-5..] is '.fxps'}
    .pipe tap (file) ->
      file.path = file.path.replace /^resource\/presets\//, ''
      metaFile = path.join presets, "#{file.relative[..-5]}meta"
      file.contents = new Buffer util.beautify
        author: ''
        bankchain: [$.dir, 'Thorus Factory', '']
        comment: ''
        deviceType: 'FX'
        modes: []
        name: path.basename file.path, '.fxps'
        types: [[path.dirname file.path]]
        uuid: util.uuid metaFile
        vendor: $.vendor
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

#
# build
# --------------------------------

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic, "src/#{$.dir}/mappings/default.json"
  gulp.src [$.resource_zip]
    .pipe unzip {filter: (entry) -> entry.path[-5..] is '.fxps'}
    .pipe data (file) ->
      preset = util.xmlString file.contents.toString()
      whiteChorus = (xpath.select '/ModulePreset/WhiteChorus', preset)[0]
      whiteChorus.removeChild child while child = whiteChorus?.lastChild
      uvi4 = util.xmlString $.pluginStateTemplate
      engine = (xpath.select '/UVI4/Engine', uvi4)[0]
      engine.appendChild whiteChorus
      properties = uvi4.createElement 'Properties'
      properties.setAttribute 'PresetPath', "$Resource/#{file.path}"
      whiteChorus.appendChild properties
      xml: uvi4
    .pipe tap (file) ->
      file.path = file.path.replace /^resource\/presets\//, ''
      
      # build PCHK chunk
      # - UVIWorkstation plugin state
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed file size (32bit LE)
      #   - <gzip deflate archive>
      uvi4 = new Buffer file.data.xml.toString()
      uncompressedSize = new Buffer 4
      uncompressedSize.writeUInt32LE uvi4.length, 0
      file.contents = new Buffer.concat [
        new Buffer [1,0,0,0]          # PCHK version
        new Buffer "UVI4"
        new Buffer [1,0,0,0]          # UVI4 version or flags
        uncompressedSize
        zlib.deflateSync uvi4
      ]
    .pipe data (pchk) ->
      nksf:
        pchk: pchk
        nisi: "src/#{$.dir}/presets/#{pchk.path[..-5]}meta"
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
    .pipe gulp.dest "#{$.Ableton.effectRacks}/#{$.dir}"

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
