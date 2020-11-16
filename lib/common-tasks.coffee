assert  = require 'assert'
path    = require 'path'
del     = require 'del'
gulp    = require 'gulp'
data    = require 'gulp-data'
exec    = require 'gulp-exec'
rename  = require 'gulp-rename'
extract = require 'gulp-riff-extractor'
gutil   = require 'gulp-util'
tap     = require 'gulp-tap'
zip     = require 'gulp-zip'
msgpack = require 'msgpack-lite'
_       = require 'underscore'
util    = require './util'
$       = require '../config'

# register following common tasks
# - preparing
#   - #{$.prefix}-print-default-magic
#   - #{$.prefix}-print-default-meta
#   - #{$.prefix}-print-default-mapping
#   - #{$.prefix}-generate-default-mapping
#   - #{$.prefix}-generate-default-parameter-list
#   - #{$.prefix}-extract-pchk
#   - #{$.prefix}-extract-pchk-from-adg
#   - #{$.prefix}-extract-pchk-from-bw
# - dist
#   - #{$.prefix}-dist
#   - #{$.prefix}-dist-image
#   - #{$.prefix}-dist-database
#   - #{$.prefix}-check-dist-presets
# - deploy
#   - #{$.prefix}-deploy
#   - #{$.prefix}-deploy-resources
#   - #{$.prefix}-deploy-presets
# - release
#   - #{$.prefix}-exclude-release * when $.releaseExcudes is defined
#   - #{$.prefix}-release * when $.releaseExcudes is defined
#
# @$ module settings
# - $.prefix           required module name
# - $.dir              required dirname (root of bankchain)
# - $.vendor           required plugin vendor name
# - $.magic            required plugin maigic
# - $.releaseExcludes  optional array of exlude relative glob pattern
# --------------------------------
module.exports = ($, nksReady) ->

  # prepairing tasks
  # --------------------------------
  # print plugin id of _Default.nksf
  gulp.task "#{$.prefix}-print-default-magic", ->
    gulp.src ["#{$.NI.userContent}/#{$.dir}/_Default.{nksf,nksfx}"]
      .pipe extract chunk_ids: ['PLID']
      .pipe tap (file) -> console.info "magic: '#{_deserializeMagic file}'"

  # print default NISI chunk as JSON
  gulp.task "#{$.prefix}-print-default-meta", ->
    gulp.src ["#{$.NI.userContent}/#{$.dir}/_Default.{nksf,nksfx}"]
      .pipe extract chunk_ids: ['NISI']
      .pipe tap (file) ->  console.info _deserialize file

  # print default NACA chunk as JSON
  gulp.task "#{$.prefix}-print-default-mapping", ->
    gulp.src ["#{$.NI.userContent}/#{$.dir}/_Default.{nksf,nksfx}"]
      .pipe extract chunk_ids: ['NICA']
      .pipe tap (file) -> console.info _deserialize file

  # generate default parameter mapping file
  gulp.task "#{$.prefix}-generate-default-mapping", ->
    gulp.src ["#{$.NI.userContent}/#{$.dir}/_Default.{nksf,nksfx}"]
      .pipe extract
        chunk_ids: ['NICA']
        filename_template: "default.json"
      .pipe tap (file) ->
        file.contents = Buffer.from _deserialize file
      .pipe gulp.dest "src/#{$.dir}/mappings"

  # generate flat parameter list from mrswatoson info.txt
  gulp.task "#{$.prefix}-generate-parameter-list", ->
    template = _.template '''
module.exports = [<% _.forEach(params, function(p, i) { %>
  {id: <%= p.idSpaces %><%= p.id %>, name: '<%= p.name %>',<%= p.nameSpaces %> section: ''}<% }); %>
]
'''
    gulp.src ["src/#{$.dir}/mrswatson-display-info.txt"], read: on
      .pipe tap (file, t) ->
        txt = file.contents.toString()
        if match = /^- [0-9]{8} [0-9]{6} Parameters \([0-9]+ total\):\n([\s\S]*)?\n^- [0-9]{8} [0-9]{6} Programs/m.exec txt
          idLength = 0
          nameLength = 0
          params = for s in match[1].split '\n'
            m = /^- [0-9]{8} [0-9]{6}\s+([0-9]+): \'(.*)?\'/.exec s
            idLength = Math.max idLength, m[1].length
            nameLength = Math.max nameLength, m[2].length
            id: m[1]
            name: m[2]
          if params
            params = for p in params
              id: p.id
              name: p.name
              idSpaces: (Buffer.alloc (idLength - p.id.length), ' ').toString()
              nameSpaces: (Buffer.alloc (nameLength - p.name.length), ' ').toString()
            # console.info template params: params
            file.contents = Buffer.from template params: params
          else
            throw new Error 'empty paramter'
        else
          throw new Error 'unexpected file format.'
      .pipe rename
        basename: 'default-parameter-list'
        extname: '.coffee'
      .pipe gulp.dest "src/#{$.dir}/mappings"

  # extract PCHK chunk from .nksf file
  gulp.task "#{$.prefix}-extract-pchk", ->
    gulp.src ["temp/#{$.dir}/**/*.{nksf,nksfx}"]
      .pipe extract chunk_ids: ['PCHK']
      .pipe gulp.dest "src/#{$.dir}/presets"

  # extract PCHK chunk from .adg (ableton rack) file
  gulp.task "#{$.prefix}-extract-pchk-from-adg", ->
    gulp.src ["temp/#{$.dir}/**/*.adg"]
      .pipe data (file) ->
        extname = path.extname file.path
        basename = path.basename file.path, extname
        dirname = path.join "src/#{$.dir}/presets", path.dirname file.relative
        srcPath: file.path.replace /`/g, '\\`'
        destDir: dirname
        destPath: (path.join dirname, "#{basename}.pchk").replace /`/g, '\\`'
      .pipe exec [
        'echo now converting file:"<%= file.data.srcPath %>"'
        'mkdir -p "<%= file.data.destDir %>"'
        'tools/adg2pchk "<%= file.data.srcPath %>" "<%= file.data.destPath %>"'
        ].join '&&'
      , $.execOpts
      .pipe exec.reporter $.execRepotOpts

  # extract PCHK chunk from .bwpreset (bitwig preset) file
  gulp.task "#{$.prefix}-extract-pchk-from-bw", ->
    gulp.src ["temp/#{$.dir}/**/*.bwpreset"]
      .pipe data (file) ->
        extname = path.extname file.path
        basename = path.basename file.path, extname
        dirname = path.join "src/#{$.dir}/presets", path.dirname file.relative
        srcPath: file.path.replace /`/g, '\\`'
        destDir: dirname
        destPath: (path.join dirname, "#{basename}.pchk").replace /`/g, '\\`'
      .pipe exec [
        'echo now converting file:"<%= file.data.srcPath %>"'
        'mkdir -p "<%= file.data.destDir %>"'
        'tools/bwpreset2pchk "<%= file.data.srcPath %>" "<%= file.data.destPath %>"'
        ].join '&&'
      , $.execOpts
      .pipe exec.reporter $.execRepotOpts

  # don't need below if nks-ready plugin
  return if nksReady

  #
  # dist
  # --------------------------------

  # copy dist files to dist folder
  gulp.task "#{$.prefix}-dist", [
    "#{$.prefix}-dist-image"
    "#{$.prefix}-dist-database"
    "#{$.prefix}-dist-presets"
  ]

  # copy image resources to dist folder
  gulp.task "#{$.prefix}-dist-image", ->
    d = util.normalizeDirname $.dir.toLowerCase()
    v = ($.vendor_sanitized or $.vendor).toLowerCase()
    gulp.src ["src/#{$.dir}/resources/image/**/*.{json,meta,png}"]
      .pipe gulp.dest "dist/#{$.dir}/NI Resources/image/#{v}/#{d}"

  # copy database resources to dist folder
  gulp.task "#{$.prefix}-dist-database", ->
    d = util.normalizeDirname $.dir.toLowerCase()
    v = ($.vendor_sanitized or $.vendor).toLowerCase()
    gulp.src ["src/#{$.dir}/resources/dist_database/**/*.{json,meta,png}"]
      .pipe gulp.dest "dist/#{$.dir}/NI Resources/dist_database/#{v}/#{d}"

  # print all presets
  gulp.task "#{$.prefix}-check-dist-presets", ->
    dist = "dist/#{$.dir}/User Content/#{$.dir}"
    gulp.src ["#{dist}/**/*.{nksf,nksfx}"], read: true
      .pipe extract chunk_ids: ['NISI', 'NICA', 'PLID']
      .pipe tap (file) -> console.info _deserialize file


  # deploy
  # --------------------------------
  gulp.task "#{$.prefix}-deploy", [
    "#{$.prefix}-deploy-resources"
    "#{$.prefix}-deploy-presets"
  ]

  # copy resources to local environment
  gulp.task "#{$.prefix}-deploy-resources", [
    "#{$.prefix}-dist-image"
    "#{$.prefix}-dist-database"
  ], ->
    gulp.src ["dist/#{$.dir}/NI Resources/**/*.{json,meta,png}"]
      .pipe gulp.dest $.NI.resources

  # copy presets to local environment
  gulp.task "#{$.prefix}-deploy-presets", [
    "#{$.prefix}-dist-presets"
  ] , ->
    gulp.src [
      "dist/#{$.dir}/User Content/**/*.{nksf,nksfx}"
      "dist/#{$.dir}/User Content/**/.previews/*.nksf.ogg"
    ]
      .pipe gulp.dest $.NI.userContent
  #
  # release
  # --------------------------------
  if $.releaseExcludes
    gulp.task "#{$.prefix}-exclude-release",  ["#{$.prefix}-dist"], (cb) ->
      excludes = $.releaseExcludes.map (p) ->
        s = p[0]
        r = p
        if s is '!'
          r = p[1..]
        else
          s = ''
        ret = "#{s}dist/#{$.dir}/User Content/#{$.dir}"
        ret += "/#{r}" if r
        ret
      del excludes, force: true, cb

  # zip dist file and copy to dropbox.
  gulp.task "#{$.prefix}-release"
  , ["#{$.prefix}-#{if $.releaseExcludes then 'exclude-release' else 'dist'}"]
  , ->
    gulp.src [
      "dist/#{$.dir}/**/*.{json,meta,png,nksf,nksfx}"
      "dist/#{$.dir}/**/.previews/*.nksf.ogg"
    ]
      .pipe zip "#{$.dir}.zip"
      .pipe gulp.dest $.release

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
  buffer = Buffer.alloc 4
  buffer.writeUInt32BE magic
  buffer.toString()
