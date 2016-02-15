chai   = require 'chai'
expect = chai.expect
should = chai.should()
#assert = require 'assert'
#should = require 'should'

xregexp = require "../labs/logreaper/public/js/bower_components/xregexp/xregexp-all"
IterUtils = require "../labs/logreaper/public/js/lib/logreaper/Iterator"
# TODO -- Unsure if this is needed yet
#TypedArrays = require "./typedarray"

# https://github.com/Benvie/view-buffer
# https://github.com/defunctzombie/stringencoding
# http://updates.html5rocks.com/2012/06/How-to-convert-ArrayBuffer-to-and-from-String
ab2str = (buf) ->
  return String.fromCharCode.apply(null, new Uint16Array(buf))
str2ab = (str) ->
  buf = new ArrayBuffer(str.length*2) # 2 bytes for each char
  bufView = new Uint16Array(buf)
  `for (var i=0, strLen=str.length; i<strLen; i++) {
    bufView[i] = str.charCodeAt(i);
  }`
  return buf

#describe "Verify imports and environment", ->
#  it "should all resolve and import", ->
#    typeof(xregexp.XRegExp).should.equal 'function'
#    typeof(ArrayBuffer).should.equal 'object'

describe "Custom Iterators", ->

  it "should iterate forwards", ->
    itr = IterUtils.ArrayIterator([1,2,3])
    ctr = 0
    while itr.hasNext()
      v = itr.next()
      if ctr is 0 then v.should.equal 1
      if ctr is 1 then v.should.equal 2
      if ctr is 2 then v.should.equal 3
#      if ctr is 3 then expect(v).to.equal undefined
      ctr++
    (() ->
      itr.next()
    ).should.throw "Requested element @ index: 3 yet array length is 3"

  it "should iterate backwards", ->
    itr = IterUtils.ArrayIterator(['Bob', 'Sally', 'Harry'])
    itr.forwardToEnd()
    itr.prev().should.equal 'Harry'
    itr.prev().should.equal 'Sally'
    itr.prev().should.equal 'Bob'
    (() ->
      itr.prev()
    ).should.throw "Index out of bounds.  Requested element @ index: -1"

  it "should iterate back and forth", ->
    itr = IterUtils.ArrayIterator(['Bob', 'Sally', 'Harry', 'Jerry'])
    itr.next().should.equal 'Bob'
    itr.next().should.equal 'Sally'
    itr.next().should.equal 'Harry'
    itr.prev().should.equal 'Sally'
    itr.next()
    itr.next().should.equal 'Jerry'
    (() ->
      v = itr.next()
      console.log v
    ).should.throw "Requested element @ index: 4 yet array length is 4"

  it "should gracefully fail with undefined or null input", ->
    itr = IterUtils.ArrayIterator()
    (() ->
      itr.next()
    ).should.throw "Index out of bounds.  Requested element @ index: 0 yet array length is undefined"
    itr = IterUtils.ArrayIterator(null)
    (() ->
      itr.next()
    ).should.throw "Index out of bounds.  Requested element @ index: 0 yet array length is undefined"

  it "should gracefully fail with an empty array input", ->
    itr = IterUtils.ArrayIterator([])
    (() ->
      itr.next()
    ).should.throw "Index out of bounds.  Requested element @ index: 0 yet array length is 0"
