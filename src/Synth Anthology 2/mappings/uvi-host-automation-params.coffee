# UVI host automation parameters
#   - The number of parameters should be less or equal than 128.
#   - part 1 parameters only
#   - properties of element
#     - @section  section name for nks parameters
#     - @id       UVI host automation parameter id (part 1 paramaters only)
#     - @name     parameter name for nks
module.exports = [
  # OSC MAIN
  {section: 'OSC MAIN',      id: 'VCO1OnOff',           name: 'On/Off'}
  {section: 'OSC MAIN',      id: 'VCO1Level',           name: 'VOL'}
  {section: 'OSC MAIN',      id: 'VCO1Pan',             name: 'PAN'}

  # OSC SUB
  {section: 'OSC SUB',       id: 'VCO2OnOff',           name: 'On/Off'}
  {section: 'OSC SUB',       id: 'VCO2Level',           name: 'VOL'}
  {section: 'OSC SUB',       id: 'VCO2Pan',             name: 'PAN'}  

  # MASTER
  {section: 'PART',          id: 'ProgramVolume',       name: 'VOL'}

  # MAIN AMP
  {section: 'MAIN AMP',      id: 'ampVelAmount1',       name: 'VELOCITY'}
  {section: 'MAIN AMP',      id: 'ampVelToAttack1',     name: 'VEL>ATK'}
  {section: 'MAIN AMP',      id: 'ampAttack1',          name: 'A'}
  {section: 'MAIN AMP',      id: 'ampDecay1',           name: 'D'}
  {section: 'MAIN AMP',      id: 'ampSustain1',         name: 'S'}
  {section: 'MAIN AMP',      id: 'ampRelease1',         name: 'R'}

  # MAIN FILTER
  {section: 'MAIN FILTER',   id: 'filterType1_1',       name: 'OFF'}
  {section: 'MAIN FILTER',   id: 'filterType2_1',       name: 'HI CUT'}
  {section: 'MAIN FILTER',   id: 'filterType3_1',       name: 'MID PASS'}
  {section: 'MAIN FILTER',   id: 'filterType4_1',       name: 'LO CUT'}
  {section: 'MAIN FILTER',   id: 'filterAttack1',       name: 'A'}
  {section: 'MAIN FILTER',   id: 'filterDecay1',        name: 'D'}
  {section: 'MAIN FILTER',   id: 'filterSustain1',      name: 'S'}
  {section: 'MAIN FILTER',   id: 'filterRelease1',      name: 'R'}
  {section: 'MAIN FILTER',   id: 'filterCutoff1',       name: 'CUT'}
  {section: 'MAIN FILTER',   id: 'filterReso1',         name: 'RES'}
  {section: 'MAIN FILTER',   id: 'velToFilter1',        name: 'VEL'}
  {section: 'MAIN FILTER',   id: 'filterEnvAmount1',    name: 'DEPTH'}

  # SUB AMP
  {section: 'SUB AMP',       id: 'ampVelAmount2',       name: 'VELOCITY', newPage: on}
  {section: 'SUB AMP',       id: 'ampVelToAttack2',     name: 'VEL>ATK'}
  {section: 'SUB AMP',       id: 'ampAttack2',          name: 'A'}
  {section: 'SUB AMP',       id: 'ampDecay2',           name: 'D'}
  {section: 'SUB AMP',       id: 'ampSustain2',         name: 'S'}
  {section: 'SUB AMP',       id: 'ampRelease2',         name: 'R'}

  # SUB FILTER
  {section: 'MAIN FILTER',   id: 'filterType1_2',       name: 'OFF'}
  {section: 'MAIN FILTER',   id: 'filterType2_2',       name: 'HI CUT'}
  {section: 'MAIN FILTER',   id: 'filterType3_2',       name: 'MID PASS'}
  {section: 'MAIN FILTER',   id: 'filterType4_2',       name: 'LO CUT'}
  {section: 'SUB FILTER',    id: 'filterAttack2',       name: 'A'}
  {section: 'SUB FILTER',    id: 'filterDecay2',        name: 'D'}
  {section: 'SUB FILTER',    id: 'filterSustain2',      name: 'S'}
  {section: 'SUB FILTER',    id: 'filterRelease2',      name: 'R'}
  {section: 'SUB FILTER',    id: 'filterCutoff2',       name: 'CUT'}
  {section: 'SUB FILTER',    id: 'filterReso2',         name: 'RES'}
  {section: 'SUB FILTER',    id: 'velToFilter2',        name: 'VEL'}
  {section: 'SUB FILTER',    id: 'filterEnvAmount2',    name: 'DEPTH'}

  # MAIN PITCH
  {section: 'MAIN PITCH',    id: 'layerMode1',          name: 'MONO',   newPage: on}
  {section: 'MAIN PITCH',    id: 'octave1',             name: 'OCTAVE'}
  {section: 'MAIN PITCH',    id: 'tune1',               name: 'SEMI'}
  {section: 'MAIN GLIDE',    id: 'glideDepth1',         name: 'DEPTH'}
  {section: 'MAIN GLIDE',    id: 'glideTime1',          name: 'PITCH'}

  # MAIN Stereo -->
  {section: 'MAIN Stereo',   id: 'stereoMode1_1',       name: 'OFF',   newPage: on}
  {section: 'MAIN Stereo',   id: 'stereoMode2_1',       name: 'ALT'}
  {section: 'MAIN Stereo',   id: 'stereoMode3_1',       name: 'UNI'}
  {section: 'MAIN Stereo',   id: 'panSpread1',          name: 'SPREAD'}
  {section: 'MAIN Stereo',   id: 'detune1',             name: 'DETUNE'}
  {section: 'MAIN Stereo',   id: 'toneShift1',          name: 'COLOR'}

  # MAIN Modwheel
  {section: 'MAIN Modwheel', id: 'wheelVibrato1',       name: 'VIBRATO', newPage: on}
  {section: 'MAIN Modwheel', id: 'vibratoRate1',        name: 'RATE'}
  {section: 'MAIN Modwheel', id: 'wheelTremolo1',       name: 'TREMOLO'}
  {section: 'MAIN Modwheel', id: 'tremoloRate1',        name: 'RATE'}
  {section: 'MAIN Modwheel', id: 'wheelFilter1',        name: 'FILTER'}
  {section: 'MAIN Modwheel', id: 'wheelFilterDepth1',   name: 'DEPTH'}
  {section: 'MAIN Modwheel', id: 'wheelDrive1',         name: 'DRIVE'}
  {section: 'MAIN Modwheel', id: 'wheelDriveDepth1',    name: 'AMOUNT'}

  # SUB PITCH -->
  {section: 'SUB PITCH',     id: 'layerMode2',          name: 'MONO', newPage: on}
  {section: 'SUB PITCH',     id: 'octave2',             name: 'OCTAVE'}
  {section: 'SUB PITCH',     id: 'tune2',               name: 'SEMI'}
  {section: 'SUB GLIDE',     id: 'glideDepth2',         name: 'DEPTH'}
  {section: 'SUB GLIDE',     id: 'glideTime2',          name: 'TIME'}

  # SUB Stereo -->
  {section: 'SUB Stereo',    id: 'stereoModeSelector1', name: 'OFF', newPage: on}
  {section: 'SUB Stereo',    id: 'stereoModeSelector2', name: 'ALT'}
  {section: 'SUB Stereo',    id: 'panSpread2',          name: 'SPREAD'}
  {section: 'SUB Stereo',    id: 'detune2',             name: 'DETUNE'}
  {section: 'SUB Stereo',    id: 'unisonVoices2',       name: 'VOICES'}

  # SUB Modwheel -->
  {section: 'SUB Modwheel',  id: 'wheelVibrato2',       name: 'VIBRATO', newPage: on}
  {section: 'SUB Modwheel',  id: 'vibratoRate2',        name: 'RATE'}
  {section: 'SUB Modwheel',  id: 'wheelTremolo2',       name: 'TREMOLO'}
  {section: 'SUB Modwheel',  id: 'tremoloRate2',        name: 'RATE'}
  {section: 'SUB Modwheel',  id: 'wheelFilter2',        name: 'FILTER'}
  {section: 'SUB Modwheel',  id: 'wheelFilterDepth2',   name: 'DEPTH'}
  {section: 'SUB Modwheel',  id: 'pwmWheelDest2',       name: 'PWM'}
  {section: 'SUB Modwheel',  id: 'pwmWheelDepth2',      name: 'AMOUNT'}

  # LFO
  {section: 'LFO',           id: 'lfoSpeed',            name: 'SPEED', newPage: on}
  {section: 'LFO',           id: 'lfoSync',             name: 'SYNC'}
  {section: 'LFO',           id: 'LfoRetrigger1',       name: 'RETRIGGER'}
  {section: 'LFO',           id: 'LfoRetrigger2',       name: 'NO RETRIGGER'}
  {section: 'LFO',           id: 'LfoRetrigger3',       name: 'LEGATO'}

  # MAIN LFO
  {section: 'MAIN LFO',      id: 'volumeLfoDest1',      name: 'VOLUME', newPage: on}
  {section: 'MAIN LFO',      id: 'volumeLfoDepth1',     name: 'AMOUNT'}
  {section: 'MAIN LFO',      id: 'filterLfoDest1',      name: 'FILTER'}
  {section: 'MAIN LFO',      id: 'filterLfoDepth1',     name: 'DEPTH'}
  {section: 'MAIN LFO',      id: 'pitchLfoDest1',       name: 'PITCH'}
  {section: 'MAIN LFO',      id: 'pitchLfoDepth1',      name: 'DEPTH'}
  {section: 'MAIN LFO',      id: 'panLfoDest1',         name: 'PAN'}
  {section: 'MAIN LFO',      id: 'panLfoDepth1',        name: 'AMOUNT'}

  # SUB LFO
  {section: 'SUB LFO',        id: 'volumeLfoDest2',     name: 'VOLUME', newPage: on}
  {section: 'SUB LFO',        id: 'volumeLfoDepth2',    name: 'AMOUNT'}
  {section: 'SUB LFO',        id: 'filterLfoDest2',     name: 'FILTER'}
  {section: 'SUB LFO',        id: 'filterLfoDepth2',    name: 'DEPTH'}
  {section: 'SUB LFO',        id: 'pitchLfoDest2',      name: 'PITCH'}
  {section: 'SUB LFO',        id: 'pitchLfoDepth2',     name: 'DEPTH'}
  {section: 'SUB LFO',        id: 'panLfoDest2',        name: 'PAN'}
  {section: 'SUB LFO',        id: 'panLfoDepth2',       name: 'AMOUNT'}

  # FX BIT CRUSHER -->
  {section: 'FX BIT CRUSHER', id: 'ReduxOnOff',         name: 'On/Off'}
  {section: 'FX BIT CRUSHER', id: 'ReduxBits',          name: 'BIT'}
  {section: 'FX BIT CRUSHER', id: 'ReduxFreq',          name: 'FREQ'}
  {section: 'FX BIT CRUSHER', id: 'ReduxMix',           name: 'MIX'}

  # FX DRIVE
  {section: 'FX DRIVE',       id: 'DriveOnOff',         name: 'ON/OFF'}
  {section: 'FX DRIVE',       id: 'Drive',              name: 'AMOUNT'}

  # FX THORUS
  {section: 'FX THORUS',      id: 'ThorusOnOff',        name: 'On/Off'}
  {section: 'FX THORUS',      id: 'ThorusSpeed',        name: 'SPEED'}
  {section: 'FX THORUS',      id: 'ThorusDepth',        name: 'DEPTH'}

  # FX PHASOR
  {section: 'FX PHASOR',      id: 'PhasorOnOff',        name: 'On/Off'}
  {section: 'FX PHASOR',      id: 'PhasorSpeed',        name: 'SPEED'}
  {section: 'FX PHASOR',      id: 'PhasorEdge',         name: 'EDGE'}
  {section: 'FX PHASOR',      id: 'PhasorDepth',        name: 'DEPTH'}

  # FX SPARKVERB
  {section: 'FX SPARKVERB',   id: 'SparkleOnOff',       name: 'On/Off'}
  {section: 'FX SPARKVERB',   id: 'SparkleDecay',       name: 'DECAY'}
  {section: 'FX SPARKVERB',   id: 'SparkleLoDecay',     name: 'LO DECAY'}
  {section: 'FX SPARKVERB',   id: 'SparkleHiDecay',     name: 'HI DECAY'}
  {section: 'FX SPARKVERB',   id: 'SparkleSize',        name: 'SIZE'}
  {section: 'FX SPARKVERB',   id: 'SparkleMix',         name: 'MIX'}

  # FX DELAY
  {section: 'FX DELAY',       id: 'DelayOnOff',         name: 'On/Off'}
  {section: 'FX DELAY',       id: 'DelayTime',          name: 'TIME'}
  {section: 'FX DELAY',       id: 'DelayLowCut',        name: 'LOW CUT'}
  {section: 'FX DELAY',       id: 'DelayHighCut',       name: 'HIGH CUT'}
  {section: 'FX DELAY',       id: 'DelayFeedback',      name: 'FDBK'}
  {section: 'FX DELAY',       id: 'DelayMix',           name: 'MIX'}
]
