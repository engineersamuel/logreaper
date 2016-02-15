_ = require 'lodash'

####################################################################################################################
# Severity field mappings to hold all of the necessary dimensions and groups for any arbitrary severity/field
####################################################################################################################
Mixin =

  severityNameMapping:
    'TRACE': ['Trace', 'trace', 'TRACE', 'FINE', 'fine']
    'DEBUG': ['Debug', 'debug', 'DEBUG']
    'INFO': ['Info', 'info', 'INFO']
    'NOTICE': ['Notice', 'notice', 'NOTICE']
    'WARN': ['Warn', 'warn', 'WARN', 'Warning', 'warning', 'WARNING']
    'ERROR': ['Error', 'error', 'ERROR', 'Err', 'err', 'ERR']
    'EMERG': ['EMERG', 'EMERGENCY', 'Emerg', 'emerg', 'Emergency', 'emergency']
    'ALERT': ['Alert', 'alert', 'ALERT']
    'CRIT': ['Crit', 'crit', 'CRIT', 'Critical', 'critical', 'CRITICAL']

  severityFieldMappings: {}
  example: {
    EMERG: {
      message: {
        dim: undefined
        group: undefined
      },
      facility: {
        dim: undefined
        group: undefined
      }
    }
  }

  ####################################################################################################################
  # Initialize the mappings for severity and field
  ####################################################################################################################
  initializeSeverityFieldMappings: (severities, fields) ->
    self = @
    _.each severities, (s) ->
      self.severityFieldMappings[s] = {}
      _.each fields, (f) ->
        self.severityFieldMappings[s][f] = {
          dim: undefined
          group: undefined
        }
    self = null

module.exports = Mixin
