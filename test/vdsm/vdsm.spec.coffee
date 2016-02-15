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
formatPath = path.join(__dirname, '../..', 'labs/logreaper/public/formats/vdsm.yml')
format = yaml.load(fs.readFileSync(formatPath, 'utf-8'))

#http://regex101.com/r/pU8vG4
describe "vdsm parsing", ->

  it "Parsing a std vdsm with full timestamp", ->
    logSanitizedPath = path.join(__dirname, 'vdsm.log')
    logSanitizedPathContents = fs.readFileSync(logSanitizedPath).toString()

    parsedLines = []

    FileIdentifier = require("../../labs/logreaper/public/js/lib/logreaper/FileIdentifier").FileIdentifier
    fi = new FileIdentifier format, XRegExp
    identification = fi.identify logSanitizedPathContents

    identification.identifiedName.should.equal 'vdsm'
    identification.identifiedRegexName.should.equal 'std'

    splitLines = logSanitizedPathContents.split(/[\r\n]+/)
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
    parsedLines.length.should.equal 178
