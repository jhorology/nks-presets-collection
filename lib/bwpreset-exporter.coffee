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
  headers: [
    {
       regexp: /^BtWg[0-9a-f]{12}([0-9a-f]{8})0{8}([0-9a-f]{8})\u0000\u0000\u0000\u0004\u0000\u0000\u0000\u0004meta/
       size: 52
       contentAddress: 16
       zipContentAddress: 32
    }
    {
      regexp: /^BtWg[0-9a-f]{12}([0-9a-f]{8})0{8}([0-9a-f]{8})00\u0000\u0000\u0000\u0004\u0000\u0000\u0000\u0004meta/
      size: 54
      contentAddress: 16
      zipContentAddress: 32
    }
    {
      regexp: /^BtWg[0-9a-f]{12}([0-9a-f]{8})0{28}([0-9a-f]{8})\u0000\u0000\u0000\u0004\u0000\u0000\u0000\u0004meta/
      size: 72
      contentAddress: 16
      zipContentAddress: 52
    }
  ]
  uuidRegexp: /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/
  # regexp for finding fxb filename
  #   00000be5 indetifier
  #   08       type string
  #   00000028 size
  #   <uuid>
  #   2e667862  '.fxb'
  #                                                                            . f x b
  fxbHexRegexp:       /(00000be50800000028)\w{16}2d\w{8}2d\w{8}2d\w{8}2d\w{24}(2e667862)/
  #                                                                            . v s t p r e s e t
  vstpresetHexRegexp: /(00000be5080000002e)\w{16}2d\w{8}2d\w{8}2d\w{8}2d\w{24}(2e767374707265736574)/

# @templateFilePath required String
#    template file path
# --------------------------------
bwpresetExporter = (templateFilePath, opts) ->
  new BwpresetExporter templateFilePath, opts

class BwpresetExporter
  constructor: (templateFilePath, opts) ->
    @template = templateFilePath
    @opts = opts
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
    tap (file) =>
      # read template file
      bwpreset = fs.readFileSync @template

      headerStr = bwpreset.toString 'ascii', 0, 80
      headerData = undefined
      headerFormat = $.headers.find (fmt) ->
        headerData = headerStr.match fmt.regexp
      unless headerFormat
        throw new Error "Unknown bwpreset header format. header:#{headerStr}"
      # content data offset
      contentOffset = parseInt headerData[1], 16
      # zip content offset
      zippedContentOffset = parseInt headerData[2], 16
      # remove zipped content part
      bwpreset = bwpreset.slice 0, zippedContentOffset
      file.contents = _replaceFilename bwpreset
      , (if @opts?.vst3 then $.vstpresetHexRegexp else $.fxbHexRegexp)
      , file.data.nksf.nisi.uuid

  # gulp phase 3 append zipped content
  # --------------------------------
  gulpAppendPluginState: (builder) ->
    data (file, done) =>
      if @opts?.vst3
        builder file.data.nksf, (err, vstpreset) ->
          if err
            done err
            return
          # append zipped vstpreset
          _zip vstpreset
          , "plugin-states/#{file.data.nksf.nisi.uuid}.vstpreset"
          , (err, zippedContent) ->
            if err
              done err
              return
            file.contents = Buffer.concat [file.contents, zippedContent]
            done undefined, file.data
      else
        builder ?= _buildFxb
        fxb = builder file.data.nksf
        # append zipped fxb
        _zip fxb
        , "plugin-states/#{file.data.nksf.nisi.uuid}.fxb"
        , (err, zippedContent) ->
          if err
            done err
            return
          file.contents = Buffer.concat [file.contents, zippedContent]
          done undefined, file.data

  # gulp phase 4 reewrite metadata
  # @mapper function(metadata)
  #  NKSF metadata -> bwpreset metadata
  # --------------------------------
  gulpRewriteMetadata: (mapper) ->
    mapper ?= _metaMapper
    rewrite (file, bwmeta) ->
      mapper file.data.nksf.nisi

# replace filename of zipped content
# @param {Buffer} buffer - bwpreset template (without zipped content)
# @param {regexp} pattern
# @param {string} uid
_replaceFilename = (buffer, pattern, uid) ->
  # convert uuid string -> hex coded binary
  hexUuid = (Buffer.from uid.toLowerCase(), 'ascii').toString 'hex'
  # convert template buffer -> hex coded string
  hex = buffer.toString 'hex'
  # replace fxb filename
  unless hex.match pattern
    throw new Error("filename pattern unmatch error. pattern:#{pattern}")
  hex = hex.replace pattern, "\$1#{hexUuid}\$2"
  # revert to binary buffer
  Buffer.from hex, 'hex'

# build bitwig zipped fxb
# @param {object} nksf
# 
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
_buildFxb = (nksf) ->
  fxb = Buffer.alloc 160, 0
  offset = 0
  # fxMagic
  fxb.write 'CcnK', offset
  offset += 4
  # byteSize
  fxb.writeUInt32BE (152 + nksf.pluginState.length), offset
  offset += 4
  # fxMagic
  fxb.write 'FBCh', offset
  offset += 4
  # version
  fxb.writeUInt32BE 2, offset
  offset += 4
  # fxID
  fxb.writeUInt32BE nksf.plid['VST.magic'], offset
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
  fxb.writeUInt32BE nksf.pluginState.length, offset
  # concat header + plugin state
  Buffer.concat [fxb, nksf.pluginState]

_zip = (buffer, filePath, done) ->
  # compress zip
  zip = new yazl.ZipFile()
  zip.addBuffer buffer, filePath

  # async function
  zip.end (finalSize) -> zip.outputStream.pipe bl done


# default metadata mapper
# map NKS soundInfo -> bitwig metadata
# @param {object} nisi - NKS soundInfo
_metaMapper = (nisi) ->
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
  bitwig.tags = _.uniq ((tags.filter (t) -> t).map (t) -> ((t.replace /\s([\/&])\s/, '$1').replace /\s/g, '_').toLowerCase())
  # delete undefined properties
  for key in Object.keys(bitwig)
    unless bitwig[key]
      delete bitwig[key]
  # return metadat for rewriting
  bitwig

bwpresetExporter.defaultMetaMapper = _metaMapper
module.exports = bwpresetExporter
