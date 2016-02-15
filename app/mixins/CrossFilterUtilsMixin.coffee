Mixin =
  ##################################################################################################################
  # Map reduce over the severity field for a single value
  ##################################################################################################################
  reduceAddSeverity: (name) ->
    return (p, v) ->
      #if v.severity is self.inverseLookup('severity', name) then ++p.count
      if v.severity is name then ++p.count
      p
  reduceRemoveSeverity: (name) ->
    return (p, v) ->
      #if v.severity is self.inverseLookup('severity', name) then --p.count
      if v.severity is name then --p.count
      p
  reduceInitialSeverity: (name) ->
    return () ->
      {
      count: 0
      #severity: self.inverseLookup('severity', name)
      severity: name
      }
  orderValue: (p) -> p.count

  ##################################################################################################################
  # Map reduce over any field
  ##################################################################################################################
  reduceAddField: (field, value) ->
    return (p, v) ->
      #if v.severity is self.inverseLookup('severity', name) then ++p.count
      if v[field] is value then ++p.count
      p
  reduceRemoveField: (field, value) ->
    return (p, v) ->
      #if v.severity is self.inverseLookup('severity', name) then --p.count
      if v[field] is value then --p.count
      p
  reduceInitialField: (field, value) ->
    return () ->
      opt = { count: 0 }
      opt[field] = value
      return opt

  ##################################################################################################################
  # Map reduce over any field and fileName
  ##################################################################################################################
  reduceAddFieldFileName: (field, value, fileNameIdx) ->
    return (p, v) ->
      #if v.severity is self.inverseLookup('severity', name) then ++p.count
      if ((v[field] is value) and (+v['fileName'] is +fileNameIdx)) then ++p.count
      p
  reduceRemoveFieldFileName: (field, value, fileNameIdx) ->
    return (p, v) ->
      #if v.severity is self.inverseLookup('severity', name) then --p.count
      if ((v[field] is value) and (+v['fileName'] is +fileNameIdx)) then --p.count
      p
  reduceInitialFieldFileName: (field, value, fileNameIdx) ->
    return () ->
      opt =
        count: 0
        fileName: +fileNameIdx

      opt[field] = value
      opt

  ##################################################################################################################
  # Map reduce sum over any field and fileName.  Field might be gcType, value might be 'GC', fieldToSum would be pause
  # and fileNameIdx might be 0 -> gc.log
  ##################################################################################################################
  reduceSumDimensional: (field, value, fieldToSum, fileNameIdx) ->
    return (p, v) ->
      #if v.severity is self.inverseLookup('severity', name) then ++p.count
      if ((v[field] is value) and (+v['fileName'] is +fileNameIdx))
        p.count += +v[fieldToSum]
      p
  reduceRemoveDimensional: (field, value, fieldToSum, fileNameIdx) ->
    return (p, v) ->
      #if v.severity is self.inverseLookup('severity', name) then --p.count
      if ((v[field] is value) and (+v['fileName'] is +fileNameIdx))
        p.count += +v[fieldToSum]
      p
  reduceInitialDimensional: (field, value, fileNameIdx) ->
    return () ->
      opt =
        count: 0
        fileName: +fileNameIdx

      opt[field] = value
      opt

module.exports = Mixin
