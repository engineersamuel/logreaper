var yaml    = require('js-yaml');
var _       = require("lodash");
var fs      = require("fs");
var logger  = require("../utils/logger");

var resolveEnvVar = function(envVar) {
    if (envVar === void 0) {
        return void 0;
    }
    var val = "";
    if (/^\$/i.test(envVar)) {
        val = process.env[envVar.slice(1, envVar.length)];
    } else {
        val = process.env[envVar];
    }
    return val != null ? val.trim() : "";
};

module.exports = {
    env: 'development', // overridden in index.js
    environment: 'development', // overridden in index.js
    urlPrefix: "/labs/logreaper",
    resolveEnvVar: resolveEnvVar
};
