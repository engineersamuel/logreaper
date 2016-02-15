# http://stackoverflow.com/questions/11389803/example-of-using-coffeescript-classes-and-requirejs-or-curljs-or-similar-for-c
crossfilter = require('crossfilter')

# Mixins
Module                     = require '../mixins/module.coffee'
TimeSeriesMixin            = require '../mixins/TimeSeriesMixin.coffee'
#HashLookupMixin            = require '../mixins/HashLookupMixin.coffee'
ReactFilterableMixin       = require '../mixins/ReactFilterableMixin.coffee'
ColorMixin                 = require '../mixins/ColorMixin.coffee'
#FileNamesMixin             = require '../mixins/FileNamesMixin.coffee'
CrossfilterUtilsMixin      = require '../mixins/CrossFilterUtilsMixin.coffee'

class ViewModelApacheAccess extends Module

  @include TimeSeriesMixin
  #@include HashLookupMixin
  @include ReactFilterableMixin
  @include CrossfilterUtilsMixin
  @include ColorMixin
  #@include FileNamesMixin

  constructor: (opts) ->
    ##################################################################################################################
    # critical fields used by the mixins that must be instance based
    ##################################################################################################################
    @start = undefined
    @end = undefined

    ####################################################################################################################
    # dimensions and groups
    ####################################################################################################################
    @ipDim = undefined
    @ipGroup = undefined

    @statusDim = undefined
    @statusGroup = undefined

    @userAgentDim = undefined
    @userAgentGroup = undefined

    @methodDim = undefined
    @methodGroup = undefined

    # Dynamic Dimension to handle filters from clicking in the chart
    @dynDim = undefined

    # Unique array of all statuses seen in the log
    @statusesInLog = undefined

    # The full set of http codes to potentially parse out.  Use this mainly to ignore the ones we don't want
    @httpCodes = undefined

    # The actual statuses to display
    @statusesToDisplay = undefined

    @logTypeName = 'accessLog'
    @viewName = 'accessLogView'

    # Crossfilter instance
    @cf = undefined

    @cappedSize = 500

  ####################################################################################################################
  # Cleanup
  ####################################################################################################################
  cleanUp: () ->
    @ipDim.dispose()
    @statusDim.dispose()
    @userAgentDim.dispose()
    @methodDim.dispose()
    @dynDim.dispose()

  ######################################################################################################################
  # To be called to process the crossfilter files
  ######################################################################################################################
  parse: (file, parsedLines, parseSeverities) ->
    self = @
    new Promise (resolve, reject) =>

      # Do a quick check to make sure that there are actually parsed lines to process
      if parsedLines?.length is 0
        console.warn "file: #{file.name} with hash: #{file.hash} has no parsedLines"
      else if file.identification.identifiedName isnt 'accessLog'
        console.warn "file: #{file.name} with hash: #{file.hash} is not of type Apache"
      else
        if self.cf?
          self.cf.add(parsedLines)
        else
          self.cf = crossfilter(parsedLines)

        #Update the estimated start and end times
        self.updateEstimatedStartTimestamp parsedLines[0]['timestamp']
        self.updateEstimatedEndTimestamp parsedLines[parsedLines.length - 1]['timestamp']

      @statusesInLog = _.chain(parsedLines).map('status').uniq().value()
      @parseStatuses = parseSeverities

      # Flatten out all of the the http codes to be potentially extracted
      @httpCodes = _.chain(file.identification.format.value.status.values).filter((v) -> _.includes(parseSeverities, v['label'])).map('values').flatten().value();

      # Calculates the actual statuses to display.  This is a bit complicated as we have to peak instead each potential error code from the top level, like 20x == 201, 202, 203, ect..
      @statusesToDisplay = _.filter(@statusesInLog, (status) -> _.includes(self.httpCodes, status))

      console.debug("Potential httpCodes: #{JSON.stringify(@httpCodes)}")

      if not self.cf or self.cf?.length <= 0
        return reject(new Error("Could not properly initialize Logreaper.  No log lines found and/or no log lines found given the selected http codes.  Try parsing with more http codes selected."))

      ####################################################################################################################
      # Build out the time series related info
      ####################################################################################################################
      self.buildTimestampDim
        cfSize: self.cf.size()
        field: 'status'
        parsedFieldValues: self.statusesToDisplay
        fileName: file.name

      # This will iterate over values like [200, 304, 500]
      # TODO -- If the status is in the selected statuses to parse
      #_.each @parseStatuses, (status) ->
      @statusesToDisplay.forEach (s) ->
        self["#{s}Group"] = self.timestampDim.group().reduce(self.reduceAddField('status', s), self.reduceRemoveField('status', s), self.reduceInitialField('status', s)).order(self.orderValue)

      @ipDim = self.cf.dimension (d) -> d.ip
      @ipGroup = @ipDim.group().reduceCount()

      @statusDim = @cf.dimension (d) -> d.status
      @statusGroup = @statusDim.group().reduceCount()

      @userAgentDim = @cf.dimension (d) -> d.userAgent
      @userAgentGroup = @userAgentDim.group().reduceCount()

      @uriStemDim = @cf.dimension (d) -> d.uriStem
      @uriStemGroup = @uriStemDim.group().reduceCount()

      @methodDim = @cf.dimension (d) -> d.method
      @methodGroup = @methodDim.group().reduceCount()

      # Create a dynamic dimension based on the dimensional field clicked
      @dynDim = @cf.dimension (d) -> d.ip

      resolve()

  generateOpts: () ->
    opts =
      typeDisplay: 'Apache Access'
      cfSize: @cf?.size() || 0
      parseStatuses: @parseStatuses
      statusesToDisplay: @statusesToDisplay

      dims:
        timestampDim: @timestampDim
        statusDim: @statusDim
        userAgentDim: @userAgentDim
        uriStemDim: @uriStemDim
        methodDim: @methodDim
        ipDim: @ipDim
        dynDim: @dynDim

      groups:
        timestampGroup: @timestampGroup
        timestampGroups: @timestampGroups # holds the <sev>Groups for each file
        statusGroup: @statusGroup
        userAgentGroup: @userAgentGroup
        uriStemGroup: @uriStemGroup
        methodGroup: @methodGroup
        ipGroup: @ipGroup
        methodGroup: @methodGroup

      # Include the status color lookup for resolving status colors
      lookupColor: @lookupColor

      # Include methods for handling filters in the UI
      lowerCaseFirstChar: @lowerCaseFirstChar
      buildDimName: @buildDimName
      buildGroupName: @buildGroupName
      #addFilter: @addFilter
      #removeFilter: @removeFilter
      #reCalculateFilters: @reCalculateFilters
      # Range filters
      #addRangeFilter: @addRangeFilter
      #removeRangeFilter: @removeRangeFilter
      #reCalculateRangeFilter: @reCalculateRangeFilter

      # time related props
      minDate: @minDate
      maxDate: @maxDate
      durationHumanized: @durationHumanized
      d3TimeFormat: @d3TimeFormat

    # Update the opts with all parsed status dims groups created
    #_.each @parseStatuses, (status) =>
    @statusesToDisplay.forEach (s) ->
      statusGroup = status + "Group"
      # example would be 200Group
      opts.groups[statusGroup] = @[statusGroup]

    opts

module.exports = ViewModelApacheAccess
