tap        = require 'gulp-tap'
riffReader = require 'riff-reader'
_          = require 'underscore'
msgpack    = require 'msgpack-lite'

module.exports =
  #
  #  gulp plugin for .nksf to .fxb
  #  - pluginName optional String default = bankchanin[0]
  #  - isAudioFX  optional boolean default = off
  # --------------------------------
  gulpNksf2Fxb: () ->
    _this = @
    tap (file) ->
      pchk = pluginId = undefined
      (riffReader file.contents or file.path, 'NIKS').readSync (id, chunk) ->
        switch id
          when 'PCHK'
            pchk = chunk.slice 4
          when 'PLID'
            pluginId = (msgpack.decode chunk.slice 4)['VST.magic']
      , ['PLID', 'PCHK']
      file.contents = _this.createFxb pluginId, pchk

  #
  #  gulp plugin for PCHK chunk file to .fxb
  #  - pluginId   required 4 characters String or int32
  # --------------------------------
  gulpPchk2Fxb: (pluginId) ->
    _this = @
    tap (file) ->
      pchk = if file.contents
        file.contents.slice 4
      else
        (fs.readFileSync file.path).slice 4
      file.contents = createFxb pluginId, pchk

  #
  #  create fxb
  #  - pluginId   required 4 characters String or int32
  #  - chunk      required Buffer of plugin-states 
  # --------------------------------
  # struct fxBank
  # {
  # //-------------------------------------------------------------------------------------------------------
  #   VstInt32 chunkMagic;    ///< 'CcnK'
  #   VstInt32 byteSize;      ///< size of this chunk, excl. magic + byteSize
  #
  #   VstInt32 fxMagic;       ///< 'FxBk' (regular) or 'FBCh' (opaque chunk)
  #   VstInt32 version;       ///< format version (1 or 2)
  #   VstInt32 fxID;          ///< fx unique ID
  #   VstInt32 fxVersion;     ///< fx version
  #
  #   VstInt32 numPrograms;   ///< number of programs
  #
  # #if VST_2_4_EXTENSIONS
  #   VstInt32 currentProgram; ///< version 2: current program number
  #   char future[124];        ///< reserved, should be zero
  # #else
  #   char future[128];        ///< reserved, should be zero
  # #endif
  #
  #   union
  #   {
  #     fxProgram programs[1]; ///< variable number of programs
  #     struct
  #     {
  #       VstInt32 size;       ///< size of bank data
  #       char chunk[1];       ///< variable sized array with opaque bank data
  #     } data;                ///< bank chunk data
  #   } content;               ///< bank content depending on fxMagic
  # //-------------------------------------------------------------------------------------------------------
  # };
  createFxb: (pluginId, chunk, version = 2) ->
    if _.isString pluginId
      pluginId = (Buffer.from pluginId).readUInt32BE(0)
    fxb = Buffer.alloc 160, 0
    offset = 0
    # fxMagic
    fxb.write 'CcnK', offset
    offset += 4 # total 4 bytes

    # byteSize
    fxb.writeUInt32BE (152 + chumk.length), offset
    offset += 4 # total 8 bytes

    # fxMagic
    fxb.write 'FBCh', offset
    offset += 4 # total 12(0x0a) bytes

    # version
    fxb.writeUInt32BE version, offset
    offset += 4 # total 16(0x10) bytes

    # fxID
    fxb.writeUInt32BE fxID, offset
    offset += 4 # total 20(0x14) bytes

    # fxVersion
    fxb.writeUInt32BE 1, offset
    offset += 4 # total 24(0x18) bytes

    # numPrograms
    fxb.writeUInt32BE 1, offset
    offset += 4 # total 28(0x1C) bytes
    
    # future
    offset += 128
    offset += 4 # total 156(0x9c) bytes

    # chunkSize
    fxb.writeUInt32BE chunk.length, offset
    Buffer.concat [fxb, chunk]
