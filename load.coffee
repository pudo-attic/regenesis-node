assert = require 'assert'
fs = require 'fs'
util = require 'util'

client = require './lib/client'

dumpvar = (o) ->
  console.log util.inspect o, true, null, true

init = () ->
  assert.ok process.env.REGENESIS_SETTINGS?, "No configuration file in REGENESIS_SETTINGS!"
  config = fs.readFileSync process.env.REGENESIS_SETTINGS
  config = JSON.parse config.toString()
  handleTable = (table) ->
    dumpvar table.facts()
  client.getTable config, handleTable, '41331-0002'

init()
