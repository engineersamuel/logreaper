chai   = require 'chai'
expect = chai.expect
should = chai.should()
#assert = require 'assert'
#should = require 'should'

ArrayBufferJSONIterator = require("../../labs/logreaper/public/js/lib/logreaper/JSONIterator").ArrayBufferJSONIterator

# https://github.com/Benvie/view-buffer
# https://github.com/defunctzombie/stringencoding
# http://updates.html5rocks.com/2012/06/How-to-convert-ArrayBuffer-to-and-from-String

ab2ui = (buf, type=8) ->
  return String.fromCharCode.apply(null, if type is 8 then new Uint8Array(buf) else new Uint16Array(buf))
str2ab = (str, type=8) ->
  buf = if type is 8 then new ArrayBuffer(str.length) else new ArrayBuffer(str.length * 2) # 2 bytes for each char
  bufView = if type is 8 then new Uint8Array(buf) else new Uint16Array(buf)
  `for (var i=0, strLen=str.length; i<strLen; i++) {
    bufView[i] = str.charCodeAt(i);
  }`
  return buf

#ab2ui8 = (buf) ->
#  return String.fromCharCode.apply(null, new Uint8Array(buf))
#utf82ab = (str) ->
#  buf = new ArrayBuffer(str.length) # 2 bytes for each char
#  bufView = new Uint8Array(buf)
#  `for (var i=0, strLen=str.length; i<strLen; i++) {
#    bufView[i] = str.charCodeAt(i);
#  }`
#  return buf
#
#
#ab2ui16 = (buf) ->
#  return String.fromCharCode.apply(null, new Uint16Array(buf))
#utf162ab = (str) ->
#  buf = new ArrayBuffer(str.length * 2) # 2 bytes for each char
#  bufView = new Uint16Array(buf)
#  `for (var i=0, strLen=str.length; i<strLen; i++) {
#    bufView[i] = str.charCodeAt(i);
#  }`
#  return buf



describe "Custom Iterators", ->

  it "should parse a single stringified object", ->
    ex = {a: 1}
    exString = JSON.stringify(ex)
    exAb = str2ab(exString)

    abi = new ArrayBufferJSONIterator(exAb)
    abi.hasNext().should.equal true
    JSON.parse(abi.next()).should.deep.equal {a: 1}
    abi.hasNext().should.equal false

  it "should parse a two stringified object", ->
    ex = {a: 1, b: 2}
    exString = JSON.stringify(ex)
    exAb = str2ab(exString)

    abi = new ArrayBufferJSONIterator(exAb)
    abi.hasNext().should.equal true
    JSON.parse(abi.next()).should.deep.equal {a: 1, b: 2}
    abi.hasNext().should.equal false

  it "should parse each object in an array", ->
    ex = [{a: 1, b: 2}, {c: 3}]
    exString = JSON.stringify(ex)
    exAb = str2ab(exString)

    abi = new ArrayBufferJSONIterator(exAb)
    abi.hasNext().should.equal true
    JSON.parse(abi.next()).should.deep.equal {a: 1, b: 2}
    JSON.parse(abi.next()).should.deep.equal {c: 3}
    abi.hasNext().should.equal false

  it "should parse nested objects", ->
    ex = {a: 1, b: {c: 2}}
    exString = JSON.stringify(ex)
    exAb = str2ab(exString)

    abi = new ArrayBufferJSONIterator(exAb)
    JSON.parse(abi.next()).should.deep.equal {a: 1, b: {c: 2}}
    abi.hasNext().should.equal false

  it "should parse nested objects in an array", ->
    ex = [{a: 1, b: {c: 1}}, {d: {e: {f: 2}}}]
    exString = JSON.stringify(ex)
    exAb = str2ab(exString, type=8)

    abi = new ArrayBufferJSONIterator(exAb, type=8)
    JSON.parse(abi.next()).should.deep.equal {a: 1, b: {c: 1}}
    JSON.parse(abi.next()).should.deep.equal {d: {e: {f: 2}}}
    abi.hasNext().should.equal false

  it "should parse a two stringified with ui16", ->
    ex = {a: 1, b: 2}
    exString = JSON.stringify(ex)
    exAb = str2ab(exString, type=16)

    abi = new ArrayBufferJSONIterator(exAb, type=16)
    abi.hasNext().should.equal true
    JSON.parse(abi.next()).should.deep.equal {a: 1, b: 2}
    abi.hasNext().should.equal false

#  it "should handle when a new buffer slice is needed", ->
#    ex = {a: 1, b: 2}
#    exString = JSON.stringify(ex)
#    exAb = str2ab(exString)
#
#    abi = new ArrayBufferJSONIterator(exAb)
#    abi.hasNext().should.equal true
#    JSON.parse(abi.next()).should.deep.equal {a: 1, b: 2}
#    abi.hasNext().should.equal false

