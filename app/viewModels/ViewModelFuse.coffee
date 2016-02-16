# http://stackoverflow.com/questions/11389803/example-of-using-coffeescript-classes-and-requirejs-or-curljs-or-similar-for-c
React       = require 'react'
_           = require 'lodash'
crossfilter = require('crossfilter').crossfilter
async       = require 'async'
moment      = require 'moment'
strata      = require 'strata'

FuseView    = require '../../../react_components/views/fuseView.coffee'

# Mixins
Module                     = require '../mixins/module.coffee'
TimeSeriesMixin            = require '../mixins/TimeSeriesMixin.coffee'
HashLookupMixin            = require '../mixins/HashLookupMixin.coffee'
ReactFilterableMixin       = require '../mixins/ReactFilterableMixin.coffee'
SeverityFieldMappingsMixin = require '../mixins/SeverityFieldMappingsMixin.coffee'
ColorMixin                 = require '../mixins/ColorMixin.coffee'
FileNamesMixin             = require '../mixins/FileNamesMixin.coffee'
CrossfilterUtilsMixin      = require '../mixins/CrossFilterUtilsMixin.coffee'

class ViewModelFuse extends Module

  @include TimeSeriesMixin
  @include HashLookupMixin
  @include ReactFilterableMixin
  @include SeverityFieldMappingsMixin
  @include ColorMixin
  @include FileNamesMixin
  @include CrossfilterUtilsMixin

  constructor: (opts) ->

    ##################################################################################################################
    # critical fields used by the mixins that must be instance based
    ##################################################################################################################
    @fieldHashes = opts?.fieldHashes || {}
    @severityFieldMappings = opts?.severityFieldMappings || {}
    @addLookupValue = opts?.addLookupValue || @addLookupValue
    @lookup = opts?.lookup || @lookup
    @inverseLookup = opts?.inverseLookup || @inverseLookup
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

    @componentDim = undefined
    @componentGroup = undefined

    # Message dim to allow filtering on Message
    @messageDim = undefined

    # These two are for tracking the top messages by severity
    @severityMessageDim = undefined
    @errorSeverityMessageGroup = undefined

    # Tracks the top severity/category counts
    @severityCategoryDim = undefined
    @errorSeverityCategoryGroup = undefined
    @warnSeverityCategoryGroup = undefined

    # Tracks the top severity/component counts
    @severityComponentDim = undefined
    @errorSeverityComponentGroup = undefined
    @warnSeverityComponentGroup = undefined

    # Tracks the top severity Thread counts
    @severityThreadDim = undefined
    @errorSeverityThreadGroup = undefined
    @warnSeverityThreadGroup = undefined

    @logTypeName = 'fuse'
    @logTypeFilter = (f) => f.extra.identification.identifiedName is @logTypeName
    @viewName = 'fuseView'
    @fileNames = []

    @parseSeverities = []

  ####################################################################################################################
  # Cleanup and resetting -- Must clean up observables and computed otherwise references will be help in memory
  # and this class won't properly be cleaned up by the browser
  ####################################################################################################################
  cleanUp: () ->
    @fieldHashes = undefined
    @severityFieldMappings = undefined
    @start = undefined
    @end = undefined

    # And the rest
    @infoGroup = undefined
    @errorGroup = undefined
    @warnGroup = undefined

    @severityDim?.dispose()
    @severityDim = undefined
    @severityGroup = undefined
    #@logCountsGroup = undefined

    @threadDim?.dispose()
    @threadDim = undefined
    @threadGroup = undefined

    @categoryDim?.dispose()
    @categoryDim = undefined
    @categoryGroup = undefined

    @componentDim?.dispose()
    @componentDim = undefined
    @componentGroup = undefined

    # Message dim to allow filtering on Message
    @messageDim?.dispose()
    @messageDim = undefined

    # These two are for tracking the top messages by severity
    @severityMessageDim?.dispose()
    @severityMessageDim = undefined
    @errorSeverityMessageGroup = undefined

    # Tracks the top severity/category counts
    @severityCategoryDim?.dispose()
    @severityCategoryDim = undefined
    @errorSeverityCategoryGroup = undefined
    @warnSeverityCategoryGroup = undefined

    # Tracks the top severity/component counts
    @severityComponentDim?.dispose()
    @severityComponentDim = undefined
    @errorSeverityComponentGroup = undefined
    @warnSeverityComponentGroup = undefined

    # Tracks the top thread/category counts
    @severityThreadDim?.dispose()
    @severityThreadDim = undefined
    @errorSeverityThreadGroup = undefined
    @warnSeverityThreadGroup = undefined

    # Once all dims and groups are nulled out, the React components can be properly GC'd
    try
      React.unmountComponentAtNode document.getElementById(@viewName)
    catch e
      undefined

  ######################################################################################################################
  # To be called to process the crossfilter files
  ######################################################################################################################
  parse: (parseCallback) ->
    self = @

    # Start post processing
    window.viewModels.viewModelFileUpload.postProcessing = true
    window.viewModels.viewModelFileUpload.postProcessingProgress = []

    @setFileNames @logTypeFilter

    # TODO this could be data driven from the yaml
    # Setup the hash lookup for each severity -> field -> dim/group
    self.initializeSeverityFieldMappings ['ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'], ['severity', 'category', 'component', 'thread', 'message']

    # Make sure to only parse out fuse type logs from the input
    _.each _.filter(window.viewModels.viewModelFileUpload.files, @logTypeFilter), (f, idx) ->

      self.parseSeverities = f.extra.parseSeverities

      # Do a quick check to make sure that there are actually parsed lines to process
      if f.extra.parsedLines?.length is 0
        console.warn "file: #{f.extra.name} with hash: #{f.extra.hash} has no parsedLines"
        #cb {warn: "file: #{f.extra.name} with hash: #{f.extra.hash} has no parsedLines"}, null
      else if f.extra.identification.identifiedName isnt 'fuse'
        console.warn "file: #{f.extra.name} with hash: #{f.extra.hash} is not of type Fuse"
        #cb {warn: "file: #{f.extra.name} with hash: #{f.extra.hash} is not a syslog file, not parsing in this class"}, null
      else
        # Setup crossfilter
        #console.debug "Normalizing #{f.extra.parsedLines.length} parsedLines"
        start = new Date()
        f.extra.parsedLines.forEach (d) ->
          # Normalize all of the logging levels.  Generally with JBoss logs this won't do much, but I have seen WARN
          # and WARNING, both of which would be reduced to just WARN
          _.each f.extra.parseSeverities, (sev) ->
            if _.contains(self.severityNameMapping[sev], d.severity) then d.severity = sev

          # For each field in the log entry object, map it to the fieldHashes
          _.reject(_.keys(d), (k) -> k is 'timestamp').forEach (key) ->
            self.addLookupValue key, d[key]
            d[key] = self.inverseLookup key, d[key]

        # Build a quick lookup of common idxs
        _.each f.extra.parseSeverities, (sev) ->
          self[sev.toLowerCase() + 'Idx'] = self.inverseLookup('severity', sev)

        if self.cf?
          self.cf.add(f.extra.parsedLines)
        else
          self.cf = crossfilter(f.extra.parsedLines)

        #Update the estimated start and end times
        self.updateEstimatedStartTimestamp f.extra.parsedLines[0]['timestamp']
        self.updateEstimatedEndTimestamp f.extra.parsedLines[f.extra.parsedLines.length - 1]['timestamp']

    ####################################################################################################################
    # Setup crossfilter and DC
    ####################################################################################################################
    #parseUnixOffset = d3.time.format('%m/%d/%Y')(new Date(d))

    if not self.cf or self.cf?.length <= 0
      parseCallback()
      return

    self.severityDim = self.cf.dimension (d) -> d.severity
    self.severityGroup = self.severityDim.group().reduceCount()

    self.threadDim = self.cf.dimension (d) -> d.thread
    self.threadGroup = self.threadDim.group().reduceCount()

    self.categoryDim = self.cf.dimension (d) -> d.category
    self.categoryGroup = self.categoryDim.group().reduceCount()

    self.componentDim = self.cf.dimension (d) -> d.component
    self.componentGroup = self.componentDim.group().reduceCount()

    self.messageDim = self.cf.dimension (d) -> d.message

    # The unique hashes of all file names for this log type.  So if just one log input, will always be 0
    # If two logs input, would be [0, 1]
    self.fileNameIdxs = _.keys self.fieldHashes.fileName.lookup
    self.buildTimestampDim
      cfSize: self.cf.size()
      field: 'severity'
      parsedFieldValues: self.parseSeverities
      fileNameIdxs: self.fileNameIdxs

    ##########################################
    # Project over the severity and category
    ##########################################
    self.severityCategoryDim = self.cf.dimension (d) -> [d.severity, d.category]
    # Count the errors in this projection
    self.severityFieldMappings['ERROR']['category']['group'] = self.severityCategoryDim.group().reduce(self.reduceAddSeverity(self.errorIdx), self.reduceRemoveSeverity(self.errorIdx), self.reduceInitialSeverity(self.errorIdx)).order(self.orderValue)
    self.severityFieldMappings['WARN']['category']['group'] = self.severityCategoryDim.group().reduce(self.reduceAddSeverity(self.warnIdx), self.reduceRemoveSeverity(self.warnIdx), self.reduceInitialSeverity(self.warnIdx)).order(self.orderValue)

    ##########################################
    # Project over the severity and component
    ##########################################
    self.severityComponentDim = self.cf.dimension (d) -> [d.severity, d.category]
    # Count the errors in this projection
    self.severityFieldMappings['ERROR']['category']['group'] = self.severityComponentDim.group().reduce(self.reduceAddSeverity(self.errorIdx), self.reduceRemoveSeverity(self.errorIdx), self.reduceInitialSeverity(self.errorIdx)).order(self.orderValue)
    self.severityFieldMappings['WARN']['category']['group'] = self.severityComponentDim.group().reduce(self.reduceAddSeverity(self.warnIdx), self.reduceRemoveSeverity(self.warnIdx), self.reduceInitialSeverity(self.warnIdx)).order(self.orderValue)

    ##########################################
    # Project over the severity and thread
    ##########################################
    self.severityThreadDim = self.cf.dimension (d) -> [d.severity, d.thread]
    # Count the errors in this projection
    self.severityFieldMappings['ERROR']['thread']['group'] = self.severityThreadDim.group().reduce(self.reduceAddSeverity(self.errorIdx), self.reduceRemoveSeverity(self.errorIdx), self.reduceInitialSeverity(self.errorIdx)).order(self.orderValue)
    self.severityFieldMappings['WARN']['thread']['group'] = self.severityThreadDim.group().reduce(self.reduceAddSeverity(self.warnIdx), self.reduceRemoveSeverity(self.warnIdx), self.reduceInitialSeverity(self.warnIdx)).order(self.orderValue)

    ##########################################
    # Project over the severity and message
    ##########################################
    self.severityMessageDim = self.cf.dimension (d) -> [d.severity, d.message]
    # Count the errors in this projection
    self.severityFieldMappings['ERROR']['message']['group'] = self.severityMessageDim.group().reduce(self.reduceAddSeverity(self.errorIdx), self.reduceRemoveSeverity(self.errorIdx), self.reduceInitialSeverity(self.errorIdx)).order(self.orderValue)
    self.severityFieldMappings['WARN']['message']['group'] = self.severityMessageDim.group().reduce(self.reduceAddSeverity(self.warnIdx), self.reduceRemoveSeverity(self.warnIdx), self.reduceInitialSeverity(self.warnIdx)).order(self.orderValue)

    # Create a group for the total count over time.
    #self.logCountsGroup = self.timestampDim.group((d) -> d.count).reduceSum()

    parseCallback()

  handlePostProcess: () ->
    ##########################################
    # Ensure the post processing elements are removed
    ##########################################
    viewModels.viewModelFileUpload.postProcessing = false
    viewModels.viewModelFileUpload.updatePostProcessingOutput()

    #viewModels.viewModelFileUpload.cleanUpPostParse()
    viewModels.viewModelFileUpload.updateSubViews()

  generateOpts: () ->
    self = @
    opts =
      typeDisplay: 'Fuse Log'
      cfSize: self.cf?.size() || 0
      fileNames: self.fileNames

      # Dims and groups
      dims:
        timestampDim: @timestampDim
        severityDim: @severityDim
        threadDim: @threadDim
        categoryDim: @categoryDim
        componentDim: @componentDim
        messageDim: @messageDim
        severityCategoryDim: @severityCategoryDim
        severityComponentDim: @severityComponentDim
        severityThreadDim: @severityThreadDim
        severityMessageDim: @severityMessageDim

      groups:
        timestampGroup: @timestampGroup
        timestampGroups: @timestampGroups # holds the <sev>Groups for each file
        severityGroup: @severityGroup
        threadGroup: @threadGroup
        categoryGroup: @categoryGroup
        componentGroup: @componentGroup


      # Handle the field lookups
      fieldHashes: @fieldHashes
      lookup: @lookup.bind(@)
      inverseLookup: @inverseLookup.bind(@)

      # Include methods for handling filters in the UI
      lowerCaseFirstChar: @lowerCaseFirstChar
      buildDimName: @buildDimName
      buildGroupName: @buildGroupName
      addFilter: @addFilter
      addFilters: @addFilters
      removeFilter: @removeFilter
      removeFilters: @removeFilters
      reCalculateFilters: @reCalculateFilters
      resetRangeFilter: @resetRangeFilter
      addRangeFilter: @addRangeFilter
      removeRangeFilter: @removeRangeFilter
      reCalculateRangeFilter: @reCalculateRangeFilter
      filterRange: @filterRange
      filterRangeAll: @filterRangeAll

      # Severity colors
      lookupColor: @lookupColor

      # Severities that were selected to be parsed
      parseSeverities: self.parseSeverities
      parseSeveritiesLower: _.map(self.parseSeverities, (s) -> s.toLowerCase())

      # Severity field mappings to get the top Severity <whatever> counts
      severityFieldMappings: self.severityFieldMappings

      # time related props
      minDate: @minDate
      maxDate: @maxDate
      durationHumanized: @durationHumanized
      #makeTimestampFieldDygraphData: self.makeTimestampFieldDygraphData
      makeTimestampGroupsFieldDygraphData: @makeTimestampGroupsFieldDygraphData

    # Update the opts with all parsed severity dims groups created
    _.each self.parseSeverities, (sev) ->
      sevLowerGroup = sev.toLowerCase() + "Group"
      # example would be infoGroup
      opts.groups[sevLowerGroup] = self[sevLowerGroup]

    opts

  render: (opts) ->
    React.renderComponent (FuseView opts), document.getElementById(@viewName)

module.exports = ViewModelFuse