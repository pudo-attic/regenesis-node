
# Docs: https://www-genesis.destatis.de/genesis/misc/GENESIS-Online-Export.pdf 
#
_ = require 'underscore'
request = require 'request'
ent = require 'ent'
csv = require 'csv'
querystring = require 'querystring'
formats = require './lib/formats'

keymap =
  wert: 'value'
  wert_verfaelscht: 'value_error'
  qualitaet: 'quality'
  gesperrt: 'locked'
  fach_schl: 'key'
  zi_wert: 'ts_value'
  ktx: 'title_de'
  ltx: 'long_title_de'
  erl: 'description_de'
  ktx_2: 'title_en'
  ltx_2: 'long_title_en'
  erl_2: 'description_en'
  def: 'definition_de'
  def_2: 'definition_en'
  me_name: 'measure_name_de'
  me_name_2: 'measure_name_en'
  notizen: 'notes'
  siehe_fach_schl: 'see_key'
  pzt: 'periodicity'
  guelt_ab: 'valid_from'
  guelt_bis: 'valid_until'
  '"mit werten"': 'includes_values'
  typ: 'type'
  nkm_stellen: 'float_precision'
  me_name: 'unit_name'
  mm_typ: 'measure_type'
  ghm_werte_jn: 'secret_values'
  ober_bgr_jn: 'meta_variable'
  summierbar: 'summable'
  bestand: 'atemporal'
  max_sbr: 'max_width'
  dst: 'data_type'

keytypes =
  eu_vbd: formats.parseBool
  genesis_vbd: formats.parseBool
  regiostat: formats.parseBool
  secret_values: formats.parseBool
  spr_tmp: formats.parseBool
  regiostat: formats.parseBool
  trans_flag_2: formats.parseBool
  meta_variable: formats.parseBool
  summable: formats.parseBool
  atemporal: formats.parseBool
  valid_from: (d) -> formats.parseDate(d)[0]
  valid_until: (d) -> formats.parseDate(d)[1]
  pos_nr: parseInt

keyignore = [
  'spr_tmp', 'trans_flag_2', 'genesis_vbd', 'regiostat', 'eu_vbd'
  ]

keylocalized = [
  'title_en', 'long_title_en', 'definition_en', 'description_en', 'me_name_2'
  ]


arrayByKey = (array, key) ->
  return _.object _.map array, (d) -> [d[key], d]


normalizeKey = (key) ->
  key = key.toLowerCase().replace /-/g, '_'
  if _.has(keymap, key)
    return keymap[key]
  return key


splitSections = (data) ->
  data = ent.decode(data).split '\n'
  sections = []
  section = null
  for row in _.rest(data)
    if row.substring(0,2) is 'K;'
      headers = row.split ';'
      section = headers[1]
      sections[section] = [row]
    else if row.substring(0,2) is 'D;'
      sections[section].push(row)
    else
      if row.substring(0,1) isnt '"'
        row = '\n' + row
      sections[section][sections[section].length-1] += row
  return sections


parseSection = (section, callback) ->
  headers = _.first(section).split ';'
  headers = _.map headers, normalizeKey
  headers = _.rest(headers)
  options =
    delimiter: ';'
  #  columns: headers
  stream = csv().from _.rest(section).join('\n'), options
  stream.to.array (data) ->
    callback _.map data, (r) -> _.rest(_.zip(headers, r))


parseSectionToObject = (section, callback) ->
  parseSection section, (data) ->
    out = []
    is_translated = true
    for item in data
      obj = {}
      for [k, v] in item
        if not v or v.length is 0
          continue
        if keytypes[k]?
          v = keytypes[k] v
        if k is 'trans_flag_2'
          is_translated = v
        if k in keyignore
          continue
        obj[k] = v
      if not is_translated
        for k in keylocalized
          if obj[k]?
            delete obj[k]
      out.push(obj)
    callback out


extractMetadata = (cube, sections, callback) ->
  metadata = cube.metadata
  parseSectionToObject sections['ERH'], (erh) ->
    parseSectionToObject sections['ERH-D'], (erhd) ->
      metadata.census = _.extend _.first(erhd), _.first(erh)
      parseSectionToObject sections['DQ'], (cube_md) ->
        parseSectionToObject sections['DQ-ERH'], (cube_md_erh) ->
          metadata.cube = _.extend _.first(cube_md), _.first(cube_md_erh)
          parseSectionToObject sections['ME'], (units) ->
            metadata.units = _.first(units)
            cube.metadata = metadata
            callback cube


extractDimensions = (cube, sections, callback) ->
  parseSectionToObject sections['MM'], (mm) ->
    dimensions = {}
    for dim in mm
      dim.values = []
      dimensions[dim.name] = dim
    parseSectionToObject sections['KMA'], (kma) ->
      values = arrayByKey kma, 'key'
      parseSectionToObject sections['KMAZ'], (kmaz) ->
        for assoc in kmaz
          value = _.extend {}, assoc, values[assoc.key]
          dimensions[assoc.name].values.push value
        cube.dimensions = dimensions
        callback cube


extractFacts = (cube, sections, callback) ->
  parseSectionToObject sections['DQA'], (axes) ->
    parseSectionToObject sections['DQZ'], (times) ->
      parseSectionToObject sections['DQI'], (measures) ->
        parseSection sections['QEI'], (raw_facts) ->
          facts = []
          for raw in raw_facts
            fact = {}
            offset = 0
            for axis in axes
              value = raw[offset][1]
              fact[axis.name] = value
              offset++
            for time in times
              range = formats.parseDate(raw[offset][1])
              fact[time.name] =
                plain: raw[offset][1]
                from: range[0]
                until: range[1]
              offset++
            for measure in measures
              m = _.extend measure,
                value: raw[offset][1]
                quality: raw[offset+1][1]
                locked: raw[offset+2][1]
                value_error: raw[offset+3][1]
              fact[measure.name] = m
              offset += 4
            facts.push fact
            cube.facts = facts
          callback cube



parseCube = (name, data, callback) ->
  sections = splitSections(data)
  cube =
    metadata:
      name: name
  extractMetadata cube, sections, (cube) ->
    extractDimensions cube, sections, (cube) ->
      extractFacts cube, sections, (cube) ->
        callback cube


exports.fetchCube = (config, name, callback) ->
  url = 'https://www.regionalstatistik.de/genesisws/services/ExportService_2010'
  opts =
    method: 'DatenExport'
    kennung: '' #config.user
    passwort: '' #config.password
    namen: name
    bereich: "Alle"
    format: "csv"
    werte: true
    metadaten: true
    zusatz: true
    startjahr: ''
    endjahr: ''
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
  #url += '?' + querystring.stringify opts
  request.get {url: url, qs: opts}, (error, response, body) ->
    parseCube name, body.match(/<quaderDaten>((.|\n)*)<\/quaderDaten>/m)[1], callback


