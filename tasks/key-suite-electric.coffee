# UVI Key Suite Electric
#
# notes
#  - 20220112
#    - UVI Workstation v3.1.3
#    - Library 1.0.6
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
  dir: 'Key Suite Electric'
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
    <NeededFS Source="/Library/Application Support/UVISoundBanks/Key Suite Electric.ufs"/>
</UVI4>
'''
  ufs: '$Key Suite Electric.ufs'
  # Ableton Live 11.0.12 Instrument Rack
  abletonRackTemplate: 'src/Key Suite Electric/templates/Key Suite Electric.adg.tpl'
  # Bitwig Studio 4.1.2 preset file
  bwpresetTemplate: 'src/Key Suite Electric/templates/Key Suite Electric.bwpreset'
  # bank/categories
  models: [
    # 1 Tines
    # ----------------------------
    {
      regexp: /^1 Tines\/EPiano Italian/
      bankchain: ['DAVOLI Pianoforti C77']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Japanese/
      bankchain: ['COLUMBIA Elepian EP-61C']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk I 1975/
      bankchain: ['Fender Rhodes Makr I', '1975']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk I 1978/
      bankchain: ['Fender Rhodes Makr I', '1978']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk I Dark Tone/
      bankchain: ['Fender Rhodes Mark I', 'Dark Tone']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk I Studio/
      bankchain: ['Fender Rhodes Mark I', 'Studio']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk II 54 Keys/
      bankchain: ['Rhodes Mark II', '54 Keys']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk II 73 Keys/
      bankchain: ['Rhodes Mark II', '73 Keys']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk II 88 Keys/
      bankchain: ['Rhodes Mark II', '88 Keys']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk III Broken/
      bankchain: ['Rhodes Mark III Broken']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk V/
      bankchain: ['Rhodes Mark V']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Mk VII/
      bankchain: ['Rhodes Mark VII']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Student Gold/
      bankchain: ['Rhodes Student', 'Gold']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^1 Tines\/EPiano Student Green/
      bankchain: ['Rhodes Student', 'Green']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }

    # 2 Reeds
    # ----------------------------
    {
      regexp: /^2 Reeds\/W 140B/
      bankchain: ['Wurlitzer 140B']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^2 Reeds\/W 145 Tubes/
      bankchain: ['Wurlitzer 145']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^2 Reeds\/W 200/
      bankchain: ['Wurlitzer 200', 'Typical']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^2 Reeds\/W 200 Studio/
      bankchain: ['Wurlitzer 200', 'Studio']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^2 Reeds\/W 270 Butterfly 1/
      bankchain: ['Wurlitzer 270', 'Exquisite Tone']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^2 Reeds\/W 270 Butterfly 2/
      bankchain: ['Wurlitzer 270', 'Dark Tone']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }

    # 3 Electric Pianos
    # ----------------------------
    {
      regexp: /^3 Electric Pianos\/CPiano 60M/
      bankchain: ['YAMAHA CP-60M']
      types: [
        ['Piano / Keys', 'Upright Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^3 Electric Pianos\/CPiano 70/
      bankchain: ['YAMAHA CP-70']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^3 Electric Pianos\/CPiano 80/
      bankchain: ['YAMAHA CP-80']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^3 Electric Pianos\/KPiano 300/
      bankchain: ['KAWAI EP-308']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^3 Electric Pianos\/KPiano 600/
      bankchain: ['KAWAI EP-608']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^3 Electric Pianos\/KPiano 700M/
      bankchain: ['KAWAI EP-705M']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^3 Electric Pianos\/Roadmaster 64/
      bankchain: ['HELPINSTILL Roadmaster 64']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }

    # 4 Clavs
    # ----------------------------
    {
      regexp: /^4 Clavs\/Clav Model C/
      bankchain: 'HOHNER Clavinet C'
      types: [
        ['Piano / Keys', 'Clavinet']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^4 Clavs\/Clav Model D6/
      bankchain: 'HOHNER Clavinet D6'
      types: [
        ['Piano / Keys', 'Clavinet']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^4 Clavs\/Clav Model E7/
      bankchain: 'HOHNER Clavinet E7'
      types: [
        ['Piano / Keys', 'Clavinet']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^4 Clavs\/Clav Model I/
      bankchain: 'HOHNER Clavinet 1'
      types: [
        ['Piano / Keys', 'Clavinet']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^4 Clavs\/Clav Model L 1/
      bankchain: 'HOHNER Clavinet L1'
      types: [
        ['Piano / Keys', 'Clavinet']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^4 Clavs\/Clav Model L 2/
      bankchain: 'HOHNER Clavinet L2'
      types: [
        ['Piano / Keys', 'Clavinet']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^4 Clavs\/Clav Model Viba/
      bankchain: 'Vintage Vibe Vibanet'
      types: [
        ['Piano / Keys', 'Clavinet']
      ]
      modes: ['Sample-based']
    }

    # 5 Electro-acoustic
    # ----------------------------
    {
      regexp: /^5 Electro-acoustic\/Cembalet/
      bankchain: 'HOHNER Cembalet'
      types: [
        ['Piano / Keys', 'Harpsichord']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Cembalino/
      bankchain: 'FARFISA Cembalino'
      types: [
        ['Piano / Keys', 'Harpsichord']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Claviset/
      bankchain: 'Weltmeister Claviset'
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Electra Piano 1/
      bankchain: ['HOHNER Electra Piano', 'Typical']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Electra Piano 2/
      bankchain: ['HOHNER Electra Piano', 'Driven']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Electra Piano T/
      bankchain: ['HOHNER Electra Piano', 'Stage']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Planet Clav Duo\/Pianet/
      bankchain: ['HOHNER Clavinet/Pianet Duo', 'Pianet']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Planet Clav Duo\/Planet Duo/
      bankchain: ['HOHNER Clavinet/Pianet Duo', 'Clavinet']
      types: [
        ['Piano / Keys', 'Clavinet']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Planet M/
      bankchain: ['HOHNER Pianet M']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Planet N/
      bankchain: ['HOHNER Pianet N']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^5 Electro-acoustic\/Sanza Keys/
      # TODO unknown maker/model
      bankchain: ['Sanza (Kalimba)']
      types: [
        ['Piano / Keys', 'Other Piano / Keys']
      ]
      modes: ['Sample-based']
    }

    # 6 Analog Keys
    # ----------------------------
    {
      regexp: /^6 Analog Keys\/Analog P16/
      bankchain: ['ARP 16-voice Electric Piano']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/AP-09/
      bankchain: ['Roland EP-09']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/AP-30/
      bankchain: ['Roland EP-30']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/CPiano 10/
      bankchain: ['YAMAHA CP-10']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/CPiano 30/
      bankchain: ['YAMAHA CP-30']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/CPiano 35/
      bankchain: ['YAMAHA CP-35']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/Custom 88/
      bankchain: ['Bladwin Kustom 88']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/InterContinental 7/
      bankchain: ['Viscount intercontinental Piano 7']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/RMI Keys\/RMI Piano/
      bankchain: ['RMI electra-piano 368X']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/RMI Keys\/RMI Harpsi/
      bankchain: ['RMI electra-piano 368X']
      types: [
        ['Piano / Keys', 'Harpsichord']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^6 Analog Keys\/RMI Keys\/RMI (?!Piano|Harpsi)/
      bankchain: ['RMI electra-piano 368X']
      types: [
        ['Piano / Keys', 'Other Piano / Keys']
      ]
      modes: ['Sample-based', 'Analog']
    }

    # 7 Bass
    # ----------------------------
    {
      regexp: /^7 Bass\/Combo Bass/
      # TODO unknown maker/model
      bankchain: ['Combo Bass']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^7 Bass\/El Toro/
      bankchain: ['moog Taurus']
      types: [
        ['Bass Synth']
      ]
      modes: ['Sample-based', 'Analog']
    }
    {
      regexp: /^7 Bass\/EPiano Bass 1965/
      bankchain: ['Rhodes Piano Bass', '1965']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^7 Bass\/EPiano Bass Custom/
      bankchain: ['Rhodes Piano Bass', 'Custom']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^7 Bass\/EPiano Bass Extended/
      bankchain: ['Rhodes Piano Bass', 'Extended']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^7 Bass\/EPiano Bass Gold/
      bankchain: ['Rhodes Piano Bass', 'Gold']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^7 Bass\/EPiano Bass Salmon/
      bankchain: ['Rhodes Piano Bass', 'Salmon']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
    {
      regexp: /^7 Bass\/K-Bass/
      bankchain: ['HOHNER Bass']
      types: [
        ['Piano / Keys', 'Electric Piano']
      ]
      modes: ['Sample-based']
    }
  ]

  # characters
  characters: [
    {regexp: /Dry/, mode: 'Dry'}
    {regexp: /Reverb/, mode: 'Reverb'}
    {regexp: /Chorused/, mode: 'Chorused'}
    {regexp: /Phase Dark/, mode: 'Phase Dark'}
    {regexp: /Rotary Wheel/, mode: 'Rotary Wheel'}
    {regexp: /Space Bells/, mode: 'Space Bells'}
    {regexp: /Tremopan/, mode: 'Tremopan'}
    {regexp: /Wha Wheel/, mode: 'Wha Wheel'}
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
      model = $.models.find (m) -> file.relative.match m.regexp
      unless model
        throw new Error "Undfined model for [#{file.relative}]"
      console.info file.relative, model
      characters = $.characters
        .filter (c) -> basename.match c.regexp
        .map (c) -> c.mode
      modes = model.modes.concat characters
      file.contents = Buffer.from util.beautify
        author: ''
        bankchain: [$.dir].concat model.bankchain
        comment: ''
        deviceType: 'INST'
        modes: model.modes.concat characters
        name: basename
        types: model.types
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
      # replace ProgramPath
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
