"use strict";

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

exports.isWithinAMonth = (unix_ts) ->
  unix_ts >= +moment().subtract(30, 'days')

exports.isWithinAYear = (unix_ts) ->
  unix_ts >= +moment().subtract(1, 'year')

exports.isOverAYear = (unix_ts) ->
  unix_ts < +moment().subtract(1, 'year')

