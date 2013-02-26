assert = require 'assert'
fs = require 'fs'
util = require 'util'
events = require 'events'

client = require './lib/client'
cube = require './cube'

dumpvar = (o) ->
  console.log util.inspect o, true, null, true

init = () ->
  assert.ok process.env.REGENESIS_SETTINGS?, "No configuration file in REGENESIS_SETTINGS!"
  config = fs.readFileSync process.env.REGENESIS_SETTINGS
  config = JSON.parse config.toString()
  handleTable = (table) ->
    dumpvar table

  #cube.fetchCube config, '11111KJ001'
  #cube.fetchCube config, '12613BJ003', (cube) ->
  #  fs.writeFileSync "export/cube_#{ cube.metadata.name }.json", JSON.stringify(cube)
  #
  exportJSONDatasets config

exportJSONDatasets = (config) ->
  ee = new events.EventEmitter()
  datasets = []
  saveDataset = (dataset_desc) ->
    datasets.push(dataset_desc)

  fetchDataset = () ->
    dataset_desc = datasets.pop()
    console.info "Fetching: #{ dataset_desc.beschriftungstext }"
    handleDataset = (data) ->
      fs.writeFileSync "export/#{ data.metadata.name }.json", JSON.stringify(data, null, '  ')
      if datasets.length > 0
        f = () -> fetchDataset()
        setTimeout(f, 20)
    cube.fetchCube config, dataset_desc.code, handleDataset

  client.getDatasetList config, saveDataset, fetchDataset


exportJSONTables = (config) ->
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
