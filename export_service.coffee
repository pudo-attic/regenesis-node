
soap = require 'soap'

wsdl_url = 'https://www-genesis.destatis.de/genesisWS/services/ExportService_2010?wsdl'

ODN_USER = "GK105862"
ODN_PASS = "roFl0815"

soap.createClient wsdl_url, (err, client) ->
  desc = client.describe()
  console.log desc.ExportService_2010Service.ExportService_2010.TabellenExport
  opts = 
    kennung: ODN_USER
    passwort: ODN_PASS
    namen: "52411-0003"
    bereich: "alle"
    format: "csv"
    strukturinformation: true
    komprimierung: false
    transponieren: false
    startjahr: ''
    endjahr: ''
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
    console.log result.TabellenExportReturn.tabellen.tabellen
