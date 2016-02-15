Mocha = require 'mocha'
path  = require('path')
fs    = require('fs')

mocha = new Mocha
  reporter: 'dot',
  ui: 'bdd',
  timeout: 999999

testDir = "#{__dirname}/test/sandbox/"

fs.readdir testDir, (err, files) ->
  if err
    console.log(err)
    return

  files.forEach (file) ->
    if path.extname(file) is '.js'
      f = testDir + file
      console.log "adding test file: #{f}"
      mocha.addFile f

  runner = mocha.run () ->
    console.log "finished"

  runner.on 'pass', (test) ->
    console.log "... #{test.title} passed"

  runner.on 'fail', (test) ->
    console.log "... #{test.title} failed"
