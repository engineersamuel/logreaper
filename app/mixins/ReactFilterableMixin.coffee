_ = require 'lodash'

Mixin =

  filterRange: (range) ->
    if @state['correlatedDims']?['timestamp']?
      # Filter each correlated dimension by the range
      _.each _.values(@state['correlatedDims']['timestamp']), (dim) ->
        dim?.filterRange([range.start, range.end])
    else
      @state['dims']['timestampDim']?.filterRange([range.start, range.end])

  filterRangeAll: () ->
    if @state['correlatedDims']?['timestamp']?
      # Filter each correlated dimension by the range
      _.each _.values(@state['correlatedDims']['timestamp']), (dim) ->
        dim?.filterAll()
    else
      @state['dims']['timestampDim']?.filterAll()


  # range is in the format {start: 123, end: 456}
  # Assumes the exact name timestampDim
  addRangeFilter: (range) ->

    if _.findIndex(@state.filters, {start: range.start, end: range.end}) isnt -1
      console.warn "Attempting to add a filter that already exists: #{JSON.stringify(item)}"
    else

      # Remove any occurrences of timestamp filters
      newFilters = _.reject(_.cloneDeep(@state.filters), {field: 'timestamp'})

      # Add this new one
      newFilters.push range

      # Filter by this range
      #@state['dims']['timestampDim']?.filterRange([range.start, range.end])
      @filterRange(range)
      @reCalculateRangeFilter(newFilters, range)

  resetRangeFilter: () ->
    # Reset the dim completely
    #@state['dims']['timestampDim']?.filterAll()
    @filterRangeAll()
    # Remove any occurrences of the timestamp in the filters
    newFilters = _.reject(_.cloneDeep(@state.filters), {field: 'timestamp'})
    # Recalculate the range filter (just update the react state)
    @reCalculateRangeFilter(newFilters)

  removeRangeFilter: (range) ->
    newFilters = _.reject(_.cloneDeep(@state.filters), {field: 'timestamp'})
    #@state['dims']['timestampDim']?.filterAll()
    @filterRangeAll()
    @reCalculateRangeFilter newFilters

  addFilter: (item) ->
    if _.findIndex(@state.filters, item) is -1
      newFilters = _.cloneDeep @state.filters
      newFilters.push item
      @reCalculateFilters newFilters, item.field
    else
      console.warn "Attempting to add a filter that already exists: #{JSON.stringify(item)}"

  addFilters: (items) ->
    newFilters = _.cloneDeep @state.filters

    _.each items, (item, idx) =>
      if _.findIndex(@state.filters, item) is -1
        newFilters.push item

        # Only on the last item should we force the state update
        if idx is items.length
          @reCalculateFilters newFilters, item.field
        # Otherwise queue up the changes
        else
          @reCalculateFilters newFilters, item.field, true

      else
        console.warn "Attempting to add a filter that already exists: #{JSON.stringify(item)}"


  removeFilter: (item) ->
    if item.field is 'timestamp'
      @removeRangeFilter()
    else
      newFilters = _.reject(@state.filters, item)
      @reCalculateFilters newFilters, item.field

  removeFilters: (items) ->
    # Make a copy of the current filters
    newFilters = _.cloneDeep @state.filters

    _.each items, (item, idx) =>

      # For each item, reject that out of the cloned filters
      newFilters = _.reject(newFilters, item)

      # Only on the last item should we force the state update
      if idx is items.length
        @reCalculateFilters newFilters, item.field
        # Otherwise queue up the changes
      else
        @reCalculateFilters newFilters, item.field, true



  # Takes a new list of filters and the current item (for the current field being filtered) and recalculates the
  # filters and sets the necessary dimension/group in the state
  reCalculateRangeFilter: (filters, range) ->

    # If in mixedView there will be this method, if it exists call it
    if @updateSubComponentFilters?
      @updateSubComponentFilters(filters)
    else
      # Setting the filters state will cause a re-render to those components injecting filters
      @setState {filters: filters}

  # Takes a new list of filters and the current item (for the current field being filtered) and recalculates the
  # filters and sets the necessary dimension/group in the state
  reCalculateFilters: (filters, field, deferUpdate=false) ->

    lowerCaseFirstChar = (str) -> str.charAt(0).toLowerCase() + str.slice(1)
    buildDimName = (field) -> "#{lowerCaseFirstChar(field)}Dim"
    #buildGroupName = (field) -> "#{lowerCaseFirstChar(field)}Group"

    # Get all filters currently associated with this field
    currentFieldFilters = _.filter filters, (f) -> f.field is field

    # Now project just the values of the current field filters
    currentFieldFilterValues = _.map currentFieldFilters, (f) -> f.value

    # Finally, filter based on the set of currentFieldFilterValues or filterAll if no filters present
    if currentFieldFilterValues.length is 0
      @state['dims'][buildDimName(field)].filterAll()
    else
      @state['dims'][buildDimName(field)].filter (x) =>
        found = false
        # === is the fastest, so for large datasets, need to fallback to native js for the breaking for loop
        # http://jsperf.com/regexp-test-search-vs-indexof/12
        `for (var i = 0; i < currentFieldFilterValues.length; i++) {
          if (currentFieldFilterValues[i] === x) {
            found = true;
            break;
          }
        }
        `
        return found

#      obj = {}
#      # Simply setting the group back to itself just to force a re-render
#      obj[buildGroupName(field)] = @state['groups'][buildGroupName(field)]
#      # Overrides the *Group state
#      @setState obj

    # Setting the filters state will cause a re-render to those components injecting filters
    if deferUpdate is false
      @setState {filters: filters}

module.exports = Mixin
