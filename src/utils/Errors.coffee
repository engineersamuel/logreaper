"use strict";

QueryError = (type, message) ->
  @name = 'QueryError'
  @type = type
  @message = message ? 'Problem executing query'
QueryError.prototype = Object.create(Error.prototype)
QueryError.prototype.constructor = QueryError

NoContentError = (type, message) ->
  @name = 'NoContentError'
  @type = type
  @message = message ? 'No Content'
NoContentError.prototype = Object.create(Error.prototype)
NoContentError.prototype.constructor = NoContentError

module.exports =
  QueryError: QueryError
  NoContentError: NoContentError
