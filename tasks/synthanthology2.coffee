# UVI Synth Anthology 2
#
# notes
#  - Komplete Kontrol 1.7.1(R49)
#  - Synth Anthology 2
#    - UVI Workstation v2.6.8
#    - Library 1.0
#
# 2016-11-15 supportt Library changes 1.0.0 ->  1.1.1
#   1.1.1
#   ------------
#   - New: add "Pitch Bend Range"
#   - Fix: wrong tuning in "P23-Pure Bell"
#   1.1.0
#   ------------
#   - Fix: missing samples in « KS8-Funny Pipe »
#   - Fix: diverse namings correction, including « ODY-Straitght Bass »
#   - Fix: sliders image glitches
#   - Fix: missing artwork
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
rename      = require 'gulp-rename'
gzip        = require 'gulp-gzip'
xpath       = require 'xpath'
_           = require 'underscore'
extract     = require 'gulp-riff-extractor'
zlib        = require 'zlib'
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
  dir: 'Synth Anthology 2'
  vendor: 'UVI'
  magic: "UVIW"

  #  local settings
  # -------------------------

  # Ableton Live 9.7 Instrument Rack
  abletonRackTemplate: 'src/Synth Anthology 2/templates/Synth Anthology 2.adg.tpl'
  # Bitwig Studio 1.3.14 RC2 preset file
  bwpresetTemplate: 'src/Synth Anthology 2/templates/Synth Anthology 2.bwpreset'
  # synth models
  synths:
    AAX: 'AKAI AX80'
    ACP: 'ARP Chroma Polaris'
    ADR: 'ALESIS Andromeda'
    ANX: 'YAMAHA AN1X'
    BBS: 'novation BASS STATION II'
    BOO: 'STUDIO ELECTRONICS BOOMSTAR 5089'
    CC1: 'CASIO CZ-1'
    CNL: 'Clavia nord lead'
    CS8: 'YAMAHA CS-80'
    CV1: 'CASIO VZ-1'
    DS1: 'KORG DSS-1'
    EE2: 'E-MU Emulator II'
    EFZ: 'ENSONiQ FiZmo'
    EK4: 'ELKA EK44'
    EMA: 'E-MU Emax'
    ES8: 'ensoniq SQ-80'
    ESQ: 'ensoniq ESQ-M'
    EVX: 'ensoniq VFX'
    FCX: 'Fairlight CMI IIX'
    FUS: 'ALESIS FUSION'
    J16: 'Roland JUNO-106'
    J60: 'Roland JUNO-60'
    JP4: 'Roland JUPITER-4'
    JP8: 'Roland JUPITER-8'
    K3M: 'KAWAI K3'
    K5K: 'KAWAI K5000'
    KBL: 'rsf kobol'
    KK4: 'KAWAI K4R'
    KM1: 'KORG M1'
    KML: 'KORG minilogue'
    KMS: 'KORG MS-20'
    KS8: 'KORG DS-8'
    KTR: 'KORG TRION'
    KW8: 'KORG DW-8000'
    KWS: 'KORG WAVESTATION'
    MEM: 'moog memorymoog'
    MM: 'moog minimoog'
    MM4: 'MELLOTRON M400'
    MPM: 'moog polymoog'
    MSB: 'moog SUB-37'
    MSR: 'moog SOURCE'
    MTX: 'Oberheim Matrix 6'
    NS2: 'NED SYNCLAVIER II'
    NUN: 'novation ULTRANOVA'
    NVA: 'novation NOVA'
    OB6: 'Oberheim OB-6'
    OBX: 'Oberheim OB-X'
    ODY: 'ARP ODYSSEY'
    OSC: 'OSC OSCAR'
    P23: 'PPG Wave 2.3'
    P5: 'SCI Prophet 5'
    PKS: 'FORMANTA POLOVOKS'
    PS3: 'KORG PS3200'
    PVS: 'SCI Prophet VS'
    QDR: 'ARP QUADRA'
    R8X: 'Roland JX-8P'
    RD5: 'Roland D-50'
    RJ8: 'Roland JD-800'
    SDK: 'SIEL DK80'
    SDS: 'SEIKO DS310'
    SP6: 'DSI Prophet 6'
    STX: 'ELKA SYNTHEX'
    TB3: 'Roland TB-303'
    VP3: 'Roland VP-330'
    VRC: 'access Virus C'
    VTI: 'VERMONA Tiracon 6V'
    WDQ: 'waldorf Q'
    WPU: 'waldorf pulse'
    WXT: 'waldorf microWAVE XT'
    XPA: 'Oberheim Xpander'
    YC2: 'YAMAHA CS-20M'
    YFS: 'YAMAHA FS1R'
    YS7: 'YAMAHA SY77'
    YSY: 'YAMAHA SY22'
    YX1: 'YAMAHA DX100'
    YX7: 'YAMAHA DX7'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# Extract PCHK chunk from .nksf files.
gulp.task "#{$.prefix}-extract-pchk", ->
  gulp.src ["temp/#{$.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe tap (file) ->
      # OCR Filename may be incorrect.
      # read correct file name from plugin state.
      #
      # - UVIWorkstation plugin states
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed file size (32bit LE)
      #   - <gzip deflate archive (.uviws file)>
      xml = util.xmlString (zlib.inflateSync file.contents.slice 16).toString()
      program = (xpath.select '/UVI4/Engine/Synth/Children/Part/Program', xml)[0]
      displayName = program.getAttribute 'DisplayName'
      programPath = program.getAttribute 'ProgramPath'
      relative = path.relative '$Synth Anthology II.ufs/Presets/', path.dirname programPath
      file.path = path.join file.base, relative, "#{displayName}.pchk"
    .pipe gulp.dest "src/#{$.dir}/presets"

# Extract PCHK chunk from .nksf files. update 1.1.1
#  - ODY-Straitght Bass
#  - KS8-Funny Pipe
#  - P23-Pure Bell
gulp.task "#{$.prefix}-extract-pchk-update-1.1.1", ->
  gulp.src ["temp/#{$.dir}/update 1.1.1/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe tap (file) ->
      # OCR Filename may be incorrect.
      # read correct file name from plugin state.
      #
      # - UVIWorkstation plugin states
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed file size (32bit LE)
      #   - <gzip deflate archive (.uviws file)>
      xml = util.xmlString (zlib.inflateSync file.contents.slice 16).toString()
      program = (xpath.select '/UVI4/Engine/Synth/Children/Part/Program', xml)[0]
      displayName = program.getAttribute 'DisplayName'
      programPath = program.getAttribute 'ProgramPath'
      relative = path.relative '$Synth Anthology II.ufs/Presets/', path.dirname programPath
      file.path = path.join file.base, relative, "#{displayName}.pchk"
    .pipe gulp.dest "src/#{$.dir}/presets"

# generate default mapping file from uvi-host-automation-parameters.coffee
gulp.task "#{$.prefix}-generate-default-mapping", ->
  gulp.src ["src/#{$.dir}/mappings/uvi-host-automation-params.coffee"]
    .pipe tap (file) ->
      params = require path.relative './tasks', file.path
      unless params?.length
        throw new Error "The parameters are not defined in 'uvi-host-automation-params.coffee'."
      if params.length > 128
        throw new Error "The number of parameters has exceeded maximum 128. length: #{params.length}"
      console.info "## params.length: #{params.length}"
      pages = []
      page = []
      prevSection = undefined
      for item, index in params
        # should create new page ?
        #  - page filled up 8 parameters
        #  - item.newPage property
        #  - remaning slots is 1 or 2 and can't include entire next section params
        if (page.length is 8 or item.newPage or
           (item.section isnt prevSection and page.length >= 6 and
            ((params.filter (i) -> i.section is item.section).length + page.length) > 8))
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
      basename: 'default'
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"


# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"], read: on
    .pipe data (file) ->
      basename = path.basename file.path, '.pchk'
      synthId = basename.replace /^(\w+)\-.*$/, '\$1'
      synthModel = $.synths[synthId]
      unless synthModel
        throw new Error "undefined Synth Model. id: #{synthId}"
      folder = file.relative.split path.sep
      file.contents = new Buffer util.beautify
        author: ''
        bankchain: [$.dir, synthModel, '']
        comment: ''
        deviceType: 'INST'
        modes: [folder[0].replace /^[0-9]+\-(.*)$/, '\$1']
        name: basename
        types: [[folder[1], synthModel]]
        uuid: util.uuid file
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
  # read LuSH-101 mapping file
  params = require "../src/#{$.dir}/mappings/uvi-host-automation-params"
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"], read: on
    .pipe data (pchk) ->
      # file.contents = PCHK chunk data
      # - 4byte PCHK version or flag
      # - UVIWorkstation plugin state
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed file size (32bit LE)
      #   - <gzip deflate archive (.uviws file)>
      xml: util.xmlString (zlib.inflateSync pchk.contents.slice 16).toString()
    .pipe data (pchk) ->
      xml = pchk.data.xml
      automation = (xpath.select '/UVI4/Engine/Automation', xml)
      if automation and automation.length
        # remove all child node if <Automation> node already exist.
        automation = automation[0]
        automation.removeChild child while child = automation?.lastChild
      else
        # create new <Automation> node.
        automation = xml.createElement 'Automation'
        engine = (xpath.select '/UVI4/Engine', xml)[0]
        engine.appendChild automation

      for param, index in params
        automationConnection = xml.createElement 'AutomationConnection'
        automationConnection.setAttribute 'sourceIndex', "#{index}"
        automationConnection.setAttribute 'targetPath', '/uvi/Part 0/Program/EventProcessor0'
        automationConnection.setAttribute 'parameterName', "#{param.id}"
        automationConnection.setAttribute 'parameterDisplayName', ""
        automation.appendChild automationConnection
      xml: xml
    .pipe tap (pchk) ->
      # rebuild PCHK chunk
      uvi4 = new Buffer pchk.data.xml.toString()
      uncompressedSize = uvi4.length
      pchk.contents = new Buffer.concat [
        pchk.contents.slice 0, 16
        zlib.deflateSync uvi4
      ]
      pchk.contents.writeUInt32LE uncompressedSize, 12
    .pipe data (pchk) ->
      nksf:
        pchk: pchk
        nisi: "#{pchk.path[..-5]}meta"
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
