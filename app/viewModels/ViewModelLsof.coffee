crossfilter = require('crossfilter')

# Mixins
Module                     = require '../mixins/module.coffee'
TimeSeriesMixin            = require '../mixins/TimeSeriesMixin.coffee'
HashLookupMixin            = require '../mixins/HashLookupMixin.coffee'
ReactFilterableMixin       = require '../mixins/ReactFilterableMixin.coffee'
FileNamesMixin             = require '../mixins/FileNamesMixin.coffee'

# LSOF output isn't time series, so won't extend ViewModelBase for now which is primarily for time series, not strictly
# though, so I could extend it in the future and that would compact this class some
class ViewModelLsof extends Module

  @include TimeSeriesMixin
  @include HashLookupMixin
  @include ReactFilterableMixin
  @include FileNamesMixin

  constructor: (opts) ->
    # Observable for the crossfilter array
    @cf = undefined

    # Cap the datatable at 10000 entries for performance reasons
    @cappedSize = 500

    # Crossfilter top n filter, default to 5
    @topN = 5

    ####################################################################################################################
    # dimensions and groups
    ####################################################################################################################
    @pidDim = undefined
    @pidGroup = undefined

    @userDim = undefined
    @userGroup = undefined

    @processDim = undefined
    @processGroup = undefined

    @nameDim = undefined
    @nameGroup = undefined

    # Dynamic Dimension to handle filters from clicking in the chart
    @dynDim = undefined

    @logTypeName = 'lsof'
    @logTypeFilter = (f) => f.identification.identifiedName is @logTypeName
    @viewName = 'lsofView'
    @fileNames = []

  cleanUp: () ->
    @pidDim.dispose()
    @userDim.dispose()
    @processDim.dispose()
    @nameDim.dispose()
    @dynDim.dispose()

  ######################################################################################################################
  # To be called to process the crossfilter files
  ######################################################################################################################
  parse: (file, parsedLines) ->
    self = @

    new Promise (resolve, reject) =>

      # Do a quick check to make sure that there are actually parsed lines to process
      if parsedLines?.length is 0
        console.warn "file: #{file.name} with hash: #{file.hash} has no parsedLines"
      else if file.identification.identifiedName isnt 'lsof'
        console.warn "file: #{file.name} with hash: #{file.hash} is not of type LSOF"

      if self.cf?
        self.cf.add(parsedLines)
      else
        self.cf = crossfilter(parsedLines)

      if not self.cf or self.cf?.length <= 0
        return reject(new Error("Could not properly initialize Logreaper.  No log lines found.  This could be due to an incorrectly formatted input file."))

      self.pidDim = self.cf.dimension (d) -> d.pid
      self.pidGroup = self.pidDim.group().reduceCount()

      self.userDim = self.cf.dimension (d) -> d.user
      self.userGroup = self.userDim.group().reduceCount()

      self.processDim = self.cf.dimension (d) -> d.process
      self.processGroup = self.processDim.group().reduceCount()

      self.nameDim = self.cf.dimension (d) -> d.name
      self.nameGroup = self.nameDim.group().reduceCount()

      # Create a dynamic dimension based on the dimensional field clicked
      self.dynDim = self.cf.dimension (d) -> d.user

      resolve()

  generateOpts: () ->
    opts =
      typeDisplay: 'Lsof'
      cfSize: @cf?.size() || 0

      dims:
        pidDim: @pidDim
        userDim: @userDim
        processDim: @processDim
        nameDim: @nameDim
        dynDim: @dynDim

      groups:
        pidGroup: @pidGroup
        userGroup: @userGroup
        processGroup: @processGroup
        nameGroup: @nameGroup
        methodGroup: @methodGroup

      # Include methods for handling filters in the UI
      lowerCaseFirstChar: @lowerCaseFirstChar
      buildDimName: @buildDimName
      buildGroupName: @buildGroupName
      addFilter: @addFilter
      removeFilter: @removeFilter
      reCalculateFilters: @reCalculateFilters

    opts

module.exports = ViewModelLsof
