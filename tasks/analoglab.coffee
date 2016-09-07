# Arturia Analog Lab
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Analog Lab    (*unknown version)
#  - recycle Ableton Live Rack presets. https://github.com/jhorology/AnalogLabPack4Live
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
rename   = require 'gulp-rename'
data     = require 'gulp-data'
del      = require 'del'
sqlite3  = require 'sqlite3'
_        = require 'underscore'
util     = require '../lib/util'
task     = require '../lib/common-tasks'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Analog Lab'
  vendor: 'Arturia'
  magic: "ALab"
  
  #  local settings
  # -------------------------
  db: '/Library/Arturia/Analog\ Lab/Labo2.db'
  soundMappingTemplateFile: 'src/Analog Lab/mappings/default-sound.json.tpl'
  multiMappingTemplateFile: 'src/Analog Lab/mappings/default-multi.json.tpl'
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/Analog Lab/templates/Analog Lab.adg.tpl'
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

# extract PCHK chunk from .adg files.
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets_from_adg ["#{$.Ableton.racks}/#{$.dir}/**/*.adg"], "src/#{$.dir}/presets"

# generate metadata from Analog Lab's sqlite database
gulp.task "#{$.prefix}-generate-meta", ->
  # open database
  db = new sqlite3.Database $.db, sqlite3.OPEN_READONLY
  gulp.src ["src/#{$.dir}/presets/**/*.pchk"]
    .pipe data (file, done) ->
      # SQL bind parameters
      soundname = path.basename file.path, '.pchk'
      folder = path.relative "src/#{$.dir}/presets", path.dirname file.path
      instname = path.dirname folder
      if instname is 'MULTI'
        # multi presets
        params =
          $MultiName: soundname
        db.all $.query_multis, params, (err, rows) ->
          done err if err
          unless rows and rows.length
            return done 'row unfound in multis'
          if rows.length > 1
            return done "row duplicated in multis. rows.length:#{rows.length}"
          console.info JSON.stringify rows[0]
          done undefined,
            vendor: $.vendor
            types: [['Multi']]
            name: soundname
            modes: [rows[0].MusicGenreName]
            deviceType: 'INST'
            comment: ''
            bankchain: [$.dir, 'MULTI', '']
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
        db.all $.query_sounds, params, (err, rows) ->
          done err if err
          unless rows and rows.length
            return done 'row unfound in sounds'
          done undefined,
            vendor: $.vendor
            types: [[rows[0].TypeName?.trim()]]
            name: soundname
            modes: _.uniq (row.CharName for row in rows)
            deviceType: 'INST'
            comment: ''
            bankchain: [$.dir, instname, '']
            author: rows[0].SoundDesigner?.trim()

    .pipe tap (file) ->
      file.data.uuid = util.uuid file
      json = beautify (JSON.stringify file.data), indent_size: $.json_indent
      # console.info json
      file.contents = new Buffer util.beautify file.data
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

# generate mapping per preset from sqlite database
gulp.task "#{$.prefix}-generate-mappings", [
  "#{$.prefix}-generate-sound-mappings"
  "#{$.prefix}-generate-multi-mappings"
]

# generate sound preset mappings from sqlite database
gulp.task "#{$.prefix}-generate-sound-mappings", ->
  template = _.template util.readFile $.soundMappingTemplateFile
  # open database
  db = new sqlite3.Database $.db, sqlite3.OPEN_READONLY
  gulp.src [
    "src/#{$.dir}/presets/**/*.pchk"
    "!src/#{$.dir}/presets/MULTI/**/*.pchk"
    ]
    .pipe data (file, done) ->
      # SQL bind parameters
      soundname = path.basename file.path, '.pchk'
      folder = path.relative "src/#{$.dir}/presets", path.dirname file.path
      instname = path.dirname folder
      # Sound presets
      # funny, Arturia change preset name 'Moog' to 'Mogue' in newer version.
      db_soundname = soundname.replace 'Moog', 'Mogue'
      db_soundname = db_soundname.replace 'moog', 'mogue'
      # initialize parameter names
      paramNames = ('' for i in [0...20])
      # fetch
      db.all $.query_sound_controls_assignments,
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
    .pipe tap (file) ->
      # console.info json
      file.contents = new Buffer template name: file.data
    .pipe rename
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"
    .on 'end', ->
      # colse database
      db.close()

# generate multi preset mappings from sqlite database
gulp.task "#{$.prefix}-generate-multi-mappings", ->
  template = _.template util.readFile $.multiMappingTemplateFile
  # open database
  db = new sqlite3.Database $.db, sqlite3.OPEN_READONLY
  gulp.src [
    "src/#{$.dir}/presets/MULTI/**/*.pchk"
    ]
    .pipe data (file, done) ->
      # SQL bind parameters
      multiName = path.basename file.path, '.pchk'
      # initialize parameter names
      partParamNames =  for i in [0...2]
        '' for i in [0...20]
      # fetch
      db.all $.query_multi_parts_controls_assignments,
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
        db.all $.query_multi_controls_assignments,
          $MultiName: multiName
        , (err, rows) ->
          multiParamNames =  ('' for i in [0...40])
          for row in rows
            multiParamNames[row.MultiCtrlID] = partParamNames[row.MultiCtrlDestPart - 1][row.CtrlID]
          done undefined, multiParamNames
    .pipe tap (file) ->
      file.contents = new Buffer template name: file.data
    .pipe rename
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings/MULTI"
    .on 'end', ->
      # colse database
      db.close()

#
# build
# --------------------------------

# copy dist files to dist folder
gulp.task "#{$.prefix}-dist", [
  "#{$.prefix}-dist-image"
  "#{$.prefix}-dist-database"
  "#{$.prefix}-dist-presets"
]

# copy image resources to dist folder
gulp.task "#{$.prefix}-dist-image", ->
  task.dist_image $.dir, $.vendor

# copy database resources to dist folder
gulp.task "#{$.prefix}-dist-database", ->
  task.dist_database $.dir, $.vendor

# build presets file to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  task.dist_presets $.dir, $.magic, (file) ->
    # per preset mapping file
    "./src/#{$.dir}/mappings/#{file.relative[..-5]}json"

# check
gulp.task "#{$.prefix}-check-dist-presets", ->
  task.check_dist_presets $.dir

#
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
  task.deploy_resources $.dir

# copy database resources to local environment
gulp.task "#{$.prefix}-deploy-presets", [
  "#{$.prefix}-dist-presets"
] , ->
  task.deploy_presets $.dir

#
# release
# --------------------------------

# release zip file to dropbox
gulp.task "#{$.prefix}-release", ["#{$.prefix}-dist"], ->
  task.release $.dir

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  task.export_adg "dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"
  , "#{$.Ableton.racks}/#{$.dir}"
  , $.abletonRackTemplate
