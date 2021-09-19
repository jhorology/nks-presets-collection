# Native Instruments Massive 1.0.0(R116)
#
# CHANGES
#  20210320
#    - add 'Hour House' libarary.
#    - renew templeate for Live 11
# ---------------------------------------------------------------
assert      = require 'assert'
path        = require 'path'
{ Readable } = require 'stream'
zlib        = require 'zlib'
gulp        = require 'gulp'
first       = require 'gulp-first'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
_           = require 'underscore'
riff        = require 'gulp-riff-extractor'
msgpack     = require 'msgpack-lite'
xmlescape   = require 'xml-escape'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'
parseNksf   = require '../lib/gulp-parse-nksf'
vstpreset   = require '../lib/vstpreset'

#
# buld environment & misc settings
#-------------------------------------------
$ = require '../config'
$ = Object.assign {}, $,
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  dir: 'Massive X'
  vendor: 'Native Instruments'
  magic: 'Ni$H'
  vst3ClassId: '5653544e-6924-486D-6173-736976652078'

  #  local settings
  # -------------------------
  nksPresets: [
    "#{$.NI.content}/Massive X Factory Library/Presets/**/*.nksf"
    "#{$.NI.content}/Drive Library/Presets/**/*.nksf"
    "#{$.NI.content}/Mechanix Library/Presets/**/*.nksf"
    "#{$.NI.content}/Moebius Library/Presets/**/*.nksf"
    "#{$.NI.content}/Our House Library/Presets/**/*.nksf"
    "#{$.NI.content}/Pulse Library/Presets/**/*.nksf"
    "#{$.NI.content}/Rush Library/Presets/**/*.nksf"
    "#{$.NI.content}/Scene Library/Presets/**/*.nksf"
  ]
  # Ableton Live 11.0
  abletonRackTemplate: 'src/Massive X/templates/Massive X 16 macors.adg.tpl'
  # Bitwig Studio 4.0.2 vst3 preset file
  bwpresetTemplate: 'src/Massive X/templates/Massive X.bwpreset'
  metaInfo: '''
<?xml version='1.0' encoding='utf-8'?>
<MetaInfo>
  <Attribute id='MediaType' value='VstPreset' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInCategory' value='Instrument|Synth' type='string' flags='writeProtected'></Attribute>
  <Attribute id='plugtype' value='Instrument|Synth' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInName' value='Massive X' type='string' flags='writeProtected'></Attribute>
  <Attribute id='plugname' value='Massive X' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInVendor' value='Native Instruments' type='string' flags='writeProtected'></Attribute>
</MetaInfo>
'''

# register common gulp tasks
# --------------------------------
commonTasks $, on  # nks-ready



# decode plugin-states
gulp.task "#{$.prefix}-parse-plugin-states", ->
  gulp.src $.nksPresets
    .pipe riff
      chunk_ids: ['PCHK']
    .pipe data (file, done) ->
      # PCHK chunk content
      #   - 4byte NKS header flags or version 32bit LE
      #   - Massive X plugin-states
      #     - A 8byte header unknown =  always 0200 0000 0000 0000
      #     - B 4byte content size of C + D (32bit LE)
      #     - C 4byte uncompressed content size of D (32bit BE)
      #     - D zlib compressed content
      inflateStream = zlib.createInflate()
      decodeStream = msgpack.createDecodeStream()
      buffer = Buffer.alloc 0
      inflateStream
        .pipe decodeStream
        .on 'data',  (d) ->
          buffer = Buffer.concat [
            buffer
            Buffer.from "#{if _.isObject d then util.beautify d else d.toString()}\n"
          ]
        .on 'end', ->
          file.contents = buffer
          done()
      inflateStream.write file.contents.slice 20
      inflateStream.end()
    .pipe rename extname: '.txt'
    .pipe gulp.dest "temp/#{$.dir}"

# decode plugin-states
gulp.task "#{$.prefix}-parse-plugin-states-as-single-json", ->
  gulp.src $.nksPresets
    .pipe riff
      chunk_ids: ['PCHK']
    .pipe data (file, done) ->
      # PCHK chunk content
      #   - 4byte NKS header flags or version 32bit LE
      #   - Massive X plugin-states
      #     - A 8byte header unknown =  always 0200 0000 0000 0000
      #     - B 4byte content size of C + D (32bit LE)
      #     - C 4byte uncompressed content size of D (32bit BE)
      #     - D zlib compressed content
      inflateStream = zlib.createInflate()
      decodeStream = msgpack.createDecodeStream()
      buffer = Buffer.alloc 0
      stats =
        st: 0
        result: {}
      inflateStream
        .pipe decodeStream
        .on 'data', (msg) ->
          try
            _decodeMessage msg, stats
          catch err
            done err
        .on 'end', ->
          file.contents = Buffer.from util.beautify stats.result
          done()
      inflateStream.write file.contents.slice 20
      inflateStream.end()
    .pipe rename extname: '.json'
    .pipe gulp.dest "temp/#{$.dir}"

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src $.nksPresets
    .pipe exporter.gulpParseNksf()
    .pipe data (file, done) ->
      inflateStream = zlib.createInflate()
      decodeStream = msgpack.createDecodeStream()
      buffer = Buffer.alloc 0
      stats =
        st: 0
        result: {}
      inflateStream
        .pipe decodeStream
        .on 'data', (msg) ->
          try
            _decodeMessage msg, stats
          catch err
            done err
        .on 'end', ->
          done undefined,
            nksf: file.data.nksf
            massive: stats.result
      inflateStream.write file.data.nksf.pluginState.slice 16
      inflateStream.end()
    .pipe exporter.gulpTemplate (file, embedParams) ->
      embedParams.macros = for i in [1..16]
        # macro name of Borken Bow.nksf contains 0x1c
        name: xmlescape file.data.massive.strings["root/engine/global/macros/macro#{i}/macroName/value"].replace /[\u0000-\u001f]+/, ''
        normalizedValue: file.data.massive.doubles["root/engine/global/macros/macro#{i}/macroValue/normalizedValue"]
    .pipe gzip append: off       # append '.gz' extension
    .pipe rename extname: '.adg'
    .pipe tap (file) ->
      # edit file path
      if file.data.nksf.nisi.types and file.data.nksf.nisi.types.length
        dirname = path.dirname file.path
        type = file.data.nksf.nisi.types[0][0].replace 'Piano / Keys', 'Piano & Keys'
        file.path = path.join dirname, type, file.relative
      else
        console.warn "[#{file.path}] doesn't have types property."
    .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ->
  exporter = bwExporter $.bwpresetTemplate, vst3: on
  gulp.src $.nksPresets
    .pipe exporter.gulpParseNksf()
    .pipe tap exportFilePath
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState (nksf, done) ->
      readable = new Readable objectMode: on
      writable = vstpreset.createWriteObjectStream $.vst3ClassId
      readable.pipe writable
      writable.on 'finish', ->
        done undefined, writable.getBuffer()
      readable.push
        id: 'Comp'
        # probably same as vst2 pluginState
        contents: nksf.pluginState
      # 'Cont' chunk size = 0
      readable.push
        id: 'Cont'
        contents: Buffer.from []
      readable.push null
    .pipe exporter.gulpRewriteMetadata()
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"

# export from .nksf to .vstpreset
gulp.task "#{$.prefix}-export-vstpreset", ->
  gulp.src $.nksPresets
    .pipe parseNksf()
    .pipe rename extname: '.vstpreset'
    .pipe tap exportFilePath
    .pipe data (file, done) ->
      readable = new Readable objectMode: on
      writable = vstpreset.createWriteObjectStream $.vst3ClassId
      readable
        .pipe writable
      writable.on 'finish', ->
        file.contents = writable.getBuffer()
        done()
      readable.push
        id: 'Comp'
        # probably same as vst2 pluginState
        contents: file.data.nksf.pluginState
      # 'Cont' chunk size = 0
      readable.push
        id: 'Cont'
        contents: Buffer.from []
      readable.push
        id: 'Info'
        contents: Buffer.from $.metaInfo
      readable.push null
    .pipe gulp.dest "#{$.Ableton.vstPresets}/#{$.vendor}/#{$.dir}"


###
 categorized by folder
###
exportFilePath = (file) ->
  if file.data.nksf.nisi.types and file.data.nksf.nisi.types.length
    dirname = path.dirname file.path
    type = file.data.nksf.nisi.types[0][0].replace 'Piano / Keys', 'Piano & Keys'
    file.path = path.join dirname, type, file.relative
  else
    console.warn "[#{file.path}] doesn't have types property."

_decodeMessage = (msg, stats) ->
  resetStats = ->
    ['dataType', 'numItems', 'numVectItems', 'vectItemIndex', 'vectKey'].forEach (k) -> delete stats[k]
    stats.st = 0
  switch
    when stats.st is 0  # data type
      assert.ok (_.isString msg), "dataType should be a string. occurs:[#{msg}]"
      assert.ok msg in ['strings', 'floats', 'doubles','ints', 'bools', 'charVecs', 'intVecs', 'floatVecs','doubleVecs', 'stringVecs']
      , "unknown dataType. occurs:#{msg}"
      stats.dataType = msg
      stats.st = 1

    when stats.st is 1
       # 1 number of data items + 1
      assert.ok (_.isNumber msg), "numItems should be a Number. occurs:[#{msg}]"
      stats.numItems = msg - 1
      switch
        when stats.numItems is 0 then resetStats()
        when stats.dataType.endsWith 'Vecs' then stats.st =  3
        else stats.st = 2
    when stats.st is 2
      # 2 object for 'strings', 'floats', 'doubles','ints', 'bools'
      assert.ok (_.isObject msg), "#{stats.dataType} data should be an object. occurs:#{msg}}"
      keysLength = (Object.keys msg).length
      assert.ok keysLength is stats.numItems, "incorrect numItems. numItems:#{stats.numItems} keys length:#{keysLength}}"
      stats.result[stats.dataType] = msg
      resetStats()
    when stats.st is 3
       # 3 number of vector items
      assert.ok (_.isNumber msg), "numVectItems should be a Number. occurs:[#{msg}]"
      stats.numVectItems = msg
      assert.ok stats.numVectItems is stats.numItems, "incorrect numItems. numItems:#{stats.numItems} numVectItems:#{stats.vectItemSize}}"
      stats.vectItemIndex = 0
      stats.result[stats.dataType] = {}
      stats.st = 4
    when stats.st is 4
       # 4 key  of vector item
      assert.ok (_.isString msg), "key of vector item should be a string. occurs:[#{msg}]"
      stats.vectKey = msg
      stats.st = 5
    when stats.st is 5
       # 5 value  of vector item
      assert.ok (Array.isArray msg), "value of vector item should be an array. occurs:[#{msg}]"
      stats.result[stats.dataType][stats.vectKey] = msg
      stats.vectItemIndex++
      if (stats.vectItemIndex < stats.numVectItems)
        stats.st = 4
      else
        resetStats()
    else
      throw new Error "Unknwon message. occurs:#{msg}"
