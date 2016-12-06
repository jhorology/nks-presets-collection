# Spectrasonics Keyscape
#
# notes
#  - Komplete Kontrol 1.7.1(R49)
#  - Keyscape
#    - Software 1.0.1
#    - Sundsources 1.0.1
#    - Patches 1.0.1
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
data     = require 'gulp-data'
rename   = require 'gulp-rename'
xpath    = require 'xpath'
_        = require 'underscore'

util     = require '../lib/util'
task     = require '../lib/common-tasks'

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

  # Ableton Live 9.7 Instrument Rack
  abletonRackTemplate: 'src/Keyscape/templates/Keyscape.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Keyscape/templates/Keyscape.bwpreset'
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

# extract PCHK chunk from .nksf files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

# generate per preset mappings
gulp.task "#{$.prefix}-generate-mappings", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"], read: on
    .pipe tap (file) ->
      basename = path.basename file.path, '.pchk'
      # read plugin state as XML DOM
      #     - first 4 bytes = PCHK version
      #     - last 1 byte = null(0x00) terminater
      xml = util.xmlString (file.contents.slice 4, file.contents.length - 1).toString()
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
      file.contents = new Buffer util.beautify {ni8: pages}, on
    .pipe rename
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"], read: on
    .pipe data (file) ->
      # read as DOM
      # keyscape plugin state is xml
      #   - first 4 bytes = PCHK version
      #   - last 1 byte = null(0x00) terminater
      xml = util.xmlString (file.contents.slice 4, file.contents.length - 1).toString()
      query = '''
/SynthMaster/SynthSubEngine/SynthEngine/SYNTHENG/ENTRYDESCR/@ATTRIB_VALUE_DATA'''
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
      file.contents = new Buffer util.beautify
        author: authors.join '; '
        bankchain: [$.dir, model, '']
        comment: comment
        deviceType: 'INST'
        name: path.basename file.path, '.pchk'
        types: [[type, model]]
        uuid: util.uuid file
        vendor: $.vendor
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

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
    # read plugin state as XMLDOM
    #   - first 4 bytes: PCHK chunk version
    #   - last 1 byte: null(0x00) terminater
    xml = util.xmlString (file.contents.slice 4, file.contents.length - 1).toString()
    # control list for host assignment
    list = _createControlList xml
    # select SYNTHENG node
    syntheng = (xpath.select '/SynthMaster/SynthSubEngine/SynthEngine/SYNTHENG', xml)[0]
    # add host assign attribute
    for item, index in list
      # host parameter = Device 0, Channel -1
      syntheng.setAttribute "#{item.id}MidiLearnDevice0", '16'
      # host parameter index
      syntheng.setAttribute "#{item.id}MidiLearnIDnum0", "#{index}"
      syntheng.setAttribute "#{item.id}MidiLearnChannel0", '-1'
    # rebuild PCHK chunk
    file.contents = Buffer.concat [
      file.contents.slice 0, 4           # PCHK version
      new Buffer xml.toString(), 'utf8'  # xml
      new Buffer [0]                     # null terminate
    ]
    # return per preset mapping file
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

# release zip file to dropbox
gulp.task "#{$.prefix}-release", ["#{$.prefix}-dist"], ->
  task.release $.dir

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  task.export_adg "dist/#{$.dir}/User Content/#{$.dir}/Factory/**/*.nksf"
  , "#{$.Ableton.racks}/#{$.dir}"
  , $.abletonRackTemplate
  , (file, meta) ->
    # edit file path
    dirname = path.dirname file.path
    file.path = path.join dirname, meta.bankchain[1], file.relative

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
  task.export_bwpreset "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Bitwig.presets}/#{$.dir}"
  , $.bwpresetTemplate


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
  query = '''
/SynthMaster/SynthSubEngine/SynthEngine/SYNTHENG/CustomData2/*[
  starts-with(local-name(), 'Custom') and
  @Kind != '0' and
  @Kind != '17'
]
'''
  nodes = xpath.select query, xml
  for node in nodes
    kind = parseInt node.getAttribute 'Kind'
    unless kind in [4,5,6,7,11,15,21]
      throw new Exception "unknown control kind. kind: #{kind}"
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
