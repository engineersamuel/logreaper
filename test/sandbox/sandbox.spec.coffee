chai   = require 'chai'
expect = chai.expect
should = chai.should()
fs     = require 'fs'
yaml   = require 'js-yaml'
path   = require 'path'
assert = require 'assert'
should = require 'should'
moment = require 'moment'
_      = require 'lodash'

prettyjson = require 'prettyjson'
FileNormalize = require 'file-normalize'

ChunkParser = require("../../labs/logreaper/public/js/lib/logreaper/ChunkParser").ChunkParser
XRegExp = require("../../labs/logreaper/public/js/bower_components/xregexp/xregexp-all").XRegExp
log4jFormatPath = path.join(__dirname, '../..', 'labs/logreaper/public/formats/log4j.yml')
fuseFormatPath = path.join(__dirname, '../..', 'labs/logreaper/public/formats/fuse.yml')
syslogFormatPath = path.join(__dirname, '../..', 'labs/logreaper/public/formats/syslog.yml')
format = yaml.load(fs.readFileSync(syslogFormatPath, 'utf-8'))


describe "sandbox testing", ->

#  it "should match hello world", ->
#    result = XRegExp.test('hello', /h/)
#    result.should.equal true
#
#    jbossLogSanitizedPath = path.join(__dirname, '../jboss/server_log_stacktrace_simple')
#    s = fs.readFileSync(jbossLogSanitizedPath, 'utf8')
#    re = XRegExp.cache("^(?<timestamp>\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}(?:,\\d{3})?(?:\\s\\d+)?)\\s+(?<severity>WARN|WARNING|ERROR|INFO|TRACE|DEBUG|FINE)\\s+\\[(?<category>.*?)\\]\\s+\\((?<thread>.*?)\\)\\s+(?<message>(?:(?!\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}(?:,\\d{3})?(?:\\s\\d+)?).|\\r?\\n)*)", 'gim')
#    result = XRegExp.exec(s, re)
#    XRegExp.forEach s, re, (match, i) ->
#      console.log "i: #{i}, match.message: #{match.message}"

  it "should extract a stupidly long message lines", ->
    logPath = path.join(__dirname, '../syslog/uevent_benign')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    format[identification.identifiedName]['title'].should.equal 'syslog'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: logContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    parsedLines.length.should.equal 28
