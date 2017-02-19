fs       = require 'fs'
uuid     = require 'uuid'
_        = require 'underscore'
beautify = require 'js-beautify'
xmldom   = (require 'xmldom').DOMParser

$        = require '../config'

module.exports =
  # generate or reuse uuid
  uuid: (arg) ->
    metaFile = switch
      when arg.path && arg.path[-5..] is '.pchk'
        "#{arg.path[..-5]}meta"
      when _.isString arg
        arg
    if fs.existsSync metaFile
      (@readJson metaFile)?.uuid or uuid.v4()
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
    str = switch
      when Buffer.isBuffer()
        JSON.stringify json.toString 'utf8'
      when _.isString json
        json
      when _.isObject json
        JSON.stringify json
      else
        throw new 'unsupported json format.'
    str = beautify str, indent_size: $.json_indent
    console.info str if print
    str
