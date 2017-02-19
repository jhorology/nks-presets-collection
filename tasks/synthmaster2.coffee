# KV311 Audio SynthMaster2
#
# notes
#  - Komplete Kontrol 1.7.1(R49)
#  - SynthMaster 2 v2.8.7
# ---------------------------------------------------------------
fs          = require 'fs'
uuid        = require 'uuid'
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
xpath       = require 'xpath'
_           = require 'underscore'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'

  #  common settings
  # -------------------------
  dir: 'SynthMaster2'
  vendor: 'KV331 Audio'
  magic: "Sm2i"

  #  local settings
  # -------------------------

  # Factory Patches folder
  presets: '/Library/Application Support/KV331 Audio/SynthMaster/Presets'
  # Ableton Live 9.7 Instrument Rack
  abletonRackTemplate: 'src/SynthMaster2/templates/SynthMaster2.adg.tpl'
  # Bitwig Studio 1.3.14 preset file
  bwpresetTemplate: 'src/SynthMaster2/templates/SynthMaster2.bwpreset'

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task "#{$.prefix}-print-default-meta", ->
  task.print_default_meta $.dir

# print mapping of _Default.nksf
gulp.task "#{$.prefix}-print-default-mapping", ->
  task.print_default_mapping $.dir

# print plugin id of _Default.nksf
gulp.task "#{$.prefix}-print-magic", ->
  task.print_plid $.dir

# generate default mapping file from _Default.nksf
gulp.task "#{$.prefix}-generate-default-mapping", ->
  task.generate_default_mapping $.dir

# generate metadata
#
# 0 author      c_PAUT r  'Bulent Biyikoglu' 'Fi'
# 1 corporation c_PCOP S  'KV311 Audio' '7\u00003'
# 2 description c_PDES r  'The' 'lea'
# 3 type        c_PCT1 z  'Lead%Sequence%Synth%' 'Ez'
# 4 music style c_PCT2 u  'Disco%Electro%Pop%'
# 5 attributes  c_PATT Z  'Analog%Factory%Mod Wheel%PWM%Pulse%Template%Velocity Mod%Version 2.8%' 'I'
# 6 bank        c_PBNK a  'Factory Presets' 'alT'
gulp.task "#{$.prefix}-generate-meta", ->
  searchVal = (name) -> (new Buffer name + '\u0000').toString 'hex'
  gulp.src ["#{$.presets}/**/*.smpr"], read: on
    .pipe data (file) ->
      hex = file.contents.toString 'hex'
      hexIndex = 0
      values = for n in ['c_PAUT', 'c_PCOP', 'c_PDES', 'c_PCT1', 'c_PCT2', 'c_PATT']
        hexIndex = hex.indexOf (searchVal n), hexIndex
        throw new Error "[#{file.path}] doesn't containg #{n} parameter." if hexIndex < 0
        throw new Error "[#{file.path}] unexpected odd-index. parameter: #{n}" if hexIndex % 2
        hexIndex += 16
        index = hexIndex >> 1
        length = file.contents.readUInt16LE index
        index += 2
        if length
          s = (file.contents.slice index, index + length).toString()
          if s[-1..] is '%' then s[..-2] else s
        else
          undefined
      modes = []
      Array.prototype.push.apply modes, values[4].split '%' if values[4]
      Array.prototype.push.apply modes, values[5].split '%' if values[5]
      basename = path.basename file.path, '.smpr'
      metaFile = path.join "src/#{$.dir}/presets", "#{file.relative[..-5]}meta"
      uid = if fs.existsSync metaFile
        (util.readJson metaFile)?.uuid || uuid.v4()
      else
        uuid.v4()
      file.contents = new Buffer util.beautify
        author: if values[1] then "#{values[0]}@#{values[1]}" else values[0]
        bankchain: [$.dir, 'SynthMaster2 Factory', '']
        comment: values[2]
        deviceType: 'INST'
        modes: modes
        name: basename
        types: if values[3] then [t] for t in (values[3].split '%') else [['Unknown']]
        uuid: uid
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
  gulp.src ["#{$.presets}/**/*.smpr"], read: on
    .pipe tap (file) ->
      # .smpr file is exactly same as plugin-state
      #  smpr -> PCHK chunk
      file.contents = Buffer.concat [
        new Buffer [1,0,0,0]
        file.contents
      ]
    .pipe data (pchk) ->
      nksf:
        pchk: pchk
        nisi: path.join "src/#{$.dir}/presets", "#{pchk.relative[..-5]}meta"
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
    .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

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
