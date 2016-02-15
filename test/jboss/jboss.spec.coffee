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

ChunkParser = require("../../labs/logreaper/public/js/lib/logreaper/ChunkParser").ChunkParser
XRegExp = require("../../labs/logreaper/public/js/bower_components/xregexp/xregexp-all").XRegExp
formatPath = path.join(__dirname, '../..', 'labs/logreaper/public/formats/log4j.yml')
format = yaml.load(fs.readFileSync(formatPath, 'utf-8'))


describe "JBoss server log parsing", ->

  it "should identify a JBoss server log", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_10')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    result = fi.identify jbossLogSanitizedPathContents
    result.matched.should.equal true

  it "basic parsing test", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_10')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()
    _.each parsedLines, (p) ->
      #console.info JSON.stringify r
      p?.timestamp.should.not.equal "Invalid date"

    parsedLines.length.should.equal 10

  it "Exception extraction", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_stacktrace_simple')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.info JSON.stringify(parsedLines, null, ' ')
    parsedLines[0].thread.should.equal 'main'
    #/ConnectionFactoryJNDIMapper/.test(parsedLines[1].message[4]).should.equal true
    parsedLines[2].severity.should.equal 'INFO'

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 3

  it "Exception extraction and unmatched lines", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_stacktrace_mixed')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    parsedLines[0].thread.should.equal 'main'
    #console.info JSON.stringify(parsedLines[1], null, ' ')
    #/ConnectionFactoryJNDIMapper/.test(parsedLines[1].message[4]).should.equal true
    parsedLines[2].severity.should.equal 'INFO'

    #console.info JSON.stringify(parsedLines, null, ' ')

    parsedLines.length.should.equal 14

  it "parse server log with time only timestamp", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_time_only')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.info JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 1

  it "parse server log stderr only", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_stderr')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    parsedLines.length.should.equal 2

  it "parse server log with err to the eof", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_error_cr_no_lf')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 2
    #parsedLines[1].message.length.should.equal 72

  it "rolls completely unmatched lines into the previously matched line message", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_unmatched_lines')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 3
    #parsedLines[1].message.length.should.equal 2

  it "should match many chars in the thread", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_thread_chars')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 4
    #parsedLines[1].message.length.should.equal 53

  it "should match a std server log with no thread", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_no_thread')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    identification.identifiedName.should.equal 'log4j'
    identification.identifiedRegexName.should.equal 'std-no-thread'

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 6

  it "should match a high resolution std server log", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_high_res')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    identification.identifiedName.should.equal 'log4j'
    identification.identifiedRegexName.should.equal 'std'

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 11

  it "should match a log with ts then thread then the rest", ->
    jbossLogSanitizedPath = path.join(__dirname, 'server_log_ts_then_thread')
    jbossLogSanitizedPathContents = fs.readFileSync(jbossLogSanitizedPath)

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify jbossLogSanitizedPathContents

    identification.identifiedName.should.equal 'log4j'
    identification.identifiedRegexName.should.equal 'std-ts-thread'

    format[identification.identifiedName]['title'].should.equal 'Log4j log'
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern, 'gim')

    p = new ChunkParser
      chunk: jbossLogSanitizedPathContents
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    parsedLines = p.parse()

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 6
