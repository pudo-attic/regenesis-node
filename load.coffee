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

  # Schlachttabelle: 
  #client.getTable config, handleTable, '41331-0002'

  # Erwerbstaetige:
  client.getTable config, handleTable, '13311-0002'
  

  #client.getDataset config, handleTable, '61111BM001'
  
  #exportJSON config

exportJSON = (config) ->
  tables = []
  saveTable = (table_desc) ->
    tables.push(table_desc)

  fetchTable = () ->
    if tables.length is 0
      return
    table_desc = tables.pop()
    console.info "Fetching: #{ table_desc.inhalt }"
    handleTable = (table) ->
      data = 
        dimensions: table.dimensions
        measures: table.measures
        facts: table.facts()
      fs.writeFileSync "export/#{ table.name }.json", JSON.stringify(data)
      fetchTable()
    client.getTable(config, handleTable, table_desc.code, 1900)

  client.getTableList config, saveTable, fetchTable
    

init()
