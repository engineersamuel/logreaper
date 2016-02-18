var settings = require('./settings');

var ipAddress = settings.resolveEnvVar('OPENSHIFT_IOJS_IP') || '0.0.0.0';
var port = settings.resolveEnvVar('OPENSHIFT_IOJS_PORT') || 8080;

// By default babel cache will be in the $HOME dir which will not work in Openshift, but the data dir will.
var homeDir = settings.resolveEnvVar('HOME');
var dataDir = settings.resolveEnvVar('OPENSHIFT_DATA_DIR');
var babelCachePath = settings.resolveEnvVar('BABEL_CACHE_PATH');
process.env.BABEL_CACHE_PATH = babelCachePath || (dataDir && dataDir + "/.babel.json") || (homeDir && homeDir + "/.babel.json");

require("./bootstrap")({
    env: 'production',
    separateStylesheet: true,
    prerender: true,
    ipAddress: ipAddress,
    index: 'index_prod_redhat',
    browserPath: '/labs/logreaper',
    port: port
});