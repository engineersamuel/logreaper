_ = require 'lodash'

####################################################################################################################
# Provides a standard set of known severity colors
####################################################################################################################
Mixin =
  setFileNames: (files, logTypeFilter) ->
    fileNames = _.chain(_.filter(files, logTypeFilter)).map('name').value()
    @fileNames = _.map fileNames, (fileName) -> decodeURIComponent(fileName).replace(/[\(\) ]+/g, "")

module.exports = Mixin
