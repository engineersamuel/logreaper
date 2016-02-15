crossfilter = require('crossfilter')

# Mixins
Module                     = require '../mixins/module.coffee'
TimeSeriesMixin            = require '../mixins/TimeSeriesMixin.coffee'
ReactFilterableMixin       = require '../mixins/ReactFilterableMixin.coffee'
SeverityFieldMappingsMixin = require '../mixins/SeverityFieldMappingsMixin.coffee'
ColorMixin                 = require '../mixins/ColorMixin.coffee'
CrossfilterUtilsMixin      = require '../mixins/CrossFilterUtilsMixin.coffee'

class ViewModelSyslog extends Module

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

    ####################################################################################################################
    # dimensions and groups
    ####################################################################################################################
    @infoGroup = undefined
    @errorGroup = undefined
    @warnGroup = undefined

    @facilityDim = undefined
    @facilityGroup = undefined

    @hostnameDim = undefined
    @hostnameGroup = undefined

    @procidDim = undefined
    @procidGroup = undefined

    @severityDim = undefined
    @severityGroup = undefined

    # Message dim to allow filtering on Message
    @messageDim = undefined

    ####################################################################################################################
    # Tracks the top severity/facility counts
    ####################################################################################################################
    @severityFacilityDim = undefined
    @errorLikeSeverityFacilityGroup = undefined
    @emergSeverityFacilityGroup = undefined
    @alertSeverityFacilityGroup = undefined
    @errorSeverityFacilityGroup = undefined
    @critSeverityFacilityGroup = undefined
    @warnSeverityFacilityGroup = undefined

    ####################################################################################################################
    # Tracks the top severity/procid counts
    ####################################################################################################################
    @severityProcidDim = undefined
    @errorLikeSeverityProcidGroup = undefined
    @emergSeverityProcidGroup = undefined
    @alertSeverityProcidGroup = undefined
    @errorSeverityProcidGroup = undefined
    @critSeverityProcidGroup = undefined
    @warnSeverityProcidGroup = undefined

    ####################################################################################################################
    # Tracks the top severity/message counts
    ####################################################################################################################
    @severityMessageDim = undefined
    @errorLikeSeverityMessageGroup = undefined
    @emergSeverityMessageGroup = undefined
    @alertSeverityMessageGroup = undefined
    @errorSeverityMessageGroup = undefined
    @critSeverityMessageGroup = undefined
    @warnSeverityMessageGroup = undefined

    ####################################################################################################################
    # Stores data for the d3 charts
    ####################################################################################################################
    @topSeverityCounts = undefined
    @topThreadCounts = undefined
    @topCategoryCounts = undefined

    @topErrorLikeSeverityFacilityGroup = undefined
    @topEmergSeverityFacilityGroup = undefined
    @topAlertSeverityFacilityGroup = undefined
    @topErrorSeverityFacilityGroup = undefined
    @topCritSeverityFacilityGroup = undefined
    @topWarnSeverityFacilityGroup = undefined

    @topErrorLikeSeverityProcidGroup = undefined
    @topEmergSeverityProcidGroup = undefined
    @topAlertSeverityProcidGroup = undefined
    @topErrorSeverityProcidGroup = undefined
    @topCritSeverityProcidGroup = undefined
    @topWarnSeverityProcidGroup = undefined

    @topErrorLikeSeverityMessageGroup = undefined
    @topEmergSeverityMessageGroup = undefined
    @topAlertSeverityMessageGroup = undefined
    @topErrorSeverityMessageGroup = undefined
    @topCritSeverityMessageGroup = undefined
    @topWarnSeverityMessageGroup = undefined

    @viewName = 'syslogView'

    @infoLevelSeverities = ['TRACE', 'DEBUG', 'INFO', 'NOTICE']
    @parseSeverities = []

  ####################################################################################################################
  # Cleanup and resetting -- Must clean up observables and computed otherwise references will be help in memory
  # and this class won't properly be cleaned up by the browser
  ####################################################################################################################
  cleanUp: () ->
    @procidDim?.dispose()
    @hostnameDim?.dispose()
    @facilityDim?.dispose()
    @severityDim?.dispose()
    @messageDim?.dispose()
    @severityFacilityDim?.dispose()
    @severityProcidDim?.dispose()
    @severityMessageDim?.dispose()

  ######################################################################################################################
  # To be called to process the crossfilter files
  ######################################################################################################################
  parse: (file, parsedLines, parseSeverities) ->
    self = @

    new Promise (resolve, reject) =>

      @parseSeverities = parseSeverities || file.identification.parseSeverities
      @initializeSeverityFieldMappings @parseSeverities, ['hostname', 'facility', 'procid', 'message', 'severity']

      # Do a quick check to make sure that there are actually parsed lines to process
      if parsedLines?.length is 0
        console.warn "file: #{file.file.name} with hash: #{file.hash} has no parsedLines"
      else if file.identification.identifiedName isnt 'syslog'
        console.warn "file: #{file.file.name} with hash: #{file.hash} is not of type Syslog"
      else
        # Setup crossfilter
        start = new Date()
        parsedLines.forEach (d) ->
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

      if not self.cf or self.cf?.length <= 0
        return reject(new Error("Could not properly initialize Logreaper.  No log lines found and/or no log lines found given the selected severities.  Try parsing with more severities selected."))

      self.severityDim = self.cf.dimension (d) -> d.severity
      self.severityGroup = self.severityDim.group().reduceCount()

      self.procidDim = self.cf.dimension (d) -> d.procid
      self.procidGroup = self.procidDim.group().reduceCount()

      self.facilityDim = self.cf.dimension (d) -> d.facility
      self.facilityGroup = self.facilityDim.group().reduceCount()

      self.messageDim = self.cf.dimension (d) -> d.message

      self.buildTimestampDim
        cfSize: self.cf.size()
        field: 'severity'
        parsedFieldValues: self.parseSeverities
        fileName: file.file.name

      _.each self.parseSeverities, (sev) ->
        sevLower = sev.toLowerCase()
        # Ex. infoGroup
        self["#{sevLower}Group"] = self.timestampDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)

      self.severityFacilityDim = self.cf.dimension (d) -> [d.severity, d.facility]
      _.each _.reject(self.parseSeverities, (d) -> _.includes(self.infoLevelSeverities, d)), (sev) ->
        self.severityFieldMappings[sev]['facility']['group'] = self.severityFacilityDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)

      self.severityProcidDim = self.cf.dimension (d) -> [d.severity, d.procid]
      _.each _.reject(self.parseSeverities, (d) -> _.includes(self.infoLevelSeverities, d)), (sev) ->
        self.severityFieldMappings[sev]['procid']['group'] = self.severityProcidDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)

      self.severityMessageDim = self.cf.dimension (d) -> [d.severity, d.message]
      _.each _.reject(self.parseSeverities, (d) -> _.includes(self.infoLevelSeverities, d)), (sev) ->
        self.severityFieldMappings[sev]['message']['group'] = self.severityMessageDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)

      resolve()

  generateOpts: () ->
    self = @
    opts =
      typeDisplay: 'Syslog Log'
      cfSize: @cf?.size() || 0

      # Dims and groups
      dims:
        timestampDim: @timestampDim
        severityDim: @severityDim
        procidDim: @procidDim
        facilityDim: @facilityDim
        messageDim: @messageDim
        severityFacilityDim: @severityFacilityDim
        severityProcidDim: @severityProcidDim
        severityMessageDim: @severityMessageDim

      groups:
        timestampGroup: @timestampGroup
        timestampGroups: @timestampGroups # holds the <sev>Groups for each file
        severityGroup: @severityGroup
        facilityGroup: @facilityGroup
        procidGroup: @procidGroup

      # Handle the field lookups
      #fieldHashes: @fieldHashes
      #lookup: @lookup.bind(self)
      #inverseLookup: @inverseLookup.bind(self)

      # Include methods for handling filters in the UI
      #lowerCaseFirstChar: @lowerCaseFirstChar
      #buildDimName: @buildDimName
      #buildGroupName: @buildGroupName
      #addFilter: @addFilter
      #addFilters: @addFilters
      #removeFilter: @removeFilter
      #removeFilters: @removeFilters
      #reCalculateFilters: @reCalculateFilters
      #resetRangeFilter: @resetRangeFilter
      #addRangeFilter: @addRangeFilter
      #removeRangeFilter: @removeRangeFilter
      #reCalculateRangeFilter: @reCalculateRangeFilter

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
      #makeTimestampFieldDygraphData: @makeTimestampFieldDygraphData
      #makeTimestampGroupsFieldDygraphData: @makeTimestampGroupsFieldDygraphData
      d3TimeFormat: @d3TimeFormat

    # Update the opts with all parsed severity dims groups created
    _.each @parseSeverities, (sev) ->
      sevLowerGroup = sev.toLowerCase() + "Group"
      # example would be infoGroup
      opts.groups[sevLowerGroup] = self[sevLowerGroup]

    opts

module.exports = ViewModelSyslog
