chai   = require 'chai'
expect = chai.expect
should = chai.should()
#assert = require 'assert'
#should = require 'should'

FunctionUtils = require("../../labs/logreaper/public/js/lib/logreaper/utils/FunctionUtils").FunctionUtils

# https://github.com/Benvie/view-buffer
# https://github.com/defunctzombie/stringencoding
# http://updates.html5rocks.com/2012/06/How-to-convert-ArrayBuffer-to-and-from-String

describe "FunctionUtils Tests", ->

  it "dereference a simple object", ->
    obj = {a: 1}
    str = "a"

    result = FunctionUtils.unwrapRefRecursiveStr obj, str
    result.should.equal 1

  it "dereference a nested object", ->
    obj = {a: {b: 2}}
    str = "a.b"

    result = FunctionUtils.unwrapRefRecursiveStr obj, str
    result.should.equal 2

  it "dereference a function call", ->
    obj = {a: {b: () -> 3}}
    str = "a.b()"

    result = FunctionUtils.unwrapRefRecursiveStr obj, str
    result.should.equal 3

  it "dereference a deeply nested function call", ->
    obj = {a: {b: () -> {c: () -> 4}}}
    str = "a.b().c()"

    result = FunctionUtils.unwrapRefRecursiveStr obj, str
    result.should.equal 4
