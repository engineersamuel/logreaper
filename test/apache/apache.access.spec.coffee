chai   = require 'chai'
expect = chai.expect
should = chai.should()
fs     = require 'fs'
yaml   = require 'js-yaml'
path   = require('path')
assert = require 'assert'
should = require 'should'
moment = require 'moment'

ParsingArrayIterator = require("../../labs/logreaper/public/js/lib/logreaper/Iterator").ParsingArrayIterator
XRegExp = require("../../labs/logreaper/public/js/bower_components/xregexp/xregexp-all").XRegExp
formatPath = path.join(__dirname, '../..', 'labs/logreaper/public/formats/accessLog.yml')
format = yaml.safeLoad(fs.readFileSync(formatPath, 'utf-8'))

accessLogSanitizedPath = path.join(__dirname, 'access_log_sanitized_test')
accessLogSanitizedPathContents = fs.readFileSync(accessLogSanitizedPath).toString()

describe "Apache access log parsing", ->

  it "should identify an Apache access log", ->

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    result = fi.identify accessLogSanitizedPathContents
    result.matched.should.equal true

  it "basic parsing test", ->
    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify accessLogSanitizedPathContents

    format[identification.identifiedName]['title'].should.equal 'Common Access Log'
    splitLines = accessLogSanitizedPathContents.split(/[\r\n]+/)
    x = XRegExp.cache(format[identification.identifiedName].regex[identification.identifiedRegexName].pattern)

    p = new ParsingArrayIterator
      arr: splitLines
      moment: moment
      Xreg: XRegExp
      re: x
      format: format[identification.identifiedName]
      identification: identification
    r = undefined
    while p.hasNext()
      r = p.next()
      if r
        r.timestamp.should.not.equal "Invalid date"

      parsedLines.push r unless not r?

    parsedLines.length.should.equal 10

