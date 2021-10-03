path          = require 'path'
stream        = require 'stream'
zlib          = require 'zlib',
uuid          = require 'uuid',
_             = require 'underscore'
gulp          = require 'gulp'
first         = require 'gulp-first'
tap           = require 'gulp-tap'
data          = require 'gulp-data'
rename        = require 'gulp-rename'
xmlescape     = require 'xml-escape'
bwExporter    = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'
parseNksf     = require '../lib/gulp-parse-nksf'
vstpreset     = require '../lib/vstpreset'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  vendor: 'iZotope, Inc.'
  # TODO what's encoding method? '939ccee2f3f4075de5d40af6aaf5c5c7'
  vendor_sanitized: 'izotope inc_939ccee2f3f4075de5d40af6aaf5c5c7'
  nksDir: '/Library/Application Support/iZotope/Ozone 9/NKS'
  plugins: [
    #                                                                        VST3 plugin class ID
    {name: 'Ozone 9',                    category: 'Fx|Mastering',           classId: '5653545a-6e4f-394f-7a6f-6e6520390000'}
    {name: 'Ozone 9 Dynamic EQ',         category: 'Fx|Dynamics',            classId: '5653545a-6e59-394f-7a6f-6e6520392044'}
    {name: 'Ozone 9 Dynamics',           category: 'Fx|Dynamics',            classId: '5653545a-6e44-394f-7a6f-6e6520392044'}
    {name: 'Ozone 9 Equalizer' ,         category: 'Fx|EQ',                  classId: '5653545a-4f39-554f-7a6f-6e6520392045'}
    {name: 'Ozone 9 Exciter',            category: 'Fx|Distortion',          classId: '5653545a-4f39-584f-7a6f-6e6520392045'}
    {name: 'Ozone 9 Imager',             category: 'Fx|Spatial',             classId: '5653545a-6e49-394f-7a6f-6e6520392049'}
    {name: 'Ozone 9 Low End Focus',      category: 'Fx|EQ',                  classId: '5653545a-4f39-4c4f-7a6f-6e652039204c'}
    {name: 'Ozone 9 Master Rebalance',   category: 'Fx|Mastering',           classId: '5653545a-4f39-524f-7a6f-6e652039204d'}
    # Match EQ dosen't have NKS presets
    {name: 'Ozone 9 Match EQ',           category: 'Fx|EQ',                  classId: '5653545a-4f39-484f-7a6f-6e652039204d'}
    {name: 'Ozone 9 Maximizer',          category: 'Fx|Dynamics',            classId: '5653545a-4f39-4d4f-7a6f-6e652039204d'}
    {name: 'Ozone 9 Spectral Shaper',    category: 'Fx|Dynamics',            classId: '5653545a-4f39-534f-7a6f-6e6520392053'}
    {name: 'Ozone 9 Vintage Compressor', category: 'Fx|Dynamics',            classId: '5653545a-4f39-434f-7a6f-6e6520392056'}
    {name: 'Ozone 9 Vintage EQ',         category: 'Fx|EQ',                  classId: '5653545a-4f39-514f-7a6f-6e6520392056'}
    {name: 'Ozone 9 Vintage Limiter',    category: 'Fx|Dynamics',            classId: '5653545a-4f39-564f-7a6f-6e6520392056'}
    {name: 'Ozone 9 Vintage Tape',       category: 'Fx|Distortion|Dynamics', classId: '5653545a-4f39-544f-7a6f-6e6520392056'}
  ]

  # plugin MetaInfo
  metaInfoTemplate: _.template '''
<?xml version='1.0' encoding='utf-8'?>
<MetaInfo>
  <Attribute id='MediaType' value='VstPreset' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInCategory' value='<%=category%>' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInName' value='<%=name%>' type='string' flags='writeProtected'></Attribute>
  <Attribute id='PlugInVendor' value='iZotope, Inc.' type='string' flags='writeProtected'></Attribute>
</MetaInfo>
'''

  # AU manufacturer 1767535728 = 'iZtp'
  # AU type 1635083896 = 'aufx'
  aupresetTemplate: _.template '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>data</key>
  <data><% _.forEach(dataLines, function(line) { %>
  <%= line %><% }); %>
  </data>
  <key>manufacturer</key>
  <integer>1767535728</integer>
  <key>name</key>
  <string><%= name %></string>
  <key>subtype</key>
  <integer><%= subtype %></integer>
  <key>type</key>
  <integer>1635083896</integer>
  <key>version</key>
  <integer>0</integer>
</dict>
</plist>
'''

prefix = (plugin) ->
  "#{$.prefix}-#{plugin.name.replace(/^Ozone 9 */, '').toLowerCase().split(' ').join('-')}"

###
 Convert vst2 plugin-states to vst3
 VST2 plugin-states
  - A. size of B + C + D + E        | 4 byte UInt32LE
  - B. header                       | 8 byte, always de8a 6800 0100 0000
  - C. size of (D + E)              | 4 byte UInt32LE
  - D. uncompessed size of E        | 4 byte UInt32LE
  - E. zlib compressed content      | JSON
  - F. unknown
 VST3 content of 'Comp', 'Cont'
  - A. header                       | 8 byte, always de8a 6800 0100 0000
  - B. size of (C + D)              | 4 byte UInt32LE
  - C. uncompessed size of D        | 4 byte UInt32LE
  - D. zlib compressed content      | JSON pluginUUID is differnt from VST2
###
vst3Contents = (vst2PluginStates) ->
  # zlib compressed content -> JSON
  size = vst2PluginStates.readUInt32LE(0)
  # json = zlib.inflateSync(vst2PluginStates.slice(4, 4 + size).slice(16)).toString()
  # preset = JSON.parse json
  # rewrite pluginUUID
  # preset['Context State'].Value.PluginUUID.Value = uuid.v4().toUpperCase()
  # buffer = Buffer.from (JSON.stringify preset, null, '  ') + '\n'
  # zBuffer = zlib.deflateSync buffer
  # sizeB = Buffer.alloc 4
  # sizeB.writeUInt32LE (zBuffer.length + 4)
  # sizeC = Buffer.alloc 4
  # sizeC.writeUInt32LE buffer.length
  vst2PluginStates.slice(4, 4 + size)

editFilePath = (file, plugin, soundInfo) ->
  dirname = path.dirname file.path
  if plugin.name is 'Ozone 9' and soundInfo.bankchain.length and soundInfo.bankchain[1]
    dirname = path.join dirname, soundInfo.bankchain[1]
  file.path = path.join dirname, file.relative
  
# register each plugin tasks
# --------------------------------
$.plugins.forEach (plugin) ->
  nksPresets = "#{$.nksDir}/#{plugin.name}/Presets/**/*.nksfx"
  # generate ableton default plugin parameter configuration
  gulp.task "#{prefix(plugin)}-generate-vst3-appc_", ->
    gulp.src [nksPresets]
      .pipe first()
      .pipe appcGenerator.gulpNksf2Vst3Appc plugin.classId
      .pipe rename
        basename: 'Default'
        extname: '.appc'
      .pipe gulp.dest "#{$.Ableton.vst3Defaults}/#{$.vendor}/#{plugin.name}"

  # export from .nksf to .vstpreset
  gulp.task "#{prefix(plugin)}-export-vstpreset_", ->
    gulp.src [nksPresets]
      .pipe parseNksf()
      .pipe rename extname: '.vstpreset'
      .pipe tap (file) -> editFilePath file, plugin, file.data.nksf.nisi
      .pipe data (file, done) ->
        contents = vst3Contents file.data.nksf.pluginState
        readable = new stream.Readable objectMode: on
        writable = vstpreset.createWriteObjectStream plugin.classId
        readable.pipe writable
        writable.on 'finish', ->
          file.contents = writable.getBuffer()
          done()
        readable.push
          id: 'Comp'
          contents: contents
        readable.push
          id: 'Cont'
          contents: contents
        readable.push
          id: 'Info'
          contents: Buffer.from $.metaInfoTemplate plugin
        readable.push null
      .pipe gulp.dest "#{$.Ableton.vstPresets}/#{$.vendor}/#{plugin.name}"

  # export from .nksf to .bwpreset bitwig studio preset
  gulp.task "#{prefix(plugin)}-export-bwpreset_", ->
    exporter = bwExporter "src/Ozone 9/templates/#{plugin.name}.bwpreset", vst3: on
    gulp.src [nksPresets]
      .pipe exporter.gulpParseNksf()
      .pipe tap (file) -> editFilePath file, plugin, file.data.nksf.nisi
      .pipe exporter.gulpReadTemplate()
      .pipe exporter.gulpAppendPluginState (nksf, done) ->
        contents = vst3Contents nksf.pluginState
        readable = new stream.Readable objectMode: on
        writable = vstpreset.createWriteObjectStream plugin.classId
        readable.pipe writable
        writable.on 'finish', ->
          done undefined, writable.getBuffer()
        readable.push
          id: 'Comp'
          contents: contents
        readable.push
          id: 'Cont'
          contents: contents
        readable.push null
      .pipe exporter.gulpRewriteMetadata()
      .pipe rename extname: '.bwpreset'
      .pipe gulp.dest "#{$.Bitwig.presets}/#{plugin.name}"

  # export from .nksf to .aupreset
  gulp.task "#{prefix(plugin)}-export-aupreset_", ->
    gulp.src [nksPresets]
      .pipe parseNksf()
      .pipe rename extname: '.aupreset'
      .pipe tap (file) -> editFilePath file, plugin, file.data.nksf.nisi
      .pipe tap (file) ->
        # same as VST3 'Cont' chunk
        base64Data = (vst3Contents file.data.nksf.pluginState).toString 'base64'
        lineWidth = 68
        numLines = (base64Data.length + lineWidth - 1) / lineWidth | 0
        # subtype is same as VST2 magic
        file.contents = Buffer.from $.aupresetTemplate
          name: xmlescape file.data.nksf.nisi.name
          subtype: file.data.nksf.plid['VST.magic']
          dataLines: for i in [1..numLines]
            base64Data.slice lineWidth * (i - 1), if i < numLines then lineWidth * i
      .pipe gulp.dest "#{$.AuPresets}/iZotope/#{plugin.name}"

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-vst3-appc", ("#{prefix(plugin)}-generate-vst3-appc_" for plugin in $.plugins)

# export VST3 vstpreset
gulp.task "#{$.prefix}-export-vstpreset", ("#{prefix(plugin)}-export-vstpreset_" for plugin in $.plugins)

# export bwpreset
gulp.task "#{$.prefix}-export-bwpreset", ("#{prefix(plugin)}-export-bwpreset_" for plugin in $.plugins)

# export bwpreset
gulp.task "#{$.prefix}-export-aupreset", ("#{prefix(plugin)}-export-aupreset_" for plugin in $.plugins)
