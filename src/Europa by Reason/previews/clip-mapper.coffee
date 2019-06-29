log = (require 'bitwig-nks-preview-generator').logger 'custom-mapper'
###
  NKS Preview MIDI clip mapper for Europa
  
  @param {Object} soundInfo - NKS Sound Info (metadata).
  @return {String} - Bitwig Studio MIDI clip file path.
###
module.exports = (soundInfo) ->
  clip = switch
    when soundInfo.types[0][0] is 'Bass'
      #return absolute path or relative path from this .js file's directory.
      'NKS-Preview-C2-Single.bwclip'
    else
      'NKS-Preview-C3-Single.bwclip'
  log.info 'NKS Info:', soundInfo, 'Clip:', clip
  clip
