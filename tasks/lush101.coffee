# ---------------------------------------------------------------
# D16 LuSH-101
#
# notes
#  - Komplete Kontrol 1.6.2.5
#  - LuSH-101 1.1.3
# ---------------------------------------------------------------
path     = require 'path'
gulp     = require 'gulp'
tap      = require 'gulp-tap'
rename   = require 'gulp-rename'
xpath    = require 'xpath'

util     = require '../lib/util.coffee'
task     = require '../lib/common-tasks'

#
# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config.coffee'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'LuSH-101'
  vendor: 'D16 Group Audio Software'
  magic: 'SH11'
  
  #  local settings
  # -------------------------
  presets: "#{process.env.HOME}/Library/Application Support/D16 Group/LuSH-101"
  pluginStateChunkId: 'VC2!'
  # contributed from @tomduncalf
  mappingFile: 'src/LuSH-101/mappings/LuSH-101.shhpmap'
  # Ableton Live 9.6.2
  abletonRackTemplate: 'src/LuSH-101/templates/LuSH-101.adg.tpl'
  buildOpts:
    Editor:
      Skin: 'Big'                        # 'Small' or 'Big'
      Keyboard: 'no'                     # keyboard visible 'yes' or 'no'
    OtherParameters:
      # 'FX 1 Audio Output Number': '1'
      # 'FX 2 Audio Output Number': '1'
      # 'FX 3 Audio Output Number': '1'
      'MultiCore Support': 'on'           # 'on' or 'off'
      'Sound Quality': 'Normal'           # 'Normal' or 'High'
      'Offline Quality': 'High'         # 'Normal' or 'High'
      'Retrigger Mode': 'SH-101'          # envelope retrigger mode, 'Normal' or 'SH-101'
      # 'Layer 1 Audio Output Number': '1'
      # 'Layer 1 Midi Channel': 'omni'
      # 'Layer 2 Audio Output Number': '1'
      # 'Layer 2 Midi Channel': 'omni'
      # 'Layer 3 Audio Output Number': '1'
      # 'Layer 3 Midi Channel': 'omni'
      # 'Layer 4 Audio Output Number': '1'
      # 'Layer 4 Midi Channel': 'omni'
      # 'Layer 5 Audio Output Number': '1'
      # 'Layer 5 Midi Channel': 'omni'
      # 'Layer 6 Audio Output Number': '1'
      # 'Layer 6 Midi Channel': 'omni'
      # 'Layer 7 Audio Output Number': '1'
      # 'Layer 7 Midi Channel': 'omni'
      # 'Layer 8 Audio Output Number': '1'
      # 'Layer 8 Midi Channel': 'omni'

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

# extract PCHK chunk from .nksf
gulp.task "#{$.prefix}-extract-raw-presets", ->
  task.extract_raw_presets ["temp/#{$.dir}/**/*.nksf"], "src/#{$.dir}/presets"

# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  presets = "src/#{$.dir}/presets"
  gulp.src ["#{presets}/**/*.pchk"]
    .pipe tap (file) ->
      extname = path.extname file.path
      basename = path.basename file.path, extname
      relative = path.relative presets, path.dirname file.path
      folder = relative.split path.sep
      bank = switch folder[0]
        when 'Presets'
          'LuSH-101 Factory Presets'
        when 'Timbres'
          'LuSH-101 Factory Timbres'
      types = switch
        when folder[0] is 'Presets'
          [folder[1], t] for t in folder[2..(folder.length)]
        when folder[0] is 'Timbres'
          ['Timbre', t] for t in folder[1..(folder.length)]
      author = if folder.length > 1
        ext = switch folder[0]
          when 'Presets'
            'shprst'
          when 'Timbres'
            'shtmbr'
        patch = path.join $.presets, relative, "#{basename}.#{ext}"
        patch = util.xmlFile patch
        (xpath.select "/Preset/@author", patch)[0]?.value
        
      meta =
        vendor: $.vendor
        uuid: util.uuid file
        types: types
        name: basename
        deviceType: 'INST'
        comment: ''
        bankchain: [$.dir, bank, '']
        author: author
      file.contents = new Buffer util.beautify meta, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"

# generate mapping from LuSH-101.shhpmap (contributed from @tomduncalf)
gulp.task "#{$.prefix}-suggest-mapping", ->
  gulp.src [$.mappingFile], read: true
    .pipe tap (file) ->
      shhpmap = util.xmlString file.contents.toString()
      assigns = xpath.select "/HostParametersMap/assign", shhpmap
      pages = []
      page = []
      prevSection = undefined
      prevLayer = undefined
      for assign in assigns
        words = (assign.getAttribute 'pluginParam').split ' '
        section = (words[0..2].join ' ').replace /Layer (\d)/, 'L$1'
        layer = words[1]
        if layer isnt prevLayer and page.length isnt 0
          while page.length < 8
            page.push autoname: false, vflag: false
          pages.push page
          page = []
        page.push
          autoname: false
          # shhpmap = 1 based, NKS = 0 based
          id: (parseInt assign.getAttribute 'hostParam') - 1
          name: words[3..].join ' '
          section: section if page.length is 0 or section isnt prevSection
          vflag: false
        if page.length is 8
          pages.push page
          page = []
        prevSection = section
        prevLayer = layer

      if page.length isnt 0
        while page.length < 8
          page.push autoname: false, vflag: false
        pages.push page
        
      file.contents = new Buffer util.beautify {ni8: pages}, on
    .pipe rename
      basename: 'default-suggest'
      extname: '.json'
    .pipe gulp.dest "src/#{$.dir}/mappings"

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
  # read LuSH-101 mapping file
  shhpmap = util.xmlFile $.mappingFile
  assigns = xpath.select "/HostParametersMap/assign", shhpmap
  task.dist_presets $.dir, $.magic, (file) ->
    # edit PCHK chunk content
    # - apply build option
    # - sync mapping between pluginstate and NICA chunk
    id = file.contents.toString 'ascii', 4, 8
    size = file.contents.readUInt32LE 8
    pluginState = util.xmlString file.contents.toString 'utf8', 12, (12 + size)
    
    # build options
    if $.buildOpts.Editor.Skin
      (xpath.select '/PluginState/Editor/Skin[1]', pluginState)[0]
        ?.setAttribute 'name', $.buildOpts.Editor.Skin
    if $.buildOpts.Editor.Keyboard
      (xpath.select "/PluginState/Editor/Keyboard[1]", pluginState)[0]
        ?.setAttribute 'visible', $.buildOpts.Editor.Keyboard
    for key in Object.keys($.buildOpts.OtherParameters)
      (xpath.select "/PluginState/Preset[@name=\"OtherParameters\"]/param[@name=\"#{key}\"]", pluginState)[0]
        ?.setAttribute 'value', $.buildOpts.OtherParameters[key]
        
    # replace mapping
    map = (xpath.select "/PluginState/HostParametersMap[@name=\"LuSH-101\"]", pluginState)[0]
    map.removeChild child while child = map?.lastChild
    for assign in assigns
      map.appendChild assign

    # build PCHK chunk
    pluginState = new Buffer pluginState.toString(), 'utf8'
    size = new Buffer 4
    size.writeInt32LE pluginState.length
    file.contents = Buffer.concat [
      file.contents.slice 0, 8
      size                       # xml size
      pluginState                # xml
      new Buffer [0]             # null terminate ?
    ]
    
    # return undefined for use default.json
    undefined

# check
gulp.task "#{$.prefix}-check-dist-presets", ->
  task.check_dist_presets $.dir

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
