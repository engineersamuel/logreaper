class ParsingArrayIterator
  # The array, the regular expression reference, and the format (see yml defs)
#  constructor: (@arr, @moment, @Xreg, @re, @format, @identification) ->
  constructor: (@opts) ->
    @index = -1
    # Defines the regexs to match forward lines to rollup.  Think java stacktraces
    @rollupRes = opts.rollupRes || undefined
    @idName = opts.identification?.identifiedName || undefined
    @idPattern = opts.identification?.identifiedRegexName || undefined
    @keyedFormat = opts.format || undefined
    @Xreg = opts.Xreg || undefined
    @re = opts.re || undefined
    @arr = opts.arr || undefined
    @moment = opts.moment || undefined

    # Record the stack index to quickly seek to the known stacktrace re
    @stackIdx = 0

    @keys = Object.keys(@keyedFormat.value) || []

    # TODO -- throw errors on missing required parameters

  # Optionally take a param lastChunk for chunked reading so the ending \r\n can be ignored
  hasNext: (lastChunk) ->
    self = @
    if not self.arr then return false


    # If there is no last chunk passed in or we are on the last chunk doesn't really matter, continue like normal
    if lastChunk is undefined or lastChunk is true
      #console.info "hasNext: #{(@index + 1) < arr.length} @index + 1: #{@index + 1}, arr.length: #{self.arr.length}"
      @index + 1 < self.arr.length

    # Otherwise, if chunking and not on the last chunk, if there is not a next element throw an error that we need more
    # data
    else
      onLastElement = (@index + 1) is self.arr.length

      if onLastElement is true
        throw {
          class: 'ParsingArrayIteratorIterator'
          name: 'Needs more data'
          level: 'error'
          message: "ParsingArrayIteratorIterator needs more chunks from the ArrayBuffer, please load more.  lastChunk: #{lastChunk}, arr.length: #{self.arr.length}, current idx: #{self.index}"
          htmlMessage: 'ParsingArrayIteratorIterator needs more chunks from the ArrayBuffer, please load more'
          toString: () -> "#{@name}: #{@message}"
        }
      else
        return (@index + 1) < self.arr.length

  hasPrevious: ->
    #console.info "hasPrevious: @index > 0: #{@index > 0}"
    @index > 0

  current: ->
    self = @
    #console.info "index: #{@index}: current: #{arr[@index]}"
    @arr[@index]

  forwardToEnd: ->
    @index = @arr.length

  # Optionally take a param lastChunk for chunked reading so the ending \r\n can be ignored
  next: (lastChunk) ->
    self = @
    if @hasNext(lastChunk)
      self.index = self.index + 1
      m = self.Xreg.exec(self.current(), self.re)
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

        # Now that the main pattern has a chance to match, must continue to peek forward looking for potential match
        # forward expressions.  The primary use case for this is for extracting stack traces
        # Note as well this should only happen after a successfully matched previous line
        #console.log "rollupUnmatched: #{self.keyedFormat.rollupUnmatched}, rollupRes length: #{self.rollupRes?.length}"
        if self.rollupRes?.length > 0
          while self.hasNext()
            # Since there is a next, peek ahead one value
            peekedValue = @arr[self.index + 1]
            #console.log "peekedValue: #{peekedValue}"

            # For loop here so we can break out
            breakWhile = false
            matchFound = false
            # Start the iteration at the last found matching position -- TODO -- this assumes that the same stack re
            # will be used in the whole file.  This is an optimization that I could see could fail in an edge case.
            `for (var j = self.stackIdx; j < self.rollupRes.length; j++) {
              // Attempt to match the peeked value from one of the stack trace regular expressions
              m = self.Xreg.exec(peekedValue, self.rollupRes[j]);
              //console.log("Attempting to match with regex: " + self.rollupRes[j] )

              // If m matches, we are within a sub matching expression
              if(m) {
                //console.log("m[message]: " + JSON.stringify(m.message));

                // Go ahead an increment the index immediately
                self.index = self.index + 1;

                // key to the field to rollup into which we know will already be initialized
                // TODO -- { and } can cause problems in the parsing, let's remove those for now
                sData[self.keyedFormat['rollupStackTo']].push(m[self.keyedFormat['rollupStackFrom']].replace(/[\{\[\}\]]/g, ''));

                // Break out of this for loop to stop matching
                matchFound = true
                break;

              // Otherwise break out of the while loop which means the index will not have been advanced and life resumes
              // as normal
              } else {
                // If there is no match found and we are at the end of the regex to test for the stack trace, break out
                // Of the while and resume normal flow
                if(!matchFound && (j === self.rollupRes.length - 1)) {

                  // Now attempt to match the line back to the main regex.  If unmatched, we know we have very
                  // unstructured data that we may want to rollup into the message
                  if(self.keyedFormat.rollupUnmatched === true) {
                    sub_m = self.Xreg.exec(peekedValue, self.re)
                    if(!sub_m && peekedValue != '') {
                      self.index = self.index + 1
                      //sData[self.keyedFormat['rollupStackTo']].push(peekedValue.replace(/[\{\[\}\]]/g, ''))
                      sData[self.keyedFormat['rollupStackTo']].push(peekedValue.replace(/[\{\}]/g, ''))
                    }
                  }

                  breakWhile = true;
                  break;
                }
              }
            }
            `

            # Breaking the inner loop won't break the while loop, must break that as a consequence
            if breakWhile then break

      return sData
    # Returning undefined or false is not advised since an array may contain undefined or false as values.
    throw Error("Index out of bounds.  Requested element @ index: #{self.index + 1} yet array length is #{self.arr?.length}")

  prev: ->
    self = @
    if @hasPrevious()
      self.index = self.index - 1
      return self.current()
    # Returning undefined or false is not advised since an array may contain undefined or false as values.
    throw Error("Index out of bounds.  Requested element @ index: #{self.index - 1}")

## Type input is either 8 or 16 to determine the Uint array type
##http://www.dofactory.com/javascript-iterator-pattern.aspx
##http://caolanmcmahon.com/posts/writing_for_node_and_the_browser/
#ArrayIterator = (arr) ->
#  index: -1
#  hasNext: ->
#    if not arr then return false
#    #console.info "hasNext: #{(@index + 1) < arr.length} @index + 1: #{@index + 1}, arr.length: #{arr.length}"
#    @index + 1 < arr.length
#
#  hasPrevious: ->
#    #console.info "hasPrevious: @index > 0: #{@index > 0}"
#    @index > 0
#
#  current: ->
#    #console.info "index: #{@index}: current: #{arr[@index]}"
#    arr[@index]
#
#  forwardToEnd: ->
#    @index = arr.length
#
#  next: ->
#    if @hasNext()
#      @index = @index + 1
#      return @current()
#    # Returning undefined or false is not advised since an array may contain undefined or false as values.
#    throw Error("Index out of bounds.  Requested element @ index: #{@index + 1} yet array length is #{arr?.length}")
#
#  prev: ->
#    if @hasPrevious()
#      @index = @index - 1
#      return @current()
#    # Returning undefined or false is not advised since an array may contain undefined or false as values.
#    throw Error("Index out of bounds.  Requested element @ index: #{@index - 1}")

# http://stackoverflow.com/questions/3225251/how-can-i-share-code-between-node-js-and-the-browser
if typeof exports isnt 'undefined'
  #exports['ArrayIterator'] = ArrayIterator
  exports['ParsingArrayIterator'] = ParsingArrayIterator
else
  this['logreaper'] || this['logreaper'] = {}
  #this['logreaper']['ArrayIterator'] = ArrayIterator
  this['logreaper']['ParsingArrayIterator'] = ParsingArrayIterator

