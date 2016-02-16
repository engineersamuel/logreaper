class FileIdentifier
  # Input the formats hash and a reference to XRegExp.  The later just makes it
  # worlds easier than dealing with client/server side import/require/global
  # Especially with web workers
  constructor: (@formats, @XRegExp) ->
    @output = {
      matched: false
      identifiedName: undefined
      identifiedRegexName: undefined
      identifiedAfterIterations: undefined
      format: undefined
    }

  identify: (rawText) ->
    self = @
    splitText = ""
    # I should evaluate here matching via the ChunkParser instead of like this.  Not sure it would make a significant difference,
    # but it could simplify things.
    if typeof(rawText) is 'object'
      splitText = rawText.toString().split(/\r?\n/)
    else
      splitText = rawText.split(/\r?\n/)

    #console.info "Matching against: #{splitText.length} lines"

    formatNames = Object.keys(self.formats)
    #console.info "Matching against formats: #{formatNames}"

    # TODO This could be much better handled by adding some sort of priority to the yml
    # Make sure specific formats are at the very end of the array we are parsing here.  For example GC logs must always
    # Be parsed last as there are some very relaxed parsing involved to determine a GC log.

    gcIdx = formatNames.indexOf("gc")
    if gcIdx isnt -1
      # Splice gc out of the formatNames and add it to the end of the array
      n = formatNames.splice(gcIdx, 1)
      formatNames.push n[0]

    BreakException = {}
    try
      # For each splitline in the test text
      ctr = 0
      splitText.forEach (line) ->
        line = line + '\n'
        ctr++

        # For each of the formats see if there is a match
        formatNames.forEach (name) ->
          #console.log "Attempting to match against: #{name}"

          # Iterate over each known regex
          regexNames = Object.keys(self.formats[name]['regex'])

          regexNames.forEach (regexName) ->
            #console.log "Attempting to match against: #{regexName}"

            # TODO -- added gim here, might need to vet the setting
            x = self.XRegExp(self.formats[name]['regex'][regexName]['pattern'], 'gim')
            m = x.exec(line)
            t = x.test(line)
            #console.log "Attempting to match with regex: #{self.formats[name]['regex'][regexName]['pattern']}"
            #console.log "line: #{line}"

            #if name is 'syslog' and regexName is 'std-abr-month'
            #  console.log "Attempting to match with regex: #{self.formats[name]['regex'][regexName]['pattern']}"
            #  console.log "line: #{line}"
            #  console.log "matched?: #{t is true}"

            if m

              # Once successfully matched, if a header is present, much make sure it passes

              # If we are on the first iteration and a header is present, create the regex and test the first line
              # If it fails, this will short circuit the match
              if self.formats[name]['regex'][regexName]['header']?
                h = self.XRegExp(self.formats[name]['regex'][regexName]['header'])

                # Make sure h is a valid regex then break if the first line doesn't match
                if self.XRegExp.isRegExp(h) and h.test(splitText[0]) is false
                  #console.log "Header does not match required header, breaking."
                  #console.log "header: #{self.formats[name]['regex'][regexName]['header']}"
                  throw BreakException

              #console.info "Line matches. Name: #{name}, regexName: #{regexName}"
              #console.info "regex: #{JSON.stringify(self.formats[name]['regex'][regexName])}"
              #console.info "Line: #{line}"

              self.output.matched = true
              self.output.firstLineMatched = line
              self.output.identifiedName = name # ex. apache
              self.output.identifiedRegexName = regexName # ex. std
              self.output.identifiedAfterIterations = ctr
              self.output.format = self.formats[name]
              throw BreakException
    catch e
      #console?.debug?(JSON.stringify(e, null, ' '))
      #console.log "Catching exception and returning self.output"
      return self.output

    return self.output

if typeof exports isnt 'undefined'
  exports['FileIdentifier'] = FileIdentifier
else
  # Namespace into logreaper for the browser
  this['logreaper'] || this['logreaper'] = {}
  this['logreaper']['FileIdentifier'] = FileIdentifier
