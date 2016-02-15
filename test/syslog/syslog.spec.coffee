chai   = require 'chai'
expect = chai.expect
should = chai.should()
fs     = require 'fs'
yaml   = require 'js-yaml'
path   = require('path')
assert = require 'assert'
should = require 'should'
moment = require 'moment'

ChunkParser = require("../../labs/logreaper/public/js/lib/logreaper/ChunkParser").ChunkParser
XRegExp = require("../../labs/logreaper/public/js/bower_components/xregexp/xregexp-all").XRegExp
formatPath = path.join(__dirname, '../..', 'labs/logreaper/public/formats/syslog.yml')
format = yaml.load(fs.readFileSync(formatPath, 'utf-8'))

#http://regex101.com/r/pU8vG4
describe "syslog parsing", ->

  it "Parsing a std messages with full timestamp", ->
    logPath = path.join(__dirname, 'msgs_full_timestamp')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    identification.identifiedName.should.equal 'syslog'
    identification.identifiedRegexName.should.equal 'std'

    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: logContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 75

  it "Parsing a std messages with abbr month and no year", ->
    logPath = path.join(__dirname, 'msgs_no_year_abr_month')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    identification.identifiedName.should.equal 'syslog'
    identification.identifiedRegexName.should.equal 'std-abr-month'

    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: logContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()
    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 9

  it "Parsing a std messages", ->
    logPath = path.join(__dirname, 'messages.1')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    identification.identifiedName.should.equal 'syslog'
    identification.identifiedRegexName.should.equal 'std-abr-month'

    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: logContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 104
