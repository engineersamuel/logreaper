# http://stackoverflow.com/questions/11389803/example-of-using-coffeescript-classes-and-requirejs-or-curljs-or-similar-for-c
crossfilter = require('crossfilter')

# Mixins
Module                     = require '../mixins/module.coffee'
TimeSeriesMixin            = require '../mixins/TimeSeriesMixin.coffee'
ReactFilterableMixin       = require '../mixins/ReactFilterableMixin.coffee'
SeverityFieldMappingsMixin = require '../mixins/SeverityFieldMappingsMixin.coffee'
ColorMixin                 = require '../mixins/ColorMixin.coffee'
CrossfilterUtilsMixin      = require '../mixins/CrossFilterUtilsMixin.coffee'

class ViewModelLog4j extends Module

  @include TimeSeriesMixin
  @include ReactFilterableMixin
  @include SeverityFieldMappingsMixin
  @include ColorMixin
  @include CrossfilterUtilsMixin

  constructor: (opts) ->

    ##################################################################################################################
    # critical fields used by the mixins that must be instance based
    ##################################################################################################################
    @severityFieldMappings = opts?.severityFieldMappings || {}
    @start = undefined
    @end = undefined

    ##################################################################################################################
    # dimensions and groups
    ##################################################################################################################
    @infoGroup = undefined
    @errorGroup = undefined
    @warnGroup = undefined

    @severityDim = undefined
    @severityGroup = undefined
    #@logCountsGroup = undefined

    @threadDim = undefined
    @threadGroup = undefined

    @categoryDim = undefined
    @categoryGroup = undefined

    # Message dim to allow filtering on Message
    @messageDim = undefined

    # These two are for tracking the top messages by severity
    @severityMessageDim = undefined
    @errorSeverityMessageGroup = undefined

    # Tracks the top severity/category counts
    @severityCategoryDim = undefined
    @errorSeverityCategoryGroup = undefined
    @warnSeverityCategoryGroup = undefined

    # Tracks the top thread/category counts
    @severityThreadDim = undefined
    @errorSeverityThreadGroup = undefined
    @warnSeverityThreadGroup = undefined

    @viewName = 'log4jView'

    @infoLevelSeverities = ['FINE', 'TRACE', 'INFO', 'DEBUG']
    @parseSeverities = []

  ####################################################################################################################
  # Dispose of crossfilter dimensions
  ####################################################################################################################
  cleanUp: () ->
    @severityDim?.dispose()
    @threadDim?.dispose()
    @categoryDim?.dispose()
    @messageDim?.dispose()
    @severityMessageDim?.dispose()
    @severityCategoryDim?.dispose()
    @severityThreadDim?.dispose()

  ######################################################################################################################
  # To be called to process the crossfilter files
  ######################################################################################################################
  parse: (file, parsedLines, parseSeverities) ->
    self = @

    new Promise (resolve, reject) =>
      # TODO this could be data driven from the yaml
      # Setup the hash lookup for each severity -> field -> dim/group

      #['ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE']
      @parseSeverities = parseSeverities || file.identification.parseSeverities
      @initializeSeverityFieldMappings parseSeverities, ['severity', 'category', 'thread', 'message']

      # Do a quick check to make sure that there are actually parsed lines to process
      if parsedLines?.length is 0
        console.warn "file: #{file.file.name} with hash: #{file.hash} has no parsedLines"
      else if file.identification.identifiedName isnt 'log4j'
        console.warn "file: #{file.file.name} with hash: #{file.hash} is not of type Log4j"
      else
        # Setup crossfilter
        start = new Date()
        parsedLines.forEach (d) ->
          # Normalize all of the logging levels.  Generally with JBoss logs this won't do much, but I have seen WARN
          # and WARNING, both of which would be reduced to just WARN
          _.each self.parseSeverities, (sev) =>
            if _.includes(self.severityNameMapping[sev], d.severity) then d.severity = sev

        if self.cf?
          console.debug "Added #{parsedLines.length} records in #{((new Date() - start) / 1000)}s to the existing crossfilter."
          self.cf.add(parsedLines)
        else
          self.cf = crossfilter(parsedLines)
          console.debug "Bootstrapped Crossfilter with: #{parsedLines.length} records"

        #Update the estimated start and end times
        self.updateEstimatedStartTimestamp parsedLines[0]['timestamp']
        self.updateEstimatedEndTimestamp parsedLines[parsedLines.length - 1]['timestamp']

      ####################################################################################################################
      # Setup crossfilter and DC
      ####################################################################################################################
      #parseUnixOffset = d3.time.format('%m/%d/%Y')(new Date(d))

      if not self.cf or self.cf?.length <= 0
        return reject(new Error("Could not properly initialize Logreaper.  No log lines found and/or no log lines found given the selected severities. Try parsing with more severities selected."))


      self.buildTimestampDim
        cfSize: self.cf.size()
        field: 'severity'
        parsedFieldValues: self.parseSeverities
        fileName: file.file.name

      self.severityDim = self.cf.dimension (d) -> d.severity
      self.severityGroup = self.severityDim.group().reduceCount()

      self.threadDim = self.cf.dimension (d) -> d.thread
      self.threadGroup = self.threadDim.group().reduceCount()

      self.categoryDim = self.cf.dimension (d) -> d.category
      self.categoryGroup = self.categoryDim.group().reduceCount()

      self.messageDim = self.cf.dimension (d) -> d.message

      self.severityCategoryDim = self.cf.dimension (d) -> [d.severity, d.category]
      self.severityThreadDim = self.cf.dimension (d) -> [d.severity, d.thread]
      self.severityMessageDim = self.cf.dimension (d) -> [d.severity, d.message]

      _.each _.reject(self.parseSeverities, (d) -> _.includes(self.infoLevelSeverities, d)), (sev) ->
        self.severityFieldMappings[sev]['category']['group'] = self.severityCategoryDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)
        self.severityFieldMappings[sev]['thread']['group'] = self.severityThreadDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)
        self.severityFieldMappings[sev]['message']['group'] = self.severityMessageDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)

      resolve()

  generateOpts: () ->
    opts =
      typeDisplay: 'Log4j Log'
      cfSize: @cf?.size() || 0

      # Dims and groups
      dims:
        timestampDim: @timestampDim
        severityDim: @severityDim
        threadDim: @threadDim
        categoryDim: @categoryDim
        messageDim: @messageDim
        severityCategoryDim: @severityCategoryDim
        severityThreadDim: @severityThreadDim
        severityMessageDim: @severityMessageDim

      groups:
        timestampGroup: @timestampGroup
        timestampGroups: @timestampGroups # holds the <sev>Groups for each file
        severityGroup: @severityGroup
        threadGroup: @threadGroup
        categoryGroup: @categoryGroup

      # Include methods for handling filters in the UI
      lowerCaseFirstChar: @lowerCaseFirstChar
      buildDimName: @buildDimName
      buildGroupName: @buildGroupName
      #addFilter: @addFilter
      #addFilters: @addFilters
      #removeFilter: @removeFilter
      #removeFilters: @removeFilters
      #reCalculateFilters: @reCalculateFilters
      #resetRangeFilter: @resetRangeFilter
      #addRangeFilter: @addRangeFilter
      #removeRangeFilter: @removeRangeFilter
      #reCalculateRangeFilter: @reCalculateRangeFilter
      #filterRange: @filterRange
      #filterRangeAll: @filterRangeAll

      # Severity colors
      lookupColor: @lookupColor

      # Severities that were selected to be parsed
      parseSeverities: @parseSeverities
      infoLevelSeverities: @infoLevelSeverities

      # Severity field mappings to get the top Severity <whatever> counts
      severityFieldMappings: @severityFieldMappings

      # time related props
      minDate: @minDate
      maxDate: @maxDate
      durationHumanized: @durationHumanized
      d3TimeFormat: @d3TimeFormat

    # Update the opts with all parsed severity dims groups created
    _.each self.parseSeverities, (sev) =>
      sevLowerGroup = sev.toLowerCase() + "Group"
      # example would be infoGroup
      opts.groups[sevLowerGroup] = @[sevLowerGroup]

    opts

module.exports = ViewModelLog4j