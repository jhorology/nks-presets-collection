path        = require 'path'
fs          = require 'fs'
del         = require 'del'
sqlite3     = require 'sqlite3'
gulp        = require 'gulp'
coffeelint  = require 'gulp-coffeelint'
coffee      = require 'gulp-coffee'
watch       = require 'gulp-watch'
extract     = require 'gulp-riff-extractor'
rewrite     = require 'gulp-nks-rewrite-meta'
changed     = require 'gulp-changed'
data        = require 'gulp-data'
nks         = require 'nks-json'
builder     = require './lib/riff-builder'
beautify    = require 'js-beautify'
uuid        = require 'uuid'

# paths, misc settings
$ =
  #
  # distribution
  #-------------------------------------------
  pub: "#{process.env.HOME}/Dropbox/Share/NKS"
  json_indent: 2
  
  #
  # Native Instruments
  #-------------------------------------------
  NI:
    userContent: "#{process.env.HOME}/Documents/Native Instruments/User Content"
    resources: '/Users/Shared/NI Resources'
  #
  # Bitwig Studio
  #-------------------------------------------
  Bitwig:
    presets: "#{process.env.HOME}/Bitwig Studio/Library/Presets"
  #
  # Air Music Technology Velvet
  #-------------------------------------------
  Velvet:
    dir: 'Velvet'
    vendor: 'Air Music Technology'
  #
  # Xfer Records Serum
  #-------------------------------------------
  Serum:
    dir: 'Serum'
    vendor: 'Xfer Records'
    PLID:
      'VST.magic': 'XfsX'
    db: '/Library/Audio/Presets/Xfer\ Records/Serum\ Presets/System/presetdb.dat'
    query: '''
select
  PresetDisplayName
  ,PresetRelativePath
  ,Author
  ,Description
  ,Category
from
  SerumPresetTable
where
  PresetDisplayName = $name
  and PresetRelativePath = $folder
'''
  
gulp.task 'coffeelint', ->
  gulp.src ['*.coffee', "lib/*.coffee"]
    .pipe coffeelint 'coffeelint.json'
    .pipe coffeelint.reporter()

gulp.task 'coffee', ['coffeelint'], ->
  gulp.src ["lib/*.coffee"]
    .pipe coffee()
    .pipe gulp.dest $.lib

gulp.task 'clean', (cb) ->
  del [
    './**/*~'
     'dist'
     'temp'
    ]
  , force: true, cb

# deploy all presets and resources
gulp.task 'deploy', [
  'deploy-velvet'
  'deploy-serum'
  'deploy-resources'
]

# Air Music Technology Velvet
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Velvet  2.0.6.18983
# ---------------------------------------------------------------
gulp.task 'velvet-prepare', ->
  gulp.src ['User Content/Velvet/**/*.nksf'], read: true
    .pipe rewrite (file, data) ->
      console.info beautify (JSON.stringify data), indent_size: 2
      undefined
      
gulp.task 'parse-deployed-velvet', ->
  gulp.src ["#{$.userContentDir}/Velvet/**/*.nksf"], read: true
    .pipe rewrite (file, data) ->
      console.info beautify (JSON.stringify data), indent_size: 2
      undefined

gulp.task 'deploy-velvet', ->
  gulp.src ['User Content/Velvet/**/*.nksf'], read: true
    .pipe rewrite (file, data) ->
      folder = path.relative 'User Content/Velvet', path.dirname file.path
      # meta
      bankchain: ['Velvet', folder, '']
      modes: ['Sample Based']
      types: [
        ["Piano/Keys"]
        ["Piano/Keys", "Electric Piano"]
      ]
    .pipe gulp.dest "#{$.userContentDir}/Velvet"

# Xfer Record Serum
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Serum  1.073 Oct 5 2015
# ---------------------------------------------------------------

#
# prepare tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'serum-print-default-meta', ->
  _print_default_meta $.Serum.dir

# print mapping of _Default.nksf
gulp.task 'serum-print-default-mapping', ->
  _print_default_mapping $.Serum.dir

# print plugin id of _Default.nksf
gulp.task 'serum-print-plid', ->
  _print_plid $.Serum.dir

# generate default mapping file from _Default.nksf
gulp.task 'serum-generate-default-mapping', ->
  _generate_default_mapping $.Serum.dir

# extract PCHK chunk from .nksf files.
gulp.task 'serum-extract-raw-presets', ->
  _extract_raw_presets [
    "#{$.NI.userContent}/#{$.Serum.dir}/**/*.nksf"
    "!#{$.NI.userContent}/#{$.Serum.dir}/_Default.nksf"
    ]
  , "src/#{$.Serum.dir}/presets"

# copy resources to dist folder
gulp.task 'serum-dist-resources', [
  'serum-dist-image'
  'serum-dist-database'
]

# generate metadata from serum's sqlite database
gulp.task 'serum-generate-meta', ->
  # open database
  db = new sqlite3.Database $.Serum.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.Serum.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      # SQL bind parameters
      params =
        $name: path.basename file.path, '.pchk'
        $folder: path.relative "src/#{$.Serum.dir}/presets", path.dirname file.path
      # execute query
      db.get $.Serum.query, params, (err, row) ->
        done err,
          author: row.Author?.trim()
          bankchain: ['Serum', 'Serum Factory', '']
          comment: row.Description?.trim()
          deviceType: 'INST'
          name: row.PresetDisplayName?.trim()
          types: [[row.Category?.trim()]]
          uuid: uuid.v4()
          vendor: $.Serum.vendor
    .pipe data (file) ->
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      file.data
    .pipe gulp.dest "src/#{$.Serum.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

# copy image resources to dist folder
gulp.task 'serum-dist-image', ->
  _dist_image $.Serum.dir, $.Serum.vendor

# copy database resources to dist folder
gulp.task 'serum-dist-database', ->
  _dist_database $.Serum.dir, $.Serum.vendor

# build presets file to dist folder
gulp.task 'serum-dist-presets', ->
  gulp.src ["src/#{$.Serum.dir}/presets/**/*.pchk"], read: true
    .pipe data (file) ->
      console.info "#### 1"
      riff = builder 'NIKS'
      console.info "#### 1-1 #{file.path[..-5]}meta"
      # NISI chunk -- metadata
      meta = _serialize require "src/#{$.Serum.dir}/presets/#{file.relative[..-5]}meta"
      console.info "#### 1-2"
      riff.pushChunk 'NISI', meta
      # NACA chunk -- mapping
      console.info "#### 2"
      mapping = _serialize require "src/#{$.Serum.dir}/mapping/default.json"
      riff.pushChunk 'NICA', mapping
      # PLID chunk -- plugin id
      console.info "#### 3"
      mapping = _serialize $.Serum.PLID
      riff.pushChunk 'PLID', mapping
      # PCHK chunk -- raw preset (pluginstates)
      console.info "#### 4"
      riff.pushChunk 'PCHK', file.contens
      # output file contents
      console.info "#### 5"
      file.contents = riff.buffer()
      # .pchk -> .nksf
      file.path = "#{file.path[..-5]}nksf"
    .pipe gulp.dest "dist/#{$.Serum.dir}/User Content"

# utility routines
# ---------------------------
 
# desrilize to json object 
_deserialize = (file) ->
  json = nks.deserializer file.contents
    .deserialize()
  beautify (JSON.stringify json), indent_size: $.json_indent

# desrilize to json object 
_serialize = (json) ->
  console.info "kpoqkpwdqwd"
  console.info beautify (JSON.stringify json), indent_size: $.json_indent
  nks.serializer json
    .serialize()
    .buffer()

# generate default parameter mapping file
_generate_default_mapping = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe changed "src/#{dir}/mappings",
      hasChanged: (stream, cb, file, dest) ->
        dest = path.join (path.dirname dest), 'default.json' 
        changed.compareLastModifiedTime stream, cb, file, dest
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NICA']
      filename_template: "default.json"
    .pipe data (file) ->
      file.contents = new Buffer _deserialize file
    .pipe gulp.dest "src/#{dir}/mappings"

# print default NISI chunk as JSON
_print_default_meta = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NISI']
    .pipe data (file) ->
      console.info _deserialize file

# print default NACA chunk as JSON
_print_default_mapping = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NICA']
    .pipe data (file) ->
      console.info _deserialize file

# print PLID chunk as JSON
_print_plid = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['PLID']
    .pipe data (file) ->
      console.info _deserialize file

# extract PCHK chunk
_extract_raw_presets = (srcs, dest) ->
  gulp.src srcs
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['PCHK']
    .pipe gulp.dest dest

# copy image resources to dist folder
_dist_image = (dir, vendor) ->
  gulp.src ["src/#{dir}/resources/image/**/*.{json,meta,png}"]
    .pipe gulp.dest "dist/#{dir}/NI Resources/image/#{vendor.toLowerCase()}/#{dir.toLowerCase()}"

# copy database resources to dist folder
_dist_database = (dir, vendor) ->
  gulp.src ["src/#{dir}/resources/dist_database/**/*.{json,meta,png}"]
    .pipe gulp.dest "dist/#{dir}/NI Resources/dist_database/#{vendor.toLowerCase()}/#{dir.toLowerCase()}"




