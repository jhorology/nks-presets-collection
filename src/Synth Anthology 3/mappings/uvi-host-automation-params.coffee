# UVI host automation parameters
#   - The number of parameters should be less or equal than 128.
#   - part 1 parameters only
#   - properties of element
#     - @section  section name for nks parameters
#     - @id       UVI host automation parameter id (part 1 paramaters only)
#     - @name     parameter name for nks
module.exports = [
  # OSC MAIN
  # {section: 'OSC MAIN',      id: 'VCO1OnOff',           name: 'On/Off'}
  {section: 'OSC MAIN',      id: 'VCO1Level',           name: 'VOL'}
  {section: 'OSC MAIN',      id: 'VCO1Pan',             name: 'PAN'}

  # OSC SUB
  {section: 'OSC SUB',       id: 'VCO2OnOff',           name: 'On/Off'}
  {section: 'OSC SUB',       id: 'OscBMenu',            name: 'W.FORM'}
  {section: 'OSC SUB',       id: 'VCO2PDMenu',           name: 'PD'}
  {section: 'OSC SUB',       id: 'VCO2PDAmount',         name: 'PD.AMT'}
  {section: 'OSC SUB',       id: 'VCO2Level',           name: 'VOL'}
  {section: 'OSC SUB',       id: 'VCO2Pan',             name: 'PAN'}  

  # MASTER
  {section: 'Part 1',        id: 'ProgramVolume',       name: 'VOL'}
  # MAIN Amp
  {section: 'MAIN Amp',      id: 'ampVelAmount1',       name: 'VELOCITY'}
  {section: 'MAIN Amp',      id: 'ampVelToAttack1',     name: 'VEL>ATK'}
  # SUB AMP
  {section: 'SUB Amp',       id: 'ampVelAmount2',       name: 'VELOCITY'}
  {section: 'SUB Amp',       id: 'ampVelToAttack2',     name: 'VEL>ATK'}

  # MAIN/SUB AMP Env
  {section: 'MAIN Amp Env',  id: 'ampAttack1',          name: 'A', newPage: on}
  {section: 'MAIN Amp Env',  id: 'ampDecay1',           name: 'D'}
  {section: 'MAIN Amp Env',  id: 'ampSustain1',         name: 'S'}
  {section: 'MAIN Amp Env',  id: 'ampRelease1',         name: 'R'}
  {section: 'SUB Amp Env',   id: 'ampAttack2',          name: 'A'}
  {section: 'SUB Amp Env',   id: 'ampDecay2',           name: 'D'}
  {section: 'SUB Amp Env',   id: 'ampSustain2',         name: 'S'}
  {section: 'SUB Amp Env',   id: 'ampRelease2',         name: 'R'}

  # MAIN FILTER
  # {section: 'MAIN Filter Mode', id: 'filterType1_1',       name: 'OFF'}
  # {section: 'MAIN Filter Mode', id: 'filterType2_1',       name: 'HI CUT'}
  # {section: 'MAIN Filter Mode', id: 'filterType3_1',       name: 'MID PASS'}
  # {section: 'MAIN Filter Mode', id: 'filterType4_1',       name: 'LO CUT'}
  {section: 'MAIN Filter',      id: 'filterCutoff1',       name: 'CUT'}
  {section: 'MAIN Filter',      id: 'filterReso1',         name: 'RES'}
  {section: 'MAIN Filter',      id: 'velToFilter1',        name: 'VEL'}
  {section: 'MAIN Filter',      id: 'filterEnvAmount1',    name: 'DEPTH'}

  # SUB FILTER
  # {section: 'SUB Filter Mode', id: 'filterType1_2',       name: 'OFF'}
  # {section: 'SUB Filter Mode', id: 'filterType2_2',       name: 'HI CUT'}
  # {section: 'SUB Filter Mode', id: 'filterType3_2',       name: 'MID PASS'}
  # {section: 'SUB Filter Mode', id: 'filterType4_2',       name: 'LO CUT'}
  {section: 'SUB Filter',      id: 'filterCutoff2',       name: 'CUT'}
  {section: 'SUB Filter',      id: 'filterReso2',         name: 'RES'}
  {section: 'SUB Filter',      id: 'velToFilter2',        name: 'VEL'}
  {section: 'SUB Filter',      id: 'filterEnvAmount2',    name: 'DEPTH'}

  # MAIN/SUB Filter Env
  {section: 'MAIN Filter Env', id: 'filterAttack1',       name: 'A'}
  {section: 'MAIN Filter Env', id: 'filterDecay1',        name: 'D'}
  {section: 'MAIN Filter Env', id: 'filterSustain1',      name: 'S'}
  {section: 'MAIN Filter Env', id: 'filterRelease1',      name: 'R'}
  {section: 'SUB Filter Env',  id: 'filterAttack2',       name: 'A'}
  {section: 'SUB Filter Env',  id: 'filterDecay2',        name: 'D'}
  {section: 'SUB Filter Env',  id: 'filterSustain2',      name: 'S'}
  {section: 'SUB Filter Env',  id: 'filterRelease2',      name: 'R'}

  # MAIN PITCH
  {section: 'MAIN Pitch',    id: 'layerMode1',          name: 'MONO', newPage: on}
  {section: 'MAIN Pitch',    id: 'octave1',             name: 'OCTAVE'}
  {section: 'MAIN Pitch',    id: 'tune1',               name: 'SEMI'}
  {section: 'MAIN Pitch',    id: 'PitchBendRange1',     name: 'BEND'}
  {section: 'MAIN Glide',    id: 'glideDepth1',         name: 'DEPTH'}
  {section: 'MAIN Glide',    id: 'glideTime1',          name: 'PITCH'}

  # SUB PITCH -->
  {section: 'SUB Pitch',     id: 'layerMode2',          name: 'MONO', newPage: on}
  {section: 'SUB Pitch',     id: 'octave2',             name: 'OCTAVE'}
  {section: 'SUB Pitch',     id: 'tune2',               name: 'SEMI'}
  {section: 'SUB Pitch',     id: 'PitchBendRange2',     name: 'BEND'}
  {section: 'SUB Glide',     id: 'glideDepth2',         name: 'DEPTH'}
  {section: 'SUB Glide',     id: 'glideTime2',          name: 'TIME'}

  # MAIN Stereo -->
  # {section: 'MAIN Stereo Mode', id: 'stereoMode1_1',       name: 'OFF', newPage: on}
  # {section: 'MAIN Stereo Mode', id: 'stereoMode2_1',       name: 'ALT'}
  # {section: 'MAIN Stereo Mode', id: 'stereoMode3_1',       name: 'UNI'}
  {section: 'MAIN Stereo',      id: 'panSpread1',          name: 'SPREAD'}
  {section: 'MAIN Stereo',      id: 'detune1',             name: 'DETUNE'}
  {section: 'MAIN Stereo',      id: 'toneShift1',          name: 'COLOR'}

  # SUB Stereo -->
  # {section: 'SUB Stereo Mode', id: 'stereoModeSelector1', name: 'OFF', newPage: on}
  # {section: 'SUB Stereo Mode', id: 'stereoModeSelector2', name: 'ALT'}
  {section: 'SUB Stereo',      id: 'panSpread2',          name: 'SPREAD'}
  {section: 'SUB Stereo',      id: 'detune2',             name: 'DETUNE'}
  {section: 'SUB Stereo',      id: 'unisonVoices2',       name: 'VOICES'}

  # MAIN Modwheel
  {section: 'MAIN Modwheel', id: 'wheelVibrato1',       name: 'VIBRATO', newPage: on}
  {section: 'MAIN Modwheel', id: 'vibratoRate1',        name: 'RATE'}
  {section: 'MAIN Modwheel', id: 'wheelTremolo1',       name: 'TREMOLO'}
  {section: 'MAIN Modwheel', id: 'tremoloRate1',        name: 'RATE'}
  {section: 'MAIN Modwheel', id: 'wheelFilter1',        name: 'FILTER'}
  {section: 'MAIN Modwheel', id: 'wheelFilterDepth1',   name: 'DEPTH'}
  {section: 'MAIN Modwheel', id: 'wheelDrive1',         name: 'DRIVE'}
  {section: 'MAIN Modwheel', id: 'wheelDriveDepth1',    name: 'AMOUNT'}



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
  {section: 'LFO Waveform',  id: 'LfoWaveform1',        name: 'SINE'}
  {section: 'LFO Waveform',  id: 'LfoWaveform2',        name: 'TRIANGLE'}
  {section: 'LFO Waveform',  id: 'LfoWaveform3',        name: 'SQUARE'}
  {section: 'LFO Waveform',  id: 'LfoWaveform4',        name: 'S/H'}

  {section: 'LFO Sync',      id: 'lfoSync',             name: 'On/Off', newPage: on}
  {section: 'LFO Sync',      id: 'LfoRetrigger1',       name: 'RETRIGGER'}
  {section: 'LFO Sync',      id: 'LfoRetrigger2',       name: 'NO RETRIGGER'}
  {section: 'LFO Sync',      id: 'LfoRetrigger3',       name: 'LEGATO'}

  # MAIN LFO
  {section: 'MAIN LFO',      id: 'volumeLfoDest1',      name: 'VOLUME'}
  {section: 'MAIN LFO',      id: 'volumeLfoDepth1',     name: 'AMOUNT'}
  {section: 'MAIN LFO',      id: 'filterLfoDest1',      name: 'FILTER'}
  {section: 'MAIN LFO',      id: 'filterLfoDepth1',     name: 'DEPTH'}
  {section: 'MAIN LFO',      id: 'pitchLfoDest1',       name: 'PITCH'}
  {section: 'MAIN LFO',      id: 'pitchLfoDepth1',      name: 'DEPTH'}
  {section: 'MAIN LFO',      id: 'panLfoDest1',         name: 'PAN'}
  {section: 'MAIN LFO',      id: 'panLfoDepth1',        name: 'AMOUNT'}

  # SUB LFO
  {section: 'SUB LFO',        id: 'volumeLfoDest2',     name: 'VOLUME'}
  {section: 'SUB LFO',        id: 'volumeLfoDepth2',    name: 'AMOUNT'}
  {section: 'SUB LFO',        id: 'filterLfoDest2',     name: 'FILTER'}
  {section: 'SUB LFO',        id: 'filterLfoDepth2',    name: 'DEPTH'}
  {section: 'SUB LFO',        id: 'pitchLfoDest2',      name: 'PITCH'}
  {section: 'SUB LFO',        id: 'pitchLfoDepth2',     name: 'DEPTH'}
  {section: 'SUB LFO',        id: 'panLfoDest2',        name: 'PAN'}
  {section: 'SUB LFO',        id: 'panLfoDepth2',       name: 'AMOUNT'}

  # FX BIT CRUSHER
  {section: 'FX BIT CRUSHER', id: 'ReduxOnOff',         name: 'On/Off'}
  {section: 'FX BIT CRUSHER', id: 'ReduxBits',          name: 'BIT'}
  {section: 'FX BIT CRUSHER', id: 'ReduxFreq',          name: 'FREQ'}
  {section: 'FX BIT CRUSHER', id: 'ReduxMix',           name: 'MIX'}

  # FX DRIVE
  {section: 'FX DRIVE',       id: 'DriveOnOff',         name: 'On/Off'}
  {section: 'FX DRIVE',       id: 'Drive',              name: 'AMOUNT'}

  # FX BIT EQUALIZER
  {section: 'FX EQUALIZER',   id: 'EQOnOff',            name: 'On/Off'}
  {section: 'FX EQUALIZER',   id: 'GainMid',            name: 'MID'}
  {section: 'FX EQUALIZER',   id: 'FreqMidHigh',        name: 'FREQ'}
  {section: 'FX EQUALIZER',   id: 'GainLow',            name: 'LO'}
  {section: 'FX EQUALIZER',   id: 'GainHigh',           name: 'High'}

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
