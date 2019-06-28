_          = require 'underscore'
fs         = require 'fs'
uuid       = require 'uuid'
data       = require 'gulp-data'
tap        = require 'gulp-tap'
riffReader = require 'riff-reader'
msgpack    = require 'msgpack-lite'
yazl       = require 'yazl'
bl         = require 'bl'
rewrite    = require 'gulp-bitwig-rewrite-meta'

$ =
  uuidRegexp: /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/
  # regexp for finding fxb filename
  #   00000be5 indetifier
  #   08       type string
  #   00000028 size
  #   <uuid>
  #   2e667862  '.fxb'
  fxbHexRegexp: /(00000be50800000028)\w{16}2d\w{8}2d\w{8}2d\w{8}2d\w{24}(2e667862)/

# @templateFilePath required String
#    template file path
# --------------------------------
bwpresetExporter = (templateFilePath) ->
  new BwpresetExporter templateFilePath

class BwpresetExporter
  constructor: (templateFilePath) ->
    @template = templateFilePath

  # gulp phase 1 parse nksf
  # --------------------------------
  gulpParseNksf: ->
    data (nksf) ->
      obj = {}
      (riffReader nksf.contents or nksf.path, 'NIKS').readSync (id, chunk) ->
        switch id
          when 'NISI'
            obj.nisi = msgpack.decode chunk.slice 4
          when 'NICA'
            obj.nica = msgpack.decode chunk.slice 4
          when 'PLID'
            obj.plid = msgpack.decode chunk.slice 4
          when 'PCHK'
            obj.pluginState = chunk.slice 4
      , ['NISI', 'NICA', 'PLID', 'PCHK']
        # some NKS ready presets uses "UUID' insted of 'uuid' for propertyName
        # some NKS ready presets doesn't have uuid
      unless obj.nisi.uuid
        obj.nisi.uuid = obj.nisi.UUID
        unless obj.nisi.uuid
          console.warn "WARN: preset doesn't have uuid. file: #{nksf.path}"
          # create new uuid
          obj.nisi.uuid = uuid.v4()
      unless obj.nisi.uuid.match $.uuidRegexp
        console.warn "WARN: invalid uuid pattern. uuid:#{obj.nisi.uuid} file: #{nksf.path}"
        obj.nisi.uuid = uuid.v4()
      nksf: obj

  # gulp phase 2 read template
  # --------------------------------
  gulpReadTemplate: ->
    _this = @
    tap (file) ->
      # read template file
      bwpreset = fs.readFileSync _this.template
      # ziped fxb offset
      offset = parseInt (bwpreset.toString 'ascii', 0x00000024, 0x00000024 + 8), 16
      # remove zipped fxb part
      bwpreset = bwpreset.slice 0, offset
      file.contents = _replace_fxb_filename bwpreset, file.data.nksf.nisi.uuid
      
  # gulp phase 3 read template
  # --------------------------------
  gulpAppendPluginState: ->
    data (file, done) ->
      # append zipped fxb to file contents
      _build_zipped_fxb file.data.nksf.pluginState
      , file.data.nksf.plid['VST.magic']
      , file.data.nksf.nisi.uuid
      , (err, zippedFxb) ->
        throw new Error err if err
        file.contents = Buffer.concat [file.contents, zippedFxb]
        done undefined, file.data

  # gulp phase 4 reewrite metadata
  # @mapper function(metadata)
  #  NKSF metadata -> bwpreset metadata
  # --------------------------------
  gulpRewriteMetadata: (mapper) ->
    mapper ?= _default_meta_map
    rewrite (file, bwmeta) ->
      mapper file.data.nksf.nisi

# replace .fxb filename in
#   @buffer bwpreset template
#   @uid   uuid for .fxb filename
_replace_fxb_filename = (buffer, uid) ->
  # convert uuid string -> hex coded binary
  hexUuid = (Buffer.from uid.toLowerCase(), 'ascii').toString 'hex'
  # convert template buffer -> hex coded string
  hex = buffer.toString 'hex'
  # replace fxb filename
  hex = hex.replace $.fxbHexRegexp, "\$1#{hexUuid}\$2"
  # revert to binary buffer
  Buffer.from hex, 'hex'

# build bitwig zipped fxb
#  @pluginState buffer
#  @fxID       Vst magic
#  @uid
#  @done       callback function(err, buffer) to support async call
#    @buffer   zipped fxb
# //--------------------------------------------------------------------
# // For Bank (.fxb) with chunk (magic = 'FBCh')
# //--------------------------------------------------------------------
# struct fxChunkBank
# {
# 	long chunkMagic;		// 'CcnK'
# 	long byteSize;			// of this chunk, excl. magic + byteSize
#
# 	long fxMagic;			// 'FBCh'
# 	long version;
# 	long fxID;				// FX unique ID
# 	long fxVersion;
#
# 	long numPrograms;
# 	char future[128];
#
# 	long chunkSize;
# 	char chunk[8];			// variable
# }
_build_zipped_fxb = (pluginState, fxID, uid, done) ->
  fxb = Buffer.alloc 160, 0
  offset = 0
  # fxMagic
  fxb.write 'CcnK', offset
  offset += 4
  # byteSize
  fxb.writeUInt32BE (152 + pluginState.length), offset
  offset += 4
  # fxMagic
  fxb.write 'FBCh', offset
  offset += 4
  # version
  fxb.writeUInt32BE 2, offset
  offset += 4
  # fxID
  fxb.writeUInt32BE fxID, offset
  offset += 4
  # fxVersion
  fxb.writeUInt32BE 1, offset
  offset += 4
  # numPrograms
  fxb.writeUInt32BE 1, offset
  offset += 4
  # future
  offset += 128
  # chunkSize
  fxb.writeUInt32BE pluginState.length, offset
  # concat header + plugin state
  fxb = Buffer.concat [fxb, pluginState]
  # compress zip
  zip = new yazl.ZipFile()
  zip.addBuffer fxb, "plugin-states/#{uid}.fxb"

  # async function
  zip.end (finalSize) -> zip.outputStream.pipe bl done


# default metadata map
#   map nks metadat -> bitwig metadata
#   @nks  metadata of .nksf file
_default_meta_map = (nisi) ->
  # util.beautify nks, on
  bitwig =
    name: nisi.name
    comment: nisi.comment
    creator: nisi.author
    preset_category: if nisi.types and nisi.types.length then nisi.types[0][0]
  tags = []
  if nisi.modes and nisi.modes.length
    tags = tags.concat nisi.modes
  if nisi.types and nisi.types.length
    for t in nisi.types
      tags.push t[1] if t.length > 1
  tags.push nisi.bankchain[1] if nisi.bankchain and nisi.bankchain.length > 1
  bitwig.tags = _.uniq ((tags.filter (t) -> t).map (t) ->((t.replace /\s([\/&])\s/, '$1').replace /\s/g, '_').toLowerCase())
  # delete undefined properties
  for key in Object.keys(bitwig)
    unless bitwig[key]
      delete bitwig[key]
  # return metadat for rewriting
  bitwig

bwpresetExporter.defaultMetaMapper = _default_meta_map
module.exports = bwpresetExporter
