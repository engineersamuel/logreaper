crossfilter = require('crossfilter')

# Mixins
Module      = require '../mixins/module.coffee'
TimeSeriesMixin            = require '../mixins/TimeSeriesMixin.coffee'
ReactFilterableMixin       = require '../mixins/ReactFilterableMixin.coffee'
SeverityFieldMappingsMixin = require '../mixins/SeverityFieldMappingsMixin.coffee'
ColorMixin                 = require '../mixins/ColorMixin.coffee'
CrossfilterUtilsMixin      = require '../mixins/CrossFilterUtilsMixin.coffee'

# TODO -- This is super similar to ViewModelLog4j, I think it only differs in fields
# Let's see how we can further parameterize to combine the two
class ViewModelVdsm extends Module

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
    @severityDim = undefined
    @severityGroup = undefined
    @logCountsGroup = undefined

    @threadIdDim = undefined
    @threadIdGroup = undefined

    @componentDim = undefined
    @componentGroup = undefined

    # Command dim to allow filtering on Command
    @messageDim = undefined

    # These two are for tracking the top messages by severity
    @severityCommandDim = undefined
    @errorSeverityCommandGroup = undefined

    # Tracks the top severity/component counts
    @severityComponentDim = undefined
    @errorSeverityComponentGroup = undefined
    @warnSeverityComponentGroup = undefined

    # Tracks the top thread/component counts
    @severityThreadIdDim = undefined
    @errorSeverityThreadIdGroup = undefined
    @warnSeverityThreadIdGroup = undefined

    @viewName = 'vdsmView'

    @infoLevelSeverities = ['TRACE', 'DEBUG', 'INFO']

    @parseSeverities = []

  ####################################################################################################################
  # Cleanup
  ####################################################################################################################
  cleanUp: () ->
    @severityDim?.dispose()
    @threadIdDim?.dispose()
    @componentDim?.dispose()
    @moduleDim?.dispose()
    @messageDim?.dispose()
    @severityCommandDim?.dispose()
    @severityComponentDim?.dispose()
    @severityThreadIdDim?.dispose()

  ######################################################################################################################
  # To be called to process the crossfilter files
  ######################################################################################################################
  parse: (file, parsedLines, parseSeverities) ->
    self = @

    new Promise (resolve, reject) =>

      @parseSeverities = parseSeverities || file.identification.parseSeverities
      @initializeSeverityFieldMappings parseSeverities, ['threadId', 'severity', 'component', 'module', 'functionName', 'command']

      # Do a quick check to make sure that there are actually parsed lines to process
      if parsedLines?.length is 0
        console.warn "file: #{file.file.name} with hash: #{file.hash} has no parsedLines"
      else if file.identification.identifiedName isnt 'vdsm'
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

      if not self.cf or self.cf?.length <= 0
        return reject(new Error("Could not properly initialize Logreaper.  No log lines found and/or no log lines found given the selected severities.  Try parsing with more severities selected."))

      self.threadIdDim = self.cf.dimension (d) -> d.threadId
      self.threadIdGroup = self.threadIdDim.group().reduceCount()

      self.severityDim = self.cf.dimension (d) -> d.severity
      self.severityGroup = self.severityDim.group().reduceCount()

      self.componentDim = self.cf.dimension (d) -> d.component
      self.componentGroup = self.componentDim.group().reduceCount()

      self.moduleDim = self.cf.dimension (d) -> d.module
      self.moduleGroup = self.moduleDim.group().reduceCount()

      self.commandDim = self.cf.dimension (d) -> d.command

      self.buildTimestampDim
        cfSize: self.cf.size()
        field: 'severity'
        parsedFieldValues: self.parseSeverities
        fileName: file.file.name

      self.severityThreadIdDim = self.cf.dimension (d) -> [d.severity, d.threadId]
      self.severityComponentDim = self.cf.dimension (d) -> [d.severity, d.component]
      self.severityModuleDim = self.cf.dimension (d) -> [d.severity, d.module]
      self.severityCommandDim = self.cf.dimension (d) -> [d.severity, d.command]

      _.each _.reject(self.parseSeverities, (d) -> _.includes(self.infoLevelSeverities, d)), (sev) ->
        self.severityFieldMappings[sev]['threadId']['group'] = self.severityThreadIdDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)
        self.severityFieldMappings[sev]['component']['group'] = self.severityComponentDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)
        self.severityFieldMappings[sev]['module']['group'] = self.severityModuleDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)
        self.severityFieldMappings[sev]['command']['group'] = self.severityCommandDim.group().reduce(self.reduceAddSeverity(sev), self.reduceRemoveSeverity(sev), self.reduceInitialSeverity(sev)).order(self.orderValue)

      resolve()

  generateOpts: () ->
    self = @
    opts =
      typeDisplay: 'VDSM Log'
      cfSize: self.cf?.size() || 0
      fileNames: self.fileNames

      # Dims and groups
      dims:
        timestampDim: @timestampDim
        severityDim: @severityDim
        threadIdDim: @threadIdDim
        componentDim: @componentDim
        moduleDim: @moduleDim
        commandDim: @commandDim
        severityThreadIdDim: @severityThreadIdDim
        severityComponentDim: @severityComponentDim
        severityModuleDim: @severityModuleDim
        severityCommandDim: @severityCommandDim

      groups:
        timestampGroup: @timestampGroup
        timestampGroups: @timestampGroups # holds the <sev>Groups for each file
        severityGroup: @severityGroup
        threadIdGroup: @threadIdGroup
        componentGroup: @componentGroup
        moduleGroup: @moduleGroup

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

      # Severity colors
      lookupColor: @lookupColor

      # Severities that were selected to be parsed
      parseSeverities: self.parseSeverities
      infoLevelSeverities: @infoLevelSeverities

      # Severity field mappings to get the top Severity <whatever> counts
      severityFieldMappings: self.severityFieldMappings

      # time related props
      minDate: @minDate
      maxDate: @maxDate
      durationHumanized: @durationHumanized
      d3TimeFormat: @d3TimeFormat

    # Update the opts with all parsed severity dims groups created
    _.each self.parseSeverities, (sev) ->
      sevLowerGroup = sev.toLowerCase() + "Group"
      # example would be infoGroup
      opts.groups[sevLowerGroup] = self[sevLowerGroup]

    opts

module.exports = ViewModelVdsm