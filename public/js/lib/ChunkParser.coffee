class ChunkParser

  # TODO -- This is created on demand and parses each chunk of text.  If the beginning line doesn't match have a special
  # regex which matches .*? up until the given timestamp which is to be rolled into the previous message, I think
  # that may work

  # The array, the regular expression reference, and the format (see yml defs)
  #constructor: (@arr, @moment, @Xreg, @re, @format, @identification) ->
  constructor: (@opts) ->
    # Defines the regexs to match forward lines to rollup.  Think java stacktraces
    @rollupRes = opts.rollupRes || undefined
    @idName = opts.identification?.identifiedName || undefined
    @idPattern = opts.identification?.identifiedRegexName || undefined
    @keyedFormat = opts.format || undefined
    @Xreg = opts.Xreg || undefined
    @re = opts.re || undefined
    @chunk = opts.chunk || undefined
    @moment = opts.moment || undefined

    @keys = Object.keys(@keyedFormat.value)

    # TODO -- throw errors on missing required parameters

  parse: () ->
    self = @
    # TODO First use the rollupRes to see if the line starts with the timestamp or with other text

    # TODO Store the text to return if necessary
    matches = []

    # Now just parse out the text with Xregex and return the parsed lines
    @Xreg.forEach @chunk, self.re, (m, i) ->
      matches.push self.handleMatch(m)

    matches

  handleMatch: (m) ->
    self = @
    sData = undefined
    if m
      sData = {}
      # Get the named capture groups and extract the data from the match
      #x.xregexp.captureNames.forEach (n) ->
      self.keys.forEach (n) ->

        # First test for any required fields that would force an exception
        if not m[n]? and self.keyedFormat.value[n].required is true
          throw Error("#{n} is required but was undefined @ line #{self.index}")

        if self.keyedFormat.value[n].kind is 'integer'
          if m[n] is undefined or m[n] is null
            # value can't be null for crossfilter
            sData[n] = self.keyedFormat.value[n].default || -1
          else
            sData[n] = +m[n]

        # Indicating something is an array generally means is part of a match forward expression like with java
        # stack traces
        else if self.keyedFormat.value[n].kind is 'array'
          if not sData[n] then sData[n] = []

          if m[n]?
            if self.keyedFormat.value[n].replace? is true
              sData[n].push m[n].replace(/[\{\[\}\]]/g, '')
            else
              sData[n].push = m[n]

        else if self.keyedFormat.value[n].kind is 'date'
          # convert to a unix offset
          if m[n]?
            # If a pattern is given for the date
            if self.keyedFormat.value[n][self.idPattern]
              sData[n] = +self.moment(m[n], self.keyedFormat.value[n][self.idPattern], 'en')
            else
              sData[n] = +self.moment(m[n])
          # Assumes the default of 'string' though I'm not specifying that
        else
          # TODO -- Not sure yet if replacing {}[] is the best way, we'll see
          if self.keyedFormat.value[n].replace? is true
            sData[n] = m[n].replace(/[\{\[\}\]]/g, '') || self.keyedFormat.value[n].default
          else
            sData[n] = m[n] || self.keyedFormat.value[n].default

    return sData


# http://stackoverflow.com/questions/3225251/how-can-i-share-code-between-node-js-and-the-browser
if typeof exports isnt 'undefined'
  exports['ChunkParser'] = ChunkParser
else
  this['logreaper'] || this['logreaper'] = {}
  this['logreaper']['ChunkParser'] = ChunkParser

