"use strict";

module.exports = function(options) {

    let fs              = require('fs');
    let _               = require('lodash');
    let util            = require('util');
    let settings        = require('./settings');
    let path            = require('path');
    let morgan          = require('morgan');
    let express         = require('express');
    let bodyParser      = require('body-parser');
    let cookieParser    = require('cookie-parser');
    let compression     = require('compression');
    let ejs             = require("ejs");
    let request         = require("request");
    let logger          = require("../utils/logger");
    if (options.env == "development") {
        logger.info("Setting the console transports level to debug");
        logger.transports.console.level = 'debug';
    } else {
        logger.info("Setting the console transports level to info");
        logger.transports.console.level = 'info';
    }

    let app         = express();
    let server      = require('http').Server(app);

    // load bundle information from stats
    let stats       = options.stats || require("../../public/dist/stats.json");
    let packageJson = require("../../package.json");
    let publicPath  = stats.publicPath;
    //assetsByChunkName": {
    //"main": [
    //  "main.js?21059f1cb71ba8fbd914",
    //  "main.css?bc8f4539d07f0f272436380df3391431"
    //]}
    let styleUrl    = options.separateStylesheet && (publicPath + "main.css?" + stats.hash);
    //var styleUrl   = publicPath + [].concat(stats.assetsByChunkName.main)[1]; // + "?" + stats.hash;
    let scriptUrl   = publicPath + [].concat(stats.assetsByChunkName.main)[0]; // + "?" + stats.hash;
    let commonsUrl  = stats.assetsByChunkName.commons && publicPath + [].concat(stats.assetsByChunkName.commons)[0];
    logger.debug("main.js" + stats.assetsByChunkName.main);
    let mainJsHash = stats.hash;
    try {
        mainJsHash = /main.js\?(.*)$/.exec(stats.assetsByChunkName.main)[1];
    } catch(e){}

    // Set this in the settings to that it can be sent with each request.  Then it can be compared to the
    // window.logreaper.mainJsHash, if there is a difference, then the user should refresh the browser.
    settings.mainJsHash = mainJsHash;
    logger.info("main.js hash: " + mainJsHash);

    // Set this so extensions can read it
    settings.version = packageJson.version;
    logger.info("version: " + packageJson.version);

    // http://expressjs.com/guide/error-handling.html
    //var clientErrorHandler = function(err, req, res, next) {
    //    res.status(500);
    //    res.render('error', { error: err });
    //};
    let ipAddress           = options.ipAddress || '127.0.0.1';
    let port                = options.port || 8080;
    let env                 = options.env || 'development';
    settings.env            = env;
    settings.environment    = env;

    logger.info("styleUrl: " + styleUrl);
    logger.info("scriptUrl: " + scriptUrl);
    logger.info("commonsUrl: " + commonsUrl);
    logger.debug(`Serving up index: ${options.index}`);

    let renderOptions = {
        STYLE_URL: styleUrl,
        SCRIPT_URL: scriptUrl,
        COMMONS_URL: commonsUrl,
        ENV: env,
        BROWSER_PATH: options.browserPath || '/',
        body: '',
        state: '',
        mainJsHash: mainJsHash,
        version: packageJson.version
    };

    // Always https in production
    if (env == "production") {
        renderOptions['STYLE_URL'] = styleUrl.replace("http", "https");
        renderOptions['SCRIPT_URL'] = scriptUrl.replace("http", "https");
    }

    logger.info("Env is " + env + ', running server http://' + ipAddress + ':' + port);
    server.listen(port, ipAddress);

    process.on('SIGTERM', function() {
        logger.info("SIGTERM, exiting.");
        server.close();
    });

    process.on('uncaughtException', function(err) {
        logger.error( " UNCAUGHT EXCEPTION " );
        logger.error( "[Inside 'uncaughtException' event] " + err.stack || err.message );
    });


    app.set('views', path.join(__dirname, 'views'));
    app.set('view engine', 'ejs');
    app.set('port', port);

    app.use(compression());
    app.use(morgan('dev'));
    // Set the limit otherwise larger payloads can cause 'Request Entity Too Large'
    app.use(bodyParser.json({limit: '50mb'}));
    app.use(bodyParser.urlencoded({limit: '50mb', extended: true}));
    app.use(cookieParser());

    // Default is /_assets but need the /labs/logreaper prefix
    app.use(`${options.browserPath}/_assets`, express.static(path.join(__dirname, "..", "..", "public", "dist"), {
        etag: false,
        maxAge: "0"
        // maxAge: "200d"
    }));
    app.use(`${options.browserPath}/static`, express.static(path.join(__dirname, "..", "..", "public"), {
        etag: false,
        maxAge: "0"
        // maxAge: "200d"
    }));

    if (options.env === 'development') {
        logger.debug("Using development error handler.");
        app.use(function(err, req, res, next) {
            res.status(err.status || 500);
            res.render('error', {
                message: err.message,
                error: err
            });
        });
    }

    // load REST API
    require("./api")(app, _.defaults(options, packageJson));

    // Redirect anything coming in to / to /labs/logreaper
    app.get("/", function(req, res, next) {
        res.redirect("/labs/logreaper");
    });

    // Proxy webpack for local development work
    app.get(/labs\/logreaper\/_assets\/.*?/, function(req, res) {
        let afterAssets = req.url.replace("/labs/logreaper/_assets/", "");
        var newUrl = `http://localhost:2992/labs/logreaper/_assets/${afterAssets}`;
        logger.debug(`Proxying _assets to ${newUrl}`);
        request(newUrl).pipe(res);
    });

    app.get("/*", (req, res) => {
        res.header("Cache-Control", "no-cache, no-store, must-revalidate");
        res.header("Pragma", "no-cache");
        res.header("Expires", 0);
        res.render(options.index, renderOptions);
    });

};