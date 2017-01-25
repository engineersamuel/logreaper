"use strict";

let settings = require('./settings');

let ipAddress = settings.resolveEnvVar('OPENSHIFT_NODEJS_IP') || '0.0.0.0';
let port = settings.resolveEnvVar('OPENSHIFT_NODEJS_PORT') || 8080;

// By default babel cache will be in the $HOME dir which will not work in Openshift, but the data dir will.
let homeDir = settings.resolveEnvVar('HOME');
let dataDir = settings.resolveEnvVar('OPENSHIFT_DATA_DIR');
let babelCachePath = settings.resolveEnvVar('BABEL_CACHE_PATH');
process.env.BABEL_CACHE_PATH = babelCachePath || (dataDir && dataDir + "/.babel.json") || (homeDir && homeDir + "/.babel.json");

require("./index")({
    env: 'production',
    separateStylesheet: true,
    prerender: true,
    ipAddress: ipAddress,
    index: 'index_prod',
    browserPath: '/labs/logreaper',
    port: port
});