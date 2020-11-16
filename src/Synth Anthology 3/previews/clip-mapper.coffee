log = (require 'bitwig-nks-preview-generator').logger 'custom-mapper'
module.exports = (soundInfo) ->
  type = soundInfo.types[0][0]
  octave = if type is 'Bass' then 2 else 3
  clip = switch
    when soundInfo.modes.includes 'Arpeggiated'
      'NKS-Preview-Cmaj-2BAR-ARP.bwclip'
    when soundInfo.modes.includes 'Sequence'
      "NKS-Preview-C#{octave}-2BAR-SEQ.bwclip"
    when ['Keyboards', 'Organs'].includes type
      'NKS-Preview-Cmaj-Chord.bwclip'
    else
      "NKS-Preview-C#{octave}-Single.bwclip"
  log.info 'NKS Info:', soundInfo, 'Clip:', clip
  clip
