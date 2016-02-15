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
formatPath = path.join(__dirname, '../..', 'labs/logreaper/public/formats/lsof.yml')
format = yaml.safeLoad(fs.readFileSync(formatPath, 'utf-8'))

# http://regex101.com/r/pU8vG4
# Severity parsing inspired from https://github.com/elasticsearch/logstash/blob/master/patterns/grok-patterns
describe "lsof parsing", ->

  it "basic parsing test", ->
    parsedLines = []

    filePath = path.join(__dirname, 'lsof_01035334.txt')
    contents = fs.readFileSync(filePath).toString()

    splitLines = contents.split(/[\r\n]+/)
    x = XRegExp.cache(format.lsof.regex.std.pattern)
    splitLines.forEach (line) ->
      if line? and line isnt ''
        m = XRegExp.exec(line, x)
        if m?
          parsedLines.push m
        #else
        #  console.warn line

  it "correctly id based on header", ->
    filePath = path.join(__dirname, 'lsof_01035334.txt')
    contents = fs.readFileSync(filePath).toString()

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify contents

    identification.identifiedName.should.equal 'lsof'
    identification.identifiedRegexName.should.equal 'std'

    format[identification.identifiedName]['title'].should.equal 'lsof'
    splitLines = contents.split(/[\r\n]+/)
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
      parsedLines.push r unless not r?

    #console.log JSON.stringify(parsedLines, null, ' ')
    parsedLines.length.should.equal 2267

  it "fail on no header", ->
    filePath = path.join(__dirname, 'lsof_no_header.txt')
    contents = fs.readFileSync(filePath).toString()

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify contents

    identification.matched.should.equal false
