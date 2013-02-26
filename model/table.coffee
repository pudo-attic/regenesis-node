_ = require 'underscore'
cheerio = require 'cheerio'

util = require 'util'
dumpvar = (o) ->
  console.log util.inspect o, true, null, true


class Table

  constructor: (result) ->
    @strukturInformation = result.strukturInformation
    text = result.tabellenDaten.replace /"(\w*(="|>))/g, '" $1'
    @doc = cheerio.load text
    @headerOffset = parseInt @strukturInformation.tabellenLayout.zeilenueberschriftenAnzahl
    @totalColumns = parseInt @strukturInformation.tabellenLayout.kopfspaltenAnzahl
    @metadata = @flattenStructure @strukturInformation.tabellenKopf.tabellenKopf
    @columnHeaders = @flattenStructure @strukturInformation.kopfZeile.kopfZeile
    @rowHeaders = @flattenStructure @strukturInformation.vorSpalte.vorSpalte
    @intraHeaders = @flattenStructure @strukturInformation.zwischenTitel.zwischenTitel
    @dimensions = @metadata.concat(@columnHeaders).concat(@rowHeaders).concat(@intraHeaders)
    @measures = _.filter @dimensions, (d) ->
      return d.typ is 'W'
    @locations = {}

  flattenStructure: (obj) ->
    dims = []
    if _.isArray obj
      for o in obj
        dims = dims.concat this.flattenStructure o
      return dims

    if not obj?
      return dims

    dumpvar obj
    dim = _.clone obj
    delete dim.strukturElemente
    delete dim.fb_art
    delete dim.fb_vr_ausg_art
    dumpvar dim
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
    if colspan is @totalColumns and @intraHeaders?
      return @intraHeaders[0]
    rowHeader = @rowHeaders[coords.col - 1]
    #dumpvar @dimensions
    if rowHeader?
      return rowHeader

  resolveLocation: (loc) ->
    if @locations[loc]
      return @locations[loc]
    $el = @doc('#' + loc)
    dimension = @interpretLocation loc, $el
    if not dimension? or dimension.typ is 'W'
      @locations[loc] = undefined
      return
    dimension.value = $el.text()
    @locations[loc] = dimension
    return dimension

  facts: () -> # reconstruct individual facts
    dumpvar @strukturInformation
    self = @
    facts = {}
    #current = {}
    #measureIdx = 0
    @doc('td').each (i, e) ->
      obj = self.doc e
      locs = (self.resolveLocation l for l in obj.attr('headers').split(' '))
      locs = _.filter locs, (l) -> return l?
      #dumpvar ([l, self.resolveLocation l] for l in obj.attr('headers').split(' '))
      dims = _.filter locs, (d) -> return d.typ isnt 'W'
      key = ([d.name, d.value] for d in dims)
      facts[key] = facts[key] or {}
      #console.log key.sort()
      for res in locs
        facts[key][res.name] = res.value or res.titel
      measure = _.filter locs, (d) -> return d.typ is 'W'
      console.log(measure)
      facts[key][measure[0].name] = obj.text()
      #measureIdx++
      #if measureIdx is self.measures.length
      #  facts.push current
      #  current = {}
      #  measureIdx = 0
    return _.values facts

exports.Table = Table
