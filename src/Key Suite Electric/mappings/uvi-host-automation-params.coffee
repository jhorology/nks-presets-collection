# UVI host automation parameters
#   - The number of parameters should be less or equal than 128.
#   - part 1 parameters only
#   - properties of element
#     - @section  section name for nks parameters
#     - @id       UVI host automation parameter id (part 1 paramaters only)
#     - @name     parameter name for nks
module.exports = [
  # Mic
  {section: 'Mic 1',         id: 'MicOnOff1',           name: 'On/Off', newPage: on}
  {section: 'Mic 1',         id: 'MicVolume1',          name: 'Volume'}
  {section: 'Mic 2',         id: 'MicOnOff2',           name: 'On/Off'}
  {section: 'Mic 2',         id: 'MicVolume2',          name: 'Volume'}
  {section: 'Mic 3',         id: 'MicOnOff3',           name: 'On/Off'}
  {section: 'Mic 3',         id: 'MicVolume3',          name: 'Volume'}
  {section: 'Velocity',      id: 'MIDICurve',           name: 'Curve'}
  {section: 'Poly',          id: 'LayerPolyphony',      name: 'Voices'}

  # Output
  {section: 'Output',        id: 'SustainVolume',        name: 'Sus', newPage: on}
  {section: 'Output',        id: 'ReleaseVolume',        name: 'Rel'}
  {section: 'Output',        id: 'SympatheticVolume',    name: 'Symp'}
  {section: 'Output',        id: 'PedalVolume',          name: 'Pedal'}
  {section: 'Page',          id: 'pageSwitches1',        name: 'Home'}
  {section: 'Page',          id: 'pageSwitches2',        name: 'Edit'}
  {section: 'Page',          id: 'pageSwitches3',        name: 'FX'}

  # Filter
  {section: 'Filter',        id: 'FilterOnOff',          name: 'On/Off'}
  {section: 'Filter',        id: 'FilterType',           name: 'Type'}
  {section: 'Filter',        id: 'Cutoff',               name: 'Cutoff'}
  {section: 'Filter',        id: 'FilterReso',           name: 'Reso'}

  # Tone
  {section: 'Tone',          id: 'toneShift',           name: 'Color'}

  # Pitch
  {section: 'Pitch',         id: 'Mono',                name: 'Mono'}
  {section: 'Pitch',         id: 'PitchEnvTime',        name: 'Time'}
  {section: 'Pitch',         id: 'PitchEnvAmount',      name: 'Depth'}
 
  # Amp Env
  {section: 'Amp Env',       id: 'ampAttack',           name: 'A', newPage: on}
  {section: 'Amp Env',       id: 'ampDecay',            name: 'D'}
  {section: 'Amp Env',       id: 'ampSustain',          name: 'S'}
  {section: 'Amp Env',       id: 'ampRelease',          name: 'R'}
  {section: 'Amp Env',       id: 'ampVelAmount',        name: 'Velocity'}
  {section: 'Amp Env',       id: 'AmpVelToAttack',      name: 'Vel->Attack'}

  # Filter Env
  {section: 'Filter Env',    id: 'filterAttack',        name: 'A', newPage: on}
  {section: 'Filter Env',    id: 'filterDecay',         name: 'D'}
  {section: 'Filter Env',    id: 'filterSustain',       name: 'S'}
  {section: 'Filter Env',    id: 'filterRelease',       name: 'R'}
  {section: 'Filter Env',    id: 'FilterEnvAmount',     name: 'Depth'}
  {section: 'Filter Env',    id: 'VelToFilter',         name: 'Velocity'}

  # Modwheel
  {section: 'Modwheel',      id: 'TremoloOnOff',        name: 'Tremolo'}
  {section: 'Modwheel',      id: 'TremoloRate',         name: 'Rate'}
  {section: 'Modwheel',      id: 'VibratoOnOff',        name: 'Vibrato'}
  {section: 'Modwheel',      id: 'VibratoRate',         name: 'Rate'}
  {section: 'Modwheel',      id: 'WheelFilterOnOff',    name: 'Filter'}
  {section: 'Modwheel',      id: 'WheelFilterDepth',    name: 'Amount'}

  # U7 Convolver
  {section: 'Convolver',     id: 'ConvolverOnOff',      name: 'On/Off'}
  {section: 'Convolver',     id: 'ConvolverMix',        name: 'Mix'}
  {section: 'Convolver',     id: 'ConvolverMenu',       name: 'Menu'}

  # EQ3 Drive
  {section: 'Drive',         id: 'DriveOnOff',          name: 'On/Off'}
  {section: 'Drive',         id: 'DriveTone',           name: 'Tone'}
  {section: 'Drive',         id: 'Drive',               name: 'Drive'}

  # EQ3 Equalizer
  {section: 'Equalizer',    id: 'EQOnOff',              name: 'On/Off'}
  {section: 'Equalizer',    id: 'GainLow',              name: 'L Gain'}
  {section: 'Equalizer',    id: 'FreqLowMid',           name: 'L->|<-M'}
  {section: 'Equalizer',    id: 'GainMid',              name: 'M Gain'}
  {section: 'Equalizer',    id: 'FreqMidHigh',          name: 'M->|<-H'}
  {section: 'Equalizer',    id: 'GainHigh',             name: 'H Gain'}

  # Modulator
  {section: 'Modulator',    id: 'ModulationOnOff',      name: 'On/Off'}
  {section: 'Modulator',    id: 'ModulationMod',        name: 'Mode'}

  # Modulator Phasor
  {section: 'Phasor',       id: 'PhasorSpeed',          name: 'Speed'}
  {section: 'Phasor',       id: 'PhasorEdge',           name: 'Feedback'}
  {section: 'Phasor',       id: 'PhasorDepth',          name: 'Depth'}

  # Modulator Chorus
  {section: 'Chorus',       id: 'ThorusSpeed',          name: 'Speed'}
  {section: 'Chorus',       id: 'ThorusDepth',          name: 'Depth'}
  {section: 'Chorus',       id: 'ThorusMix',            name: 'Mix'}

  # Modulator Flanger
  {section: 'Flanger',      id: 'FlangerSpeed',         name: 'Speed'}
  {section: 'Flanger',      id: 'FlangerDepth',         name: 'Depth'}
  {section: 'Flanger',      id: 'FlangerFeedback',      name: 'Feedback'}

  # Modulator Rotary
  {section: 'Rotary',       id: 'RotaryDistance',       name: 'Distance'}
  {section: 'Rotary',       id: 'RotaryHornVol',        name: 'Horn Vol'}
  {section: 'Rotary',       id: 'RotaryDrumVol',        name: 'Drum Vol'}

  # Delay
  {section: 'Delay',        id: 'DelayOnOff',           name: 'On/Off', newPage: on}
  {section: 'Delay',        id: 'DelayTime',            name: 'Rate'}
  {section: 'Delay',        id: 'DelayFeedback',        name: 'Feedback'}
  {section: 'Delay',        id: 'DelayMix',             name: 'Mix'}
  {section: 'Delay',        id: 'DelayHighCut',         name: 'LPF'}
  {section: 'Delay',        id: 'DelayLowCut',          name: 'HPF'}

  # Reverb
  {section: 'Reverb',       id: 'SparkVerbOnOff',       name: 'On/Off', newPage: on}
  {section: 'Reverb',       id: 'SparkVerbMix',         name: 'Mix'}
  {section: 'Reverb',       id: 'SparkVerbSize',        name: 'Size'}
  {section: 'Reverb',       id: 'SparkleLoDecay',       name: 'Low'}
  {section: 'Reverb',       id: 'SparkVerbDecay',       name: 'Decay'}
  {section: 'Reverb',       id: 'SparkleHiDecay',       name: 'Hi'}
]
