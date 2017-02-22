# iZotope Neutron Compressor
#
# notes
#  - Komplete Kontrol 1.7.1(R49)
#  - Neutron Compressor Version: 1010
# ---------------------------------------------------------------

fs          = require 'fs'
path        = require 'path'
uuid        = require 'uuid'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
xpath       = require 'xpath'
_           = require 'underscore'
zlib        = require 'zlib'
unzip       = require 'gulp-unzip'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
extract = require 'gulp-riff-extractor'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  # dir: 'UVIWorkstationVST'
  dir: 'Neutron Compressor'
  vendor: 'iZotope'
  magic: "ZnBd"

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------
# generate metadata
gulp.task "#{$.prefix}-analyze-pluginstate", ->
  gulp.src ["#{$.NI.userContent}/#{$.dir}/_Default.nksf"], read: on
    .pipe extract chunk_ids: ['PCHK']
    .pipe tap (file) ->
      size = file.contents.readUInt32LE 4
      console.info size
      archive = file.contents.slice 8, size + 8
      fs.writeFileSync 'test.dat', archive
      console.info (zlib.unzipSync archive).toString()


# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"], read: on
    .pipe tap (file) ->
      basename = path.basename file.path, '.pchk'
      type = switch
        when basename[0...4] is 'Bass'   then 'Bass'
        when basename[0...4] is 'Drum'   then 'Drum'
        when basename[0...4] is 'Guit'   then 'Guitar'
        when basename[0...4] is 'Misc'   then 'Misc'
        when basename[0...4] is 'Perc'   then 'Percussion'
        when basename[0...5] is 'Synth'  then 'Synth'
        when basename[0...6] is 'Vocals' then 'Vocals'
        else 'Default'
      console.info "#{type}  #{basename}"
      file.contents = new Buffer util.beautify
        author: ''
        bankchain: [$.dir, 'Ohmicide Factory', '']
        comment: ''
        deviceType: 'FX'
        modes: []
        name: basename
        types: [[type]]
        uuid: util.uuid file
        vendor: $.vendor
      , on    # print
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
          
#
# build
# --------------------------------

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic, "src/#{$.dir}/mappings/default.json"
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"], read: on
    .pipe data (pchk) ->
      nksf:
        pchk: pchk
        nisi: "#{pchk.path[..-5]}meta"
    .pipe builder.gulp()
    .pipe rename extname: '.nksf'
    .pipe gulp.dest "dist/#{$.dir}/User Content/#{$.dir}"

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpTemplate()
    .pipe gzip append: off       # append '.gz' extension
    .pipe rename extname: '.adg'
    .pipe tap (file) ->
      # edit file path
      dirname = path.dirname file.path
      file.path = path.join dirname, file.data.nksf.nisi.types[0][0], file.relative
    .pipe gulp.dest "#{$.Ableton.effectRacks}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
  exporter = bwExporter $.bwpresetTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState()
    .pipe exporter.gulpRewriteMetadata()
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
