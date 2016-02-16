# !! console is not availble in FF, it is in Chrome though

importScripts('/labs/logreaper/static/js/lib/xregexp-all-min.js')
# https://developer.mozilla.org/en-US/Add-ons/Code_snippets/StringView
importScripts('/labs/logreaper/static/js/lib/stringview.js')
# moment
importScripts('/labs/logreaper/static/js/lib/moment.min.js')
#  Used for Identifying files
importScripts('/labs/logreaper/static/js/lib/FileIdentifier.js')
# Common script for parsing files
importScripts('/labs/logreaper/static/js/lib/Iterator.js')
importScripts('/labs/logreaper/static/js/lib/ChunkParser.js')

# StringView will read into a Uint8Array by default, so use that instead of a Uint16Array
utf82ab = (str) ->
  buf = new ArrayBuffer(str.length) # 2 bytes for each char
  bufView = new Uint8Array(buf)
  `for (var i=0, strLen=str.length; i<strLen; i++) {
    bufView[i] = str.charCodeAt(i);
  }`
  return buf

isFirefox = false
if (navigator.userAgent.indexOf('Firefox') != -1 and parseFloat(navigator.userAgent.substring(navigator.userAgent.indexOf('Firefox') + 8)) >= 3.6)
  isFirefox = true

self.addEventListener 'message', (e) ->
  switch e.data.cmd
    when 'identify'
      blobSlice = e.data.file.slice or e.data.file.mozSlice or e.data.file.webkitSlice
      chunkSize = 1024 * 1024 # 1MB

      reader = undefined
      # Take a 1m chunk to identify the file
      content = new StringView(reader.readAsArrayBuffer blobSlice.call(e.data.file, 0, chunkSize))
      fi = new logreaper.FileIdentifier e.data.formats, XRegExp
      output = fi.identify content.toString()
      self.postMessage {cmd: 'identificationComplete', result: output, hash: e.data.hash}
      self.close()
      return

    when 'parse'
      ##################################################################################################################
      # Setup the variables required for reading
      ##################################################################################################################
      p = undefined # This is the main parser, creating a top level so state accessible in closures
      blobSlice = e.data.file.slice or e.data.file.mozSlice or e.data.file.webkitSlice
      chunkSize = 1024 * 1024 * 1 # 1MB
      # chunkSize = 1024 * 1024 * 5 # 5MB
      # chunkSize = 1024 # 1kb
      chunks = Math.ceil(e.data.file.size / chunkSize)
      currentChunk = 0

      # This is set to the last element in the split array, and added to the next element, thus circumventing the
      # split in chunk issues where the split isn't on the \r?\n
      leftOverString = undefined

      # Quicker access to the file identification
      fileId = e.data.identification

      # Determine which severities, if any need to be filtered.
      parseSeverityLabels = e.data.parseSeverities

      # Defines which field to access that determines the severity, log4j would usually be severity, access log status
      severityField = e.data.severityField;

      # Map out all severitiy labels and filter by the ones we want to parse, extract all of those values/aliases
      # i.e. if ignoring INFO and NOTICE the resulting array would be [Info, info, INFO, NOTICE, notice, Notice]
      parseSeverityValues = []
      if fileId.format.value[severityField]?.values?
        fileId.format.value[severityField].values.forEach (v) ->
          # If the label is in the parsed labels, push all values to the parsed values
          if parseSeverityLabels.indexOf(v.label) is -1
            v.values.forEach (value) -> parseSeverityValues.push value

      #console.debug "chunkSizse: #{chunkSize}, file size: #{e.data.file.size}, totalChunks: #{chunks}"
      self.postMessage {cmd: 'initialMetadata', totalChunks: chunks}
      # Number of lines parsed
      ctr = 0
      # The number of lines parsed per parsingProgress msg
      sub_ctr = 0
      # Duration in ms since parsing
      dur = 0
      # Start of processing
      start = Date.now()

      totalChunks = chunks

      # TODO -- when format is undefined, none of this will, work, so I think I have to prevent the parser to begin with,
      # not hack every place I find
      x = XRegExp.cache(fileId.format['regex'][fileId.identifiedRegexName]['pattern'], 'gim')

      ##################################################################################################################
      # Define the methods for reading the array buffer
      ##################################################################################################################
      handleChunk = (result) ->
        #self.postMessage {cmd: 'log-debug', data: "read ##{currentChunk} of #{chunks}, chunkSize: #{chunkSize / 1024}kb"}

        # result = fevt.target.result
        content = new StringView(result)

        p = new logreaper.ChunkParser
          chunk: content.toString()
          moment: moment
          Xreg: XRegExp
          re: x
          format: fileId.format
          identification: fileId

        parsedLines = p.parse()

        #console.debug "arr is length: #{splitLines.length}"
        #####################################
        # Update the progress every chunk, this assumes the chunks are probably large enough that updating won't happen
        # at too high of a frequency
        #####################################
        msg =
          cmd: 'parsingProgress'
          hash: e.data.hash
          progress: currentChunk / totalChunks
          linesParsed: sub_ctr
          chunksParsed: currentChunk

        self.postMessage msg

        #####################################
        # Here is the meat
        #####################################
        try
          parsedLines.forEach (r) ->
            # The name may have spaces and will be encoded from the File api so must decode it and replace spaces
            # and () otherwise down the line things are not happy
#            r.fileName = decodeURIComponent(e.data.name).replace(/[\(\)\ ]+/g, "")
#            self.postMessage {cmd: 'lineParsed', hash: e.data.hash, parsedLine: JSON.stringify(r)} unless not r?

            if r? and parseSeverityValues?.indexOf(r[severityField]) is -1
              # The name may have spaces and will be encoded from the File api so must decode it and replace spaces
              # and () otherwise down the line things are not happy
              r.fileName = decodeURIComponent(e.data.name).replace(/[\(\) ]+/g, "")
              self.postMessage {cmd: 'lineParsed', hash: e.data.hash, parsedLine: JSON.stringify(r)} unless not r?
            sub_ctr++

        catch err
          self.postMessage {cmd: 'error', data: JSON.stringify(e)}
        finally

          # This logic is all pretty much short circuited by the above while loop, I may be able to remove it
          currentChunk++
          #self.postMessage {cmd: 'log-debug', data: "currentChunk: #{currentChunk}"}

          if currentChunk < chunks
            if isFirefox is true
              loadChunkSync()
            else
              loadChunkAsync()
          else
            self.postMessage {cmd: 'parsingComplete', hash: e.data.hash}
            self.close()

      frOnerror = (err) ->
        #console.error JSON.stringify(err)
        cb err

      # Proxy to the common handle chunk code
      handleChunkAsync = (fevt) ->
        handleChunk fevt.target.result

      loadChunkAsync = ->
        fileReader = new FileReader()
        #fileReader.onload = frOnload
        fileReader.onload = handleChunkAsync
        fileReader.onerror = frOnerror
        start = currentChunk * chunkSize
        #console.debug "e: #{e?.data?.file}"
        end = (if ((start + chunkSize) >= e.data.file.size) then e.data.file.size else start + chunkSize)
        fileReader.readAsArrayBuffer blobSlice.call(e.data.file, start, end)

      loadChunkSync = ->
        fileReader = new FileReaderSync()
        start = currentChunk * chunkSize
        #console.debug "e: #{e?.data?.file}"
        end = (if ((start + chunkSize) >= e.data.file.size) then e.data.file.size else start + chunkSize)
        #self.postMessage {cmd: 'log-debug', data: "start: #{start}, end: #{end}, totalChunks: #{totalChunks}, currentChunk: #{currentChunk}, totalFileSize: #{e.data.file.size}"}
        handleChunk fileReader.readAsArrayBuffer blobSlice.call(e.data.file, start, end)

      # Initiate the chunked reading of each file.
      #loadChunkAsync()
      # Firefox doesn't have the FileReaderAsync, whodathunk
      if isFirefox then loadChunkSync() else loadChunkAsync()

    when 'status'
      #console.log "status from worker"
      undefined
    when 'stop'
      #console.log "stopping fileParser worker"
      #self.postMessage {cmd: 'workerStopped'}
      self.close()
, false
