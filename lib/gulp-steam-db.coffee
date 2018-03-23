fs      = require 'fs'
path    = require 'path'
through = require 'through2'
gutil   = require 'gulp-util'
_       = require 'underscore'
sax     = require 'sax'

PLUGIN_NAME = 'gulp-steam-db'

module.exports = (opts) ->
  opts ?= {}
  opts = _.defaults opts,
    filter: (filePath) -> on
    
  through.obj (file, enc, cb) ->
    rewrited = off
    error = (err) =>
      @emit 'error', new gutil.PluginError PLUGIN_NAME, err

    unless file
      return error 'Files can not be empty'

    if file.isStream()
      return error 'Streaming not supported'

    # readable stream for sax parser
    readable = fs.createReadStream file.path
    # random read fd for file contents
    fd = fs.openSync file.path, 'r'
    dir = []
    files = []
    offset = 0
    _this = this
    saxStream = sax.createStream on, trim: on
      .on 'opentag', (node) ->
        switch node.name
          when 'DIR'
            dir.push node.attributes.name
          when 'FILE'
            filePath = path.join (dir.join path.sep), node.attributes.name
            unless opts.filter filePath
              return
            files.push
              file: filePath
              offset: parseInt node.attributes.offset
              size: parseInt node.attributes.size
      .on 'closetag', (tagName) ->
        switch tagName
          when 'DIR'
            dir.pop()
          when 'FileSystem'
            offset = this._parser.position + 1
            readable.unpipe saxStream
            readable.close()
            this._parser.onerror = (err) -> {}
            this._parser.onopentag = (err) -> {}
            this._parser.error = null
            this._parser.close()
      .on 'error', (err) ->
        @emit 'error', new gutil.PluginError PLUGIN_NAME, err
      .on 'end', ->
        for f in files
          contents = Buffer.alloc f.size
          fs.readSync fd, contents, 0, contents.length, offset + f.offset
          _this.push new gutil.File
            cwd: './'
            path: f.file
            contents: contents
        cb()
    readable.pipe saxStream
