_ = require 'underscore'
cheerio = require 'cheerio'

util = require 'util'
dumpvar = (o) ->
  console.log util.inspect o, true, null, true


class Table

  constructor: (result) ->
    @strukturInformation = result.strukturInformation
    dumpvar @strukturInformation
    @doc = cheerio.load result.tabellenDaten
    @headerOffset = parseInt @strukturInformation.tabellenLayout.zeilenueberschriftenAnzahl
    @totalColumns = parseInt @strukturInformation.tabellenLayout.kopfspaltenAnzahl
    @metadata = @flattenStructure @strukturInformation.tabellenKopf.tabellenKopf
    @columnHeaders = @flattenStructure @strukturInformation.kopfZeile.kopfZeile
    @rowHeaders = @flattenStructure @strukturInformation.vorSpalte.vorSpalte
    @intraHeaders = @flattenStructure @strukturInformation.zwischenTitel.zwischenTitel
    @dimensions = @metadata.concat(@columnHeaders).concat(@rowHeaders).concat(@intraHeaders)
    @measures = _.filter @dimensions, (d) ->
      return d.typ is 'W'

  flattenStructure: (obj) ->
    dims = []
    if _.isArray obj
      for o in obj
        dims = dims.concat this.flattenStructure o
      return dims

    dim = _.clone obj
    delete dim.strukturElemente
    delete dim.fb_art
    delete dim.fb_vr_ausg_art
    dims.push dim

    if obj.strukturElemente?.strukturElemente?
      dims = dims.concat this.flattenStructure obj.strukturElemente.strukturElemente

    return dims

  parseLocation: (loc) ->
    loc = loc.replace 'Z', ''
    [row, col] = loc.split 'S'
    return {} =
      row: parseInt row
      col: parseInt col

  interpretLocation: (loc, $el) ->
    coords = @parseLocation loc
    columnHeader = @columnHeaders[coords.row - @headerOffset - 1]
    if columnHeader?
      return columnHeader
    colspan = parseInt $el.attr('colspan')
    console.log colspan
    rowHeader = @rowHeaders[coords.col - 1]
    if rowHeader?
      return rowHeader

  resolveLocation: (loc) ->
    $el = @doc('#' + loc)
    dimension = @interpretLocation loc, $el
    if not dimension? or dimension.typ is 'W'
      return
    dimension.value = $el.text()
    return dimension

  facts: () -> # reconstruct individual facts
    self = @
    facts = []
    current = {}
    measureIdx = 0
    @doc('td').each (i, e) ->
      obj = self.doc e
      for loc in obj.attr('headers').split(' ')
        res = self.resolveLocation loc
        if res?
          current[res.name] = res.value or res.titel
      measure = self.measures[measureIdx]
      current[measure.name] = obj.text()
      measureIdx++
      if measureIdx is self.measures.length
        facts.push current
        current = {}
        measureIdx = 0
    return facts

exports.Table = Table
