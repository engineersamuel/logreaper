_       = require 'lodash'
moment  = require 'moment-timezone'

exports.truthy = (obj) ->
  if obj is undefined
    return false
  else if _.isBoolean obj
    return obj
  else if _.isString obj
    return if _.contains ['YES', 'Yes', 'yes', 'Y', 'y', '1', 'true', 'TRUE', 'ok', 'OK', 'Ok'], obj then true else false
  else if _.isNumber obj
    return parseInt(obj) is 1
  else
    return false

exports.getRegion = (tz) ->
  if _.includes(tz, "America")
    return "NA"
  else if _.includes(tz, "Europe") or _.includes(tz, "GMT")
    return "EMEA"
  else if _.includes(tz, "Asia") or _.includes(tz, "Pacific") or _.includes(tz, "Australia")
    return "APAC"
  return tz

exports.isWithinAMonth = (unix_ts) ->
  unix_ts >= +moment().subtract(30, 'days')

exports.isWithinAYear = (unix_ts) ->
  unix_ts >= +moment().subtract(1, 'year')

exports.isOverAYear = (unix_ts) ->
  unix_ts < +moment().subtract(1, 'year')

exports.setDateFields = (ref, fieldBaseName, date, opts={}) ->

  xDate               = date
  xDateValue          = 0

  if _.isNumber(xDate)
    # If the value is greater than 13 then we have a unix timestamp with ms
    if "#{xDate}".length >= 13
      xDateValue = +moment(xDate)

    # Otherwise we have seconds
    else
      xDateValue = +moment.unix(xDate)
  else
    xDateValue = +moment(date)


  #xDateValue          = if _.isNumber(xDate) then +moment.unix(xDate) else +moment(xDate)
  xDateDisplay        = if opts.user?.timezone? then moment(xDateValue).tz(opts.user.timezone).format('MM/DD/YYYY HH:mm:ss z') else moment(xDateValue).format('MM/DD/YYYY HH:mm:ss')
  #xDateDisplayShort   = if opts.user?.timezone? then moment(xDateValue).tz(opts.user.timezone).format('MM/DD/YYYY z') else moment(xDateValue).format('MM/DD/YYYY')
  xDateDisplayShort   = moment(xDateValue).format('MM/DD/YYYY')

  ref["#{fieldBaseName}Date"]               = date
  ref["#{fieldBaseName}DateValue"]          = xDateValue
  ref["#{fieldBaseName}DateDisplay"]        = xDateDisplay
  ref["#{fieldBaseName}DateDisplayShort"]   = xDateDisplayShort
