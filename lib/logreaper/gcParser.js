var Converter, GCParser, _, async, exec, fs, gcViewerJar, path;

path = require('path');

fs = require('fs');

async = require('async');

_ = require('lodash');

exec = require('child_process').exec;

Converter = require('csvtojson').Converter;

gcViewerJar = __dirname + "/../../libs/gcviewer-1.34.1.jar";

GCParser = {};

GCParser.parse = function(obj, cb) {
  return async.parallel({
    csv_ts: function(innerCb) {
      var execString;
      execString = "java -jar " + gcViewerJar + " " + obj.path + " " + obj.csvPath + " -t CSV_TS";
      return exec(execString, function(error, stdout, stderr) {
        if (error != null) {
          return innerCb(error);
        } else {
          return fs.readFile(obj.csvPath, 'utf8', function(err, data) {
            var csvConverter, e, error1, fileStream;
            if (err != null) {
              return innerCb(err);
            } else {
              try {
                fileStream = fs.createReadStream(obj.csvPath);
                csvConverter = new Converter({
                  constructResult: true
                });
                csvConverter.on('end_parsed', function(jsonObj) {
                  return innerCb(null, _.map(jsonObj, function(o) {
                    return {
                      timestamp: +o['Timestamp(unix/#)'],
                      used: +o['Used(K)'],
                      total: +o['Total(K)'],
                      pause: +o['Pause(sec)'],
                      gcType: o['GC-Type'],
                      fileName: obj.fileName
                    };
                  }));
                });
                return fileStream.pipe(csvConverter);
              } catch (error1) {
                e = error1;
                return innerCb(e);
              }
            }
          });
        }
      });
    },
    summary: function(innerCb) {
      var execString;
      execString = "java -jar " + gcViewerJar + " " + obj.path + " " + obj.summaryPath + " -t SUMMARY";
      return exec(execString, function(error, stdout, stderr) {
        if (error != null) {
          return innerCb(error);
        } else {
          return fs.readFile(obj.summaryPath, 'utf8', function(err, data) {
            var constructedArray, output;
            if (err != null) {
              return innerCb(err);
            } else {
              constructedArray = _.map(_.map(data.split(/\r?\n/g), function(d) {
                return d.split(';');
              }), function(s) {
                var key, ref, ref1;
                key = s != null ? s[0] : void 0;
                return {
                  field: key != null ? key.trim() : void 0,
                  value: s != null ? (ref = s[1]) != null ? ref.trim() : void 0 : void 0,
                  units: s != null ? (ref1 = s[2]) != null ? ref1.trim() : void 0 : void 0
                };
              });
              output = {};
              _.each(constructedArray, function(c) {
                if (((c != null ? c['key'] : void 0) != null) !== "") {
                  return output[c['field']] = {
                    value: c['value'],
                    units: c['units'],
                    fileName: obj.fileName
                  };
                }
              });
              return innerCb(null, output);
            }
          });
        }
      });
    }
  }, function(err, results) {
    return cb(err, results);
  });
};

module.exports = GCParser;
