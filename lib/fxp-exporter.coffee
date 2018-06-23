data       = require 'gulp-data'
riffReader = require 'riff-reader'
_          = require 'underscore'
msgpack    = require 'msgpack-lite'

module.exports =
  #
  #  gulp plugin for .nksf to .fxp
  #  - numParams required
  # --------------------------------
  gulpNksf2Fxp: (numParams) ->
    _this = @
    data (file) ->
      nisi = nica = content = pluginId = undefined
      (riffReader file.contents or file.path, 'NIKS').readSync (id, chunk) ->
        switch id
          when 'NISI'
            nisi = (msgpack.decode chunk.slice 4)
          when 'NICA'
            nica = (msgpack.decode chunk.slice 4)
          when 'PCHK'
            content = chunk.slice 4
          when 'PLID'
            pluginId = (msgpack.decode chunk.slice 4)['VST.magic']
      , ['NISI', 'NICA', 'PLID', 'PCHK']
      file.contents = _this.createFxp pluginId, content, numParams
      # for general purpose, append NKS info to vinyl file 
      nksf:
        nisi: nisi
        nica: nica
  #
  #  create fxp
  #  - pluginId   required 4 characters String or int32
  #  - content    required Buffer
  #  - numParams  required Number integer value
  # --------------------------------
  # typedef struct fxProgram
  # {
  # //-------------------------------------------------------------------------------------------------------
  #   VstInt32 chunkMagic;    ///< 'CcnK'
  #   VstInt32 byteSize;      ///< size of this chunk, excl. magic + byteSize
  #
  #   VstInt32 fxMagic;       ///< 'FxCk' (regular) or 'FPCh' (opaque chunk)
  #   VstInt32 version;       ///< format version (currently 1)
  #   VstInt32 fxID;          ///< fx unique ID
  #   VstInt32 fxVersion;     ///< fx version
  #
  #   VstInt32 numParams;     ///< number of parameters
  #   char prgName[28];       ///< program name (null-terminated ASCII string)
  #
  #   union
  #   {
  #     float params[1];      ///< variable sized array with parameter values
  #     struct 
  #     {
  #       VstInt32 size;      ///< size of program data
  #       char chunk[1];      ///< variable sized array with opaque program data
  #     } data;               ///< program chunk data
  #   } content;              ///< program content depending on fxMagic
  # //-------------------------------------------------------------------------------------------------------
  # } fxProgram;
  createFxp: (pluginId, content, numParams) ->
    if _.isString pluginId
      pluginId = (Buffer.from pluginId).readUInt32BE(0)
    fxb = Buffer.alloc 60, 0
    offset = 0
    # 0x0000 chunkMagic
    fxb.write 'CcnK', offset
    offset += 4
    
    # 0x0004 byteSize
    fxb.writeUInt32BE (52 + content.length), offset
    offset += 4
    
    # 0x0008 fxMagic
    fxb.write 'FPCh', offset
    offset += 4
    
    # 0x000c version
    fxb.writeUInt32BE 1, offset
    offset += 4

    # 0x0010 fxID
    fxb.writeUInt32BE pluginId, offset
    offset += 4
    
    # 0x0014 fxVersion
    fxb.writeUInt32BE 1, offset
    offset += 4

    # 0x0018 numParams
    fxb.writeUInt32BE numParams, offset
    offset += 4

    # 0x001c prgName
    offset += 28

    # 0x0038 chunkSize
    fxb.writeUInt32BE content.length, offset
    # total 60 bytes
    
    Buffer.concat [fxb, content]
