# UVI Synth Anthology 3
#
# notes
#  - Synth Anthology 3
#    - UVI Workstation v3.0.15
#    - Library 1.0.0
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
uuid        = require 'uuid'
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
  dir: 'Synth Anthology 3'
  vendor: 'UVI'
  magic: "UVIW"

  #  local settings
  # -------------------------

  # Ableton Live 9.7 Instrument Rack
  abletonRackTemplate: 'src/Synth Anthology 3/templates/Synth Anthology 3.adg.tpl'
  # Bitwig Studio 1.3.14 RC2 preset file
  bwpresetTemplate: 'src/Synth Anthology 3/templates/Synth Anthology 3.bwpreset'

  ufs: '$Synth Anthology 3.ufs'

  types:
    'Atmosphere-Ethereal': ['Atmosphere-Ethereal']
    Bass: ['Bass']
    Bellish: ['Bellish']
    Chords: ['Chords']
    Flutes: ['Flutes']
    'FX-Weird': ['FX-Weird']
    'Guitar Like': ['Guitar Like']
    Keyboards: ['Keyboards']
    Leads: ['Leads']
    'Mallets-Percs': ['Mallets-Percs']
    Organs: ['Organs']
    Pads: ['Pads']
    Pluck: ['Pluck']
    Polysynth: ['Polysynth'],
    'Short-Sequence': ['Short-Sequence']
    Strings: ['Strings']
    Sweeps: ['Sweeps']
    'Synth Brass': ['Synth Brass']
    'Vox-Choirs': ['Vox-Choirs']

  characters:
    '1-Classic Analog': ['Classic Analog']
    '2-Modern Analog': ['Modern Analog']
    '3-Analog Modeling': ['Analog Modeling']
    '4-FM and Formant': ['FM and Formant']
    '5-Wavetable and Digital': ['Wavetable and Digital']
    '6-Vector Synthesis': ['Vector Synthesis']
    '7-Additive': ['Additive']
    '8-PCM Synth': ['PCM Synth']
    '9-Samplers': ['Samplers']

  uviwsTemplate: '''
<UVI4>
  <Engine Name="" Bypass="0" GlobalTune="440" Tempo="120" AutoPlay="1" DisplayName="Default Multi" MeterNumerator="4" MeterDenominator="4" SyncToHost="1">
    <Synth Name="uvi" Bypass="0" BypassInsertFX="0" Gain="1" Pan="0" DisplayName="Master" OutputName="">
      <Auxs>
        <AuxEffect Name="Aux0" Bypass="0" Gain="1" Pan="0" PreInsert="1" DisplayName="Aux 1"/>
        <AuxEffect Name="Aux1" Bypass="0" Gain="1" Pan="0" PreInsert="1" DisplayName="Aux 2"/>
      </Auxs>
      <Children>
        <Part Name="Part 0" Bypass="0" BypassInsertFX="0" Gain="1" Pan="0" Mute="0" MidiMute="0" Solo="0" DisplayName="Part 1" CoarseTune="0" FineTune="0" TransposeOctaves="0" TransposeSemiTones="0" OutputName="" ExclusiveGroup="0" MidiInput="0" MidiChannel="0" LowKey="0" HighKey="127" LowVelocity="1" HighVelocity="127" LowKeyFade="0" HighKeyFade="0" LowVelocityFade="0" HighVelocityFade="0" RestrictVelocityRange="0" RestrictKeyRange="0" Streaming="1">
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
        <Part Name="Part 1" Bypass="0" BypassInsertFX="0" Gain="1" Pan="0" Mute="0" MidiMute="0" Solo="0" DisplayName="Part 2" CoarseTune="0" FineTune="0" TransposeOctaves="0" TransposeSemiTones="0" OutputName="" ExclusiveGroup="0" MidiInput="0" MidiChannel="1" LowKey="0" HighKey="127" LowVelocity="1" HighVelocity="127" LowKeyFade="0" HighKeyFade="0" LowVelocityFade="0" HighVelocityFade="0" RestrictVelocityRange="0" RestrictKeyRange="0" Streaming="1">
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
        <Part Name="Part 2" Bypass="0" BypassInsertFX="0" Gain="1" Pan="0" Mute="0" MidiMute="0" Solo="0" DisplayName="Part 3" CoarseTune="0" FineTune="0" TransposeOctaves="0" TransposeSemiTones="0" OutputName="" ExclusiveGroup="0" MidiInput="0" MidiChannel="2" LowKey="0" HighKey="127" LowVelocity="1" HighVelocity="127" LowKeyFade="0" HighKeyFade="0" LowVelocityFade="0" HighVelocityFade="0" RestrictVelocityRange="0" RestrictKeyRange="0" Streaming="1">
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
        <Part Name="Part 3" Bypass="0" BypassInsertFX="0" Gain="1" Pan="0" Mute="0" MidiMute="0" Solo="0" DisplayName="Part 4" CoarseTune="0" FineTune="0" TransposeOctaves="0" TransposeSemiTones="0" OutputName="" ExclusiveGroup="0" MidiInput="0" MidiChannel="3" LowKey="0" HighKey="127" LowVelocity="1" HighVelocity="127" LowKeyFade="0" HighKeyFade="0" LowVelocityFade="0" HighVelocityFade="0" RestrictVelocityRange="0" RestrictKeyRange="0" Streaming="1">
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
  <NeededFS Source="/Volumes/Media/Music/UVI/UVISoundBanks/Synth Anthology 3.ufs"/>
</UVI4>
'''

# regist common gulp tasks
# --------------------------------
commonTasks $

# study & analyze
# --------------------------------

gulp.task "#{$.prefix}-decode-plugin-state", ->
  gulp.src ["temp/#{$.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe tap (file) ->
      # - UVIWorkstation plugin states
      #   - A id  4bytes string "UVI4"
      #   - B version or flags  always 1 (32bit LE)
      #   - C unncompressed size of D    (32bit LE)
      #   - D zlib compressed content    (same as .uviws file)
      console.info (zlib.inflateSync file.contents.slice 16).toString()
  
gulp.task "#{$.prefix}-analyze-uvip", ->
  types = {}
  characters = {}
  validatePathh = (p) ->
    /^.+(\/Presets\/.+)/.exec p

  gulp.src ["src/#{$.dir}/presets/**/*.uvip"]
    .pipe data (file) ->
      console.info '----------------', file.relative, '----------------------'
      # create XML DOM tree
      dom = util.xmlFile file.path
      # maschine, category & character
      program = (xpath.select '//Program', dom)[0]
      programPath = program.getAttribute('ProgramPath')
      paths = programPath.split('/')[-3...-1]
      unless paths[0].match /^[0-9]+\-/
        console.warn "ProgramPath is something different. ProgramPath='#{programPath}'"
        samplePlayer = (xpath.select '//SamplePlayer', dom)[0]
        paths = samplePlayer.getAttribute('SamplePath').split('/')[-4...-2]
      maschine =  path.dirname file.relative
      [character, type] = paths
      unless $.types[type] and $.characters[character]
        throw new Error "Unknown type or character.#{{file: file.relative, type, character}}"
      node = xpath.select('//ScriptProcessor/Properties', program)[0]
      # OriginalProgramPath="$Synth Anthology 3.ufs/Presets/11-Sorted by Machines/ACCESS Virus C/VRC-Access Recorder.uvip"
      unless node
        throw new Error "Unfound node: '//ScriptProcessor/Properties'"
      scriptPath =  node.getAttribute 'ScriptPath'
      match = /^.+(\/Scripts\/.+)/.exec scriptPath
      unless match and match[1]
        throw new Error "Unknown ScriptPath: #{match}"
      #console.info 'ScriptPath:', match[1]
      xpath.select('//Oscillators/SamplePlayer', program).forEach (node) ->
        samplePath = node.getAttribute 'SamplePath'
        match = /^.+(\/Samples\/.+)/.exec samplePath
        unless match and match[1]
          throw new Error "Unknown SamplePath: #{match}"
        #console.info 'SamplePath:', match[1]
      xpath.select('//Oscillators/WaveTableOscillator', program).forEach (node) ->
        wavetablePath = node.getAttribute 'WavetablePath'
        match = /^.+(\/Samples\/.+)/.exec wavetablePath
        unless match and match[1]
          throw new Error "Unknown WavetablePath: #{match}"
        #console.info 'WavetablePath:', match[1]

# preparing
# --------------------------------

# generate default mapping file from uvi-host-automation-parameters.coffee
gulp.task "#{$.prefix}-generate-default-mapping", ->
  gulp.src ["src/#{$.dir}/mappings/uvi-host-automation-params.coffee"]
    .pipe tap (file) ->
      params = require path.relative './tasks', file.path
      unless params?.length
        throw new Error "The parameters are not defined in 'uvi-host-automation-params.coffee'."
      if params.length > 128
        throw new Error "The number of automation parameters has been exceeded maximum 128. length: #{params.length}"
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

#
# build
# --------------------------------


gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic, "src/#{$.dir}/mappings/default.json"
  params = require "../src/#{$.dir}/mappings/uvi-host-automation-params"
  gulp.src ["src/#{$.dir}/presets/**/*.uvip"], read: on
    .pipe data (file) ->
      # create DOM tree
      program: (xpath.select '/UVI4/Program', util.xmlString file.contents.toString())[0]
      uviws: util.xmlString $.uviwsTemplate
    .pipe data (file) ->
      {program, uviws} = file.data
      # define preset, machine, character, type
      basename = path.basename file.relative
      name = path.basename file.relative, '.uvip'
      programPath = program.getAttribute('ProgramPath')
      paths = programPath.split('/')[-3...-1]
      unless paths[0].match /^[0-9]+\-/
        console.warn "ProgramPath is something different. ProgramPath='#{programPath}'"
        samplePlayer = (xpath.select '//SamplePlayer', program)[0]
        paths = samplePlayer.getAttribute('SamplePath').split('/')[-4...-2]
      machine =  path.dirname file.relative
      [character, type] = paths
      unless $.types[type] and $.characters[character]
        throw new Error "Unknown type or character.#{{file: file.relative, type, character}}"

      program.setAttribute 'ProgramPath', "#{$.ufs}/Presets/11-Sorted by Machines/#{machine}/#{basename}"
      node = xpath.select('//ScriptProcessor/Properties', program)[0]
      unless node
        throw new Error "node '//ScriptProcessor/Properties' is missing."
      node.setAttribute 'OriginalProgramPath', "#{$.ufs}/Presets/11-Sorted by Machines/#{machine}/#{basename}"
      match = /^.+(\/Scripts\/.+)/.exec node.getAttribute('ScriptPath')
      unless match and match[1]
        throw new Error "Unknown ScriptPath='#{match}'"
      node.setAttribute 'ScriptPath', "#{$.ufs}#{match[1]}"

      xpath.select('//Oscillators/SamplePlayer', program).forEach (node) ->
        samplePath = node.getAttribute 'SamplePath'
        match = /^.+(\/Samples\/.+)/.exec samplePath
        unless match and match[1]
          throw new Error "Unknown SamplePath=#{match}"
        node.setAttribute 'SamplePath', "#{$.ufs}#{match[1]}"
      xpath.select('//Oscillators/WaveTableOscillator', program).forEach (node) ->
        wavetablePath = node.getAttribute 'WavetablePath'
        match = /^.+(\/Samples\/.+)/.exec wavetablePath
        unless match and match[1]
          throw new Error "Unknown WavetablePath=#{match}"
        node.setAttribute 'WavetablePath', "#{$.ufs}/Scripts/..#{match[1]}"
      # remove <BusRouters/>
      (xpath.select '//BusRouters', program).forEach (node) ->
        node.parentNode.removeChild node
      # append <AutomationConnection props.../>
      automation = (xpath.select '/UVI4/Engine/Automation', uviws)[0]
      params.forEach (param, index) ->
        automationConnection = uviws.createElement 'AutomationConnection'
        automationConnection.setAttribute 'sourceIndex', "#{index}"
        automationConnection.setAttribute 'targetPath', '/uvi/Part 0/Program/EventProcessor0'
        automationConnection.setAttribute 'parameterName', "#{param.id}"
        automationConnection.setAttribute 'parameterDisplayName', ''
        automation.appendChild automationConnection
      # append <Program props.../> to Part0
      (xpath.select "/UVI4/Engine/Synth/Children/Part[@Name='Part 0']", uviws)[0].appendChild program
      # create PCHK chunk
      # - UVIWorkstation plugin states
      #   - 4byte chunkId = "UVI4"
      #   - 4byte version or flags = 1 (32bit LE)
      #   - 4byte uncompressed xml size (32bit LE)
      #   - <zlib deflate archive (.uviws file)>
      xml = Buffer.from uviws.toString()
      uncompressedSize = Buffer.alloc 4
      uncompressedSize.writeUInt32LE xml.length
      nksf:
        pchk: Buffer.concat [
          Buffer.from [1,0,0,0]         # PCHK header
          Buffer.from 'UVI4'
          Buffer.from [1,0,0,0]
          uncompressedSize
          zlib.deflateSync xml
        ]
        nisi:
          author: ''
          bankchain: [$.dir, machine, ''],
          comment: '',
          deviceType: 'INST',
          modes: $.characters[character],
          name: name,
          types: [
            $.types[type]
          ],
          uuid: uuid.v4()
          vendor: 'UVI'
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
