# u-he Diva 1.4.1.4078
#
# ---------------------------------------------------------------
path        = require 'path'
stream      = require 'stream'
gulp        = require 'gulp'
first       = require 'gulp-first'
tap         = require 'gulp-tap'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
data        = require 'gulp-data'
_           = require 'underscore'
msgpack     = require 'msgpack-lite'
xmlescape   = require 'xml-escape'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'
parseNksf   = require '../lib/gulp-parse-nksf'
vstpreset   = require '../lib/vstpreset'
riffBuilder = require '../lib/riff-builder'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  dir: 'Super 8'
  vendor: 'Native Instruments'
  magic: 'NIS8'
  vst3ClassId: '5653544e-4953-3873-7570-657220380000'

  #  local settings
  # -------------------------
  nksPresets: [
    '/Library/Application Support/Native Instruments/Super 8 R2/Presets/**/*.nksf'
  ]
  # Bitwig Studio 3.2.8 5 preset file
  bwpresetTemplate: 'src/Super 8/templates/Super 8.bwpreset'
  metaInfo: '''
<?xml version='1.0' encoding='utf-8'?>
<MetaInfo>
  <Attribute id='MediaType' value='VstPreset' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInCategory' value='Instrument' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInName' value='Super 8' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInVendor' value='Native Instruments' type='string' flags='writeProtected'></Attribute>
</MetaInfo>
'''
  aupresetTemplate: _.template '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>data</key>
  <data>
  </data>
  <key>manufacturer</key>
  <integer>760105261</integer>
  <key>name</key>
  <string><%= name %></string>
  <key>subtype</key>
  <integer>1313428280</integer>
  <key>type</key>
  <integer>1635085685</integer>
  <key>version</key>
  <integer>0</integer>
  <key>vstdata</key>
  <data><% _.forEach(dataLines, function(line) { %>
  <%= line %><% }); %>
  </data>
</dict>
</plist>
'''
# register common gulp tasks
# --------------------------------
# commonTasks $, on  # nks-ready

# export
# --------------------------------

###
 Build VST3 Component State('Comp' chunk)
 Component state is same as NKSF format, it's that simple.
 NKSF format
  - NISI chunk = {} empty object
  - NICA chunk = {} empty object
###
vst3ComponentState = (nksf) ->
  riffBuilder 'NIKS'
    # soundInfo = empty object
    .pushChunk 'NISI', Buffer.concat [
      Buffer.from [1,0,0,0]
      msgpack.encode {}
    ]
    # controller assignments = empty object
    .pushChunk 'NICA', Buffer.concat [
      Buffer.from [1,0,0,0]
      msgpack.encode {}
    ]
    # plugin Id
    .pushChunk 'PLID', Buffer.concat [
      Buffer.from [1,0,0,0]
      msgpack.encode nksf.plid
    ]
    # plugin state
    .pushChunk 'PCHK', Buffer.concat [
      Buffer.from [1,0,0,0]
      nksf.pluginState
    ]
    .buffer()

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

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ->
  exporter = bwExporter $.bwpresetTemplate, vst3: on
  gulp.src $.nksPresets
    .pipe exporter.gulpParseNksf()
    .pipe tap exportFilePath
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState (nksf, done) ->
      readable = new stream.Readable objectMode: on
      writable = vstpreset.createWriteObjectStream $.vst3ClassId
      readable.pipe writable
      writable.on 'finish', ->
        done undefined, writable.getBuffer()
      readable.push
        id: 'Comp'
        contents: vst3ComponentState nksf
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
      readable = new stream.Readable objectMode: on
      writable = vstpreset.createWriteObjectStream $.vst3ClassId
      readable
        .pipe writable
      writable.on 'finish', ->
        file.contents = writable.getBuffer()
        done()
      readable.push
        id: 'Comp'
        contents: vst3ComponentState file.data.nksf
      # 'Cont' chunk size = 0
      readable.push
        id: 'Cont'
        contents: Buffer.from []
      readable.push
        id: 'Info'
        contents: Buffer.from $.metaInfo
      readable.push null
    .pipe gulp.dest "#{$.Ableton.vstPresets}/#{$.vendor}/#{$.dir}"


# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-vst3-appc", ->
  gulp.src $.nksPresets
    .pipe first()
    .pipe appcGenerator.gulpNksf2Vst3Appc $.vst3ClassId, $.dir
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.vst3Defaults}/#{$.vendor}/#{$.dir}"

# export from .nksf to .aupreset
gulp.task "#{$.prefix}-export-aupreset", ->
  gulp.src $.nksPresets
    .pipe parseNksf()
    .pipe rename extname: '.aupreset'
    .pipe tap exportFilePath
    .pipe data (file) ->
      base64Data = (vst3ComponentState file.data.nksf).toString 'base64'
      lineWidth = 68
      numLines = (base64Data.length + lineWidth - 1) / lineWidth | 0
      file.contents = Buffer.from $.aupresetTemplate
        name: xmlescape file.data.nksf.nisi.name
        dataLines: for i in [1..numLines]
          base64Data.slice lineWidth * (i - 1), if i < numLines then lineWidth * i
    .pipe gulp.dest "#{$.AuPresets}/#{$.vendor}/#{$.dir}"
