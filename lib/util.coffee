fs       = require 'fs'
uuid     = require 'uuid'
_        = require 'underscore'
beautify = require 'js-beautify'
xmldom   = (require 'xmldom').DOMParser

$        = require '../config'

module.exports =
  # generate or reuse uuid
  uuid: (pchkFile) ->
    metaFile = "#{pchkFile.path[..-5]}meta"
    if fs.existsSync metaFile
      (@readJson metaFile)?.uuid || uuid.v4()
    else
      uuid.v4()

  # read JSON file
  readJson: (filePath) ->
    JSON.parse @readFile filePath

  # read file as String
  readFile: (filePath) ->
    fs.readFileSync filePath, "utf8"

  # resource dirname can't use ".", "!"
  normalizeDirname: (dir) ->
    dir.replace /[\.\!]/, ' '

  xmlFile: (filePath) ->
    @xmlString @readFile filePath
    
  xmlString: (s) ->
    new xmldom().parseFromString s

  beautify: (json, print) ->
    result = beautify (if _.isString json then json else (JSON.stringify json)), indent_size: $.json_indent
    console.info result if print
    result
