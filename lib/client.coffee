
soap = require 'soap'
table_model = require '../model/table'

# SOAP Client Handling
#

_clients = {}

getClient = (wsdl_url, callback) ->
  if _clients[wsdl_url]?
    return callback client
  soap.createClient wsdl_url, (err, client) ->
    _clients[wsdl_url] = client
    callback client

exports.getTable = (config, callback, name, start='', end='') ->
    getClient config.export_wsdl, (client) ->
      opts =
        kennung: config.user
        passwort: config.password
        namen: name
        bereich: "alle"
        format: "html"
        strukturinformation: true
        komprimierung: true
        transponieren: false
        startjahr: start
        endjahr: end
        zeitscheiben: ''
        regionalmerkmal: ''
        regionalschluessel: ''
        sachmerkmal: ''
        sachschluessel: ''
        sachmerkmal2: ''
        sachschluessel2: ''
        sachmerkmal3: ''
        sachschluessel3: ''
        stand: ''
        auftrag: false
        sprache: 'de'
      client.ExportService_2010Service.ExportService_2010.TabellenExport opts, (err, result) ->
        table = new table_model.Table result.TabellenExportReturn.tabellen.tabellen
        callback table
