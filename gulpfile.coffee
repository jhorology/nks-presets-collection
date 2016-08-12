assert      = require 'assert'
path        = require 'path'
fs          = require 'fs'
_           = require 'underscore'
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
exec        = require 'gulp-exec'
zip         = require 'gulp-zip'
rename      = require 'gulp-rename'
msgpack     = require 'msgpack-lite'
builder     = require './lib/riff-builder'
beautify    = require 'js-beautify'
uuid        = require 'uuid'
xpath       = require 'xpath'
xmldom      = (require 'xmldom').DOMParser
hiveParser  = require 'u-he-hive-meta-parser'

$ =
  #
  # buld environment & misc settings
  #-------------------------------------------
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

  #
  # Bitwig Studio
  #-------------------------------------------
  Bitwig:
    presets: "#{process.env.HOME}/Documents/Bitwig Studio/Library/Presets"

  #
  # Air Music Technology Velvet
  #-------------------------------------------
  Velvet:
    dir: 'Velvet'
    vendor: 'Air Music Technology'
    magic: "tvlV"
  #
  # Air Music Technology Xpand!2
  #-------------------------------------------
  Xpand2:
    dir: 'Xpand!2'
    vendor: 'Air Music Technology'
    magic: "2dpX"

  #
  # Air Music Technology Loom
  #-------------------------------------------
  Loom:
    dir: 'Loom'
    vendor: 'Air Music Technology'
    magic: "mooL"

  #
  # Air Music Technology Hybrid
  #-------------------------------------------
  Hybrid:
    dir: 'Hybrid'
    vendor: 'Air Music Technology'
    magic: "drbH"

  #
  # Air Music Technology Vacuum Pro
  #-------------------------------------------
  VacuumPro:
    dir: 'VacuumPro'
    vendor: 'Air Music Technology'
    magic: "rPcV"

  #
  # Air Music Technology Vacuum Pro
  #-------------------------------------------
  theRiser:
    dir: 'theRiser'
    vendor: 'Air Music Technology'
    magic: "rsRt"

  #
  # Air Music Technology Strike
  #-------------------------------------------
  Structure:
    dir: 'Structure'
    vendor: 'Air Music Technology'
    magic: 'urtS'
    libs: '/Applications/AIR Music Technology/Structure/Structure Factory Libraries'

  #
  # Air Music Technology Strike
  #-------------------------------------------
  Strike:
    dir: 'Strike'
    vendor: 'Air Music Technology'
    magic: 'krtS'
  #
  # Air Music Technology DB-33
  #-------------------------------------------
  DB_33:
    dir: 'DB-33'
    vendor: 'Air Music Technology'
    magic: '33BD'

  #
  # Air Music Technology MiniGrand
  #-------------------------------------------
  MiniGrand:
    dir: 'MiniGrand'
    vendor: 'Air Music Technology'
    magic: 'rGnM'

  #
  # Reveal Sound Spire
  #-------------------------------------------
  Spire:
    dir: 'Spire'
    vendor: 'Reveal Sound'
    magic: 'Spir'

  #
  # Reveal Sound Spire
  #-------------------------------------------
  Spire_1_1:
    dir: 'Spire-1.1'
    vendor: 'Reveal Sound'
    magic: "Spr2"

  #
  # Arturia Analog Lab
  #-------------------------------------------
  AnalogLab:
    dir: 'Analog Lab'
    vendor: 'Arturia'
    magic: "ALab"
    db: '/Library/Arturia/Analog\ Lab/Labo2.db'
    # SQL query for sound metadata
    query_sounds: '''
select
  Sounds.SoundName
  ,Sounds.SoundDesigner
  ,Instruments.InstName
  ,Types.TypeName
  ,Characteristics.CharName
from
  Sounds
  join Instruments on Sounds.InstID = Instruments.InstID
  join Types on Sounds.TypeID = Types.TypeID
  left join SoundCharacteristics on Sounds.SoundGUID = SoundCharacteristics.SoundGUID
  left join Characteristics on SoundCharacteristics.CharID = Characteristics.CharID
where
  Instruments.InstName = $InstName
  and Sounds.SoundName = $SoundName
'''
    # SQL query for multi metadata
    query_multis: '''
select
  Multis.MultiName
  ,Multis.MultiDesigner
  ,MusicGenres.MusicGenreName
from
  multis
  join MusicGenres on Multis.MusicGenreID = MusicGenres.MusicGenreID
where
  Multis.MultiName = $MultiName
'''
    # SQL query for inst mappings
    # CtrlID 0     level
    # CtrlID 1-19  assignable
    # CtrlID 20-21 Bend/Mod
    query_sound_controls_assignments: '''
select
  '0' as Priority,
  t1.CtrlID as CtrlID,
  t2.VstParamID as VstParamID,
  t2.VstParamName as VstParamName
from
  Instruments t0
  join DefaultAssignments t1 on t0.InstID = t1.InstID
  join ParameterNames t2 on t0.InstID = t2.InstID and t1.VstParamID=t2.VstParamID
where
   t1.CtrlID < 20
   and t0.InstName = $InstName
union
select
  '1' as Priority,
  t2.CtrlID as CtrlID,
  t3.VstParamID as VstParamID,
  t3.VstParamName as VstParamName
from
  Sounds t0
  join Instruments t1 on t0.InstID = t1.InstID
  join ControllerAssignments t2 on t0.SoundGUID = t2.SoundGUID
  join ParameterNames t3 on t0.InstID = t3.InstID and t2.VstParamID=t3.VstParamID
where
   t2.CtrlID < 20
   and t0.SoundName= $SoundName
   and t1.InstName = $InstName
order by Priority
'''
    # SQL query for multi mappings
    query_multi_parts_controls_assignments: '''
select
  '0' as Priority,
  t1.PartID as PartID,
  t3.CtrlID as CtrlID,
  t4.VstParamID as VstParamID,
  t4.VstParamName as VstParamName
from
  Multis t0
  join Parts t1 on t0.MultiGUID = t1.MultiGUID
  join Sounds t2 on t1.SoundGUID = t2.SoundGUID
  join DefaultAssignments t3 on t2.InstID = t3.InstID
  join ParameterNames t4 on t2.InstID = t4.InstID and t3.VstParamID=t4.VstParamID
where
  t3.CtrlID < 20
  and t0.MultiName = $MultiName
union
select
  '1' as Priority,
  t1.PartID as PartID,
  t3.CtrlID as CtrlID,
  t4.VstParamID as VstParamID,
  t4.VstParamName as VstParamName
from
  Multis t0
  join Parts t1 on t0.MultiGUID = t1.MultiGUID
  join Sounds t2 on t1.SoundGUID = t2.SoundGUID
  join ControllerAssignments t3 on t1.SoundGUID = t3.SoundGUID
  join ParameterNames t4 on t2.InstID = t4.InstID and t3.VstParamID=t4.VstParamID
where
  t3.CtrlID < 20
  and t0.MultiName = $MultiName
order by Priority
'''
    # SQL query for multi mappings
    query_multi_controls_assignments: '''
select
  '0' as Priority,
  t0.MultiCtrlID as MultiCtrlID,
  t0.MultiCtrlDestPart as MultiCtrlDestPart,
  t0.CtrlID as CtrlID
from
  MultiControlsDef t0
where
  t0.MultiCtrlID < 40
union
select
  '1' as Priority,
  t1.MultiCtrlID as MultiCtrlID,
  t1.MultiCtrlDestPart as MultiCtrlDestPart,
  t1.CtrlID as CtrlID
from
  Multis t0
  join MultiControls t1 on t0.MultiGUID = t1.MultiGUID
where
  t1.MultiCtrlID < 40
  and t0.MultiName = $MultiName
order by
  Priority
'''

  #
  # Arturia Analog Lab 2
  #-------------------------------------------
  AnalogLab2:
    dir: 'Analog Lab 2'
    vendor: 'Arturia'
    magic: 'Ala2'
    presets_dir: '/Library/Arturia/Presets'
    db: '/Library/Arturia/Presets/db.db3'
    query_preset: '''
select
  t0.name as name,
  t1.name as type,
  t2.name as inst,
  t3.name as author,
  t4.name as pack,
  t0.comment as comment,
  t6.name as characteristic
from
  Preset_Id t0
  join Types t1 on t0.type = t1.key_id
  join Instruments t2 on t0.instrument_key = t2.key_id
  join Sound_Designers t3 on t0.sound_designer = t3.key_id
  join Packs t4 on t0.pack = t4.key_id
  left outer join Preset_Characteristics t5 on t0.key_id = t5.preset_key
  left outer join Characteristics t6 on t5.characteristic_key = t6.key_id
where
  t0.file_path = $FilePath
'''
  #
  # discoDSP Discovery Pro
  #-------------------------------------------
  DiscoveryPro:
    dir: 'DiscoveryPro'
    vendor: 'discoDSP'
    magic: 'DPVx'

  #
  # u-he Hive
  #-------------------------------------------
  Hive:
    dir: 'Hive'
    vendor: 'u-he'
    magic: 'hIVE'
    presets: '/Library/Audio/Presets/u-he/Hive'

  #
  # Novation BassStation
  #-------------------------------------------
  BassStation:
    dir: 'BassStation'
    vendor: 'Novation'
    magic: 'NvB2'

  #
  # Novation V-Station
  #-------------------------------------------
  VStation:
    dir: 'VStation'
    vendor: 'Novation'
    magic: 'NvS0'

  #
  # Camel Audio Alchemy
  #-------------------------------------------
  Alchemy:
    dir: 'Alchemy'
    vendor: 'Camel Audio'
    magic: 'CaAl'
    presets: '/Library/Application Support/Camel Audio/Alchemy/Presets'
    db: '/Library/Application Support/Camel Audio/Alchemy/Alchemy_Preset_Ratings_And_Tags'
    query_items: '''
select
  t0.ITEM_NAME as name
  ,t3.ATTRIBUTE_TYPE_NAME as key
  ,t2.ATTRIBUTE_NAME as value
  ,t4.ATTRIBUTE_NAME as parentValue
from
  items as t0
  left join attributes_map t1 on t0.ITEM_ID = t1.ITEM_ID
  left join attributes t2 on t1.ATTRIBUTE_ID = t2.ATTRIBUTE_ID
  left join ATTRIBUTE_TYPES t3 on t2.ATTRIBUTE_TYPE_ID = t3.ATTRIBUTE_TYPE_ID
  left join attributes t4 on t2.ATTRIBUTES_TREE_PARENT = t4.ATTRIBUTE_ID
where
  t0.STORAGE_PATH = $preset
order by
  t2.ATTRIBUTE_ID
'''

  #
  # FabFilter Twin 2
  #-------------------------------------------
  Twin2:
    dir: 'FabFilter Twin 2'
    vendor: 'FabFilter'
    magic: 'FT2i'

  #
  # SONiVOX EightyEight
  #-------------------------------------------
  EightyEight:
    dir: 'EightyEight 2_64'
    vendor: 'SONiVOX'
    magic: 'eit2'

  #
  # Xfer Records Serum
  #-------------------------------------------
  Serum:
    dir: 'Serum'
    vendor: 'Xfer Records'
    magic: 'XfsX'
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
    .pipe gulp.dest 'lib'

gulp.task 'clean', (cb) ->
  del [
    './**/*~'
     'dist'
     'temp'
    ]
  , force: true, cb


gulp.task 'dist', [
  'velvet-dist'
  'serum-dist'
  'xpand2-dist'
  'analoglab-dist'
  'spire-dist'
  'alchemy-dist'
  'loom-dist'
  'spire_1_1-dist'
  'structure-dist'
  'strike-dist'
  'theriser-dist'
  'db33-dist'
  'minigrand-dist'
  'analoglab2-dist'
]

gulp.task 'deploy', [
  'velvet-deploy'
  'serum-deploy'
  'xpand2-deploy'
  'analoglab-deploy'
  'spire-deploy'
  'alchemy-deploy'
  'loom-deploy'
  'spire_1_1-deploy'
  'structure-deploy'
  'strike-deploy'
  'theriser-deploy'
  'db33-deploy'
  'minigrand-deploy'
  'analoglab2-deploy'
]

gulp.task 'release', [
  'velvet-release'
  'serum-release'
  'xpand2-release'
  'analoglab-release'
  'spire-release'
  'alchemy-release'
  'loom-release'
  'spire_1_1-release'
  'structure-release'
  'strike-release'
  'theriser-release'
  'db33-release'
  'minigrand-release'
  'analoglab2-release'
]

# Air Music Technology Velvet
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Velvet  2.0.6.18983
# ---------------------------------------------------------------


# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'velvet-print-default-meta', ->
  _print_default_meta $.Velvet.dir

# print mapping of _Default.nksf
gulp.task 'velvet-print-default-mapping', ->
  _print_default_mapping $.Velvet.dir

# print plugin id of _Default.nksf
gulp.task 'velvet-print-magic', ->
  _print_plid $.Velvet.dir

# generate default mapping file from _Default.nksf
gulp.task 'velvet-generate-default-mapping', ->
  _generate_default_mapping $.Velvet.dir

# extract PCHK chunk from .nksf files.
gulp.task 'velvet-extract-raw-presets', ->
  _extract_raw_presets [
    "#{$.NI.userContent}/#{$.Velvet.dir}/**/*.nksf"
    "!#{$.NI.userContent}/#{$.Velvet.dir}/_Default.nksf"
    ]
  , "src/#{$.Velvet.dir}/presets"

# generate metadata
gulp.task 'velvet-generate-meta', ->
  presets = "src/#{$.Velvet.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      # meta
      meta =
        vendor: $.Velvet.vendor
        uuid: _uuid file
        types: [
          ["Piano/Keys", "Electric Piano"]
        ]
        modes: ['Sample Based']
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Velvet', folder, '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Velvet.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'velvet-dist', [
  'velvet-dist-image'
  'velvet-dist-database'
  'velvet-dist-presets'
]

# copy image resources to dist folder
gulp.task 'velvet-dist-image', ->
  _dist_image $.Velvet.dir, $.Velvet.vendor

# copy database resources to dist folder
gulp.task 'velvet-dist-database', ->
  _dist_database $.Velvet.dir, $.Velvet.vendor

# build presets file to dist folder
gulp.task 'velvet-dist-presets', ->
  _dist_presets $.Velvet.dir, $.Velvet.magic

# check
gulp.task 'velvet-check-dist-presets', ->
  _check_dist_presets $.Velvet.dir

#
# deploy
# --------------------------------
gulp.task 'velvet-deploy', [
  'velvet-deploy-resources'
  'velvet-deploy-presets'
]

# copy resources to local environment
gulp.task 'velvet-deploy-resources', [
  'velvet-dist-image'
  'velvet-dist-database'
  ], ->
    _deploy_resources $.Velvet.dir

# copy database resources to local environment
gulp.task 'velvet-deploy-presets', [
  'velvet-dist-presets'
  ] , ->
    _deploy_presets $.Velvet.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'velvet-release',['velvet-dist'], ->
  _release $.Velvet.dir

# ---------------------------------------------------------------
# end Air Music Technology Velvet
#


# ---------------------------------------------------------------
# Air Music Technology Xpand!2
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Xpand!2  2.2.4.18852
#  - recycle bitwig presets. https://github.com/jhorology/Xpand2Pack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'xpand2-print-default-meta', ->
  _print_default_meta $.Xpand2.dir

# print mapping of _Default.nksf
gulp.task 'xpand2-print-default-mapping', ->
  _print_default_mapping $.Xpand2.dir

# print plugin id of _Default.nksf
gulp.task 'xpand2-print-magic', ->
  _print_plid $.Xpand2.dir

# generate default mapping file from _Default.nksf
gulp.task 'xpand2-generate-default-mapping', ->
  _generate_default_mapping $.Xpand2.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'xpand2-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Xpand2.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Xpand2.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# generate metadata
gulp.task 'xpand2-generate-meta', ->
  presets = "src/#{$.Xpand2.dir}/presets"
  resourceDir = _normalizeDirname $.Xpand2.dir
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      bank = if basename[0] is '+'
        'Xpand!2 Factory+'
      else
        'Xpand!2 Factory'
      # meta
      meta =
        vendor: $.Xpand2.vendor
        uuid: _uuid file
        types: [
          # remove first 3 char from folder name.
          # ex) '01 Soft Pads' -> 'Soft Pads'
          [folder[3..]]
        ]
        modes: ["Sample Based"]
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: [resourceDir, bank, '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Xpand2.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'xpand2-dist', [
  'xpand2-dist-image'
  'xpand2-dist-database'
  'xpand2-dist-presets'
]

# copy image resources to dist folder
gulp.task 'xpand2-dist-image', ->
  _dist_image $.Xpand2.dir, $.Xpand2.vendor

# copy database resources to dist folder
gulp.task 'xpand2-dist-database', ->
  _dist_database $.Xpand2.dir, $.Xpand2.vendor

# build presets file to dist folder
gulp.task 'xpand2-dist-presets', ->
  _dist_presets $.Xpand2.dir, $.Xpand2.magic

# check
gulp.task 'xpand2-check-dist-presets', ->
  _check_dist_presets $.Xpand2.dir

#
# deploy
# --------------------------------
gulp.task 'xpand2-deploy', [
  'xpand2-deploy-resources'
  'xpand2-deploy-presets'
]

# copy resources to local environment
gulp.task 'xpand2-deploy-resources', [
  'xpand2-dist-image'
  'xpand2-dist-database'
  ], ->
    _deploy_resources $.Xpand2.dir

# copy database resources to local environment
gulp.task 'xpand2-deploy-presets', [
  'xpand2-dist-presets'
  ] , ->
    _deploy_presets $.Xpand2.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'xpand2-release',['xpand2-dist'], ->
  _release $.Xpand2.dir

# ---------------------------------------------------------------
# end Air Music Technology Xpand!2
#


# ---------------------------------------------------------------
# Air Music Technology Loom
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Loom  1.0.3.18538
#  - recycle bitwig presets. https://github.com/jhorology/LoomPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'loom-print-default-meta', ->
  _print_default_meta $.Loom.dir

# print mapping of _Default.nksf
gulp.task 'loom-print-default-mapping', ->
  _print_default_mapping $.Loom.dir

# print plugin id of _Default.nksf
gulp.task 'loom-print-magic', ->
  _print_plid $.Loom.dir

# generate default mapping file from _Default.nksf
gulp.task 'loom-generate-default-mapping', ->
  _generate_default_mapping $.Loom.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'loom-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Loom.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Loom.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# generate metadata
gulp.task 'loom-generate-meta', ->
  presets = "src/#{$.Loom.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      # meta
      meta =
        vendor: $.Loom.vendor
        uuid: _uuid file
        types: [
          # remove first 3 char from folder name.
          # ex) '01 Meet Loom' -> 'Meet Loom'
          [folder[3..]]
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Loom', 'Loom Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Loom.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'loom-dist', [
  'loom-dist-image'
  'loom-dist-database'
  'loom-dist-presets'
]

# copy image resources to dist folder
gulp.task 'loom-dist-image', ->
  _dist_image $.Loom.dir, $.Loom.vendor

# copy database resources to dist folder
gulp.task 'loom-dist-database', ->
  _dist_database $.Loom.dir, $.Loom.vendor

# build presets file to dist folder
gulp.task 'loom-dist-presets', ->
  _dist_presets $.Loom.dir, $.Loom.magic

# check
gulp.task 'loom-check-dist-presets', ->
  _check_dist_presets $.Loom.dir

#
# deploy
# --------------------------------
gulp.task 'loom-deploy', [
  'loom-deploy-resources'
  'loom-deploy-presets'
]

# copy resources to local environment
gulp.task 'loom-deploy-resources', [
  'loom-dist-image'
  'loom-dist-database'
  ], ->
    _deploy_resources $.Loom.dir

# copy database resources to local environment
gulp.task 'loom-deploy-presets', [
  'loom-dist-presets'
  ] , ->
    _deploy_presets $.Loom.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'loom-release',['loom-dist'], ->
  _release $.Loom.dir

# ---------------------------------------------------------------
# end Air Music Technology Loom
#

# ---------------------------------------------------------------
# Air Music Technology Hybrid
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Hybrid  3.0.0.18468
#  - recycle bitwig presets. https://github.com/jhorology/HybridPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'hybrid-print-default-meta', ->
  _print_default_meta $.Hybrid.dir

# print mapping of _Default.nksf
gulp.task 'hybrid-print-default-mapping', ->
  _print_default_mapping $.Hybrid.dir

# print plugin id of _Default.nksf
gulp.task 'hybrid-print-magic', ->
  _print_plid $.Hybrid.dir

# generate default mapping file from _Default.nksf
gulp.task 'hybrid-generate-default-mapping', ->
  _generate_default_mapping $.Hybrid.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'hybrid-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Hybrid.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Hybrid.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# extract PCHK chunk from .nksf files.
gulp.task 'hybrid-extract-expansions-raw-presets', ->
  gulp.src ["temp/#{$.Hybrid.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.Hybrid.dir}/presets"

# generate metadata
gulp.task 'hybrid-generate-meta', ->
  presets = "src/#{$.Hybrid.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = (path.relative presets, path.dirname file.path).split path.sep
      type = if folder.length < 2 then 'Default' else folder[1][3..]
      # meta
      meta =
        vendor: $.Hybrid.vendor
        uuid: _uuid file
        types: [
          [type]
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Hybrid', folder[0], '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Hybrid.dir}/presets"

# suggest mapping
gulp.task 'hybrid-suggest-mapping', ->
  prefixes = [
    'Morph'
    'Chorus'
    'Delay'
    'Reverb'
    'PartA Filter 1'
    'PartA Filter 2'
    'PartA Filter'
    'PartA Oscillator1'
    'PartA Oscillator2'
    'PartA Oscillator3'
    'PartA Env1'
    'PartA Env2'
    'PartA EnvF'
    'PartA EnvA'
    'PartA LFO1'
    'PartA LFO2'
    'PartA LFO3'
    'PartA Pumper'
    'PartA SSeq'
    'PartA Gate'
    'PartA Note'
    'PartA Velocity'
    'PartA CtrlSeq1'
    'PartA CtrlSeq2'
    'PartA'
    'PartB Filter 1'
    'PartB Filter 2'
    'PartB Filter'
    'PartB Oscillator1'
    'PartB Oscillator2'
    'PartB Oscillator3'
    'PartB Env1'
    'PartB Env2'
    'PartB EnvF'
    'PartB EnvA'
    'PartB LFO1'
    'PartB LFO2'
    'PartB LFO3'
    'PartB Pumper'
    'PartB SSeq'
    'PartB Gate'
    'PartB Note'
    'PartB Velocity'
    'PartB CtrlSeq1'
    'PartB CtrlSeq2'
    'PartB'
    ]
  gulp.src ["src/#{$.Hybrid.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe data (file) ->
      flatList = JSON.parse file.contents.toString()
      mapping =
        ni8: []
      groups = _.groupBy flatList, (param) ->
        group = _.find prefixes, (prefix) ->
          (param.name.indexOf prefix) is 0
        group ?= 'undefined'
      console.info beautify (JSON.stringify groups), indent_size: $.json_indent
      makepages = (section, del) ->
        c = 0
        pages = []
        page = []
        for param in groups[section]
          page.push if c is 0
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section} ", '' else param.name
            section: section
            vflag: false
          else
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section} ", '' else param.name
            vflag: false
          c++
          if c is 8
            pages.push page
            page = []
            c = 0
        if c
          for i in [c...8]
            page.push
              autoname: false
              vflag: false
          pages.push page
        pages
      Array.prototype.push.apply mapping.ni8, makepages 'undefined', false
      for prefix in prefixes
        Array.prototype.push.apply mapping.ni8, makepages prefix, true
      json = beautify (JSON.stringify mapping), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      mapping
    .pipe rename basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.Hybrid.dir}/mappings"

# check mapping
gulp.task 'hybrid-check-default-mapping', ->
  gulp.src ["src/#{$.Hybrid.dir}/mappings/default.json"], read: true
    .pipe data (file) ->
      mapping = JSON.parse file.contents.toString()
      for page in mapping.ni8
        assert.ok page.length is 8, "items per page shoud be 8.\n #{JSON.stringify page}"



# ---------------------------------------------------------------
# end Air Music Technology Hybrid
#


# ---------------------------------------------------------------
# Air Music Technology VacuumPro
#
# notes
#  - Komplete Kontrol  1.5.0(R3065)
#  - VacuumPro         1.0.3.18538
#  - recycle bitwig presets. https://github.com/jhorology/HybridPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'vacuumpro-print-default-meta', ->
  _print_default_meta $.VacuumPro.dir

# print mapping of _Default.nksf
gulp.task 'vacuumpro-print-default-mapping', ->
  _print_default_mapping $.VacuumPro.dir

# print plugin id of _Default.nksf
gulp.task 'vacuumpro-print-magic', ->
  _print_plid $.VacuumPro.dir

# generate default mapping file from _Default.nksf
gulp.task 'vacuumpro-generate-default-mapping', ->
  _generate_default_mapping $.VacuumPro.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'vacuumpro-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.VacuumPro.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.VacuumPro.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# extract PCHK chunk from .nksf files.
gulp.task 'vacuumpro-extract-expansions-raw-presets', ->
  gulp.src ["temp/#{$.VacuumPro.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.VacuumPro.dir}/presets"

# generate metadata
gulp.task 'vacuumpro-generate-meta', ->
  presets = "src/#{$.VacuumPro.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = (path.relative presets, path.dirname file.path).split path.sep
      # meta
      meta = if folder[0] is 'Expansions'
        vendor: $.VacuumPro.vendor
        uuid: _uuid file
        types: [
          [folder[2][3..]]
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['VacuumPro', folder[1], '']
        author: ''
      else
        vendor: $.VacuumPro.vendor
        uuid: uid
        types: [
          [folder[0][3..]]
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['VacuumPro', 'VacuumPro Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.VacuumPro.dir}/presets"

# suggest mapping
gulp.task 'vacuumpro-suggest-mapping', ->
  prefixes = [
    'Smart'
    'Master'
    'Delay'
    'A Glide'
    'A VTO 1'
    'A VTO 2'
    'A HPF'
    'A LPF'
    'A Env 1'
    'A Env 2'
    'A Env 3'
    'A Env 4'
    'A Env'
    'A LFO 1'
    'A LFO 2'
    'A Mod 1'
    'A Mod 2'
    'A Velocity'
    'A'
    'B Glide'
    'B VTO 1'
    'B VTO 2'
    'B HPF'
    'B LPF'
    'B Env 1'
    'B Env 2'
    'B Env 3'
    'B Env 4'
    'B Env'
    'B LFO 1'
    'B LFO 2'
    'B Mod 1'
    'B Mod 2'
    'B Velocity'
    'B'
    ]
  gulp.src ["src/#{$.VacuumPro.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe data (file) ->
      flatList = JSON.parse file.contents.toString()
      mapping =
        ni8: []
      groups = _.groupBy flatList, (param) ->
        group = _.find prefixes, (prefix) ->
          (param.name.indexOf prefix) is 0
        group ?= 'undefined'
      console.info beautify (JSON.stringify groups), indent_size: $.json_indent
      makepages = (section, del) ->
        c = 0
        pages = []
        page = []
        for param in groups[section]
          page.push if c is 0
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section} ", '' else param.name
            section: section
            vflag: false
          else
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section} ", '' else param.name
            vflag: false
          if c++ is 8
            pages.push page
            page = []
            c = 0
        if c
          for i in [c...8]
            page.push
              autoname: false
              vflag: false
          pages.push page
          pages
      Array.prototype.push.apply mapping.ni8, makepages 'undefined', false
      for prefix in prefixes
        Array.prototype.push.apply mapping.ni8, makepages prefix, true
      json = beautify (JSON.stringify mapping), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      mapping
    .pipe rename basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.VacuumPro.dir}/mappings"

# check mapping
gulp.task 'vacuumpro-check-default-mapping', ->
  gulp.src ["src/#{$.VacuumPro.dir}/mappings/default.json"], read: true
    .pipe data (file) ->
      mapping = JSON.parse file.contents.toString()
      for page in mapping.ni8
        assert.ok page.length is 8, "items per page shoud be 8.\n #{JSON.stringify page}"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'vacuumpro-dist', [
  'vacuumpro-dist-image'
  'vacuumpro-dist-database'
  'vacuumpro-dist-presets'
]

# copy image resources to dist folder
gulp.task 'vacuumpro-dist-image', ->
  _dist_image $.VacuumPro.dir, $.VacuumPro.vendor

# copy database resources to dist folder
gulp.task 'vacuumpro-dist-database', ->
  _dist_database $.VacuumPro.dir, $.VacuumPro.vendor

# build presets file to dist folder
gulp.task 'vacuumpro-dist-presets', ->
  _dist_presets $.VacuumPro.dir, $.VacuumPro.magic

# check
gulp.task 'vacuumpro-check-dist-presets', ->
  _check_dist_presets $.VacuumPro.dir

#
# deploy
# --------------------------------
gulp.task 'vacuumpro-deploy', [
  'vacuumpro-deploy-resources'
  'vacuumpro-deploy-presets'
]

# copy resources to local environment
gulp.task 'vacuumpro-deploy-resources', [
  'vacuumpro-dist-image'
  'vacuumpro-dist-database'
  ], ->
    _deploy_resources $.VacuumPro.dir

# copy database resources to local environment
gulp.task 'vacuumpro-deploy-presets', [
  'vacuumpro-dist-presets'
  ] , ->
    _deploy_presets $.VacuumPro.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'vacuumpro-release',['vacuumpro-dist'], ->
  _release $.VacuumPro.dir


# ---------------------------------------------------------------
# end Air Music Technology VacuumPro
#


# ---------------------------------------------------------------
# Air Music Technology theRiser
#
# notes
#  - Komplete Kontrol  1.5.0(R3065)
#  - theRiser          *unknown
#  - recycle bitwig presets. https://github.com/jhorology/theRiserPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'theriser-print-default-meta', ->
  _print_default_meta $.theRiser.dir

# print mapping of _Default.nksf
gulp.task 'theriser-print-default-mapping', ->
  _print_default_mapping $.theRiser.dir

# print plugin id of _Default.nksf
gulp.task 'theriser-print-magic', ->
  _print_plid $.theRiser.dir

# generate default mapping file from _Default.nksf
gulp.task 'theriser-generate-default-mapping', ->
  _generate_default_mapping $.theRiser.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'theriser-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.theRiser.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.theRiser.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# extract PCHK chunk from .nksf files.
gulp.task 'theriser-extract-expansions-raw-presets', ->
  gulp.src ["temp/#{$.theRiser.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.theRiser.dir}/presets"

# generate metadata
gulp.task 'theriser-generate-meta', ->
  presets = "src/#{$.theRiser.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = (path.relative presets, path.dirname file.path).split path.sep
      # meta
      meta = if folder[0] is 'Expansions'
        vendor: $.theRiser.vendor
        uuid: _uuid file
        types: [
          ['Sound Effects']
        ]
        # gave up auto categlizing
        # modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['theRiser', folder[1], '']
        author: ''
      else
        vendor: $.theRiser.vendor
        uuid: _uuid file
        types: [
          ['Sound Effects']
        ]
        modes: [folder[0][3..]]
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['theRiser', 'theRiser Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.theRiser.dir}/presets"

# suggest mapping
gulp.task 'theriser-suggest-mapping', ->
  prefixes = [
    'Sweep Gain'
    'Sweep Freq'
    'SweepOsc Shape'
    'Noise Gain'
    'Noise Shape'
    'Noise Tune'
    'Chord Gain'
    'Chord Shape'
    'Chord Brightness'
    'Filter Freq'
    'Filter Reso'
    'Distortion'
    'Master Gain'
    'Pan'
    'Pumper'
    'Delay'
    'Reverb'
    'Effect Mix'
    'LFO A'
    'LFO B'
    'Lock'
    'Sync'
    ]
  postfixes = [
    'Decay'
    ]
  gulp.src ["src/#{$.theRiser.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe data (file) ->
      flatList = JSON.parse file.contents.toString()
      mapping =
        ni8: []
      groups = _.groupBy flatList, (param) ->
        group = _.find prefixes, (prefix) ->
          (param.name.indexOf prefix) is 0
        group ?= _.find postfixes, (postfix) ->
          (param.name.indexOf postfix) is (param.name.length - postfix.length)
        group ?= 'undefined'
      console.info beautify (JSON.stringify groups), indent_size: $.json_indent
      makepages = (section, del) ->
        c = 0
        pages = []
        page = []
        for param in groups[section]
          page.push if c is 0
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section} ", '' else param.name
            section: section
            vflag: false
          else
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section} ", '' else param.name
            vflag: false
          if c++ is 8
            pages.push page
            page = []
            c = 0
        if c
          for i in [c...8]
            page.push
              autoname: false
              vflag: false
          pages.push page
          pages
      Array.prototype.push.apply mapping.ni8, makepages 'undefined', false
      for prefix in prefixes
        Array.prototype.push.apply mapping.ni8, makepages prefix, true
      json = beautify (JSON.stringify mapping), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      mapping
    .pipe rename basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.theRiser.dir}/mappings"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'theriser-dist', [
  'theriser-dist-image'
  'theriser-dist-database'
  'theriser-dist-presets'
]

# copy image resources to dist folder
gulp.task 'theriser-dist-image', ->
  _dist_image $.theRiser.dir, $.theRiser.vendor

# copy database resources to dist folder
gulp.task 'theriser-dist-database', ->
  _dist_database $.theRiser.dir, $.theRiser.vendor

# build presets file to dist folder
gulp.task 'theriser-dist-presets', ->
  _dist_presets $.theRiser.dir, $.theRiser.magic

# check
gulp.task 'theriser-check-dist-presets', ->
  _check_dist_presets $.theRiser.dir

#
# deploy
# --------------------------------
gulp.task 'theriser-deploy', [
  'theriser-deploy-resources'
  'theriser-deploy-presets'
]

# copy resources to local environment
gulp.task 'theriser-deploy-resources', [
  'theriser-dist-image'
  'theriser-dist-database'
  ], ->
    _deploy_resources $.theRiser.dir

# copy database resources to local environment
gulp.task 'theriser-deploy-presets', [
  'theriser-dist-presets'
  ] , ->
    _deploy_presets $.theRiser.dir

#
# release
# --------------------------------

# delete third-party expansions
gulp.task 'theriser-delete-expansions',  ['theriser-dist'], (cb) ->
  del [
    "dist/#{$.theRiser.dir}/User Content/#{$.theRiser.dir}/Expansions/**"
    ]
  , force: true, cb

# release zip file to dropbox
gulp.task 'theriser-release', ['theriser-delete-expansions'], ->
  _release $.theRiser.dir

# ---------------------------------------------------------------
# end Air Music Technology theRiser
#

# ---------------------------------------------------------------
# Air Music Technology Structure
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Strike  2.06.18983
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'structure-print-default-meta', ->
  _print_default_meta $.Structure.dir

# print mapping of _Default.nksf
gulp.task 'structure-print-default-mapping', ->
  _print_default_mapping $.Structure.dir

# print plugin id of _Default.nksf
gulp.task 'structure-print-magic', ->
  _print_plid $.Structure.dir

# generate default mapping file from _Default.nksf
gulp.task 'structure-generate-default-mapping', ->
  _generate_default_mapping $.Structure.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'structure-extract-raw-presets', ->
  gulp.src ["temp/#{$.Structure.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.Structure.dir}/presets"

# generate per preset mappings
gulp.task 'structure-generate-mappings', ->
  # read default mapping template
  template = _.template (fs.readFileSync "src/#{$.Structure.dir}/mappings/default.json.tpl").toString()
  gulp.src ["#{$.Structure.libs}/**/*.patch"], read: on
    .pipe data (file) ->
      doc = new xmldom().parseFromString file.contents.toString()
      data  = {}
      for key in ['Edit1','Edit2','Edit3','Edit4','Edit5','Edit6']
        data[key] = (xpath.select "/H3Patch/H3Assign[@Source=\"#{key}\"]/@Name", doc)[0].value
      mapping = template data
      # set buffer contents
      file.contents = new Buffer mapping
      # rename .patch to .json
      file.path = "#{file.path[..-6]}json"
      file.data
    .pipe gulp.dest "src/#{$.Structure.dir}/mappings"

# generate per preset mappings
gulp.task 'structure-generate-meta', ->
  # read default mapping template
  presets = "src/#{$.Structure.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      basename = path.basename file.path, '.pchk'
      folder = path.relative presets, path.dirname file.path
      patchFile = path.join $.Structure.libs, folder, "#{basename}.patch"
      patch = new xmldom().parseFromString _readFile patchFile
      metaxml = (xpath.select "/H3Patch/MetaData/text()", patch).toString().replace /&lt;/mg, '<'
      meta = new xmldom().parseFromString metaxml
      kkmeta =
        vendor: $.Structure.vendor
        uuid: _uuid file
        types: [
          (xpath.select "/DBValueMap/category/text()", meta).toString().trim().split ': '
          ]
        name: basename.trim()
        modes: (xpath.select "/DBValueMap/keywords/text()", meta).toString().trim().split ' '
        deviceType: 'INST'
        comment: (xpath.select "/H3Patch/Comment/text()", patch).toString().trim()
        bankchain: ['Structure', 'Structure Factory', '']
        author: (xpath.select "/DBValueMap/manufacturer/text()", meta).toString().trim().split ': '
      json = beautify (JSON.stringify kkmeta), indent_size: $.json_indent
      # console.info json
      # set buffer contents
      file.contents = new Buffer json
      # rename .patch to .json
      file.path = "#{file.path[..-6]}meta"
      file.data
    .pipe gulp.dest "src/#{$.Structure.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'structure-dist', [
  'structure-dist-image'
  'structure-dist-database'
  'structure-dist-presets'
]

# copy image resources to dist folder
gulp.task 'structure-dist-image', ->
  _dist_image $.Structure.dir, $.Structure.vendor

# copy database resources to dist folder
gulp.task 'structure-dist-database', ->
  _dist_database $.Structure.dir, $.Structure.vendor

# build presets file to dist folder
gulp.task 'structure-dist-presets', ->
  _dist_presets $.Structure.dir, $.Structure.magic, (file) ->
    "./src/#{$.Structure.dir}/mappings/#{file.relative[..-5]}json"

# check
gulp.task 'structure-check-dist-presets', ->
  _check_dist_presets $.Structure.dir

#
# deploy
# --------------------------------
gulp.task 'structure-deploy', [
  'structure-deploy-resources'
  'structure-deploy-presets'
]

# copy resources to local environment
gulp.task 'structure-deploy-resources', [
  'structure-dist-image'
  'structure-dist-database'
  ], ->
    _deploy_resources $.Structure.dir

# copy database resources to local environment
gulp.task 'structure-deploy-presets', [
  'structure-dist-presets'
  ] , ->
    _deploy_presets $.Structure.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'structure-release',['structure-dist'], ->
  _release $.Structure.dir


# ---------------------------------------------------------------
# end Air Music Technology Structure
#



# ---------------------------------------------------------------
# Air Music Technology Strike
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Strike  2.06.18983
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'strike-print-default-meta', ->
  _print_default_meta $.Strike.dir

# print mapping of _Default.nksf
gulp.task 'strike-print-default-mapping', ->
  _print_default_mapping $.Strike.dir

# print plugin id of _Default.nksf
gulp.task 'strike-print-magic', ->
  _print_plid $.Strike.dir

# generate default mapping file from _Default.nksf
gulp.task 'strike-generate-default-mapping', ->
  _generate_default_mapping $.Strike.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'strike-extract-raw-presets', ->
  gulp.src ["temp/#{$.Strike.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.Strike.dir}/presets"

# generate metadata
gulp.task 'strike-generate-meta', ->
  presets = "src/#{$.Strike.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      # meta
      meta =
        vendor: $.Strike.vendor
        uuid: _uuid file
        types: [
          ['Drum']
        ]
        modes: folder.split '+'
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Strike', 'Strike Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Strike.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'strike-dist', [
  'strike-dist-image'
  'strike-dist-database'
  'strike-dist-presets'
]

# copy image resources to dist folder
gulp.task 'strike-dist-image', ->
  _dist_image $.Strike.dir, $.Strike.vendor

# copy database resources to dist folder
gulp.task 'strike-dist-database', ->
  _dist_database $.Strike.dir, $.Strike.vendor

# build presets file to dist folder
gulp.task 'strike-dist-presets', ->
  _dist_presets $.Strike.dir, $.Strike.magic

# check
gulp.task 'strike-check-dist-presets', ->
  _check_dist_presets $.Strike.dir

#
# deploy
# --------------------------------
gulp.task 'strike-deploy', [
  'strike-deploy-resources'
  'strike-deploy-presets'
]

# copy resources to local environment
gulp.task 'strike-deploy-resources', [
  'strike-dist-image'
  'strike-dist-database'
  ], ->
    _deploy_resources $.Strike.dir

# copy database resources to local environment
gulp.task 'strike-deploy-presets', [
  'strike-dist-presets'
  ] , ->
    _deploy_presets $.Strike.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'strike-release',['strike-dist'], ->
  _release $.Strike.dir

# ---------------------------------------------------------------
# end Air Music Technology Strike
#

# ---------------------------------------------------------------
# Air Music Technology DB-33
#
# notes
#  - Komplete Kontrol 1.6.2.5
#  - DB-33  1.2.7.19000
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'db33-print-default-meta', ->
  _print_default_meta $.DB_33.dir

# print mapping of _Default.nksf
gulp.task 'db33-print-default-mapping', ->
  _print_default_mapping $.DB_33.dir

# print plugin id of _Default.nksf
gulp.task 'db33-print-magic', ->
  _print_plid $.DB_33.dir

# generate default mapping file from _Default.nksf
gulp.task 'db33-generate-default-mapping', ->
  _generate_default_mapping $.DB_33.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'db33-extract-raw-presets', ->
  gulp.src ["temp/#{$.DB_33.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.DB_33.dir}/presets"

# generate metadata
gulp.task 'db33-generate-meta', ->
  presets = "src/#{$.DB_33.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      # meta
      meta =
        vendor: $.DB_33.vendor
        uuid: _uuid file
        types: [
          ['Organ']
        ]
        modes: [folder[2..]]
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['DB-33', 'DB-33 Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.DB_33.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'db33-dist', [
  'db33-dist-image'
  'db33-dist-database'
  'db33-dist-presets'
]

# copy image resources to dist folder
gulp.task 'db33-dist-image', ->
  _dist_image $.DB_33.dir, $.DB_33.vendor

# copy database resources to dist folder
gulp.task 'db33-dist-database', ->
  _dist_database $.DB_33.dir, $.DB_33.vendor

# build presets file to dist folder
gulp.task 'db33-dist-presets', ->
  _dist_presets $.DB_33.dir, $.DB_33.magic

# check
gulp.task 'db33-check-dist-presets', ->
  _check_dist_presets $.DB_33.dir

#
# deploy
# --------------------------------
gulp.task 'db33-deploy', [
  'db33-deploy-resources'
  'db33-deploy-presets'
]

# copy resources to local environment
gulp.task 'db33-deploy-resources', [
  'db33-dist-image'
  'db33-dist-database'
  ], ->
    _deploy_resources $.DB_33.dir

# copy database resources to local environment
gulp.task 'db33-deploy-presets', [
  'db33-dist-presets'
  ] , ->
    _deploy_presets $.DB_33.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'db33-release',['db33-dist'], ->
  _release $.DB_33.dir

# ---------------------------------------------------------------
# end Air Music Technology DB-33
#

# ---------------------------------------------------------------
# Air Music Technology MiniGrand
#
# notes
#  - Komplete Kontrol 1.6.2.5
#  - DB-33  1.2.7.19000
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'minigrand-print-default-meta', ->
  _print_default_meta $.MiniGrand.dir

# print mapping of _Default.nksf
gulp.task 'minigrand-print-default-mapping', ->
  _print_default_mapping $.MiniGrand.dir

# print plugin id of _Default.nksf
gulp.task 'minigrand-print-magic', ->
  _print_plid $.MiniGrand.dir

# generate default mapping file from _Default.nksf
gulp.task 'minigrand-generate-default-mapping', ->
  _generate_default_mapping $.MiniGrand.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'minigrand-extract-raw-presets', ->
  gulp.src ["temp/#{$.MiniGrand.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.MiniGrand.dir}/presets"

# generate metadata
gulp.task 'minigrand-generate-meta', ->
  presets = "src/#{$.MiniGrand.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      # meta
      meta =
        vendor: $.MiniGrand.vendor
        uuid: _uuid file
        types: [
          ['Piano']
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['MiniGrand', 'MiniGrand Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.MiniGrand.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'minigrand-dist', [
  'minigrand-dist-image'
  'minigrand-dist-database'
  'minigrand-dist-presets'
]

# copy image resources to dist folder
gulp.task 'minigrand-dist-image', ->
  _dist_image $.MiniGrand.dir, $.MiniGrand.vendor

# copy database resources to dist folder
gulp.task 'minigrand-dist-database', ->
  _dist_database $.MiniGrand.dir, $.MiniGrand.vendor

# build presets file to dist folder
gulp.task 'minigrand-dist-presets', ->
  _dist_presets $.MiniGrand.dir, $.MiniGrand.magic

# check
gulp.task 'minigrand-check-dist-presets', ->
  _check_dist_presets $.MiniGrand.dir

#
# deploy
# --------------------------------
gulp.task 'minigrand-deploy', [
  'minigrand-deploy-resources'
  'minigrand-deploy-presets'
]

# copy resources to local environment
gulp.task 'minigrand-deploy-resources', [
  'minigrand-dist-image'
  'minigrand-dist-database'
  ], ->
    _deploy_resources $.MiniGrand.dir

# copy database resources to local environment
gulp.task 'minigrand-deploy-presets', [
  'minigrand-dist-presets'
  ] , ->
    _deploy_presets $.MiniGrand.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'minigrand-release',['minigrand-dist'], ->
  _release $.MiniGrand.dir

# ---------------------------------------------------------------
# end Air Music Technology MiniGrand
#

# ---------------------------------------------------------------
# Reveal Sound Spire 1.0.x
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Spire    (*unknown version)
#  - recycle bitwig presets. https://github.com/jhorology/SpirePack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'spire-print-default-meta', ->
  _print_default_meta $.Spire.dir

# print mapping of _Default.nksf
gulp.task 'spire-print-default-mapping', ->
  _print_default_mapping $.Spire.dir

# print plugin id of _Default.nksf
gulp.task 'spire-print-magic', ->
  _print_plid $.Spire.dir

# generate default mapping file from _Default.nksf
gulp.task 'spire-generate-default-mapping', ->
  _generate_default_mapping $.Spire.dir

# extract PCHK chunk from .bwpreset files.
gulp.task 'spire-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Spire.dir}/Factory Banks/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Spire.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# generate metadata
gulp.task 'spire-generate-meta', ->
  presets = "src/#{$.Spire.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = (path.relative presets, path.dirname file.path).split path.sep
      bank = folder[0]
      type = switch
        when basename[0..3] is 'ATM '  then 'Atmosphere'
        when basename[0..2] is 'AR '   then 'Arpeggiated'
        when basename[0..3] is 'ARP '  then 'Arpeggiated'
        when basename[0..2] is 'BA '   then 'Bass'
        when basename[0..3] is 'BSQ '  then 'Bass Sequence'
        when basename[0..2] is 'CD '   then 'Chord'
        when basename[0..3] is 'CHD '  then 'Chord'
        when basename[0..2] is 'DR '   then 'Drum'
        when basename[0..2] is 'FX '   then 'FX'
        when basename[0..2] is 'GT '   then 'Gated'
        when basename[0..3] is 'KEY '  then 'Keyboard'
        when basename[0..2] is 'LD '   then 'Lead'
        when basename[0..2] is 'LV '   then 'Instrument'
        when basename[0..2] is 'OR '   then 'Organ'
        when basename[0..3] is 'ORG '  then 'Organ'
        when basename[0..2] is 'PD '   then 'Pad'
        when basename[0..2] is 'PA '   then 'Pad'
        when basename[0..2] is 'PL '   then 'Pluck'
        when basename[0..3] is 'STR '  then 'Strings'
        when basename[0..2] is 'SQ '   then 'Sequnce'
        when basename[0..2] is 'SY '   then 'Synth'
        when basename[0..3] is 'VOC '  then 'Vocal'
        when basename[0..4] is 'WIND ' then 'Winds'
        when basename[0..2] is 'SN '   then 'Siren'
        when basename[0..4] is 'Bass ' then 'Bass'
        when basename[0..4] is 'Lead ' then 'Lead'
        when basename[0..4] is 'Chord' then 'Chord'
        when (basename.indexOf ' BS ') > 0  then 'Bass'
        when (basename.indexOf ' LD ') > 0  then 'Lead'
        when (basename.indexOf ' PD ') > 0  then 'Pad'
        when (basename.indexOf ' PL ') > 0  then 'Pluck'
        when basename[-3..] is ' FX'   then 'FX'
        else 'Non-Category'

      author = switch
        when bank is 'Factory Bank 1'   then 'Reveal Sound'
        when bank is 'Factory Bank 5'   then folder[1]
        when basename[-3..] is ' AS'    then 'Adam Szabo'
        when basename[-3..] is ' AZ'    then 'Aiyn Zahev Sounds'
        when basename[-4..] is ' IPM'   then 'Ice Planet Music'
        when basename[-2..] is ' I'     then 'Invader!'
        when basename[-4..] is ' JRM'   then 'Julian Ray'
        when basename[-3..] is ' HJ'    then 'Joseph Hollo'
        when basename[-4..] is ' LUF'   then 'Luftrum'
        when basename[-3..] is ' DP'    then 'Dallaz Project'
        when basename[-4..] is ' BJP'   then 'Braian John Porter'
        when basename[-3..] is ' SK'    then 'Serhiy Klimenkov'
        when basename[-2..] is ' V'     then 'Vullcan'
        when basename[-4..] is ' VTL'   then 'Vi Ta Lee'
        when basename[-4..] is ' MLM'   then 'Mathieu Le Manson'
        when basename[-6..] is ' AL&RS' then 'Alex Larichev & Rusty Spica'
        when basename[-3..] is ' eX'    then 'E.SoX'
        else ''
      # meta
      meta =
        vendor: $.Spire.vendor
        uuid: _uuid file
        types: [
          # remove first 3 char from folder name.
          # ex) '01 Soft Pads' -> 'Soft Pads'
          [type]
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Spire', bank, '']
        author: author
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Spire.dir}/presets"


#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'spire-dist', [
  'spire-dist-image'
  'spire-dist-database'
  'spire-dist-presets'
]

# copy image resources to dist folder
gulp.task 'spire-dist-image', ->
  _dist_image $.Spire.dir, $.Spire.vendor

# copy database resources to dist folder
gulp.task 'spire-dist-database', ->
  _dist_database $.Spire.dir, $.Spire.vendor

# build presets file to dist folder
gulp.task 'spire-dist-presets', ->
  _dist_presets $.Spire.dir, $.Spire.magic

# check
gulp.task 'spire-check-dist-presets', ->
  _check_dist_presets $.Spire.dir

#
# deploy
# --------------------------------
gulp.task 'spire-deploy', [
  'spire-deploy-resources'
  'spire-deploy-presets'
]

# copy resources to local environment
gulp.task 'spire-deploy-resources', [
  'spire-dist-image'
  'spire-dist-database'
  ], ->
    _deploy_resources $.Spire.dir

# copy database resources to local environment
gulp.task 'spire-deploy-presets', [
  'spire-dist-presets'
  ] , ->
    _deploy_presets $.Spire.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'spire-release',['spire-dist'], ->
  _release $.Spire.dir

# ---------------------------------------------------------------
# end Reveal Sound Spire
#

# ---------------------------------------------------------------
# Reveal Sound Spire 1.1.x
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Spire    1.1.0
#  - Spire    1.1.8 Bank 6, Bank 7
#  - recycle bitwig presets. https://github.com/jhorology/SpirePack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'spire_1_1-print-default-meta', ->
  _print_default_meta $.Spire_1_1.dir

# print mapping of _Default.nksf
gulp.task 'spire_1_1-print-default-mapping', ->
  _print_default_mapping $.Spire_1_1.dir

# print plugin id of _Default.nksf
gulp.task 'spire_1_1-print-magic', ->
  _print_plid $.Spire_1_1.dir

# generate default mapping file from _Default.nksf
gulp.task 'spire_1_1-generate-default-mapping', ->
  _generate_default_mapping $.Spire_1_1.dir

# extract PCHK chunk from .nksf files.
gulp.task 'spire_1_1-extract-raw-presets', ->
  gulp.src ["temp/#{$.Spire_1_1.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.Spire_1_1.dir}/presets"

# generate metadata
gulp.task 'spire_1_1-generate-meta', ->
  presets = "src/#{$.Spire_1_1.dir}/presets"
  resourceDir = _normalizeDirname $.Spire_1_1.dir
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = (path.basename file.path, extname).trim()
      folder = (path.relative presets, path.dirname file.path).split path.sep
      bank = folder[0]
      type = switch
        when (basename.indexOf ' Kick ') > 0  then 'Kick'
        when basename[0..3] is 'ATM '  then 'Atmosphere'
        when basename[0..2] is 'AR '   then 'Arpeggiated'
        when basename[0..3] is 'ARP '  then 'Arpeggiated'
        when basename[0..2] is 'BA '   then 'Bass'
        when basename[0..2] is 'BS '   then 'Bass'
        when basename[0..3] is 'BSQ '  then 'Bass Sequence'
        when basename[0..2] is 'CD '   then 'Chord'
        when basename[0..3] is 'CHD '  then 'Chord'
        when basename[0..2] is 'DR '   then 'Drum'
        when basename[0..2] is 'FX '   then 'FX'
        when basename[0..3] is 'SFX '  then 'FX'
        when basename[0..2] is 'GT '   then 'Gated'
        when basename[0..3] is 'KEY '  then 'Keyboard'
        when basename[0..2] is 'LD '   then 'Lead'
        when basename[0..2] is 'LV '   then 'Instrument'
        when basename[0..2] is 'OR '   then 'Organ'
        when basename[0..3] is 'ORG '  then 'Organ'
        when basename[0..2] is 'PD '   then 'Pad'
        when basename[0..3] is 'PAD '  then 'Pad'
        when basename[0..2] is 'PA '   then 'Pad'
        when basename[0..2] is 'PL '   then 'Pluck'
        when basename[0..3] is 'PLK '  then 'Pluck'
        when basename[0..3] is 'STR '  then 'Strings'
        when basename[0..2] is 'SQ '   then 'Sequnce'
        when basename[0..3] is 'SEQ '  then 'Sequnce'
        when basename[0..2] is 'SY '   then 'Synth'
        when basename[0..3] is 'VOC '  then 'Vocal'
        when basename[0..4] is 'WIND ' then 'Winds'
        when basename[0..2] is 'SN '   then 'Siren'
        when basename[0..4] is 'Bass ' then 'Bass'
        when basename[0..4] is 'Lead ' then 'Lead'
        when basename[0..4] is 'Chord' then 'Chord'
        when (basename.indexOf ' BS ') > 0  then 'Bass'
        when (basename.indexOf ' LD ') > 0  then 'Lead'
        when (basename.indexOf ' PD ') > 0  then 'Pad'
        when (basename.indexOf ' PL ') > 0  then 'Pluck'
        when basename[-3..] is ' FX'   then 'FX'
        when basename[0..1] is '--'    then 'Default'
        else 'Non-Category'

      author = switch
        when bank is 'Factory Bank 1'   then 'Reveal Sound'
        when bank is 'Factory Bank 5'   then folder[1]
        when bank is 'Factory Bank 6' and basename[-4..] is ' HFM' then 'HFM'  # could'nt find name
        when bank is 'Factory Bank 6'   then 'Reveal Sound'
        when bank is 'Factory Bank 7'   then folder[1]
        when bank.match /^EDM Remastered/  then 'Derrek'
        when bank.match /^Andi Vax/     then 'Andi Vax'
        when basename[-3..] is ' AS'    then 'Adam Szabo'
        when basename[-3..] is ' AZ'    then 'Aiyn Zahev Sounds'
        when basename[-4..] is ' IPM'   then 'Ice Planet Music'
        when basename[-2..] is ' I'     then 'Invader!'
        when basename[-4..] is ' JRM'   then 'Julian Ray'
        when basename[-3..] is ' HJ'    then 'Joseph Hollo'
        when basename[-4..] is ' LUF'   then 'Luftrum'
        when basename[-3..] is ' DP'    then 'Dallaz Project'
        when basename[-4..] is ' BJP'   then 'Braian John Porter'
        when basename[-3..] is ' SK'    then 'Serhiy Klimenkov'
        when basename[-2..] is ' V'     then 'Vullcan'
        when basename[-4..] is ' VTL'   then 'Vi Ta Lee'
        when basename[-4..] is ' MLM'   then 'Mathieu Le Manson'
        when basename[-6..] is ' AL&RS' then 'Alex Larichev & Rusty Spica'
        when basename[-3..] is ' eX'    then 'E.SoX'
        else ''
      # meta
      meta =
        vendor: $.Spire_1_1.vendor
        uuid: _uuid file
        types: [
          # remove first 3 char from folder name.
          # ex) '01 Soft Pads' -> 'Soft Pads'
          [type]
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: [resourceDir, bank, '']
        author: author
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Spire_1_1.dir}/presets"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'spire_1_1-dist', [
  'spire_1_1-dist-image'
  'spire_1_1-dist-database'
  'spire_1_1-dist-presets'
]

# copy image resources to dist folder
gulp.task 'spire_1_1-dist-image', ->
  _dist_image $.Spire_1_1.dir, $.Spire_1_1.vendor

# copy database resources to dist folder
gulp.task 'spire_1_1-dist-database', ->
  _dist_database $.Spire_1_1.dir, $.Spire_1_1.vendor

# build presets file to dist folder
gulp.task 'spire_1_1-dist-presets', ->
  _dist_presets $.Spire_1_1.dir, $.Spire_1_1.magic

# check
gulp.task 'spire_1_1-check-dist-presets', ->
  _check_dist_presets $.Spire_1_1.dir

#
# deploy
# --------------------------------
gulp.task 'spire_1_1-deploy', [
  'spire_1_1-deploy-resources'
  'spire_1_1-deploy-presets'
]

# copy resources to local environment
gulp.task 'spire_1_1-deploy-resources', [
  'spire_1_1-dist-image'
  'spire_1_1-dist-database'
  ], ->
    _deploy_resources $.Spire_1_1.dir

# copy database resources to local environment
gulp.task 'spire_1_1-deploy-presets', [
  'spire_1_1-dist-presets'
  ] , ->
    _deploy_presets $.Spire_1_1.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'spire_1_1-release',['spire_1_1-dist'], ->
  _release $.Spire_1_1.dir

# ---------------------------------------------------------------
# end Reveal Sound Spire 1.1
#


# ---------------------------------------------------------------
# Arturia Analog Lab
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Analog Lab    (*unknown version)
#  - recycle Ableton Live Rack presets. https://github.com/jhorology/AnalogLabPack4Live
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'analoglab-print-default-meta', ->
  _print_default_meta $.AnalogLab.dir

# print mapping of _Default.nksf
gulp.task 'analoglab-print-default-mapping', ->
  _print_default_mapping $.AnalogLab.dir

# print plugin id of _Default.nksf
gulp.task 'analoglab-print-magic', ->
  _print_plid $.AnalogLab.dir

# generate default mapping file from _Default.nksf
gulp.task 'analoglab-generate-default-mapping', ->
  _generate_default_mapping $.AnalogLab.dir

# extract PCHK chunk from ableton .adg files.
gulp.task 'analoglab-extract-raw-presets', ->
  gulp.src ["#{$.Ableton.racks}/#{$.AnalogLab.dir}/**/*.adg"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.AnalogLab.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'echo "now converting file:<%= file.relative %>"'
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/adg2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# generate metadata from Analog Lab's sqlite database
gulp.task 'analoglab-generate-meta', ->
  # open database
  db = new sqlite3.Database $.AnalogLab.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.AnalogLab.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      # SQL bind parameters
      soundname = path.basename file.path, '.pchk'
      folder = path.relative "src/#{$.AnalogLab.dir}/presets", path.dirname file.path
      instname = path.dirname folder
      if instname is 'MULTI'
        # multi presets
        params =
          $MultiName: soundname
        db.all $.AnalogLab.query_multis, params, (err, rows) ->
          done err if err
          unless rows and rows.length
            return done 'row unfound in multis'
          if rows.length > 1
            return done "row duplicated in multis. rows.length:#{rows.length}"
          console.info JSON.stringify rows[0]
          done undefined,
            vendor: $.AnalogLab.vendor
            types: [['Multi']]
            name: soundname
            modes: [rows[0].MusicGenreName]
            deviceType: 'INST'
            comment: ''
            bankchain: [$.AnalogLab.dir, 'MULTI', '']
            author: rows[0].SoundDesigner?.trim()
      else
        # Instruments presets

        # funny, Arturia change preset name 'Moog' to 'Mogue' in newer version.
        db_soundname = soundname.replace 'Moog', 'Mogue'
        db_soundname = db_soundname.replace 'moog', 'mogue'
        params =
          $InstName: instname
          $SoundName: db_soundname

        # execute query
        db.all $.AnalogLab.query_sounds, params, (err, rows) ->
          done err if err
          unless rows and rows.length
            return done 'row unfound in sounds'
          done undefined,
            vendor: $.AnalogLab.vendor
            types: [[rows[0].TypeName?.trim()]]
            name: soundname
            modes: _.uniq (row.CharName for row in rows)
            deviceType: 'INST'
            comment: ''
            bankchain: [$.AnalogLab.dir, instname, '']
            author: rows[0].SoundDesigner?.trim()

    .pipe data (file) ->
      file.data.uuid = _uuid file
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      # console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      file.data
    .pipe gulp.dest "src/#{$.AnalogLab.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

# generate mapping per preset from sqlite database
gulp.task 'analoglab-generate-mappings', [
  'analoglab-generate-sound-mappings'
  'analoglab-generate-multi-mappings'
  ]

# generate sound preset mappings from sqlite database
gulp.task 'analoglab-generate-sound-mappings', ->
  # open database
  db = new sqlite3.Database $.AnalogLab.db, sqlite3.OPEN_READONLY
  gulp.src [
    "src/#{$.AnalogLab.dir}/presets/**/*.pchk"
    "!src/#{$.AnalogLab.dir}/presets/MULTI/**/*.pchk"
    ]
    .pipe data (file, done) ->
      # SQL bind parameters
      soundname = path.basename file.path, '.pchk'
      folder = path.relative "src/#{$.AnalogLab.dir}/presets", path.dirname file.path
      instname = path.dirname folder
      # Sound presets
      # funny, Arturia change preset name 'Moog' to 'Mogue' in newer version.
      db_soundname = soundname.replace 'Moog', 'Mogue'
      db_soundname = db_soundname.replace 'moog', 'mogue'
      # initialize parameter names
      paramNames = ('' for i in [0...20])
      # fetch
      db.all $.AnalogLab.query_sound_controls_assignments,
        $InstName: instname
        $SoundName: db_soundname
      , (err, rows) ->
        if err
          return done err
        unless rows and rows.length
          return done 'DefaultAssignment unfound', undefined
        for row in rows
          paramNames[row.CtrlID] = row.VstParamName
        done undefined, paramNames
    .pipe data (file) ->
      #
      template = _.template (fs.readFileSync "src/#{$.AnalogLab.dir}/mappings/default-sound.json.tpl").toString()
      json = template name: file.data
      # console.info json
      file.contents = new Buffer json
      # rename .pchk to .json
      file.path = "#{file.path[..-5]}json"
      file.data
    .pipe gulp.dest "src/#{$.AnalogLab.dir}/mappings"
    .on 'end', ->
      # colse database
      db.close()

# generate multi preset mappings from sqlite database
gulp.task 'analoglab-generate-multi-mappings', ->
  # open database
  db = new sqlite3.Database $.AnalogLab.db, sqlite3.OPEN_READONLY
  gulp.src [
    "src/#{$.AnalogLab.dir}/presets/MULTI/**/*.pchk"
    ]
    .pipe data (file, done) ->
      # SQL bind parameters
      multiName = path.basename file.path, '.pchk'
      # initialize parameter names
      partParamNames =  for i in [0...2]
        '' for i in [0...20]
      # fetch
      db.all $.AnalogLab.query_multi_parts_controls_assignments,
        $MultiName: multiName
      , (err, rows) ->
        if err
          done err
          return
        unless rows and rows.length
          done 'MultiControls unfound', undefined
          return
        for row in rows
          partParamNames[row.PartID - 1][row.CtrlID] = row.VstParamName
        db.all $.AnalogLab.query_multi_controls_assignments,
          $MultiName: multiName
        , (err, rows) ->
          multiParamNames =  ('' for i in [0...40])
          for row in rows
            multiParamNames[row.MultiCtrlID] = partParamNames[row.MultiCtrlDestPart - 1][row.CtrlID]
          done undefined, multiParamNames
    .pipe data (file) ->
      template = _.template (fs.readFileSync "src/#{$.AnalogLab.dir}/mappings/default-multi.json.tpl").toString()
      json = template name: file.data
      # console.info json
      file.contents = new Buffer json
      # rename .pchk to .json
      file.path = "#{file.path[..-5]}json"
      file.data
    .pipe gulp.dest "src/#{$.AnalogLab.dir}/mappings/MULTI"
    .on 'end', ->
      # colse database
      db.close()

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'analoglab-dist', [
  'analoglab-dist-image'
  'analoglab-dist-database'
  'analoglab-dist-presets'
]

# copy image resources to dist folder
gulp.task 'analoglab-dist-image', ->
  _dist_image $.AnalogLab.dir, $.AnalogLab.vendor

# copy database resources to dist folder
gulp.task 'analoglab-dist-database', ->
  _dist_database $.AnalogLab.dir, $.AnalogLab.vendor

# build presets file to dist folder
gulp.task 'analoglab-dist-presets', ->
  _dist_presets $.AnalogLab.dir, $.AnalogLab.magic, (file) ->
    "./src/#{$.AnalogLab.dir}/mappings/#{file.relative[..-5]}json"

# check
gulp.task 'analoglab-check-dist-presets', ->
  _check_dist_presets $.AnalogLab.dir

#
# deploy
# --------------------------------
gulp.task 'analoglab-deploy', [
  'analoglab-deploy-resources'
  'analoglab-deploy-presets'
]

# copy resources to local environment
gulp.task 'analoglab-deploy-resources', [
  'analoglab-dist-image'
  'analoglab-dist-database'
  ], ->
    _deploy_resources $.AnalogLab.dir

# copy database resources to local environment
gulp.task 'analoglab-deploy-presets', [
  'analoglab-dist-presets'
  ] , ->
    _deploy_presets $.AnalogLab.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'analoglab-release',['analoglab-dist'], ->
  _release $.AnalogLab.dir

# ---------------------------------------------------------------
# end Arturia Analog Lab
#

# ---------------------------------------------------------------
# Arturia Analog Lab 2
#
# notes
#  - Komplete Kontrol 1.5.1(R3132)
#  - Analog Lab 2  2.0.1.51
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'analoglab2-print-default-meta', ->
  _print_default_meta $.AnalogLab2.dir

# print mapping of _Default.nksf
gulp.task 'analoglab2-print-default-mapping', ->
  _print_default_mapping $.AnalogLab2.dir

# print plugin id of _Default.nksf
gulp.task 'analoglab2-print-magic', ->
  _print_plid $.AnalogLab2.dir

# generate default mapping file from _Default.nksf
gulp.task 'analoglab2-generate-default-mapping', ->
  _generate_default_mapping $.AnalogLab2.dir

# extract PCHK chunk from ableton .adg files.
gulp.task 'analoglab2-extract-raw-presets', ->
  gulp.src ["temp/#{$.AnalogLab2.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.AnalogLab2.dir}/presets"

# generate metadata from Analog Lab's sqlite database
gulp.task 'analoglab2-generate-meta', ->
  # open database
  db = new sqlite3.Database $.AnalogLab2.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.AnalogLab2.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      # SQL bind parameters
      presetName = path.basename file.path, '.pchk'
      folder = path.relative "src/#{$.AnalogLab2.dir}/presets", path.dirname file.path
      instname = path.dirname folder
      params =
        $FilePath: path.join $.AnalogLab2.presets_dir, folder, presetName
      # execute query
      db.all $.AnalogLab2.query_preset, params, (err, rows) ->
        done err if err
        unless rows and rows.length
          return done "row unfound. $FilePath:#{params.$FilePath}"
        # replace Analog Lab => MULT
        inst = rows[0].inst
        if inst is 'Analog Lab'
          inst = 'MULTI'
        done undefined,
          vendor: $.AnalogLab2.vendor
          types: [[rows[0].type?.trim()]]
          name: presetName
          modes: if rows[0].characteristic then _.uniq (row.characteristic for row in rows) else []
          deviceType: 'INST'
          comment: rows[0].comment?.trim()
          bankchain: [$.AnalogLab2.dir, inst, rows[0].pack]
          author: rows[0].author?.trim()
    .pipe data (file) ->
      file.data.uuid = _uuid file
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      # console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      file.data
    .pipe gulp.dest "src/#{$.AnalogLab2.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()
#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'analoglab2-dist', [
  'analoglab2-dist-image'
  'analoglab2-dist-database'
  'analoglab2-dist-presets'
]

# copy image resources to dist folder
gulp.task 'analoglab2-dist-image', ->
  _dist_image $.AnalogLab2.dir, $.AnalogLab2.vendor

# copy database resources to dist folder
gulp.task 'analoglab2-dist-database', ->
  _dist_database $.AnalogLab2.dir, $.AnalogLab2.vendor

# build presets file to dist folder
gulp.task 'analoglab2-dist-presets', ->
  _dist_presets $.AnalogLab2.dir, $.AnalogLab2.magic

# check
gulp.task 'analoglab2-check-dist-presets', ->
  _check_dist_presets $.AnalogLab2.dir

#
# deploy
# --------------------------------
gulp.task 'analoglab2-deploy', [
  'analoglab2-deploy-resources'
  'analoglab2-deploy-presets'
]

# copy resources to local environment
gulp.task 'analoglab2-deploy-resources', [
  'analoglab2-dist-image'
  'analoglab2-dist-database'
  ], ->
    _deploy_resources $.AnalogLab2.dir

# copy database resources to local environment
gulp.task 'analoglab2-deploy-presets', [
  'analoglab2-dist-presets'
  ] , ->
    _deploy_presets $.AnalogLab2.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'analoglab2-release',['analoglab2-dist'], ->
  _release $.AnalogLab2.dir

# ---------------------------------------------------------------
# end Arturia Analog Lab2
#

# ---------------------------------------------------------------
# discoDSP Discovery Pro
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Analog Lab    (*unknown version)
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/DiscoveryProPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'discoverypro-print-default-meta', ->
  _print_default_meta $.DiscoveryPro.dir

# print mapping of _Default.nksf
gulp.task 'discoverypro-print-default-mapping', ->
  _print_default_mapping $.DiscoveryPro.dir

# print plugin id of _Default.nksf
gulp.task 'discoverypro-print-magic', ->
  _print_plid $.DiscoveryPro.dir

# generate default mapping file from _Default.nksf
gulp.task 'discoverypro-generate-default-mapping', ->
  _generate_default_mapping $.DiscoveryPro.dir

# extract PCHK chunk from bitwig .bwpresetfiles.
gulp.task 'discoverypro-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.DiscoveryPro.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.DiscoveryPro.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# generate metadata
gulp.task 'discoverypro-generate-meta', ->
  presets = "src/#{$.DiscoveryPro.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      bank = path.relative presets, path.dirname file.path
      # meta
      meta =
        vendor: $.DiscoveryPro.vendor
        uuid: _uuid file
        types: []
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['DiscoveryPro', bank, '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.DiscoveryPro.dir}/presets"

# suggest mapping
gulp.task 'discoverypro-suggest-mapping', ->
  prefixes = [
    # layer A
    'A:Filter_'
    'A:Lfo1_'
    'A:Lfo2_'
    'A:ModEnv_'
    'A:Osc1_'
    'A:Osc2_'
    'A:Osc_'
    'A:Amp_'
    'A:Fil_'
    'A:Pan_'
    'A:Port_'
    'A:Delay_'
    'A:Dly_'
    'A:L_Dly_'
    'A:R_Dly_'
    'A:Gat_'
    'A:Mod_'
    'A:Wave_'
    'A:Misc_'
    'A:'
    # layer B
    'B:Filter_'
    'B:Lfo1_'
    'B:Lfo2_'
    'B:ModEnv_'
    'B:Osc1_'
    'B:Osc2_'
    'B:Osc_'
    'B:Amp_'
    'B:Fil_'
    'B:Pan_'
    'B:Port_'
    'B:Delay_'
    'B:Dly_'
    'B:L_Dly_'
    'B:R_Dly_'
    'B:Gat_'
    'B:Mod_'
    'B:Wave_'
    'B:Misc_'
    'B:'
    # layer C
    'C:Filter_'
    'C:Lfo1_'
    'C:Lfo2_'
    'C:ModEnv_'
    'C:Osc1_'
    'C:Osc2_'
    'C:Osc_'
    'C:Amp_'
    'C:Fil_'
    'C:Pan_'
    'C:Port_'
    'C:Dly_'
    'C:Delay_'
    'C:L_Dly_'
    'C:R_Dly_'
    'C:Gat_'
    'C:Mod_'
    'C:Wave_'
    'C:Misc_'
    'C:'
    # layer D
    'D:Filter_'
    'D:Lfo1_'
    'D:Lfo2_'
    'D:ModEnv_'
    'D:Osc1_'
    'D:Osc2_'
    'D:Osc_'
    'D:Amp_'
    'D:Fil_'
    'D:Pan_'
    'D:Port_'
    'D:Delay_'
    'D:Dly_'
    'D:L_Dly_'
    'D:R_Dly_'
    'D:Gat_'
    'D:Mod_'
    'D:Wave_'
    'D:Misc_'
    'D:'
    ]
  gulp.src ["src/#{$.DiscoveryPro.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe data (file) ->
      flatList = JSON.parse file.contents.toString()
      mapping =
        ni8: []
      groups = _.groupBy flatList, (param) ->
        group = _.find prefixes, (prefix) ->
          (param.name.indexOf prefix) is 0
        group ?= 'undefined'
      console.info beautify (JSON.stringify groups), indent_size: $.json_indent
      makepages = (section, del) ->
        c = 0
        pages = []
        page = []
        for param in groups[section]
          page.push if c is 0
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section}", '' else param.name
            section: section.replace /_$/, ''
            vflag: false
          else
            autoname: false
            id: parseInt param.id[14..]
            name: if del then param.name.replace "#{section}", '' else param.name
            vflag: false
          if c++ is 8
            pages.push page
            page = []
            c = 0
        if c
          for i in [c...8]
            page.push
              autoname: true
              vflag: false
          pages.push page
          pages
      for prefix in prefixes
        Array.prototype.push.apply mapping.ni8, makepages prefix, true
      json = beautify (JSON.stringify mapping), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      mapping
    .pipe rename basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.DiscoveryPro.dir}/mappings"


# check mapping
gulp.task 'discoverypro-check-default-mapping', ->
  gulp.src ["src/#{$.DiscoveryPro.dir}/mappings/default.json"], read: true
    .pipe data (file) ->
      mapping = JSON.parse file.contents.toString()
      for page in mapping.ni8
        assert.ok page.length is 8, "items per page shoud be 8.\n #{JSON.stringify page}"

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'discoverypro-dist', [
  'discoverypro-dist-image'
  'discoverypro-dist-database'
  'discoverypro-dist-presets'
]

# copy image resources to dist folder
gulp.task 'discoverypro-dist-image', ->
  _dist_image $.DiscoveryPro.dir, $.DiscoveryPro.vendor

# copy database resources to dist folder
gulp.task 'discoverypro-dist-database', ->
  _dist_database $.DiscoveryPro.dir, $.DiscoveryPro.vendor

# build presets file to dist folder
gulp.task 'discoverypro-dist-presets', ->
  _dist_presets $.DiscoveryPro.dir, $.DiscoveryPro.magic

# check
gulp.task 'discoverypro-check-dist-presets', ->
  _check_dist_presets $.DiscoveryPro.dir

#
# deploy
# --------------------------------
gulp.task 'discoverypro-deploy', [
  'discoverypro-deploy-resources'
  'discoverypro-deploy-presets'
]

# copy resources to local environment
gulp.task 'discoverypro-deploy-resources', [
  'discoverypro-dist-image'
  'discoverypro-dist-database'
  ], ->
    _deploy_resources $.DiscoveryPro.dir

# copy database resources to local environment
gulp.task 'discoverypro-deploy-presets', [
  'discoverypro-dist-presets'
  ] , ->
    _deploy_presets $.DiscoveryPro.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'discoverypro-release',['discoverypro-dist'], ->
  _release $.DiscoveryPro.dir

# ---------------------------------------------------------------
# end discoDSP Discovery Pro
#


# ---------------------------------------------------------------
# u-he Hive
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Hive   1.0 revision 3514
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/HivePack4Bitwig
#  - recycle Ableton Racks. https://github.com/jhorology/HivePack4Live
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'hive-print-default-meta', ->
  _print_default_meta $.Hive.dir

# print mapping of _Default.nksf
gulp.task 'hive-print-default-mapping', ->
  _print_default_mapping $.Hive.dir

# print plugin id of _Default.nksf
gulp.task 'hive-print-magic', ->
  _print_plid $.Hive.dir

# generate default mapping file from _Default.nksf
gulp.task 'hive-generate-default-mapping', ->
  _generate_default_mapping $.Hive.dir

# extract PCHK chunk from bitwig .bwpresetfiles.
gulp.task 'hive-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.Hive.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Hive.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# extract PCHK chunk from .nksf files.
gulp.task 'hive-extract-raw-presets-nksf', ->
  gulp.src ["temp/#{$.Hive.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.Hive.dir}/presets"

gulp.task 'hive-check-presets-h2p', ->
  presets = "src/#{$.Hive.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      relative = path.relative presets, path.dirname file.path
      hivePreset = path.join $.Hive.presets, relative, "#{basename}.h2p"
      if not fs.existsSync hivePreset
        console.info "#{relative}/#{basename}.h2p not found."

gulp.task 'hive-check-presets-pchk', ->
  presets = "#{$.Hive.presets}"
  gulp.src ["#{$.Hive.presets}/**/*.h2p"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      relative = path.relative presets, path.dirname file.path
      pchkPreset = path.join "src/#{$.Hive.dir}/presets", relative, "#{basename}.pchk"
      if not fs.existsSync pchkPreset
        console.info "#{relative}/#{basename}.pchk not found."

# extract PCHK chunk from ableton .adg files.
gulp.task 'hive-extract-extra-raw-presets', ->
  gulp.src ["#{$.Ableton.racks}/#{$.Hive.dir}/TREASURE TROVE/**/*.adg"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.Hive.dir}/presets/TREASURE TROVE/", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'echo "now converting file:<%= file.relative %>"'
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/adg2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts


# suggest mapping
gulp.task 'hive-suggest-mapping', ->
  gulp.src ["src/#{$.Hive.dir}/mappings/bitwig-direct-paramater.json"], read: true
    .pipe data (file) ->
      lastSection = undefined
      pages = []
      page = []
      fillPage = (page) ->
        while page.length < 8
          page.push
            autoname: false
            vflag: false
        page
      for param in JSON.parse file.contents.toString()
        section = (param.name.split ':')[0]
        if section isnt lastSection and (_.isArray page) and page.length
          pages.push fillPage page
          page = []
        page.push if page.length is 0
          autoname: false
          id: parseInt param.id[14..]
          name: param.name.replace "#{section}: ", ''
          section: section
          vflag: false
        else
          autoname: false
          id: parseInt param.id[14..]
          name: param.name.replace "#{section}: ", ''
          vflag: false
        if page.length is 8
          pages.push page
          page = []
        lastSection = section
      pages.push fillPage page if page.length

      json = beautify (JSON.stringify ni8: pages), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
    .pipe rename basename: 'default-suggest'
    .pipe gulp.dest "src/#{$.Hive.dir}/mappings"

# check mapping
gulp.task 'hive-check-default-mapping', ->
  gulp.src ["src/#{$.Hive.dir}/mappings/default.json"], read: true
    .pipe data (file) ->
      mapping = JSON.parse file.contents.toString()
      for page in mapping.ni8
        assert.ok page.length is 8, "items per page shoud be 8.\n #{JSON.stringify page}"

# generate metadata
gulp.task 'hive-generate-meta', ->
  presets = "src/#{$.Hive.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      relative = path.relative presets, path.dirname file.path
      folder = relative.split path.sep
      hivePreset = path.join $.Hive.presets, relative, "#{basename}.h2p"
      hiveMeta = hiveParser.parse hivePreset
      bank = switch
        when folder[0].match /^[0-9][0-9] / then 'Hive Factory'
        when not folder[0] then 'Hive Preview'
        else folder[0]
      subBank = if folder.length is 2 then folder[1] else ''
      # meta
      meta =
        vendor: $.Hive.vendor
        uuid: _uuid file
        types: []
        modes: []
        name: basename
        deviceType: 'INST'
        bankchain: ['Hive', bank, subBank]
      meta.types = [[folder[0][3..]]] if bank is 'Hive Factory'
      meta.author = hiveMeta.Author.trim() if hiveMeta?.Author
      meta.comment = hiveMeta.Description.trim() if hiveMeta?.Description
      meta.comment = '' if not hiveMeta?.Description and hiveMeta?.Usage
      meta.comment += '\n' if hiveMeta?.Description and hiveMeta?.Usage
      meta.comment += "Usage:\n#{hiveMeta.Usage}" if hiveMeta?.Usage

      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info "##### meta:#{json}"
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.Hive.dir}/presets"



# ---------------------------------------------------------------
# end u-he Hive Pro
#


# ---------------------------------------------------------------
# Novation BassStation
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - BassStation  2.1
#  - recycle Bitwig Sttudio presets. https://github.com/jhorology/BassStationPack4Bitwig
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'bassstation-print-default-meta', ->
  _print_default_meta $.BassStation.dir

# print mapping of _Default.nksf
gulp.task 'bassstation-print-default-mapping', ->
  _print_default_mapping $.BassStation.dir

# print plugin id of _Default.nksf
gulp.task 'bassstation-print-magic', ->
  _print_plid $.BassStation.dir

# generate default mapping file from _Default.nksf
gulp.task 'bassstation-generate-default-mapping', ->
  _generate_default_mapping $.BassStation.dir

# extract PCHK chunk from bitwig .bwpresetfiles.
gulp.task 'bassstation-extract-raw-presets', ->
  gulp.src ["#{$.Bitwig.presets}/#{$.BassStation.dir}/**/*.bwpreset"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      dirname = path.join "src/#{$.BassStation.dir}/presets", path.dirname file.relative
      destDir: dirname
      destPath: path.join dirname, "#{basename}.pchk"
    .pipe exec [
      'mkdir -p "<%= file.data.destDir %>"'
      'tools/bwpreset2pchk "<%= file.path%>" "<%= file.data.destPath %>"'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

# generate metadata
gulp.task 'bassstation-generate-meta', ->
  presets = "src/#{$.BassStation.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, path.extname file.path
      # meta
      meta =
        vendor: $.BassStation.vendor
        uuid: _uuid file
        types: [
          ['Bass']
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['BassStation', 'BassStation Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.BassStation.dir}/presets"

# ---------------------------------------------------------------
# end Novation Bassstation
#

# ---------------------------------------------------------------
# Novation V-Station
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - V-Station  2.3
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'vstation-print-default-meta', ->
  _print_default_meta $.VStation.dir

# print mapping of _Default.nksf
gulp.task 'vstation-print-default-mapping', ->
  _print_default_mapping $.VStation.dir

# print plugin id of _Default.nksf
gulp.task 'vstation-print-magic', ->
  _print_plid $.VStation.dir

# generate default mapping file from _Default.nksf
gulp.task 'vstation-generate-default-mapping', ->
  _generate_default_mapping $.VStation.dir

# extract PCHK chunk from .nksf files.
gulp.task 'vstation-extract-raw-presets', ->
  gulp.src ["temp/#{$.VStation.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.VStation.dir}/presets"

gulp.task 'vstation-generate-meta', ->
  presets = "src/#{$.VStation.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      type = basename.replace /^[0-9]+ /, ''
      type = type.replace /[ ,0-9]+$/, ''
      # meta
      meta =
        vendor: $.VStation.vendor
        uuid: _uuid file
        types: [
          [type]
        ]
        modes: []
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['VStation', 'VStation Factory', '']
        author: ''
      json = beautify (JSON.stringify meta), indent_size: $.json_indent
      console.info json
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      meta
    .pipe gulp.dest "src/#{$.VStation.dir}/presets"

# ---------------------------------------------------------------
# end Novation V-Station
#


# ---------------------------------------------------------------
# Camel Audio Alchemy
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Alchemy(Player)  1.55.0P
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'alchemy-print-default-meta', ->
  _print_default_meta $.Alchemy.dir

# print mapping of _Default.nksf
gulp.task 'alchemy-print-default-mapping', ->
  _print_default_mapping $.Alchemy.dir

# print plugin id of _Default.nksf
gulp.task 'alchemy-print-magic', ->
  _print_plid $.Alchemy.dir

# generate default mapping file from _Default.nksf
gulp.task 'alchemy-generate-default-mapping', ->
  _generate_default_mapping $.Alchemy.dir

# extract PCHK chunk from .nksf files.
gulp.task 'alchemy-extract-raw-presets', ->
  gulp.src ["temp/#{$.Alchemy.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.Alchemy.dir}/presets"


# generate per preset mappings
#
# *.acp is text file, contain control assignmnets as follow:
# Cont1Lbl = VibratOo
# Cont2Lbl = FltDecay
# Cont3Lbl = SymReZ
# Cont4Lbl = EVF1depth
# Cont5Lbl = Comp On
# Cont6Lbl = CompRel
# Cont7Lbl = CoffSet--
# Cont8Lbl = Amp
# XyPad1x = Curved
# XyPad1y = EQ
# XyPad2x = Thinner
# XyPad2y =
gulp.task 'alchemy-generate-mappings', ->
  # read default mapping template
  template = _.template (fs.readFileSync "src/#{$.Alchemy.dir}/mappings/default.json.tpl").toString()
  gulp.src ["#{$.Alchemy.presets}/**/*.acp"], read: on
    .pipe data (file) ->
      preset = file.contents.toString()
      match = /(Cont1Lbl =[\s\S]*?XyPad2y = [\s\S]*?\n)/.exec preset
      # convert json style
      regexp = / = (.*$)/gm
      assignments = match[1].replace regexp, ": \"$1\","
      # some presets headig '_' e.g '_XyPad1x'
      assignments = assignments.replace /_XyPad/g, 'XyPad'
      # string to object
      console.info "({#{assignments}})"
      assignments = eval "({#{assignments}})"
      mapping = template assignments
      # set buffer contents
      file.contents = new Buffer mapping
      # rename .acp to .json
      file.path = "#{file.path[..-4]}json"
      file.data
    .pipe gulp.dest "src/#{$.Alchemy.dir}/mappings"


# generate metadata from serum's sqlite database
gulp.task 'alchemy-generate-meta', ->
  # open database
  db = new sqlite3.Database $.Alchemy.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.Alchemy.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      bank = file.relative.replace /(\/.*$)/, ''
      # execute query
      db.all $.Alchemy.query_items, $preset: "Alchemy/Presets/#{file.relative[..-5]}acp", (err, rows) ->
        unless rows and rows.length
          return done "record not found in database. preset:#{file.relative}"
        author = ''
        types = []
        modes = []
        for row in rows
          switch row.key
            when 'Category'
              types.push [row.value]
            when 'Subcategory'
              types.push [row.parentValue, row.value]
            when 'Timber'
              modes.push row.value
            when 'Genre'
              modes.push row.value
            when 'Articulation'
              modes.push row.value
            when 'Sound Designer'
              author = row.value
            else
        done undefined,
          vendor: $.Alchemy.vendor
          types: types
          name: rows[0].name
          modes: _.uniq modes
          deviceType: 'INST'
          comment: ''
          bankchain: ['Alchemy', bank, '']
          author: author
    .pipe data (file) ->
      file.data.uuid = _uuid file
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      file.contents = new Buffer json
      # rename .acp to .meta
      file.path = "#{file.path[..-5]}meta"
      file.data
    .pipe gulp.dest "src/#{$.Alchemy.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'alchemy-dist', [
  'alchemy-dist-image'
  'alchemy-dist-database'
  'alchemy-dist-presets'
]

# copy image resources to dist folder
gulp.task 'alchemy-dist-image', ->
  _dist_image $.Alchemy.dir, $.Alchemy.vendor

# copy database resources to dist folder
gulp.task 'alchemy-dist-database', ->
  _dist_database $.Alchemy.dir, $.Alchemy.vendor

# build presets file to dist folder
gulp.task 'alchemy-dist-presets', ->
  _dist_presets $.Alchemy.dir, $.Alchemy.magic, (file) ->
    "./src/#{$.Alchemy.dir}/mappings/#{file.relative[..-5]}json"

# check
gulp.task 'alchemy-check-dist-presets', ->
  _check_dist_presets $.Alchemy.dir

#
# deploy
# --------------------------------
gulp.task 'alchemy-deploy', [
  'alchemy-deploy-resources'
  'alchemy-deploy-presets'
]

# copy resources to local environment
gulp.task 'alchemy-deploy-resources', [
  'alchemy-dist-image'
  'alchemy-dist-database'
  ], ->
    _deploy_resources $.Alchemy.dir

# copy database resources to local environment
gulp.task 'alchemy-deploy-presets', [
  'alchemy-dist-presets'
  ] , ->
    _deploy_presets $.Alchemy.dir

#
# release
# --------------------------------

# delete third-party libs
gulp.task 'alchemy-delete-thirdparty-libs',  ['alchemy-dist'], (cb) ->
  del [
    "dist/#{$.Alchemy.dir}/User Content/#{$.Alchemy.dir}/**"
    "!dist/#{$.Alchemy.dir}/User Content/#{$.Alchemy.dir}"
    "!dist/#{$.Alchemy.dir}/User Content/#{$.Alchemy.dir}/Factory/**"
    ]
  , force: true, cb

# release zip file to dropbox
gulp.task 'alchemy-release', ['alchemy-delete-thirdparty-libs'], ->
  _release $.Alchemy.dir

# ---------------------------------------------------------------
# end Camel Audio Alchemy
#


# ---------------------------------------------------------------
# FabFilter Twin 2
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - FabFilter Twin 2 2.23
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'twin2-print-default-meta', ->
  _print_default_meta $.Twin2.dir

# print mapping of _Default.nksf
gulp.task 'twin2-print-default-mapping', ->
  _print_default_mapping $.Twin2.dir

# print plugin id of _Default.nksf
gulp.task 'twin2-print-magic', ->
  _print_plid $.Twin2.dir

# generate default mapping file from _Default.nksf
gulp.task 'twin2-generate-default-mapping', ->
  _generate_default_mapping $.Twin2.dir

# extract PCHK chunk from .nksf
gulp.task 'twin2-extract-raw-presets', ->
  gulp.src ["temp/#{$.Twin2.dir}/**/*.nksf.new"]
    .pipe extract
      chunk_ids: ['PCHK']
      filename_template: "<%= basename.substring(0,basename.length-5) %><%= count ? '_' + count : '' %>.<%= id.trim().toLowerCase() %>"
    .pipe gulp.dest "src/#{$.Twin2.dir}/presets"

# ---------------------------------------------------------------
# end FabFilter Twin2
#

# ---------------------------------------------------------------
# SONiVOX EightyEight
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - EightyEight Twin Version 2.3 Build 2.5.0.15
# ---------------------------------------------------------------

# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'eightyeight-print-default-meta', ->
  _print_default_meta $.EightyEight.dir

# print mapping of _Default.nksf
gulp.task 'eightyeight-print-default-mapping', ->
  _print_default_mapping $.EightyEight.dir

# print plugin id of _Default.nksf
gulp.task 'eightyeight-print-magic', ->
  _print_plid $.EightyEight.dir

# generate default mapping file from _Default.nksf
gulp.task 'eightyeight-generate-default-mapping', ->
  _generate_default_mapping $.EightyEight.dir

# extract PCHK chunk from .mksf files.
gulp.task 'eightyeight-extract-raw-presets', ->
  gulp.src ["temp/#{$.EightyEight.dir}/**/*.nksf"]
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest "src/#{$.EightyEight.dir}/presets"


# ---------------------------------------------------------------
# end SONiVOX EightyEight
#


# Xfer Record Serum
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Serum  1.073 Oct 5 2015
# ---------------------------------------------------------------

#
# preparing tasks
# --------------------------------

# print metadata of _Default.nksf
gulp.task 'serum-print-default-meta', ->
  _print_default_meta $.Serum.dir

# print mapping of _Default.nksf
gulp.task 'serum-print-default-mapping', ->
  _print_default_mapping $.Serum.dir

# print plugin id of _Default.nksf
gulp.task 'serum-print-magic', ->
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
          vendor: $.Serum.vendor
          types: [[row.Category?.trim()]]
          name: row.PresetDisplayName?.trim()
          deviceType: 'INST'
          comment: row.Description?.trim()
          bankchain: ['Serum', 'Serum Factory', '']
          author: row.Author?.trim()
    .pipe data (file) ->
      file.data.uuid = _uuid file
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      file.contents = new Buffer json
      # rename .pchk to .meta
      file.path = "#{file.path[..-5]}meta"
      file.data
    .pipe gulp.dest "src/#{$.Serum.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task 'serum-dist', [
  'serum-dist-image'
  'serum-dist-database'
  'serum-dist-presets'
]

# copy image resources to dist folder
gulp.task 'serum-dist-image', ->
  _dist_image $.Serum.dir, $.Serum.vendor

# copy database resources to dist folder
gulp.task 'serum-dist-database', ->
  _dist_database $.Serum.dir, $.Serum.vendor

# build presets file to dist folder
gulp.task 'serum-dist-presets', ->
  _dist_presets $.Serum.dir, $.Serum.magic

# check
gulp.task 'serum-check-dist-presets', ->
  _check_dist_presets $.Serum.dir

#
# deploy
# --------------------------------
gulp.task 'serum-deploy', [
  'serum-deploy-resources'
  'serum-deploy-presets'
]

# copy resources to local environment
gulp.task 'serum-deploy-resources', [
  'serum-dist-image'
  'serum-dist-database'
  ], ->
    _deploy_resources $.Serum.dir

# copy database resources to local environment
gulp.task 'serum-deploy-presets', [
  'serum-dist-presets'
  ] , ->
    _deploy_presets $.Serum.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task 'serum-release',['serum-dist'], ->
  _release $.Serum.dir

# ---------------------------------------------------------------
# end Xfer Record Serum



# common routines
# ---------------------------------------------------------------

#
# utility
# --------------------------------

# desrilize to json string
_deserialize = (file) ->
  ver = file.contents.readUInt32LE 0
  assert.ok (ver is $.chunkVer), "Unsupported chunk format version. version:#{ver}"
  json = msgpack.decode file.contents.slice 4
  beautify (JSON.stringify json), indent_size: $.json_indent

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


# generate or reuse uuid
_uuid = (pchkFile) ->
  metaFile = "#{pchkFile.path[..-5]}meta"
  if fs.existsSync metaFile
    (_readJson metaFile).uuid || uuid.v4()
  else
    uuid.v4()

# read JSON file
_readJson = (filePath) ->
  JSON.parse _readFile filePath

# read file as String
_readFile = (filePath) ->
  fs.readFileSync filePath, "utf8"

# resource dirname can't use ".", "!"
_normalizeDirname = (dir) ->
  dir.replace /[\.\!]/, ' '

#
# prepair
# --------------------------------

# generate default parameter mapping file
_generate_default_mapping = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe changed "src/#{dir}/mappings",
      hasChanged: (stream, cb, file, dest) ->
        dest = path.join (path.dirname dest), 'default.json'
        changed.compareLastModifiedTime stream, cb, file, dest
    .pipe extract
      chunk_ids: ['NICA']
      filename_template: "default.json"
    .pipe data (file) ->
      file.contents = new Buffer _deserialize file
    .pipe gulp.dest "src/#{dir}/mappings"

# print default NISI chunk as JSON
_print_default_meta = (dir) ->
  console.info "#{$.NI.userContent}/#{dir}/_Default.nksf"
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      chunk_ids: ['NISI']
    .pipe data (file) ->
      console.info _deserialize file

# print default NACA chunk as JSON
_print_default_mapping = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      chunk_ids: ['NICA']
    .pipe data (file) ->
      console.info _deserialize file

# print PLID chunk as JSON
_print_plid = (dir) ->
  gulp.src ["#{$.NI.userContent}/#{dir}/_Default.nksf"]
    .pipe extract
      chunk_ids: ['PLID']
    .pipe data (file) ->
      magic = _deserializeMagic file
      console.info "magic: '#{magic}'"

# extract PCHK chunk
_extract_raw_presets = (srcs, dest) ->
  gulp.src srcs
    .pipe extract
      chunk_ids: ['PCHK']
    .pipe gulp.dest dest

#
# dist
# --------------------------------

# copy image resources to dist folder
_dist_image = (dir, vendor) ->
  gulp.src ["src/#{dir}/resources/image/**/*.{json,meta,png}"]
    .pipe gulp.dest "dist/#{dir}/NI Resources/image/#{vendor.toLowerCase()}/#{_normalizeDirname dir.toLowerCase()}"

# copy database resources to dist folder
_dist_database = (dir, vendor) ->
  gulp.src ["src/#{dir}/resources/dist_database/**/*.{json,meta,png}"]
    .pipe gulp.dest "dist/#{dir}/NI Resources/dist_database/#{vendor.toLowerCase()}/#{_normalizeDirname dir.toLowerCase()}"

# build presets file to dist folder
# callback(file) optional, provide per preset mapping filepath.
_dist_presets = (dir, magic, callback) ->
  presets = "src/#{dir}/presets"
  mappings = "./src/#{dir}/mappings"
  dist = "dist/#{dir}/User Content/#{dir}"
  defaultMapping = undefined
  unless _.isFunction callback
    defaultMapping = _serialize require "#{mappings}/default.json"
  pluginId = _serializeMagic magic
  gulp.src ["#{presets}/**/*.pchk"], read: true
    .pipe data (file) ->
      mapping = defaultMapping
      if _.isFunction callback
        mapping = _serialize require callback file
      riff = builder 'NIKS'
      # NISI chunk -- metadata
      meta = _serialize _readJson "#{presets}/#{file.relative[..-5]}meta"
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
_check_dist_presets = (dir, PLID) ->
  dist = "dist/#{dir}/User Content/#{dir}"
  gulp.src ["#{dist}/**/*.nksf"], read: true
    .pipe extract
      chunk_ids: ['NISI', 'NICA', 'PLID']
    .pipe data (file) ->
      console.info _deserialize file
#
# deploy
# --------------------------------

# copy resources to local environment
_deploy_resources = (dir) ->
  gulp.src ["dist/#{dir}/NI Resources/**/*.{json,meta,png}"]
    .pipe gulp.dest $.NI.resources

# copy presets to local environment
_deploy_presets = (dir) ->
  gulp.src ["dist/#{dir}/User Content/**/*.nksf"]
    .pipe gulp.dest $.NI.userContent

#
# release
# --------------------------------

# zip dist file and copy to dropbox.
_release = (dir) ->
  gulp.src ["dist/#{dir}/**/*.{json,meta,png,nksf}"]
    .pipe zip "#{dir}.zip"
    .pipe gulp.dest $.release
