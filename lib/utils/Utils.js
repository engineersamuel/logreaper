var _, moment;

_ = require('lodash');

moment = require('moment-timezone');

exports.truthy = function(obj) {
  if (obj === void 0) {
    return false;
  } else if (_.isBoolean(obj)) {
    return obj;
  } else if (_.isString(obj)) {
    if (_.contains(['YES', 'Yes', 'yes', 'Y', 'y', '1', 'true', 'TRUE', 'ok', 'OK', 'Ok'], obj)) {
      return true;
    } else {
      return false;
    }
  } else if (_.isNumber(obj)) {
    return parseInt(obj) === 1;
  } else {
    return false;
  }
};

exports.getRegion = function(tz) {
  if (_.includes(tz, "America")) {
    return "NA";
  } else if (_.includes(tz, "Europe") || _.includes(tz, "GMT")) {
    return "EMEA";
  } else if (_.includes(tz, "Asia") || _.includes(tz, "Pacific") || _.includes(tz, "Australia")) {
    return "APAC";
  }
  return tz;
};

exports.isWithinAMonth = function(unix_ts) {
  return unix_ts >= +moment().subtract(30, 'days');
};

exports.isWithinAYear = function(unix_ts) {
  return unix_ts >= +moment().subtract(1, 'year');
};

exports.isOverAYear = function(unix_ts) {
  return unix_ts < +moment().subtract(1, 'year');
};

exports.setDateFields = function(ref, fieldBaseName, date, opts) {
  var ref1, xDate, xDateDisplay, xDateDisplayShort, xDateValue;
  if (opts == null) {
    opts = {};
  }
  xDate = date;
  xDateValue = 0;
  if (_.isNumber(xDate)) {
    if (("" + xDate).length >= 13) {
      xDateValue = +moment(xDate);
    } else {
      xDateValue = +moment.unix(xDate);
    }
  } else {
    xDateValue = +moment(date);
  }
  xDateDisplay = ((ref1 = opts.user) != null ? ref1.timezone : void 0) != null ? moment(xDateValue).tz(opts.user.timezone).format('MM/DD/YYYY HH:mm:ss z') : moment(xDateValue).format('MM/DD/YYYY HH:mm:ss');
  xDateDisplayShort = moment(xDateValue).format('MM/DD/YYYY');
  ref[fieldBaseName + "Date"] = date;
  ref[fieldBaseName + "DateValue"] = xDateValue;
  ref[fieldBaseName + "DateDisplay"] = xDateDisplay;
  return ref[fieldBaseName + "DateDisplayShort"] = xDateDisplayShort;
};
