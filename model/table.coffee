_ = require 'underscore'
cheerio = require 'cheerio'


class TableMetadata

  constructor: (@strukturInformation) ->
    @headerOffset = parseInt @strukturInformation.tabellenLayout.zeilenueberschriftenAnzahl
    @metadata = @flattenStructure @strukturInformation.tabellenKopf.tabellenKopf
    @columnHeaders = @flattenStructure @strukturInformation.kopfZeile.kopfZeile
    @rowHeaders = @flattenStructure @strukturInformation.vorSpalte.vorSpalte
    @dimensions = @metadata.concat(@columnHeaders).concat(@rowHeaders)
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

  interpretLocation: (loc) ->
    coords = @parseLocation loc
    columnHeader = @columnHeaders[coords.row - @headerOffset - 1]
    if columnHeader?
      return columnHeader
    rowHeader = @rowHeaders[coords.col - 1]
    if rowHeader?
      return rowHeader


class Table

  constructor: (result) ->
    @meta = new TableMetadata result.strukturInformation
    @doc = cheerio.load result.tabellenDaten

  resolveLocation: (loc) ->
    dimension = @meta.interpretLocation loc
    if not dimension? or dimension.typ is 'W'
      return
    dimension.value = @doc('#' + loc).text()
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
      measure = self.meta.measures[measureIdx]
      current[measure.name] = obj.text()
      measureIdx++
      if measureIdx is self.meta.measures.length
        facts.push current
        current = {}
        measureIdx = 0
    return facts

exports.Table = Table
