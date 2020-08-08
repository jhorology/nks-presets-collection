# Spectrasonics Keyscape
#
# notes
#  - Komplete Kontrol 1.7.1(R49)
#  - Keyscape
#    - Software 1.0.1
#    - Sundsources 1.0.1
#    - Patches 1.0.1
# - 20170124
#  - Keyscape
#    - Software 1.0.2c
#    - Sundsources v1.0.2
#    - Patches v1.1d
# - 20180328
#    - Software 1.1.0v
#    - Sundsources v1.0.2
#    - Patches v1.2c
# - 20180911
#    - Patches v1.3c
# - 20200809
#    - Software 1.1.3c
#    - Sundsources v1.0.3c
#    - Patches v1.3.1c
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
steam       = require '../lib/gulp-steam-db'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
fxpExporter  = require '../lib/fxp-exporter'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  dir: 'Keyscape'
  vendor: 'Spectrasonics'
  magic: "Kstn"

  #  local settings
  # -------------------------
 
  # number of parameters, mrswaton -p Kyespcape --display-info
  numParams: 512
  # Ableton Live 10.0.1 Instrument Rack
  abletonRackTemplate: 'src/Keyscape/templates/Keyscape.adg.tpl'
  # Bitwig Studio 3.2.6 preset file
  bwpresetTemplate: 'src/Keyscape/templates/Keyscape.bwpreset'
  # STEAM patch
  steamPatchDb: '/Volumes/Media/Music/Spectrasonics/STEAM/Keyscape/Settings Library/Patches/Factory/Keyscape Library.db'
  # SynthMaster 1.1.0f template
  synthMasterTpl: 'src/Keyscape/presets/SynthMaster-1.1.3c.xml.tpl'
  # common host map parameters
  commonParams: [
    { id: 'poly', name: 'Voices', section: 'Settings'}
    { id: 'gain', name: 'Gain',   section: 'Settings'}
    { id: 'pbdn', name: 'Down',   section: 'Bend'}
    { id: 'pbup', name: 'Up',     section: 'Bend'}
    { id: 'vcb',  name: 'Bias',   section: 'Velocity'}
    { id: 'vcg',  name: 'Gain',   section: 'Velocity'}
    { id: 'vcx',  name: 'X',      section: 'Velocity'}
    { id: 'vcy',  name: 'Y',      section: 'Velocity'}
  ]
  # build options
  buildOpts:
    SYNTHENG:
      # velocity curve for S61
      # ---------------------
      VCname: 'NI Kontrol S61'
      vcx: "3f000000"
      vcy: "3f000000"
      # velocity curve for S88
      # ---------------------
      # VCname: 'NI Kontrol S88'
      # vcx: "3de38e39"
      # vcy: "3d302c10"
    
# register common gulp tasks
# --------------------------------
commonTasks $

# for debug
# --------------------------------
gulp.task "#{$.prefix}-steam-extract-all", ->
  gulp.src $.steamPatchDb, read: off
    .pipe steam()
    .pipe gulp.dest "temp/Keyscape"
    
# preparing tasks
# --------------------------------

# generate per preset mappings
gulp.task "#{$.prefix}-generate-mappings", ->
  gulp.src $.steamPatchDb, read: off
    .pipe steam {filter: (filePath) -> (path.extname filePath) is ".prt_key"}
    .pipe tap (file) ->
      # read plugin state as XML DOM
      #     - first 4 bytes = PCHK version
      #     - last 1 byte = null(0x00) terminater
      xml = util.xmlString file.contents.toString().trim()
      # select custom control nodes
      list = _createControlList xml
      pages = []
      page = []
      prevSection = undefined
      for item, index in list
        # should create new page ?
        #  - page filled up 8 parameters
        #  - remaning slots is 1 or 2 and can't include entire next section params
        #  - first commonParams
        if (page.length is 8 or
            (item.section isnt prevSection and page.length >= 6 and
             ((list.filter (i) -> i.section is item.section).length + page.length) > 8) or
            (item.section isnt prevSection and item.section is 'Settings'))
          # fill empty slot
          while page.length < 8
            page.push autoname: false, vflag: false
          pages.push page
          page = []
        page.push
          autoname: false
          id: index
          name: item.name
          section: item.section if page.length is 0 or item.section isnt prevSection
          vflag: false
        prevSection = item.section
      # fill empty slot
      if page.length
        while page.length < 8
          page.push autoname: false, vflag: false
        pages.push page
      file.contents = Buffer.from util.beautify {ni8: pages}, on
    .pipe rename
      dirname: 'Factory'
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"
    
# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  gulp.src $.steamPatchDb, read: off
    .pipe steam {filter: (filePath) -> (path.extname filePath) is ".prt_key"}
    .pipe data (file) ->
      # read as DOM
      # keyscape plugin state is xml
      #   - first 4 bytes = PCHK version
      #   - last 1 byte = null(0x00) terminater
      xml = util.xmlString file.contents.toString().trim()
      query = '''
/KeyscapePart/SynthEngine/SYNTHENG/ENTRYDESCR/@ATTRIB_VALUE_DATA'''
      attrib = (xpath.select query, xml)[0]?.value
      # convert to JSON style
      authors = []
      type = model = comment = undefined
      for item in ((attrib.split ";")[...-1])
        match = /^([\w ]+)=([\s\S]+)/.exec item
        switch match[1]
          when 'Author'
            authors.push match[2]
          when 'Type'
            type = match[2]
          when 'Model'
            model = match[2]
          when 'Description'
            comment = match[2]
      file.contents = Buffer.from util.beautify
        author: authors.join '; '
        bankchain: [$.dir, model, '']
        comment: comment
        deviceType: 'INST'
        name: path.basename file.path, '.prt_key'
        types: [[type, model]]
        uuid: util.uuid "src/#{$.dir}/presets/Factory/#{path.basename file.path, '.prt_key'}.meta"
        vendor: $.vendor
      , on    # print
    .pipe rename
      dirname: 'Factory'
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

#
# build
# --------------------------------

gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic
  templateDOM = util.xmlFile $.synthMasterTpl
  gulp.src $.steamPatchDb, read: off
    .pipe steam {filter: (filePath) -> (path.extname filePath) is ".prt_key"}
    .pipe tap (file) ->
      # read plugin state as XMLDOM
      #   - first 4 bytes: PCHK chunk version
      #   - last 1 byte: null(0x00) terminater
      xml = util.xmlString file.contents.toString().trim()
      # control list for host assignment
      list = _createControlList xml
      # select SYNTHENG node
      syntheng = (xpath.select '/KeyscapePart/SynthEngine/SYNTHENG', xml)[0]
      # add host assign attribute
      for item, index in list
        # host parameter = Device 16, Channel -1
        syntheng.setAttribute "#{item.id}MidiLearnDevice0", '16'
        # host parameter index
        syntheng.setAttribute "#{item.id}MidiLearnIDnum0", "#{index}"
        syntheng.setAttribute "#{item.id}MidiLearnChannel0", '-1'

      entrydescr = (xpath.select '/KeyscapePart/SynthEngine/SYNTHENG/ENTRYDESCR', xml)[0]
      # "Keyscape Library FOOTBALL 1.2c" -> "Keyscape Library"
      entrydescr.setAttribute 'library', 'Keyscape Library'
      # apply SYNTHENG options
      if $.buildOpts.SYNTHENG
        syntheng.setAttribute key, value for key, value of $.buildOpts.SYNTHENG
      # merge prt_key into template
      synthSubEngine = (xpath.select '/SynthMaster/SynthSubEngine', templateDOM)[0]
      synthSubEngine.removeChild child while child = synthSubEngine?.lastChild
      synthSubEngine.appendChild (xpath.select '/KeyscapePart//SynthEngine', xml)[0]
      # rebuild PCHK chunk
      header = Buffer.alloc 4
      header.write
      file.contents = Buffer.concat [
        Buffer.from [1, 0, 0, 0]           # PCHK version or flags
        Buffer.from templateDOM.toString(), 'ascii'  # xml
        Buffer.from [0]                    # null terminate
      ]
    .pipe rename
      dirname: 'Factory'
      extname: '.nksf'
    .pipe data (file) ->
      nksf:
        pchk: file
        nisi: "src/#{$.dir}/presets/Factory/#{path.basename file.path, '.nksf'}.meta"
        nica: "src/#{$.dir}/mappings/Factory/#{path.basename file.path, '.nksf'}.json"
    .pipe builder.gulp()
    .pipe gulp.dest "dist/#{$.dir}/User Content/#{$.dir}"

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/Factory/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpTemplate()
    .pipe gzip append: off       # append '.gz' extension
    .pipe rename extname: '.adg'
    .pipe tap (file) ->
      # edit file path
      dirname = path.dirname file.path
      file.path = path.join dirname, file.data.nksf.nisi.bankchain[1], file.relative
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

# export from .nksf to .fxp
gulp.task "#{$.prefix}-export-fxp", ["#{$.prefix}-dist-presets"], ->
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/Factory/**/*.nksf"]
    .pipe fxpExporter.gulpNksf2Fxp $.numParams
    .pipe tap (file) ->
      # edit file path
      dirname = path.dirname file.path
      file.path = path.join dirname, file.data.nksf.nisi.bankchain[1], file.relative
    .pipe rename extname: '.fxp'
    .pipe gulp.dest "#{$.fxpPresets}/#{$.dir}"

# functions
# --------------------------------

# create control list for host assignment
#   control kind
#   - 4   on/off switch
#   - 5   section label
#   - 6   labeled on/off switch
#   - 7   knob
#   - 11  radio button group
#   - 15  pull down list
#   - 17  line
#   - 21  rotaly selector
_createControlList = (xml) ->
  list = []
#   query = '''
# /SynthMaster/SynthSubEngine/SynthEngine/SYNTHENG/CustomData2/*[
#   starts-with(local-name(), 'Custom') and
#   @Kind != '0' and
#   @Kind != '17'
# ]
# '''
  query = '''
/KeyscapePart/SynthEngine/SYNTHENG/CustomData2/*[
  starts-with(local-name(), 'Custom') and
  @Kind != '0' and
  @Kind != '17'
]
'''
  nodes = xpath.select query, xml
  for node in nodes
    kind = parseInt node.getAttribute 'Kind'
    unless kind in [4,5,6,7,11,15,21]
      throw new Error "unknown control kind. kind: #{kind}"
    posY = (parseInt node.getAttribute 'PosY')
    list.push
      id: node.tagName.replace /Custom([0-9]+)$/, 'Custom_\$1'
      name: node.getAttribute 'Label'
      kind: kind
      page: parseInt node.getAttribute 'Page'
      # + 10 for rotaly selector
      col: ((parseInt node.getAttribute 'PosX') + 10) / 107 | 0
      row: switch
        # kind 21 rotaly selector -> row 1
        when posY < 420 and kind isnt 21 then 0
        when posY < 500 or kind is 21 then 1
        else 2
  # sort order by page, col, row
  list.sort (a, b) ->
    (a.page - b.page) or
    (a.col - b.col) or
    (a.row - b.row)
  section = undefined
  # add section and modify param name
  for item in list
    # row 0 label is section name
    section = item.name if item.row is 0
    # row 0 labeled switch
    item.name = 'On/Off' if item.row is 0 and item.kind is 6
    # row 2 switch
    item.name = 'On/Off' if item.row is 2 and item.kind is 4
    # raido button group don't have Label
    item.name = 'Mode' if item.kind is 11
    item.section = section
  # remove row 0 label
  list = list.filter (item) -> item.kind isnt 5
  # concat common params
  list.concat $.commonParams
