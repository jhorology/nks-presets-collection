# UVI Key Suite Digital
#
# notes
#  - Key Suite Digital
#    - UVI Workstation v3.0.5
#    - Library 1.0.0
#  - 20190912
#    - UVI Workstation v3.0.5
#    - Library 1.1.0
#  - 20190912
#    - UVI Workstation v3.0.5
#    - Library 1.1.0
#  - 201901010
#    - UVI Workstation v3.0.5
#    - Library 1.1.1
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
  dir: 'Key Suite Digital'
  vendor: 'UVI'
  magic: "UVIW"

  #  local settings
  # -------------------------

  uvi4Template: '''
<UVI4>
    <Engine Name="" Bypass="0" SyncToHost="1" GlobalTune="440" Tempo="120" AutoPlay="1" DisplayName="Default Multi" MeterNumerator="4" MeterDenominator="4">
        <Synth Name="uvi" Bypass="0" Gain="1" Pan="0" DisplayName="Master" OutputName="" BypassInsertFX="0">
            <Auxs>
                <AuxEffect Name="Aux0" Bypass="0" Gain="1" Pan="0" PreInsert="1" DisplayName="Aux 1"/>
                <AuxEffect Name="Aux1" Bypass="0" Gain="1" Pan="0" PreInsert="1" DisplayName="Aux 2"/>
            </Auxs>
            <Children>
                <Part Name="Part 0" Bypass="0" Gain="1" Pan="0" Mute="0" MidiMute="0" Solo="0" DisplayName="Part 1" CoarseTune="0" FineTune="0" TransposeOctaves="0" TransposeSemiTones="0" OutputName="" ExclusiveGroup="0" MidiInput="0" MidiChannel="0" LowKey="0" HighKey="127" LowVelocity="1" HighVelocity="127" LowKeyFade="0" HighKeyFade="0" LowVelocityFade="0" HighVelocityFade="0" RestrictVelocityRange="0" RestrictKeyRange="0" Streaming="1" BypassInsertFX="0">
                    <Connections>
                        <SignalConnection Name="SignalConnection 1" Ratio="1" Source="@MIDI CC 11" Destination="Gain" Mapper="" ConnectionMode="0" Bypass="0" Inverted="0"/>
                        <SignalConnection Name="SignalConnection 0" Ratio="1" Source="@MIDI CC 7" Destination="Gain" Mapper="" ConnectionMode="1" Bypass="0" Inverted="0" Offset="0" SignalConnectionVersion="1"/>
                        <SignalConnection Name="SignalConnection 0" Ratio="1" Source="@MIDI CC 10" Destination="Pan" Mapper="" ConnectionMode="1" Bypass="0" Inverted="0" Offset="0" SignalConnectionVersion="1"/>
                    </Connections>
                    <ControlSignalSources/>
                    <BusRouters>
                        <BusRouter Name="AuxSend0" Bypass="0" Gain="0" Destination="../../Aux0" PreFader="0" BusRouterVersion="1"/>
                        <BusRouter Name="AuxSend1" Bypass="0" Gain="0" Destination="../../Aux1" PreFader="0" BusRouterVersion="1"/>
                    </BusRouters>
                </Part>
                <Part Name="Part 1" Bypass="0" Gain="1" Pan="0" Mute="0" MidiMute="0" Solo="0" DisplayName="Part 2" CoarseTune="0" FineTune="0" TransposeOctaves="0" TransposeSemiTones="0" OutputName="" ExclusiveGroup="0" MidiInput="0" MidiChannel="1" LowKey="0" HighKey="127" LowVelocity="1" HighVelocity="127" LowKeyFade="0" HighKeyFade="0" LowVelocityFade="0" HighVelocityFade="0" RestrictVelocityRange="0" RestrictKeyRange="0" Streaming="1" BypassInsertFX="0">
                    <Connections>
                        <SignalConnection Name="SignalConnection 1" Ratio="1" Source="@MIDI CC 11" Destination="Gain" Mapper="" ConnectionMode="0" Bypass="0" Inverted="0"/>
                        <SignalConnection Name="SignalConnection 0" Ratio="1" Source="@MIDI CC 7" Destination="Gain" Mapper="" ConnectionMode="1" Bypass="0" Inverted="0" Offset="0" SignalConnectionVersion="1"/>
                        <SignalConnection Name="SignalConnection 0" Ratio="1" Source="@MIDI CC 10" Destination="Pan" Mapper="" ConnectionMode="1" Bypass="0" Inverted="0" Offset="0" SignalConnectionVersion="1"/>
                    </Connections>
                    <ControlSignalSources/>
                    <BusRouters>
                        <BusRouter Name="AuxSend0" Bypass="0" Gain="0" Destination="../../Aux0" PreFader="0" BusRouterVersion="1"/>
                        <BusRouter Name="AuxSend1" Bypass="0" Gain="0" Destination="../../Aux1" PreFader="0" BusRouterVersion="1"/>
                    </BusRouters>
                </Part>
                <Part Name="Part 2" Bypass="0" Gain="1" Pan="0" Mute="0" MidiMute="0" Solo="0" DisplayName="Part 3" CoarseTune="0" FineTune="0" TransposeOctaves="0" TransposeSemiTones="0" OutputName="" ExclusiveGroup="0" MidiInput="0" MidiChannel="2" LowKey="0" HighKey="127" LowVelocity="1" HighVelocity="127" LowKeyFade="0" HighKeyFade="0" LowVelocityFade="0" HighVelocityFade="0" RestrictVelocityRange="0" RestrictKeyRange="0" Streaming="1" BypassInsertFX="0">
                    <Connections>
                        <SignalConnection Name="SignalConnection 1" Ratio="1" Source="@MIDI CC 11" Destination="Gain" Mapper="" ConnectionMode="0" Bypass="0" Inverted="0"/>
                        <SignalConnection Name="SignalConnection 0" Ratio="1" Source="@MIDI CC 7" Destination="Gain" Mapper="" ConnectionMode="1" Bypass="0" Inverted="0" Offset="0" SignalConnectionVersion="1"/>
                        <SignalConnection Name="SignalConnection 0" Ratio="1" Source="@MIDI CC 10" Destination="Pan" Mapper="" ConnectionMode="1" Bypass="0" Inverted="0" Offset="0" SignalConnectionVersion="1"/>
                    </Connections>
                    <ControlSignalSources/>
                    <BusRouters>
                        <BusRouter Name="AuxSend0" Bypass="0" Gain="0" Destination="../../Aux0" PreFader="0" BusRouterVersion="1"/>
                        <BusRouter Name="AuxSend1" Bypass="0" Gain="0" Destination="../../Aux1" PreFader="0" BusRouterVersion="1"/>
                    </BusRouters>
                </Part>
                <Part Name="Part 3" Bypass="0" Gain="1" Pan="0" Mute="0" MidiMute="0" Solo="0" DisplayName="Part 4" CoarseTune="0" FineTune="0" TransposeOctaves="0" TransposeSemiTones="0" OutputName="" ExclusiveGroup="0" MidiInput="0" MidiChannel="3" LowKey="0" HighKey="127" LowVelocity="1" HighVelocity="127" LowKeyFade="0" HighKeyFade="0" LowVelocityFade="0" HighVelocityFade="0" RestrictVelocityRange="0" RestrictKeyRange="0" Streaming="1" BypassInsertFX="0">
                    <Connections>
                        <SignalConnection Name="SignalConnection 1" Ratio="1" Source="@MIDI CC 11" Destination="Gain" Mapper="" ConnectionMode="0" Bypass="0" Inverted="0"/>
                        <SignalConnection Name="SignalConnection 0" Ratio="1" Source="@MIDI CC 7" Destination="Gain" Mapper="" ConnectionMode="1" Bypass="0" Inverted="0" Offset="0" SignalConnectionVersion="1"/>
                        <SignalConnection Name="SignalConnection 0" Ratio="1" Source="@MIDI CC 10" Destination="Pan" Mapper="" ConnectionMode="1" Bypass="0" Inverted="0" Offset="0" SignalConnectionVersion="1"/>
                    </Connections>
                    <ControlSignalSources/>
                    <BusRouters>
                        <BusRouter Name="AuxSend0" Bypass="0" Gain="0" Destination="../../Aux0" PreFader="0" BusRouterVersion="1"/>
                        <BusRouter Name="AuxSend1" Bypass="0" Gain="0" Destination="../../Aux1" PreFader="0" BusRouterVersion="1"/>
                    </BusRouters>
                </Part>
            </Children>
        </Synth>
        <Automation>
        </Automation>
    </Engine>
    <NeededFS Source="/Library/Application Support/UVISoundBanks/Key Suite Digital.ufs"/>
</UVI4>
'''
  ufs: '$Key Suite Digital.ufs'
  # Ableton Live 10.1b21 Instrument Rack
  abletonRackTemplate: 'src/Key Suite Digital/templates/Key Suite Digital.adg.tpl'
  # Bitwig Studio 2.5.1 preset file
  bwpresetTemplate: 'src/Key Suite Digital/templates/Key Suite Digital.bwpreset'
  # bank
  models:
    D330: 'Roland P-330'
    SG:   'KORG SG-1D'
    MW:   'AKAI SG01p'
    NP:   'ALESIS NanoPiano'
    PFM:  'E-MU PROFORMANCE /1'
    SPM:  'ensoniq SPM-1'
    T80:  'Rhodes mk-80'
    TM:   'KURZWEIL MicroPiano'
    T20:  'Roland MKS-20'
    TXP:  'YAMAHA TX1P'
  # bank
  categories: [
    {
      pattern: /Clavinet/
      type: ['Piano / Keys', 'Clavinet']
      modes: ['Sample-based']
    }
    {
      pattern: /Honky|Tonk/
      type: ['Piano / Keys', 'Upright Piano']
      modes: ['Sample-based']
    }
    {
      pattern: /PFM Piano Bell/
      type: ['Piano / Keys', 'Other Piano / Keys']
      modes: ['Sample-based']
    }
    {
      pattern: /Electric Piano|EPiano|Epiano|Tines|T20 Electric/
      type: ['Piano / Keys', 'Electric Piano']
      modes: ['Sample-based']
    }
    {
      pattern: /Grand|Acoustic Piano|APiano|PFM Acoustic|T80 Piano|T20 Piano|TXP Piano/
      type: ['Piano / Keys', 'Grand Piano']
      modes: ['Sample-based']
    }
    {
      pattern: /Harpsichord/
      type: ['Piano / Keys', 'Harpsichord']
      modes: ['Sample-based']
    }
    {
      pattern: /Vibraphone|Vibes|NP Electric Vibe/
      type: ['Mallet Instruments', 'Vibraphone']
      modes: ['Sample-based']
    }
    {
      pattern: /Marimba/
      type: ['Mallet Instruments', 'Marimba']
      modes: ['Sample-based']
    }
    {
      pattern: /Organ/
      type: ['Organ', 'Electric']
      modes: ['Sample-based']
    }
    {
      pattern: /Double Bass/
      type: ['Bass', 'Upright']
      modes: ['Sample-based']
    }
    {
      pattern: /EBass/
      type: ['Bass', 'Fingered']
      modes: ['Sample-based']
    }
    {
      pattern: /Pad/
      type: ['Synth Pad', 'Basic']
      modes: ['Sample-based', 'Slow Attack']
    }
    {
      pattern: /Pad/
      type: ['Synth Pad', 'Basic']
      modes: ['Sample-based', 'Slow Attack']
    }
    {
      pattern: /^NP Lead/
      type: ['Synth Lead', 'Classic Mono']
      modes: ['Sample-based']
    }
    {
      pattern: /^NP /
      type: ['Mallet Instruments', 'Other']
      modes: ['Sample-based']
    }
  ]
# register common gulp tasks
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
      #   - zlib deflate archive (.uviws file)>
      console.info (zlib.inflateSync file.contents.slice 16).toString()

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
      file.contents = Buffer.from util.beautify {ni8: pages}, on

    .pipe rename
      basename: 'default'
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.uvip"], read: on
    .pipe data (file) ->
      basename = path.basename file.path, '.uvip'
      modelId = basename.replace /^(\w+).*$/, '\$1'
      bankName = $.models[modelId]
      unless bankName
        throw new Error "undefined model. id: #{modelId}"
      category = ((name) ->
        $.categories.find (c) ->
          name.match c.pattern
      )(basename)
      unless category
        throw new Error "category not found. name: #{basename}"
      file.contents = Buffer.from util.beautify
        author: ''
        bankchain: [$.dir, bankName, '']
        comment: ''
        deviceType: 'INST'
        modes: category.modes
        name: basename
        types: [category.type]
        uuid: util.uuid "#{(file.path.split '.')[...-1].join '.'}.meta"
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
  replacePath = (node, attrName, regexp) ->
    v = node.getAttribute attrName
    v = v.replace regexp, "#{$.ufs}$2"
    if v
      node.setAttribute attrName, v
    v
  params = require "../src/#{$.dir}/mappings/uvi-host-automation-params"
  gulp.src ["src/#{$.dir}/presets/**/*.uvip"], read: on
    .pipe data (uvip) ->
      uvi4 = util.xmlString $.uvi4Template
      program = (xpath.select '/UVI4/Program', util.xmlString uvip.contents.toString())[0]
      # replace ProogramPath
      programPath = replacePath program, 'ProgramPath', /^(.+)(\/Presets\/.+)/
      # remove <BusRouters/>
      (xpath.select '//BusRouters', program).forEach (node) ->
        node.parentNode.removeChild node
      # Properties[@ScriptPath]
      (xpath.select '//Properties[@ScriptPath]', program).forEach (node) ->
        replacePath node, 'ScriptPath', /^(.+)(\/Scripts\/.+)/
        node.setAttribute 'OriginalProgramPath', programPath
      # Convolver[@SamplePath]
      (xpath.select '//Convolver[@SamplePath]', program).forEach (node) ->
        replacePath node, 'SamplePath', /^(.+)(\/IR\/.+)/
      # SamplePlayer[@SamplePath]
      (xpath.select '//SamplePlayer[@SamplePath]', program).forEach (node) ->
        replacePath node, 'SamplePath', /^(.+)(\/Samples\/.+)/
      automation = (xpath.select '/UVI4/Engine/Automation', uvi4)[0]
      # append <AutomationConnection props.../>
      params.forEach (param, index) ->
        automationConnection = uvi4.createElement 'AutomationConnection'
        automationConnection.setAttribute 'sourceIndex', "#{index}"
        automationConnection.setAttribute 'targetPath', '/uvi/Part 0/Program/EventProcessor0'
        automationConnection.setAttribute 'parameterName', "#{param.id}"
        automationConnection.setAttribute 'parameterDisplayName', ''
        automation.appendChild automationConnection
      # append <Program props.../> to Part0
      (xpath.select "/UVI4/Engine/Synth/Children/Part[@Name='Part 0']", uvi4)[0].appendChild program
      # create PCHK chunk
      # - UVIWorkstation plugin states
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed xml size (32bit LE)
      #   - <zlib deflate archive (.uviws file)>
      xml = Buffer.from uvi4.toString()
      uncompressedSize = Buffer.alloc 4
      uncompressedSize.writeUInt32LE xml.length
      pchk = Buffer.concat [
        Buffer.from [1,0,0,0]         # PCHK header
        Buffer.from 'UVI4'
        Buffer.from [1,0,0,0]
        uncompressedSize
        zlib.deflateSync xml
      ]
      nksf:
        pchk: pchk
        nisi: "#{uvip.path[..-5]}meta"
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
    .pipe exporter.gulpRewriteMetadata (nisi) ->
      meta = bwExporter.defaultMetaMapper nisi
      meta.creator = $.dir
      meta
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
