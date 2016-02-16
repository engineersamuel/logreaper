
JSONIterator = (ab) ->
  index: -1
  hasNext: ->
    if not arr then return false
    #console.info "hasNext: #{(@index + 1) < arr.length} @index + 1: #{@index + 1}, arr.length: #{arr.length}"
    @index + 1 < arr.length

  hasPrevious: ->
    #console.info "hasPrevious: @index > 0: #{@index > 0}"
    @index > 0

  current: ->
    #console.info "index: #{@index}: current: #{arr[@index]}"
    arr[@index]

  forwardToEnd: ->
    @index = arr.length

  next: ->
    if @hasNext()
      @index = @index + 1
      return @current()
    # Returning undefined or false is not advised since an array may contain undefined or false as values.
    throw Error("Index out of bounds.  Requested element @ index: #{@index + 1} yet array length is #{arr?.length}")

  prev: ->
    if @hasPrevious()
      @index = @index - 1
      return @current()
    # Returning undefined or false is not advised since an array may contain undefined or false as values.
    throw Error("Index out of bounds.  Requested element @ index: #{@index - 1}")

# Do not use, exploratory code
class ArrayBufferJSONIterator

  # Type input is either 8 or 16 to determine the Uint array type
  constructor: (@ab, @type=8) ->
    self = @
    @extractedLines = []
    #@index = -1
    #@chunkSize = 1025*1024*1
    # Records the current offset in the ArrayBuffer
    @offset = 0
    # Next New Line Offset.  Marks where the next newline begins
    @nnlOffset = -1
    # Previous New Line offset. Marks where the previous newline begines
    @pnlOffset = -1
    # The UintxxArray view of the array buffer
    @uia = if self.type is 8 then new Uint8Array(self.ab) else new Uint16Array(self.ab)

    # Marks the beginning of a brace for a full object
    @braceOffsetBegin = -1
    # Marks the end of a brace for a full object
    @braceOffsetEnd = -1

    # Brace open char code for '{'
    @bocc = 123
    # Brace closed char code for '}'
    @bccc = 125

  hasNext: ->
    self = @
    if not @ab then return false
    # hasNext means in this ArrayBuffer there exists a full line, one we can extract
    byteLength = @ab.byteLength
    #console.info "searching byteArray fwds from #{self.offset} to #{byteLength} for a { char"

    # Count the open braces so when we know when a full object is matched.
    openBraces = 0
    # Count the close braces so when we know when a full object is matched.
    closeBraces = 0
    # Always reset the brace offsets before searching for new ones.
    self.braceOffsetBegin = -1
    self.braceOffsetEnd = -1
    `for (var i = self.offset; i < byteLength; i++) {
      //var char = String.fromCharCode(self.uia[i]);
      //console.info(i + ": " + char + " : " + self.uia[i]);

      // Add to the open braces count
      if (self.uia[i] == self.bocc) {
        openBraces += 1
      }

      // While a valid brace hasn't been found, look for one and set the offset
      if (self.uia[i] === self.bocc && self.braceOffsetBegin === -1 ) {
        self.braceOffsetBegin = i
        //console.info("braceOffsetBegin: " + self.braceOffsetBegin);
      }

      // Add to the close braces count
      if (self.uia[i] == self.bccc) {
        closeBraces += 1
      }

      // Look for a valid end brace.  Ie. } and end offset not yet set and open/close braces match
      if (self.uia[i] == self.bccc && self.braceOffsetEnd === -1 && (openBraces === closeBraces)) {
        self.braceOffsetEnd = i
        //console.info("braceOffsetEnd: " + self.braceOffsetEnd + ", openBraces: " + openBraces + ", closeBraces: " + closeBraces);
        break
      }
    }`
    # If the nnlOffset is -1 then it wasn't found
    return if (self.braceOffsetBegin isnt -1 and self.braceOffsetEnd isnt -1) then true else false
  #console.info "hasNext: #{(@index + 1) < arr.length} @index + 1: #{@index + 1}, arr.length: #{arr.length}"
  #@index + 1 < @ab.length

#  hasPrev: ->
#    self = @
#    #console.info "hasPrevious: @index > 0: #{@index > 0}"
#    console.info "searching byteArray bwds from #{self.offset} to 0 for a newline"
#    `for (var i = self.offset; i >= 0; i--) {
#      var char = String.fromCharCode(self.uia[i]);
#      console.info(i + ": " + char + " : " + self.uia[i]);
#      if (char.match(/[\r\n]+/) !== null) {
#        console.info("hasNext: next new line @ " + i);
#        self.pnlOffset = i;
#        break
#      }
#    }`
#    return

#  current: ->
#    self = @
#    #console.info "index: #{@index}: current: #{arr[@index]}"
#    console.info "current: Returning string between #{self.offset} and #{self.nnlOffset}"
#
#    # There is definitely room for optimizing this algorithm.  Can't just slice the Uint8Array based on indexes found
#    # since a word length is 2.  See http://stackoverflow.com/questions/8455757/uint16array-access-byteoffset-1-3-5-etc
#    # For now the below works though I'm unsure on how performant it is.
#    line = ""
#    `for (var i = self.offset; i < self.nnlOffset; i++) {
#      var char = String.fromCharCode(self.uia[i]);
#      if (char.match(/[\r\n]+/) !== null) {
#        line += char;
#      }
#    }`
#    return

  forwardToEnd: ->
    @index = @ab.byteLength

  next: ->
    self = @
    if self.hasNext()
      #console.info "next: returning chars between #{self.braceOffsetBegin} and #{self.braceOffsetEnd}, ab.byteLength: #{self.ab.byteLength}"
      #chars = String.fromCharCode.apply(null, if self.type is 8 then new Uint8Array(self.ab, self.braceOffsetBegin, self.braceOffsetEnd) else new Uint16Array(self.ab, self.braceOffsetBegin, self.braceOffsetEnd))
      #chars = String.fromCharCode.apply(null, new Uint8Array(self.ab, self.braceOffsetBegin, self.braceOffsetEnd ))
      chars = ""
      i = self.braceOffsetBegin
      while i <= self.braceOffsetEnd
        chars += String.fromCharCode(self.uia[i])
        i += 1

#      `for (var i = self.braceOffsetBegin; i <= self.braceOffsetEnd; i++) {
#        var char = String.fromCharCode(self.uia[i]);
#        //console.info(i + ": " + char + " : " + self.uia[i]);
#        chars += char;
#      }`

      #console.info chars
      #console.info "Setting offset to: #{self.braceOffsetEnd + 1}"
      self.offset = self.braceOffsetEnd + 1
      return chars

    throw Error("Index out of bounds.  Requested element @ offset: #{self.offset + 1} yet array length is #{self.ab?.byteLength}")

#  prev: ->
#    self = @
#    if self.hasPrev()
#      # Get a single line.
#      line = ""
#      `for (var i = self.pnlOffset; i < self.self.offset; i++) {
#        var char = String.fromCharCode(self.uia[i]);
#        console.info(i + ": " + char + " : " + self.uia[i]);
#        line += char;
#      }`
#
#      console.info "next: returning string between #{self.offset} and #{self.nnlOffset}: #{line}"
#      console.info "Setting offset to: #{self.nnlOffset + 1}"
#      self.offset = self.nnlOffset + 1
#      return line
#    # Returning undefined or false is not advised since an array may contain undefined or false as values.
#    throw Error("Index out of bounds.  Requested element @ index: #{@index - 1}")

#itr = require '...'
#iter = itr.ArrayIterator
# http://stackoverflow.com/questions/3225251/how-can-i-share-code-between-node-js-and-the-browser
if typeof exports isnt 'undefined'
  exports['JSONIterator'] = JSONIterator
  exports['ArrayBufferJSONIterator'] = ArrayBufferJSONIterator
else
  this['logreaper'] || this['logreaper'] = {}
  this['logreaper']['JSONIterator'] = JSONIterator
  this['logreaper']['ArrayBufferJSONIterator'] = ArrayBufferJSONIterator

