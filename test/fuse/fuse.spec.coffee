ParsingArrayIterator = undefined
XRegExp = undefined
assert = undefined
chai = undefined
expect = undefined
format = undefined
formatPath = undefined
fs = undefined
moment = undefined
path = undefined
should = undefined
yaml = undefined
chai = require("chai")
expect = chai.expect
should = chai.should()
fs = require("fs")
yaml = require("js-yaml")
path = require("path")
assert = require("assert")
should = require("should")
moment = require("moment")
ChunkParser = require("../../labs/logreaper/public/js/lib/logreaper/ChunkParser").ChunkParser
XRegExp = require("../../labs/logreaper/public/js/bower_components/xregexp/xregexp-all").XRegExp
formatPath = path.join(__dirname, "../..", "labs/logreaper/public/formats/fuse.yml")
format = yaml.load(fs.readFileSync(formatPath, "utf-8"))

describe "fuse parsing", ->
  it "should parse basic log entries", ->

    logPath = path.join(__dirname, 'fuse.log.simple')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    format[identification.identifiedName]['title'].should.equal 'Fuse root container log'
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
    parsedLines.length.should.equal 2

  it "should extract a simple exception", ->
    logPath = path.join(__dirname, 'fuse.log.simple_exception')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    format[identification.identifiedName]['title'].should.equal 'Fuse root container log'
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
    parsedLines.length.should.equal 2

  it "should extract a complex exception with gaps", ->
    logPath = path.join(__dirname, 'fuse.log.long_exception_with_gaps')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    format[identification.identifiedName]['title'].should.equal 'Fuse root container log'
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
    parsedLines.length.should.equal 2

  it "should extract a complex exception", ->
    logPath = path.join(__dirname, 'fuse.log.long_exception')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    format[identification.identifiedName]['title'].should.equal 'Fuse root container log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: logContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    parsedLines[0].thread.should.equal "FelixStartLevel"
    parsedLines[1].severity.should.equal "INFO"
    /Error occurred during starting Camel/.test(parsedLines[0].message).should.equal true
    parsedLines.length.should.equal 3

  it "should extract a stupidly long message lines", ->
    logPath = path.join(__dirname, 'fuse.log.long_message')
    logContents = fs.readFileSync(logPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logContents

    format[identification.identifiedName]['title'].should.equal 'Fuse root container log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: logContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    parsedLines[0].thread.should.equal "tp2064112929-612"
    parsedLines[1].severity.should.equal "INFO"
    /Route to  techpubsServices/.test(parsedLines[1].message).should.equal true
    /Request headers: Accept=application/.test(parsedLines[2].message).should.equal true
    parsedLines.length.should.equal 5
