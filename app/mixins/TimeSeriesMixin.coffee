moment  = require 'moment'
_       = require 'lodash'
d3      = require 'd3'

fiveMinusInMs = 300000
oneHourInMs = 3000600
twelveHoursInMS = 43200000
oneDayInMs = 86400000
threeDaysInMs = oneDayInMs * 3

Mixin =
  d3TimeGranularity: undefined
  d3TimeGranularityDisplay: undefined
  timeTransform: undefined
  duration: undefined
  durationHumanized: undefined
  start: undefined
  end: undefined

  # accepts cfSize and logType
  # https://github.com/mbostock/d3/wiki/Time-Formatting
  determineTimeGranularity: (opts) ->
    # 15 hours HH
    @duration = @end - @start
    #console.debug "Duration determined to be: #{moment.duration(@duration, 'milliseconds').humanize()}"
    @durationHumanized = moment.duration(@duration, 'milliseconds').humanize()

    # If the cfSizse is less than 1000, that is 1000 data points, short circuit to seconds
    # Also if this is a gc log, only interested in the finest granularity
    if opts.cfSize < 1000 or opts.logType is 'gc'
    #if opts.cfSize < 1000
      @timeFormat = 'YYYY-MM-DD HH:mm:ss'
      # The time is the second, effectively do nothing
      @timeTransform = (t) -> t
      @d3TimeGranularity = d3.time.second
      @d3TimeGranularityDisplay = "1 second"
      @d3TimeFormat = d3.time.format('%I:%M:%S')
    # If duration is less than an 5 hours, use minutes, that'd be 60*5=300 plot points
    else if @duration <= (1000 * 60 * 60 * 5)
      @timeFormat = 'YYYY-MM-DD HH:mm'
      # Floor the time to the minute
      @timeTransform = (t) -> Math.floor( t / (60 * 1000)) * (60 * 1000)
      @d3TimeGranularity = d3.time.minute
      @d3TimeGranularityDisplay = "1 minute"
      @d3TimeFormat = d3.time.format('%I:%M')
    # If duration is less than an 10 days, use hours, that'd be up to 24*10=240 plot points
    else if @duration <= (1000 * 60 * 60 * 24 * 10)
      @timeFormat = 'YYYY-MM-DD HH'
      # Floor the time to the minute
      @timeTransform = (t) -> Math.floor( t / (1000 * 60 * 60)) * (1000 * 60 * 60)
      @d3TimeGranularity = d3.time.hour
      @d3TimeGranularityDisplay = "1 hour"
      @d3TimeFormat = d3.time.format('%I:%M')
    # Otherwise use days
    else
      @timeFormat = 'YYYY-MM-DD'
      # Floor the time to the minute
      @timeTransform = (t) -> Math.floor( t / (1000 * 60 * 60 * 24)) * (1000 * 60 * 60 * 24)
      @d3TimeGranularity = d3.time.day
      @d3TimeGranularityDisplay = "1 day"
      @d3TimeFormat = d3.time.format('%x')

    #console.debug "Time granularity set to: #{@d3TimeGranularityDisplay}"


  updateEstimatedStartTimestamp: (estimatedStart) ->
    if @start is undefined or estimatedStart < @start
      @start = estimatedStart

  updateEstimatedEndTimestamp: (estimatedEnd) ->
    if @end is undefined or estimatedEnd > @end
      @end = estimatedEnd

  # I am iffy on the full ramifications of normalizing these times, I know it is necessary for the zoom logic in the dygraph
  # and I doubt it will ever cause a significant issue, but it is rounding the time, be ware.  When I say round I mean
  # transforming the time to the second or minute.  This is necessary though how things are currently constructed
  setDateBounds: () ->
    self = @
    #self.minDate = self.timestampDim.bottom(1)[0].timestamp
    #self.maxDate = self.timestampDim.top(1)[0].timestamp
    self.minDate = self.timeTransform.call @, self.timestampDim.bottom(1)[0].timestamp
    self.maxDate = self.timeTransform.call @, self.timestampDim.top(1)[0].timestamp
    self = null

  # Accepts cfSize, field, parsedFieldValues, fileNameIdxs, fieldToSum, logType
#  buildTimestampDim: (opts) ->
#    self = @
#
#    self.determineTimeGranularity opts
#
#    #start = new Date()
#    # Apply the timeTransform to the unix timestamp
#
#    # TODO self is null I believe due to the view moden mixed problems
#    self.timestampDim = self.cf.dimension (d) -> self.timeTransform.call(@, d.timestamp)
#    #self.timestampGroup = self.timestampDim.group().reduceCount()
#    #dur = (new Date() - start) / 1000
#    #window.viewModels.viewModelFileUpload.postProcessingProgress.push "Completed building the timestamp dim in #{dur} with #{self.timestampDim.top(Infinity).length} items"
#
#    _.each  opts.parsedFieldValues, (v) ->
#      sevLower = "#{v}".toLowerCase()
#      sevLowerIdx = sevLower + 'Idx'
#      # Ex. infoGroup, errorGroup
#      self["#{sevLower}Group"] = self.timestampDim.group().reduce(self.reduceAddField(opts.field, self[sevLowerIdx]), self.reduceRemoveField(opts.field, self[sevLowerIdx]), self.reduceInitialField(opts.field, self[sevLowerIdx])).order(self.orderValue)
#
#    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#    # Each file, Then, for each parseSeverities, I will need to recreate a group for each one.  That would be
#    # a minimal set of information required to show at least the time series
#    # So something like self.timestampDims = {fileName0: dim}, {filename1: ...}
#    # So something like self.timestampGroups = {fileName0: group}, {filename1: ...}
#    # self.severityGroups = {filename0: {errorGroup: group, infoGroup: group, ect..}}
#    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#    self.timestampGroups = {}
#
#    _.each opts.fileNameIdxs, (idx) ->
#
#      fileName = self.lookup 'fileName', idx
#
#      self.timestampGroups[fileName] = {}
#
#      _.each opts.parsedFieldValues, (v) ->
#
#        sevLower = "#{v}".toLowerCase()
#        #sevLowerIdx = sevLower + 'Idx'
#        fieldValueIdx = self.inverseLookup opts.field, v
#
#        # if fieldToSum is present, then the count will be a sum of the specified field
#        if opts.fieldToSum?
#          self.timestampGroups[fileName][sevLower] = self.timestampDim.group().reduce(self.reduceSumDimensional(opts.field, fieldValueIdx, opts.fieldToSum, idx), self.reduceRemoveDimensional(opts.field,  fieldValueIdx, opts.fieldToSum, idx), self.reduceInitialDimensional(opts.field,fieldValueIdx, idx)).order(self.orderValue)
#        # Otherwise the count will be a simple count of occurrences
#        else
#          # For example if someLog.log -> 0 ERROR -> 1 then self.timestampGroups[0][1]
#          # the idx has to be used for the fileName here since a file name can contain spaces, which aren't
#          self.timestampGroups[fileName][sevLower] = self.timestampDim.group().reduce(self.reduceAddFieldFileName(opts.field, fieldValueIdx, idx), self.reduceRemoveFieldFileName(opts.field,  fieldValueIdx, idx), self.reduceInitialFieldFileName(opts.field, fieldValueIdx, idx)).order(self.orderValue)
#
#    self.setDateBounds()
#
#    self = null

  buildTimestampDim: (opts) ->
    self = @

    self.determineTimeGranularity opts

    self.timestampDim = self.cf.dimension (d) -> self.timeTransform.call(@, d.timestamp)

    _.each  opts.parsedFieldValues, (v) ->
      field = "#{v}".toLowerCase()
      # Ex. infoGroup, errorGroup
      self["#{field}Group"] = self.timestampDim.group().reduce(self.reduceAddField(opts.field, v), self.reduceRemoveField(opts.field, v), self.reduceInitialField(opts.field, v)).order(self.orderValue)

    self.timestampGroups = {}

    _.each opts.parsedFieldValues, (v) ->

      field = "#{v}"

      # if fieldToSum is present, then the count will be a sum of the specified field
      if opts.fieldToSum?
        self.timestampGroups[field] = self.timestampDim.group().reduce(self.reduceSum(opts.field, v, opts.fieldToSum), self.reduceRemoveDimensional(opts.field,  v, opts.fieldToSum), self.reduceInitialDimensional(opts.field, v)).order(self.orderValue)
      # Otherwise the count will be a simple count of occurrences
      else
        self.timestampGroups[field] = self.timestampDim.group().reduce(self.reduceAddField(opts.field, v), self.reduceRemoveField(opts.field,  v), self.reduceInitialField(opts.field, v)).order(self.orderValue)

    self.setDateBounds()

  ####################################################################################################################
  # Functions for transforming the data to d3 and dygraph formats, these will need to be recalled with
  # the specific this context in whatever is calling to it
  ####################################################################################################################
  makeD3Stream: (key, values) -> [ key: key, values: values ]

  # This assumes present dims and groups
  # Key may be ['ERROR', 'WARN'] for sevs or [200, 500, 404] for statues
  makeTimestampFieldStreams: (keys) ->
    self = @
    streams = []

    # Construct the object of the sev group timestamp occurrences
    timeSevOccurrences = {}
    _.each keys, (key) ->

      timeSevOccurrences[key] = {}

      _.each self.state.groups["#{key.toLowerCase()}Group"].top(Infinity), (obj) ->
        # the key here is the timestamp
        if not timeSevOccurrences[sev][obj.key]?
          timeSevOccurrences[key][obj.key] = 0

        # For each time occurrence of this key, increment by the grouped count
        timeSevOccurrences[key][obj.key] += obj.value.count

    _.each keys, (key) ->
      stream = {
        key: key
        values: []
      }

      for ts, val of timeSevOccurrences[key]
        stream.values.push
          x: +ts
          y: val

      stream.values.sort (a, b) -> a.x - b.x
      streams.push stream

    streams.sort (a, b) -> a.key - b.key
    streams

  # Generates dygraph data from the state.timestampGroups[fileName][sevGroup]
  makeTimestampGroupsFieldDygraphData: (fileName, keys) ->
    self = @

    #keys = @props.parseSeverities.sort()
    keys.sort()

    dgLabels = _.flatten ['Date', keys]

    # Construct the object of the timestamp sev occurrences
    timeSevOccurrences = {}
    _.each keys, (key) ->
      # For example errorGroup, warnGroup, ect..
      groupData = self.state.groups['timestampGroups'][fileName]?["#{key.toLowerCase()}"].top(Infinity)
      groupData?.sort (a, b) -> a.key - b.key
      _.each groupData, (obj) ->
        # the key here is the timestamp
        if not timeSevOccurrences[obj.key]?
          timeSevOccurrences[obj.key] = {}

        if not timeSevOccurrences[obj.key][key]?
          timeSevOccurrences[obj.key][key] = 0

        # For each time occurrence of this key, increment by the grouped count
        timeSevOccurrences[obj.key][key] += obj.value.count

    # Output would now look like
    # timeSevOccurrences = {123456: {ERROR: 0, WARN: 1}, 23456: {ERROR: 1, WARN 0}}

    dgData = []

    for ts, value of timeSevOccurrences
      arr = [moment(+ts).toDate()]
      _.each keys, (key) ->
        arr.push value[key]

      dgData.push arr

    {
      dygraphData: dgData
      dygraphLabels: dgLabels
    }

module.exports = Mixin
