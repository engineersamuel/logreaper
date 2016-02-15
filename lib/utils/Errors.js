var NoContentError, QueryError;

QueryError = function(type, message) {
  this.name = 'QueryError';
  this.type = type;
  return this.message = message != null ? message : 'Problem executing query';
};

QueryError.prototype = Object.create(Error.prototype);

QueryError.prototype.constructor = QueryError;

NoContentError = function(type, message) {
  this.name = 'NoContentError';
  this.type = type;
  return this.message = message != null ? message : 'No Content';
};

NoContentError.prototype = Object.create(Error.prototype);

NoContentError.prototype.constructor = NoContentError;

module.exports = {
  QueryError: QueryError,
  NoContentError: NoContentError
};
