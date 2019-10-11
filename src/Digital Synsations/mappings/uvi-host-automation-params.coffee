# UVI host automation parameters
#   - The number of parameters should be less or equal than 128.
#   - part 1 parameters only
#   - properties of element
#     - @section  section name for nks parameters
#     - @id       UVI host automation parameter id (part 1 paramaters only)
#     - @name     parameter name for nks
module.exports = [
  # Amp Env
  {section: 'AMPLITUDE',   id: 'ampAttack',           name: 'A'}
  {section: 'AMPLITUDE',   id: 'ampDecay',            name: 'D'}
  {section: 'AMPLITUDE',   id: 'ampSustain',          name: 'S'}
  {section: 'AMPLITUDE',   id: 'ampRelease',          name: 'R'}
  {section: 'AMPLITUDE',   id: 'AmpVelToAttack',      name: 'VEL>ATK'}
  {section: 'AMPLITUDE',   id: 'ampVelAmount',        name: 'VEL'}
  
  # Filter Type
  {section: 'FILTER',      id: 'FilterType1',         name: 'HP', newPage: on}
  {section: 'FILTER',      id: 'FilterType2',         name: 'BP'}
  {section: 'FILTER',      id: 'FilterType3',         name: 'LP'}
  {section: 'FILTER',      id: 'filterAttack',        name: 'A'}
  {section: 'FILTER',      id: 'filterDecay',         name: 'D'}
  {section: 'FILTER',      id: 'filterSustain',       name: 'S'}
  {section: 'FILTER',      id: 'filterRelease',       name: 'R'}
  
  {section: 'FILTER',      id: 'Cutoff',              name: 'CUTOFF', newPage: on}
  {section: 'FILTER',      id: 'FilterReso',          name: 'RES'}
  {section: 'FILTER',      id: 'FilterEnvAmount',     name: 'ENVELOPE'}
  {section: 'FILTER',      id: 'velToFilter',         name: 'VEL'}

  # Pitch
  {section: 'PITCH',       id: 'PitchEnvAmount',      name: 'DEPTH'}
  {section: 'PITCH',       id: 'PitchEnvTime',        name: 'TIME'}
  # VOICES
  {section: 'VOICES',      id: 'LayerModes1',         name: 'MONO'}
  {section: 'VOICES',      id: 'LayerModes2',         name: 'POLY'}

  # DRIVE
  {section: 'DRIVE',       id: 'DriveOnOff',          name: 'POWER', newPage: on}
  {section: 'DRIVE',       id: 'DriveAmount',         name: 'AMT'}

  # STEREO
  {section: 'STEREO',      id: 'StereoType1',         name: 'OFF'}
  {section: 'STEREO',      id: 'StereoType2',         name: 'ALT'}
  {section: 'STEREO',      id: 'StereoType3',         name: 'UNI'}
  {section: 'STEREO',      id: 'toneShift',           name: 'COLOR'}
  {section: 'STEREO',      id: 'panSpread',           name: 'WIDTH'}
  {section: 'STEREO',      id: 'detune',              name: 'TUNE'}

  # BITCRUSHER
  {section: 'BITCRUSHER',  id: 'bitCrusherOnOff',     name: 'POWER', newPage: on}
  {section: 'BITCRUSHER',  id: 'bitCrusherBitSize',   name: 'BIT'}
  {section: 'BITCRUSHER',  id: 'bitCrusherFreq',      name: 'FREQ'}
  {section: 'BITCRUSHER',  id: 'bitCrusherDrive',     name: 'DRIVE'}
  
  # EFFECTS
  {section: 'EFFECTS',     id: 'phaserOnOff',         name: 'PHASER', newPage: on}
  {section: 'EFFECTS',     id: 'phaserAmount',        name: 'MIX'}
  {section: 'EFFECTS',     id: 'delayOnOff',          name: 'DELAY'}
  {section: 'EFFECTS',     id: 'delayAmount',         name: 'MIX'}
  {section: 'EFFECTS',     id: 'sparkleOnOff',        name: 'REVERB'}
  {section: 'EFFECTS',     id: 'sparkleAmount',       name: 'MIX'}

  # MODWHEEL
  {section: 'MODWHEEL',    id: 'VibratoOnOff',        name: 'VIBRATO', newPage: on}
  {section: 'MODWHEEL',    id: 'VibratoRate',         name: 'RATE'}
  {section: 'MODWHEEL',    id: 'TremoloOnOff',        name: 'TREM'}
  {section: 'MODWHEEL',    id: 'TremoloRate',         name: 'RATE'}
  {section: 'MODWHEEL',    id: 'WheelFilterOnOff',    name: 'FILTER'}
  {section: 'MODWHEEL',    id: 'WheelFilterDepth',    name: 'DEPTH'}
]
