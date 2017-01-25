####################################################################################################################
# Provides a standard set of known severity colors
####################################################################################################################
Mixin =
  severityColorMappings:
    'FINE': 'darkblue'
    'TRACE': 'darkblue'
    'DEBUG': '#4f544c'
    'INFO': 'lightblue'
    'NOTICE': 'lightblue'
    'WARN': '#f69900'
    'ERROR': 'darkred'
    'EMERG': '#770000'
    'ALERT': '#630000'
    'CRIT': '#4f0000'

  statusColorMappings:
    '200': 'green'
    '206': 'green'
    '301': 'orange'
    '302': 'orange'
    '304': 'orange'
    '404': 'black'
    '500': 'darkred'

  lookupColor: (field, value) ->
    switch field
      when 'severity'
        return Mixin.severityColorMappings[value + ""]
      when 'status'
        if (value + "").indexOf("20") isnt -1
          return 'green'
        else if (value + "").indexOf("30") isnt -1
          return 'orange'
        else if (value + "").indexOf("40") isnt -1
          return 'black'
        else if (value + "").indexOf("50") isnt -1
          return 'darkred'
        else
          return Mixin.statusColorMappings[value + ""] || 'black'
      else
        console.warn "Could not lookup color on field: #{field} with value: #{value}"

module.exports = Mixin
