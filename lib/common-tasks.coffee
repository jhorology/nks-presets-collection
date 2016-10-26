assert      = require 'assert'
path        = require 'path'
fs          = require 'fs'
gulp        = require 'gulp'
data        = require 'gulp-data'
exec        = require 'gulp-exec'
changed     = require 'gulp-changed'
extract     = require 'gulp-riff-extractor'
tap         = require 'gulp-tap'
zip         = require 'gulp-zip'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
uuid        = require 'uuid'
_           = require 'underscore'
builder     = require './riff-builder.coffee'
msgpack     = require 'msgpack-lite'
beautify    = require 'js-beautify'
riffReader  = require 'riff-reader'
yazl        = require 'yazl'
bl          = require 'bl'
bitwigRewriteMeta = require 'gulp-bitwig-rewrite-meta'
util        = require './util'
$           = require '../config'

module.exports =

  # prepairing tasks
  # --------------------------------

  # generate default parameter mapping file
  generate_default_mapping: (dir) ->
    gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
      .pipe changed "src/#{dir}/mappings",
        hasChanged: (stream, cb, file, dest) ->
          dest = path.join (path.dirname dest), 'default.json'
          changed.compareLastModifiedTime stream, cb, file, dest
      .pipe extract
        chunk_ids: ['NICA']
        filename_template: "default.json"
      .pipe tap (file) ->
        file.contents = new Buffer _deserialize file
      .pipe gulp.dest "src/#{dir}/mappings"

  # print default NISI chunk as JSON
  print_default_meta: (dir) ->
    console.info "#{$.NI.userContent}/#{dir}/_Default.nksf"
    gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
      .pipe extract
        chunk_ids: ['NISI']
      .pipe tap (file) ->
        console.info _deserialize file

  # print default NACA chunk as JSON
  print_default_mapping: (dir) ->
    gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
      .pipe extract
        chunk_ids: ['NICA']
      .pipe tap (file) ->
        console.info _deserialize file

  # print PLID chunk as JSON
  print_plid: (dir) ->
    gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
      .pipe extract
        chunk_ids: ['PLID']
      .pipe tap (file) ->
        magic = _deserializeMagic file
        console.info "magic: '#{magic}'"

  # extract PCHK chunk from .nksf file
  extract_raw_presets: (srcs, dest) ->
    gulp.src srcs
      .pipe extract
        chunk_ids: ['PCHK']
      .pipe gulp.dest dest

  # extract PCHK chunk from .adg (ableton rack) file
  extract_raw_presets_from_adg: (srcs, dest) ->
    gulp.src srcs
      .pipe data (file) ->
        extname = path.extname file.path
        basename = path.basename file.path, extname
        dirname = path.join dest, path.dirname file.relative
        destDir: dirname
        destPath: path.join dirname, "#{basename}.pchk"
      .pipe exec [
        'echo "now converting file:<%= file.relative %>"'
        'mkdir -p "<%= file.data.destDir %>"'
        'tools/adg2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
        ].join '&&'
      , $.execOpts
      .pipe exec.reporter $.execRepotOpts

  # extract PCHK chunk from .bwpreset (bitwig preset) file
  extract_raw_presets_from_bw: (srcs, dest) ->
    gulp.src srcs
      .pipe data (file) ->
        extname = path.extname file.path
        basename = path.basename file.path, extname
        dirname = path.join dest, path.dirname file.relative
        destDir: dirname
        destPath: path.join dirname, "#{basename}.pchk"
      .pipe exec [
        'mkdir -p "<%= file.data.destDir %>"'
        'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
        ].join '&&'
      , $.execOpts
      .pipe exec.reporter $.execRepotOpts

  #
  # dist
  # --------------------------------

  # copy image resources to dist folder
  dist_image: (dir, vendor) ->
    d = util.normalizeDirname dir.toLowerCase()
    v = vendor.toLowerCase()
    gulp.src ["src/#{dir}/resources/image/**/*.{json,meta,png}"]
      .pipe gulp.dest "dist/#{dir}/NI Resources/image/#{v}/#{d}"

  # copy database resources to dist folder
  dist_database: (dir, vendor) ->
    d = util.normalizeDirname dir.toLowerCase()
    v = vendor.toLowerCase()
    gulp.src ["src/#{dir}/resources/dist_database/**/*.{json,meta,png}"]
      .pipe gulp.dest "dist/#{dir}/NI Resources/dist_database/#{v}/#{d}"

  # build presets file to dist folder
  # callback(file) optional
  #   -  do something file.contents
  #   -  return preset mapping filepath or mapping object.
  #   -  return null or undefine for use default.json
  dist_presets: (dir, magic, callback) ->
    presets = "src/#{dir}/presets"
    mappings = "src/#{dir}/mappings"
    dist = "dist/#{dir}/User Content/#{dir}"
    defaultMapping = undefined
    defaultMapping = if fs.existsSync "#{mappings}/default.json"
      _serialize util.readJson "#{mappings}/default.json"
    pluginId = _serializeMagic magic
    gulp.src ["#{presets}/**/*.pchk"], read: true
      .pipe tap (file) ->
        mapping = defaultMapping
        mapping = if _.isFunction callback
          m = callback file
          switch
            when _.isString m
              _serialize util.readJson m
            when _.isObject m and m.ni8
              _serialize m
            else
              defaultMapping
        else
          defaultMapping
        riff = builder 'NIKS'
        # NISI chunk -- metadata
        meta = _serialize util.readJson "#{presets}/#{file.relative[..-5]}meta"
        riff.pushChunk 'NISI', meta
        # NACA chunk -- mapping
        riff.pushChunk 'NICA', mapping
        # PLID chunk -- plugin id
        riff.pushChunk 'PLID', pluginId
        # PCHK chunk -- raw preset (pluginstates)
        riff.pushChunk 'PCHK', file.contents
        # output file contents
        file.contents = riff.buffer()
        # .pchk -> .nksf
        file.path = "#{file.path[..-5]}nksf"
      .pipe gulp.dest dist

  # print all presets
  check_dist_presets: (dir, PLID) ->
    dist = "dist/#{dir}/User Content/#{dir}"
    gulp.src ["#{dist}/**/*.nksf"], read: true
      .pipe extract
        chunk_ids: ['NISI', 'NICA', 'PLID']
      .pipe tap (file) ->
        console.info _deserialize file
  #
  # deploy
  # --------------------------------

  # copy resources to local environment
  deploy_resources: (dir) ->
    gulp.src ["dist/#{dir}/NI Resources/**/*.{json,meta,png}"]
      .pipe gulp.dest $.NI.resources

  # copy presets to local environment
  deploy_presets: (dir) ->
    gulp.src ["dist/#{dir}/User Content/**/*.nksf"]
      .pipe gulp.dest $.NI.userContent

  #
  # release
  # --------------------------------

  # zip dist file and copy to dropbox.
  release: (dir) ->
    gulp.src ["dist/#{dir}/**/*.{json,meta,png,nksf}"]
      .pipe zip "#{dir}.zip"
      .pipe gulp.dest $.release

  #
  # export from nksf to adg(ableton rack)
  #  @srcs      String or Array of String - .nksf glob pattern
  #  @dst       String - destination
  #  @template  String - template file path
  #  @cb1       function(file, metadata) optional - do something with .nksf file and metadata
  #  @cb2       function(file, chunk) optional - do something with PCHK chunk
  #  @cb3       function(file) optional - do something with uncompressed .adg file
  # --------------------------------
  export_adg: (srcs, dst, template, cb1, cb2, cb3)  ->
    template = _.template util.readFile template
    gulp.src srcs, read: on
      .pipe tap (file) ->
        if _.isFunction cb1
          metadata = undefined
          (riffReader file.contents, 'NIKS').readSync (id, chunk) ->
            metadata = msgpack.decode chunk.slice 4
          , ['NISI']
          cb1 file, metadata
      .pipe tap (file) ->
        templateSource =
          params: []
          bufferLines: []
        (riffReader file.contents, 'NIKS').readSync (id, chunk) ->
          switch id
            when 'NICA'
              params = []
              ni8 = (msgpack.decode chunk.slice 4).ni8
              for page, pageIndex in ni8
                for param, paramIndex in page
                  if param.id
                    templateSource.params.push
                      id: param.id
                      name: param.name
                      visualIndex: pageIndex * 8 + paramIndex
                    break if templateSource.params.length >= 128
                break if templateSource.params.length >= 128
            when 'PCHK'
              lines = []
              cb2(file, chunk) if _.isFunction cb2
              size = chunk.length
              offset = 4
              while offset < size
                end = offset + 40
                end = size if end > size
                templateSource.bufferLines.push chunk.toString 'hex', offset, end
                offset += 40
        , ['NICA', 'PCHK']
        #
        file.contents = new Buffer template templateSource
      .pipe tap (file) ->
        cb3(file) if _.isFunction cb3
      .pipe gzip
        append: off       # append '.gz' extension
      .pipe rename
        extname: '.adg'
      .pipe gulp.dest dst

  #
  # export from nksf to adg(ableton rack)
  #  @srcs      String or Array of String - .nksf glob pattern
  #  @dst       String - destination
  #  @template  String - template file path
  #  @cb1       function(file) optional - do something with .nksf file and file.data
  #  @cb2       function(nks_metadata) optional - map to bitwig metadata
  # --------------------------------
  export_bwpreset: (srcs, dst, template, cb1, cb2)  ->
    gulp.src srcs, read: on
      .pipe tap (file) ->
        # parse all chunks
        file.data = {}
        (riffReader file.contents, 'NIKS').readSync (id, chunk) ->
          switch id
            when 'NISI'
              file.data.meta = msgpack.decode chunk.slice 4
            when 'NICA'
              file.data.ni8 = (msgpack.decode chunk.slice 4).ni8
            when 'PLID'
              file.data.fxID = (msgpack.decode chunk.slice 4)['VST.magic']
            when 'PCHK'
              file.data.pluginState = chunk.slice 4
        , ['NISI', 'NICA', 'PLID', 'PCHK']
        # callback
        cb1 file if _.isFunction cb1
        # read template file
        bwpreset = fs.readFileSync template
        # ziped fxb offset
        offset = parseInt (bwpreset.toString 'ascii', 0x00000024, 0x00000024 + 8), 16
        # remove zipped fxb part
        bwpreset = bwpreset.slice 0, offset
        file.contents = _bitwig_replace_fxb_filename bwpreset, file.data.meta.uuid
      .pipe data (file, done) ->
        # append zipped fxb to file contents
        _build_bitwig_zipped_fxb file.data.pluginState, file.data.fxID, file.data.meta.uuid, (err, zippedFxb) ->
          throw new Exception err if err
          file.contents = Buffer.concat [file.contents, zippedFxb]
          done undefined, file.data
      .pipe bitwigRewriteMeta (file) ->
        if _.isFunction cb2
          cb2 file.data.meta
        else
          _bitwig_default_meta_map file.data.meta
      .pipe rename
        extname: '.bwpreset'
      .pipe gulp.dest dst

#
# routines
# --------------------------------

# desrilize to json string
_deserialize = (file) ->
  ver = file.contents.readUInt32LE 0
  assert.ok (ver is $.chunkVer), "Unsupported chunk format version. version:#{ver}"
  util.beautify msgpack.decode file.contents.slice 4

# desrilize to magic string
_deserializeMagic = (file) ->
  ver = file.contents.readUInt32LE 0
  assert.ok (ver is $.chunkVer), "Unsupported chunk format version. version:#{ver}"
  json = msgpack.decode file.contents.slice 4
  magic = json['VST.magic']
  buffer = new Buffer 4
  buffer.writeUInt32BE magic
  buffer.toString()

# esrilize to PLID chunk
_serializeMagic = (magic) ->
  buffer = new Buffer 4
  buffer.write magic, 0, 4, 'ascii'
  x = buffer.readUInt32BE 0
  _serialize
    "VST.magic": buffer.readUInt32BE 0

# srilize to chunk
_serialize = (json) ->
  ver = new Buffer 4
  ver.writeUInt32LE $.chunkVer
  Buffer.concat [ver, msgpack.encode json]

# replace .fxb filename in
#   @buffer bwpreset template
#   @uuid   uuid for .fxb filename
_bitwig_replace_fxb_filename = (buffer, uuid) ->
  assert.ok (uuid.match $.uuidRegexp), "invalid uuid pattern. uuid:#{uuid}"
  # convert uuid string -> hex coded binary
  hexUuid = (new Buffer uuid.toLowerCase(), 'ascii').toString 'hex'
  # convert template buffer -> hex coded string
  hex = buffer.toString 'hex'
  # replace fxb filename
  hex = hex.replace $.Bitwig.fxbHexRegexp, "\$1#{hexUuid}\$2"
  # revert to binary buffer
  new Buffer hex, 'hex'

# build bitwig zipped fxb
#  @pluginState buffer
#  @fxID       Vst magic
#  @uuid
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
_build_bitwig_zipped_fxb = (pluginState, fxID, uuid, done) ->
  fxb = Buffer.alloc 160, 0
  offset = 0
  # fxMagic
  fxb.write 'CcnK', offset
  offset += 4
  # byteSize
  fxb.writeUInt32BE (154 + pluginState.length), offset
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
  zip.addBuffer fxb, "plugin-states/#{uuid}.fxb"

  # async function
  zip.end (finalSize) ->
     zip.outputStream.pipe bl done
    
    
# default metadata map
#   map nks metadat -> bitwig metadata
#   @nks  metadata of .nksf file
_bitwig_default_meta_map = (nks) ->
  bitwig =
    name: nks.name
    comment: nks.comment
    creator: nks.author
    preset_category: nks.types[0][0]
  tags = []
  if nks.modes and nks.modes.length
    tags = tags.concat nks.modes
  if nks.types and nks.types.length
    for t in nks.types
      tags.push t[1] if t.length > 1
  tags.push nks.bankchain[1] if nks.bankchain and nks.bankchain.length > 1
  bitwig.tags = _.uniq ((tags.filter (t) -> t).map (t) -> (t.replace /\s/g, '_').toLowerCase())   
  # delete undefined properties
  for key in Object.keys(bitwig)
    unless bitwig[key]
      delete bitwig[key]
  # return metadat for rewriting
  bitwig
