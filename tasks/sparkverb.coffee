# UVI Sparkverb
#
# notes
#  - Komplete Kontro 2.0.2(R2)
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
appcGenerator = require '../lib/appc-generator'
extract      = require 'gulp-riff-extractor'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  # dir: 'UVIWorkstationVST'
  dir: 'SparkVerb'
  vendor: 'UVI'
  magic: "SpVb"

  #  local settings
  # -------------------------
  resource_zip: '/Library/Audio/Plug-ins/VST/SparkVerb.vst/Contents/Resources/resource.zip'
  pluginStateTemplate: '''
<UVI4>
  <Engine Name="" Bypass="0" SyncToHost="1" GlobalTune="440" Tempo="120" AutoPlay="1" DisplayName="Default Multi" MeterNumerator="4" MeterDenominator="4">
    <SparkVerb Name="SparkVerb" Bypass="0" ModDepth="4" ModRate="1" Diffusion="0.61799997" DiffusionStart="5" Width="1" RoomSize="20" DecayTime="1" DecayLow="1" DecayHigh="1" FreqLow="250" FreqHigh="12000" Shape="0" Mix="0.5" Quality="3" Mode="1" HiCut="0" LowCut="0" Rolloff="20000" DiffusionOnOff="0" PreDelay="0" MixMode="1" SparkVerbVersion="1">
      <Properties PresetPath=""/>
    </SparkVerb>
  </Engine>
</UVI4>
'''
  # Ableton Live 10.0.2 Audio Effect Rack
  abletonRackTemplate: 'src/SparkVerb/templates/SparkVerb.adg.tpl'
  # Bitwig Studio 2.3.4 preset file
  bwpresetTemplate: 'src/SparkVerb/templates/SparkVerb.bwpreset'

# register common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------
gulp.task "#{$.prefix}-print-default-uvi-plugin-states", ->
  gulp.src ["#{$.NI.userContent}/#{$.dir}/_Default.nksfx"]
    .pipe extract chunk_ids: ['PCHK']
    .pipe tap (file) ->
      #  PCHK chunk
      # - 4bbyte NKS 4byte version or flags = 1 (32bit LE)
      # - UVIWorkstation plugin state
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed file size (32bit LE)
      #   - <zlib deflate archive>
      console.info (zlib.inflateSync file.contents.slice 16).toString 'utf8'

gulp.task "#{$.prefix}-print-generated-uvi-plugin-states", ->
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe extract chunk_ids: ['PCHK']
    .pipe tap (file) ->
      #  PCHK chunk
      # - 4bbyte NKS 4byte version or flags = 1 (32bit LE)
      # - UVIWorkstation plugin state
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed file size (32bit LE)
      #   - <zlib deflate archive>
      console.info "------ #{file.path} ------"
      console.info (zlib.inflateSync file.contents.slice 16).toString 'utf8'

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src $.resource_zip
    .pipe unzip {filter: (entry) -> entry.path[-5..] is '.fxps'}
    .pipe tap (file) ->
      file.path = file.path.replace /^resource\/presets\//, ''
      metaFile = path.join presets, "#{file.relative[..-5]}meta"
      # remove numbering
      type = (path.dirname file.path).replace /^\d+ /, ''
      file.contents = Buffer.from util.beautify
        author: ''
        bankchain: [$.dir, 'SparkVerb Factory', '']
        comment: ''
        deviceType: 'FX'
        modes: []
        name: path.basename file.path, '.fxps'
        types: [[type]]
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
      uvi4 = util.xmlString $.pluginStateTemplate
      sparkVerbSrc = (xpath.select '/ModulePreset/SparkVerb', preset)[0]
      sparkVerbDest = (xpath.select '/UVI4/Engine/SparkVerb', uvi4)[0]
      for attr in sparkVerbSrc.attributes
        # fixed value 'SparkVerb'
        continue if attr.name is 'Name'
        value = attr.value
        # strip trailling '0'
        if value and value.indexOf(".") >= 0
          value = (value.replace /0*$/, '').replace /\.$/, ''
        sparkVerbDest.setAttribute attr.name, value
      properties = (xpath.select '/UVI4/Engine/SparkVerb/Properties', uvi4)[0]
      properties.setAttribute 'PresetPath', "$Resource/#{file.path}"
      xml: uvi4
    .pipe tap (file) ->
      file.path = file.path.replace /^resource\/presets\//, ''
      
      # build PCHK chunk
      # - UVIWorkstation plugin state
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed file size (32bit LE)
      #   - <gzip deflate archive>
      uvi4 = Buffer.from file.data.xml.toString()
      uncompressedSize = Buffer.alloc 4
      uncompressedSize.writeUInt32LE uvi4.length, 0
      file.contents = Buffer.concat [
        Buffer.from [1,0,0,0]          # PCHK version
        Buffer.from "UVI4"
        Buffer.from [1,0,0,0]          # UVI4 version or flags
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

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-appc", ->
  gulp.src "src/#{$.dir}/mappings/default.json"
    .pipe appcGenerator.gulpNica2Appc $.magic, $.dir, on
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
