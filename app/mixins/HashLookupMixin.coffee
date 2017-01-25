_ = require 'lodash'

Mixin =
  ####################################################################################################################
  # Quick lookups for common severity indexes, this just saves some verbosity
  ####################################################################################################################
  emergIdx: undefined
  alertIdx: undefined
  errorIdx: undefined
  critIdx: undefined
  warnIdx: undefined
  noticeIdx: undefined
  infoIdx: undefined
  debugIdx: undefined
  traceIdx: undefined

  ####################################################################################################################
  # Performance Optimization, hash lookup. Hash all string fields into indexed lookups
  ####################################################################################################################
  fieldHashes: {}
  example: {
    severity: {
      lookup: {
        0: 'ERROR',
        1: 'WARN',
        2: 'DEBUG'
      },
      inverseLookup: {
        'ERROR': 0
        'WARN': 1
        'DEBUG': 2
      }
    },
    category: {
      0: 'org.jboss',
      1: 'org.foo.bar'
    }
  }

  ####################################################################################################################
  # Hash lookup utils
  ####################################################################################################################
  # Add a value to the lookup and return the idx if added
  addLookupValue: (field, value) ->
    self = @
    idx = undefined

    if field is 'message' and _.isArray(value)
      value = value.join('\n')

    # If the field doesn't exist, initialize with lookup and inverse lookups
    if not self.fieldHashes[field]?
      self.fieldHashes[field] = {
        lookup: {}
        inverseLookup: {}
        nextIdx: 0
        getNextIdx: () ->
          idx = @nextIdx
          @nextIdx += 1
          return idx
      }

    # if the value doesn't exist in the inverse lookup, add it to both, and increment the idx key
    if not self.fieldHashes[field]['inverseLookup'][value]?
      idx = self.fieldHashes[field].getNextIdx()
      self.fieldHashes[field]['inverseLookup'][value] = idx
      self.fieldHashes[field]['lookup'][idx] = value
      return idx

    idx = null
    self = null

  # Given a field and an idx, lookup the value
  # Returns value
  lookup: (field, idx, compressed=false) ->
    try
      if not compressed
        return @fieldHashes[field]['lookup'][idx]
      else
        return LZString.decompress(@fieldHashes[field]['lookup'][idx])

    catch err
      console.warn "Error looking up field: #{field}, idx: #{idx}, compressed: #{compressed}"
      #e = new Error()
      #console.error e.stack
      undefined

  # Given a field and an actual value, lookup the idx
  # Returns idx
  inverseLookup: (field, value) ->
    try
      if field is 'message' and _.isArray(value)
        @fieldHashes[field]['inverseLookup'][value.join('\n')]
      else
        @fieldHashes[field]['inverseLookup'][value]
    catch err
      console.warn "Error inversely looking up field: #{field}, value: #{value}"
      #e = new Error()
      #console.error e.stack
      undefined

module.exports = Mixin
