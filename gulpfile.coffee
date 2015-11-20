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
msgpack     = require 'msgpack-lite'
builder     = require './lib/riff-builder'
beautify    = require 'js-beautify'
uuid        = require 'uuid'

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
    
  #
  # Air Music Technology Strike
  #-------------------------------------------
  Strike:
    dir: 'Strike'
    vendor: 'Air Music Technology'
    magic: 'krtS'

  #
  # Reveal Sound Spire
  #-------------------------------------------
  Spire:
    dir: 'Spire'
    vendor: 'Reveal Sound'
    magic: "Spir"

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
]

gulp.task 'deploy', [
  'velvet-deploy'
  'serum-deploy'
  'xpand2-deploy'
  'analoglab-deploy'
  'spire-deploy'
  'alchemy-deploy'
  'loom-deploy'
]

gulp.task 'release', [
  'velvet-release'
  'serum-release'
  'xpand2-release'
  'analoglab-release'
  'spire-release'
  'alchemy-release'
  'loom-release'
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
        uuid: uuid.v4()
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
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      metafile = "#{file.path[..-5]}meta"
      uid = if fs.existsSync metafile
        (_require_meta metafile).uuid
      else
        uuid.v4()
      bank = if basename[0] is '+'
        'Xpand!2 Factory+'
      else
        'Xpand!2 Factory'
      # meta
      meta =
        vendor: $.Xpand2.vendor
        uuid: uid
        types: [
          # remove first 3 char from folder name.
          # ex) '01 Soft Pads' -> 'Soft Pads'
          [folder[3..]]
        ]
        modes: ["Sample Based"]
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: ['Xpand!2', bank, '']
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
      metafile = "#{file.path[..-5]}meta"
      uid = if fs.existsSync metafile
        (_require_meta metafile).uuid
      else
        uuid.v4()
      # meta
      meta =
        vendor: $.Loom.vendor
        uuid: uid
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

# generate metadata
gulp.task 'hybrid-generate-meta', ->
  presets = "src/#{$.Hybrid.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = (path.relative presets, path.dirname file.path).split path.sep
      type = if folder.length < 2 then 'Default' else folder[1][3..]
      metafile = "#{file.path[..-5]}meta"
      uid = if fs.existsSync metafile
        (_require_meta metafile).uuid
      else
        uuid.v4()
      # meta
      meta =
        vendor: $.Hybrid.vendor
        uuid: uid
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

# generate metadata
gulp.task 'vacuumpro-generate-meta', ->
  presets = "src/#{$.VacuumPro.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      metafile = "#{file.path[..-5]}meta"
      uid = if fs.existsSync metafile
        (_require_meta metafile).uuid
      else
        uuid.v4()
      # meta
      meta =
        vendor: $.VacuumPro.vendor
        uuid: uid
        types: [
          [folder[3..]]
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

# generate metadata
gulp.task 'theriser-generate-meta', ->
  presets = "src/#{$.theRiser.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      metafile = "#{file.path[..-5]}meta"
      uid = if fs.existsSync metafile
        (_require_meta metafile).uuid
      else
        uuid.v4()
      # meta
      meta =
        vendor: $.theRiser.vendor
        uuid: uid
        types: [
          [folder[3..]]
        ]
        modes: []
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

# generate metadata
gulp.task 'strike-generate-meta', ->
  presets = "src/#{$.Strike.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe data (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      folder = path.relative presets, path.dirname file.path
      metafile = "#{file.path[..-5]}meta"
      uid = if fs.existsSync metafile
        (_require_meta metafile).uuid
      else
        uuid.v4()
      # meta
      meta =
        vendor: $.Strike.vendor
        uuid: uid
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

# ---------------------------------------------------------------
# end Air Music Technology Strike
#


# ---------------------------------------------------------------
# Reveal Sound Spire
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
        uuid: uuid.v4()
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
            uuid: uuid.v4()
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
            uuid: uuid.v4()
            types: [[rows[0].TypeName?.trim()]]
            name: soundname
            modes: _.uniq (row.CharName for row in rows)
            deviceType: 'INST'
            comment: ''
            bankchain: [$.AnalogLab.dir, instname, '']
            author: rows[0].SoundDesigner?.trim()

    .pipe data (file) ->
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
      metafile = "#{file.path[..-5]}meta"
      uid = if fs.existsSync metafile
        (_require_meta metafile).uuid
      else
        uuid.v4()
      # meta
      meta =
        vendor: $.VStation.vendor
        uuid: uid
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
  gulp.src ["#{$.Alchemy.presets}/**/*.acp"]
    .pipe data (file, done) ->
      bank = file.relative.replace /(\/.*$)/, ''
      # execute query
      db.all $.Alchemy.query_items, $preset: "Alchemy/Presets/#{file.relative}", (err, rows) ->
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
          uuid: uuid.v4()
          types: types
          name: rows[0].name
          modes: _.uniq modes
          deviceType: 'INST'
          comment: ''
          bankchain: ['Alchemy', bank, '']
          author: author
    .pipe data (file) ->
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      file.contents = new Buffer json
      # rename .acp to .meta
      file.path = "#{file.path[..-4]}meta"
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
          uuid: uuid.v4()
          types: [[row.Category?.trim()]]
          name: row.PresetDisplayName?.trim()
          deviceType: 'INST'
          comment: row.Description?.trim()
          bankchain: ['Serum', 'Serum Factory', '']
          author: row.Author?.trim()
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


# read JSON file
# * 'require' can't use for non '.js,.json' file
_require_meta = (filePath) ->
  JSON.parse fs.readFileSync filePath, "utf8"

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
    .pipe gulp.dest "dist/#{dir}/NI Resources/image/#{vendor.toLowerCase()}/#{dir.toLowerCase()}"

# copy database resources to dist folder
_dist_database = (dir, vendor) ->
  gulp.src ["src/#{dir}/resources/dist_database/**/*.{json,meta,png}"]
    .pipe gulp.dest "dist/#{dir}/NI Resources/dist_database/#{vendor.toLowerCase()}/#{dir.toLowerCase()}"

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
      meta = _serialize _require_meta "#{presets}/#{file.relative[..-5]}meta"
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

