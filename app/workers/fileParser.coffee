# !! console is not availble in FF, it is in Chrome though

# v3
#importScripts('/labs/logreaper/js/bower_components/xregexp/build/xregexp-all-min.js')
importScripts('/labs/logreaper/static/js/lib/xregexp/xregexp-all-min.js')
# https://developer.mozilla.org/en-US/Add-ons/Code_snippets/StringView
importScripts('/labs/logreaper/static/js/lib/html5/stringview.js')
# moment
importScripts('/labs/logreaper/static/js/lib/moment/moment.min.js')
#  Used for Identifying files
importScripts('/labs/logreaper/static/js/lib/logreaper/FileIdentifier.js')
# Common script for parsing files
importScripts('/labs/logreaper/static/js/lib/logreaper/Iterator.js')

# StringView will read into a Uint8Array by default, so use that instead of a Uint16Array
utf82ab = (str) ->
  buf = new ArrayBuffer(str.length) # 2 bytes for each char
  bufView = new Uint8Array(buf)
  `for (var i=0, strLen=str.length; i<strLen; i++) {
    bufView[i] = str.charCodeAt(i);
  }`
  return buf

self.addEventListener 'message', (e) ->
  switch e.data.cmd
    when 'identify'
      blobSlice = e.data.file.slice or e.data.file.mozSlice or e.data.file.webkitSlice
      chunkSize = 1024 * 10 # 10kb

      reader = new FileReaderSync()
      # Split the file, abhorrent for memory usage, but the above is not completed yet
      content = new StringView(reader.readAsArrayBuffer blobSlice.call(e.data.file, start, chunkSize))
      fi = new logreaper.FileIdentifier e.data.formats, XRegExp
      output = fi.identify content.toString()
      self.postMessage {cmd: 'identificationComplete', result: output, hash: e.data.hash}
      self.close()
      return

    when 'parse'
      # Quicker access to the file identification
      fileId = e.data.extra.identification

      # Read the file synchronously
      reader = new FileReaderSync()

      # Determine which severities, if any need to be filtered.
      parseSeverityLabels = e.data.parseSeverities

      # Map out all severitiy labels and filter by the ones we want to parse, extract all of those values/aliases
      # i.e. if ignoring INFO and NOTICE the resulting array would be [Info, info, INFO, NOTICE, notice, Notice]
      parseSeverityValues = []
      fileId.format.value.severity?.values?.forEach (v) ->
        # If the label is in the parsed labels, push all values to the parsed values
        if parseSeverityLabels.indexOf(v.label) isnt -1
          v.values.forEach (value) -> parseSeverityValues.push value

      # Split the file, abhorrent for memory usage, but the above is not completed yet
      splitLines = reader.readAsText(e.data.file, 'utf-8').split(/[\r\n]+/)
      totalLines = splitLines?.length || 0
      self.postMessage {cmd: 'initialMetadata', totalLines: totalLines}
      parsedLines = []
      # Number of lines parsed
      ctr = 0
      # The number of lines parsed per parsingProgress msg
      sub_ctr = 0
      # Duration in ms since parsing
      dur = 0
      # Start of processing
      start = Date.now()

      # TODO -- So apparently this file is being used to parse instead of the fileParserNoAbCopy, I believe that is the problem
      # This should be used to identify not parse
      x = XRegExp.cache(fileId.format['regex'][fileId.identifiedRegexName]['pattern'])
      console.debug "fileParsing: ParsingArrayIterator"
      p = new logreaper.ParsingArrayIterator
        arr: splitLines
        moment: moment
        Xreg: XRegExp
        re: x
        format: fileId.format
        identification: fileId
      #  constructor: (@arr, @moment, @Xreg, @re, @format, @identification) ->

      rollupRes = []
      if fileId.format['regex'][fileId.identifiedRegexName]['stack']?
        fileId.format['regex'][fileId.identifiedRegexName]['stack'].forEach (r) ->
          rollupRes.push XRegExp.cache(r)

      p.rollupRes = rollupRes

      r = undefined
      while p.hasNext()
        # Every 300 lines update the progress
        if ctr % 300 is 0
          dur = Date.now() - start
          linesPerSecond = ctr / (dur / 1000)
          estimatedSecondsLeft = (totalLines - ctr) / linesPerSecond
          self.postMessage
            cmd: 'parsingProgress'
            progress: ctr / totalLines
            timeProgress: 1 - (ctr / totalLines)
            linesParsed: sub_ctr
            linesPerSecond: linesPerSecond
            estimatedSecondsLeft: estimatedSecondsLeft

          # Since sub_ctr represents the # processed since we last pushed a progress, reset here
          sub_ctr = 0

        # These two lines are really the meat here, the above is purely for statistics
        r = p.next()
        parsedLines.push r unless not r?

        # TODO -- if going back to this approach, and I probably won't, but if I do, I need to filter out ignored severities

        ctr++
        sub_ctr++

      # Excellent step-by-step walkthrough on transferable objects -- http://typedarray.org/concurrency-in-javascript/
      #console.debug "converting #{parsedLines.length} parsedLines to ab"
      ab = utf82ab(JSON.stringify(parsedLines))
      #console.debug "posting that ab back"
      self.postMessage {cmd: 'parsingComplete', hash: e.data.extra.hash, parsedLinesBuff: ab}, [ab]
      self.close()

    when 'status'
      #console.log "status from worker"
      undefined
    when 'stop'
      #console.log "stopping fileParser worker"
      self.postMessage {cmd: 'workerStopped'}
      self.close()
, false
