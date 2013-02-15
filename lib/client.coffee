
soap = require 'soap'
table_model = require '../model/table'

# SOAP Client Handling
#

_clients = {}

getClient = (wsdl_url, callback) ->
  if _clients[wsdl_url]?
    return callback _clients[wsdl_url]
  soap.createClient wsdl_url, (err, client) ->
    _clients[wsdl_url] = client
    callback _clients[wsdl_url]

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
      if err?
          console.error err
      else
          table = new table_model.Table result.TabellenExportReturn.tabellen.tabellen
          table.name = name
          callback table


exports.getTableList = (config, tableCallback, doneCallback, prefix=9) ->
  getClient config.recherche_wsdl, (client) ->
    opts =
      kennung: config.user
      passwort: config.password
      filter: prefix + '*'
      bereich: 'Katalog'
      listenLaenge: 500
      sprache: 'de'
    client.RechercheService_2010Service.RechercheService_2010.TabellenKatalog opts, (err, result) ->
      entries = result.TabellenKatalogReturn.tabellenKatalogEintraege.tabellenKatalogEintraege
      if entries?
        for entry in entries
          console.log entry.inhalt
          tableCallback entry
      if prefix >= 0
        exports.getTableList config, tableCallback, doneCallback, prefix-1
      else
        doneCallback()

exports.getDataset = (config, callback, name, start='', end='') ->
  getClient config.export_wsdl, (client) ->
    opts =
      kennung: config.user
      passwort: config.password
      namen: name
      bereich: "Alle"
      format: "csv"
      werte: true,
      metadaten: true,
      zusatz: true,
      startjahr: start
      endjahr: end
      zeitscheiben: ''
      inhalte: ''
      regionalmerkmal: ''
      regionalschluessel: ''
      sachmerkmal: ''
      sachschluessel: ''
      sachmerkmal2: ''
      sachschluessel2: ''
      sachmerkmal3: ''
      sachschluessel3: ''
      stand: ''
      sprache: 'de'
    client.ExportService_2010Service.ExportService_2010.DatenExport opts, (err, result) ->
      if err?
          console.error err
      else
          callback dataset



