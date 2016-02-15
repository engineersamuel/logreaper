# Debug -- http://youtrack.jetbrains.com/issue/WEB-7091, http://devnet.jetbrains.com/message/5481211
path            = require('path')
fs              = require 'fs'
async           = require 'async'
_               = require 'lodash'
exec            = require('child_process').exec
Converter       = require('csvtojson').Converter

gcViewerJar = "#{__dirname}/../../libs/gcviewer-1.34.1.jar"

GCParser = {}

GCParser.parse = (obj, cb) ->

#  console.log('stdout: ' + stdout)
#  console.log('stderr: ' + stderr)
#  if error?
#    console.log "exec error: #{error}"
  #logger.debug "Executing: #{execString}"
  async.parallel {
    csv_ts: (innerCb) ->
      # Get the csv timestamped output
      execString = "java -jar #{gcViewerJar} #{obj.path} #{obj.csvPath} -t CSV_TS"
      exec execString, (error, stdout, stderr) ->
        if error?
          innerCb error
        else
          fs.readFile obj.csvPath,'utf8', (err, data) ->
            if err?
              innerCb err
            else
              try
                fileStream = fs.createReadStream obj.csvPath
                csvConverter = new Converter {constructResult: true}
                csvConverter.on 'end_parsed', (jsonObj) ->
                  # Now finally callback to async, map each json output to a normalized output for this gc type.  These
                  # field names are modeled after the gc.yml
                  innerCb null, _.map jsonObj, (o) ->
                    timestamp: +o['Timestamp(unix/#)']
                    used: +o['Used(K)']
                    total: +o['Total(K)']
                    pause: +o['Pause(sec)']
                    gcType: o['GC-Type']
                    fileName: obj.fileName
                # Kick off the file stream to the csv
                fileStream.pipe csvConverter
              catch e
                innerCb e

    summary: (innerCb) ->
      # Get the summary output
      execString = "java -jar #{gcViewerJar} #{obj.path} #{obj.summaryPath} -t SUMMARY"
      exec execString, (error, stdout, stderr) ->
        if error?
          innerCb error
        else
          fs.readFile obj.summaryPath, 'utf8', (err, data) ->
            if err?
              innerCb err
            else
              # Take the GCViewer output and construct it into an array of json objects
              constructedArray = _.map(_.map(data.split(/\r?\n/g), (d) -> d.split(';')), (s) ->
                key = s?[0]
                {
                  field: key?.trim()
                  value: s?[1]?.trim()
                  units: s?[2]?.trim()
                }
              )

              # Now project that to a json object keyed by the field name
              output = {}
              _.each constructedArray, (c) ->
                if c?['key']? isnt ""
                  output[c['field']] =
                    value: c['value']
                    units: c['units']
                    fileName: obj.fileName

              innerCb null, output

  }, (err, results) ->
    cb err, results

module.exports = GCParser