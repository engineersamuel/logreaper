props =
  logCountsGroup: undefined
  logCountsSelector: 'nala-log-counts'
  # Range chart for the timeSeries
  logCountsChart: true
  logCountsChartWidth: 0
  logCounts: undefined

  buildLogCountsGroup: (dim) ->
    # Create a group for the total count over time.
    @logCountsGroup = @timestampDim.group((d) -> d.count).reduceSum()

  buildLogCountsChart: (dim, group, minDate, maxDate) ->
    @logCountsChart = dc.barChart('#' + @logCountsSelector)
    @logCountsChartWidth = $('#' + @logCountsSelector).parent().width()

    self.logCountsChart
      .width(@logCountsChartWidth)
      .height(200)
      .margins({top: 10, right: 0, bottom: 20, left: 50})
      .dimension(dim)
      .group(group)
      .centerBar(true)
      .elasticY(true)
      .gap(1)
      .x(d3.time.scale().domain([minDate, maxDate]))
      .renderHorizontalGridLines(true)

module.exports = props
