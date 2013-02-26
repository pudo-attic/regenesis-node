
dayLength = 24 * 60 * 60 * 1000
beforeMidnight = (dayLength - 1)

endDate = (year, month, day) ->
  date = new Date(year, parseInt(month or 1)-1, day or 1)
  return new Date(date.getTime() + beforeMidnight)


exports.parseDate = (dateString) ->
  m = dateString.match /^\d{4}$/
  if m?
    return [new Date(m[0], 0, 1), endDate(m[0], 12, 31)]
  m = dateString.match /^(\d{4})-(\d{4})$/
  if m?
    return [new Date(m[1], 0, 1), endDate(m[2], 12, 31)]
  m = dateString.match /^(\d{2})\/(\d{4})$/
  if m?
    begin = new Date(m[2], parseInt(m[1]-1))
    end = new Date(new Date(m[2], parseInt(m[1])).getTime() - 1)
    return [begin, end]
  m = dateString.match /^(\d{2}).(\d{2}).(\d{4})$/
  if m?
    begin = new Date(m[3], parseInt(m[2])-1, m[1])
    return [begin, endDate(m[3], m[2], m[1])]
  m = dateString.match /^(\d{4})\/(\d{2})$/
  if m?
    m[2] = m[1][..1] + m[2]
    return [new Date(m[1], 0, 1), endDate(m[2], 12, 31)]

  m = dateString.match /^I\/(\d{4})$/
  if m?
    begin = new Date(m[1], 0)
    end = new Date(new Date(m[1], 3).getTime() - 1)
    return [begin, end]
  m = dateString.match /^II\/(\d{4})$/
  if m?
    begin = new Date(m[1], 3)
    end = new Date(new Date(m[1], 6).getTime() - 1)
    return [begin, end]
  m = dateString.match /^III\/(\d{4})$/
  if m?
    begin = new Date(m[1], 6)
    end = new Date(new Date(m[1], 9).getTime() - 1)
    return [begin, end]
  m = dateString.match /^IV\/(\d{4})$/
  if m?
    begin = new Date(m[1], 9)
    end = new Date(new Date(parseInt(m[1])+1, 0).getTime() - 1)
    return [begin, end]

  m = dateString.match /^WS (\d{4})\/\d{2}$/
  if m?
    begin = new Date(m[1], 9, 1)
    end = endDate(parseInt(m[1])+1, 3, 31)
    return [begin, end]
  m = dateString.match /^SS (\d{4})$/
  if m?
    end = endDate(parseInt(m[1]), 9, 30)
    return [new Date(m[1], 3, 1), end]

  m = dateString.match /^KW (\d{2})\/(\d{4})$/
  if m?
    year_begin = new Date(m[2]).getTime()
    week_offset = (parseInt(m[1]) - 1) * (7 * dayLength)
    randomDay = new Date(year_begin + week_offset)
    randomDay = new Date(randomDay.getFullYear(), randomDay.getMonth()+1, randomDay.getDate())
    week_begin = randomDay.getTime() - ((randomDay.getDay() - 1) * dayLength)
    begin = new Date(week_begin)
    end = new Date(begin.getTime() + (6*dayLength) + beforeMidnight)
    return [begin, end]

  return [null, null]

exports.parseBool = (val) ->
  return val is 'J'

