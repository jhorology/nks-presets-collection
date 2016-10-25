#
# buld environment & misc settings
#-------------------------------------------
module.exports =
  release: "#{process.env.HOME}/Dropbox/Share/NKS Presets"
  chunkVer: 1
  json_indent: 2
  # gulp-exec options
  execOpts:
    continueOnError: false # default = false, true means don't emit error event
    pipeStdout: false      # default = false, true means stdout is written to file.contents
  execReportOpts:
    err: true              # default = true, false means don't write err
    stderr: true           # default = true, false means don't write stderr
    stdout: true           # default = true, false means don't write stdout
  uuidRegexp: /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/
  
  #
  # Native Instruments
  #-------------------------------------------
  NI:
    userContent: "#{process.env.HOME}/Documents/Native Instruments/User Content"
    resources: '/Users/Shared/NI Resources'

  #
  # Ableton Live
  #-------------------------------------------
  Ableton:
    racks: "#{process.env.HOME}/Music/Ableton/User Library/Presets/Instruments/Instrument Rack"
    drumRacks: "#{process.env.HOME}/Music/Ableton/User Library/Presets/Instruments/Drum Rack"

  #
  # Bitwig Studio
  #-------------------------------------------
  Bitwig:
    presets: "#{process.env.HOME}/Documents/Bitwig Studio/Library/Presets"
    # regexp for finding fxb filename
    #   00000be5 indetifier
    #   08       type string
    #   00000028 size
    #   <uuid>
    #   2e667862  '.fxb'
    fxbHexRegexp: /(00000be50800000028)\w{16}2d\w{8}2d\w{8}2d\w{8}2d\w{24}(2e667862)/
