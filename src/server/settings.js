var yaml    = require('js-yaml');
var _       = require("lodash");
var fs      = require("fs");
var logger  = require("../utils/logger");

// Get document, or throw exception on error
try {
    var config_file = null;
    if (_.trim(process.env['OPENSHIFT_DATA_DIR']) != "")
        config_file = process.env['OPENSHIFT_DATA_DIR'] + ".quest-settings.yml";
    else
        config_file = process.env['HOME'] + "/.quest-settings.yml";
    var doc = yaml.safeLoad(fs.readFileSync(config_file, 'utf8'));
    logger.info(JSON.stringify(doc));
} catch (e) {
    logger.error(e);
}

var resolveEnvVar = function(envVar) {
    if (envVar === void 0) {
        return void 0;
    }
    if (/^\$/i.test(envVar)) {
        return process.env[envVar.slice(1, envVar.length)];
    }
    return process.env[envVar];
};

var objToExport = {
    env: 'development', // overridden in index.js
    environment: 'development', // overridden in index.js
    urlPrefix: "/labs/logreaper",
    resolveEnvVar: resolveEnvVar
};

module.exports = _.defaults(objToExport, doc);
