"use strict";

let _           = require('lodash');
let yaml        = require('js-yaml');
let glob        = require('glob');
let path        = require('path');
let fs          = require('fs');
let request     = require('request');
let Uri         = require('jsuri');
let logger      = require("../utils/logger");

// 1 day
const ttl = 1000 * 60 * 60 * 24;
var ttlRecommendationMap = {
    // text:
        // dateMs
        // recommendations
};

// If the recommendation date is greater than the ttl return false
let isRecommendationStale = (text) => (+(new Date()) - ttlRecommendationMap[text].dateMs) > ttl;
let deleteAllStaleRecommendations = () =>  {

    let keysToDelete = [];
    _.keys(ttlRecommendationMap).forEach(k => {
        if ((+(new Date()) - ttlRecommendationMap[k].dateMs) > ttl) {
            keysToDelete.push(k);
        }
    });
    keysToDelete.forEach(k => delete ttlRecommendationMap[k]);
};

module.exports = function(app, options) {

    app.get(options.browserPath + "/formats", function(req, res) {
        let output = {},
            formatsDir = path.join(__dirname, '../../public/formats/*.yml');
        glob(formatsDir, function(err, files) {
            _(files).forEach(function(f) {
                let doc = yaml.safeLoad(fs.readFileSync(f, 'utf-8'));
                _.keys(doc).forEach((key) => delete doc[key].sample );
                _.extend(output, doc);
            });
            res.contentType('text/json');
            res.write(JSON.stringify(output));
            res.end();
        });
    });

    app.post(options.browserPath + "/recommendations", function(req, res) {
        let text = req.body.text;

        deleteAllStaleRecommendations();

        if (ttlRecommendationMap[text] && !isRecommendationStale(text)) {
            return res.json(ttlRecommendationMap[text].recommendations);
        }

        let uri = new Uri("https://access.redhat.com/rs/recommendations");
        if(options.env != 'development') {
            uri.addQueryParam('redhat_client', `logreaper-prod-${options.version}`);
        } else {
            uri.addQueryParam('redhat_client', `logreaper-dev-${options.version}`);
        }

        // Only return Solutions or Articles
        uri.addQueryParam('fq', 'documentKind:Solution');
        uri.addQueryParam('fq', '-internalTags:helper_solution');
        // Only return 1 row by default.  1 Row has the best Recall and Precision
        uri.addQueryParam('rows', req.query.rows || 1);
        // Text to query
        uri.addQueryParam('q', text);
        // Add in the solution/article id for ease of use in the UI
        uri.addQueryParam('fl', '*,score');

        logger.debug(`Hitting recommendations with : ${uri.toString()}`);

        let requestOpts = {
            url: uri.toString(),
            method: 'GET',
            gzip: true,
            rejectUnauthorized: false,
            json: true,
            headers: {
                'Accept': 'application/vnd.redhat.solr+json'
            },
            cache: true
        };

        request(requestOpts, (err, response, body) => {
            if (err) {
                logger.error("err: " + err);
                logger.error(JSON.stringify(body, null, ' '));
                res.writeHead(500, {
                    'Content-Type': 'text/plain'
                });
                return res.end(JSON.stringify(err));
            }
            ttlRecommendationMap[text] = {
                dateMs: +(new Date()),
                recommendations: _.get(body, 'response.docs', [])
            };
            res.json(ttlRecommendationMap[text].recommendations);
        });
    });

    app.post(options.browserPath + "/upload/gc", function(req, res) {
        res.end(500);
        //var form;
        //form = new multiparty.Form();
        //form.parse(req, function(err, fields, files) {
        //    resumable.post(fields, files, function(status, filename, original_filename, identifier, unChunkedFileName) {
        //        if (status === 'done' && unChunkedFileName) {
        //            let obj = {
        //                fileName: identifier,
        //                path: unChunkedFileName,
        //                csvPath: "/tmp/" + identifier + ".csv",
        //                summaryPath: "/tmp/" + identifier + ".summary"
        //            };
        //            return GCParser.parse(obj, function(err, result) {
        //                try {
        //                    fs.unlinkSync(obj.path);
        //                    fs.unlinkSync(obj.csvPath);
        //                    fs.unlinkSync(obj.summaryPath);
        //                } catch (_error) {
        //                    logger.warn(_error);
        //                }
        //                if (err) {
        //                    res.writeHead(500, {
        //                        'Content-Type': 'text/plain'
        //                    });
        //                    res.end(JSON.stringify(err));
        //                } else {
        //                    obj = {
        //                        name: identifier,
        //                        csv_ts: result.csv_ts,
        //                        summary: result.summary
        //                    };
        //                    res.writeHead(200, {
        //                        'Content-Type': 'application/json'
        //                    });
        //                    res.end(JSON.stringify(obj));
        //                }
        //            });
        //        } else {
        //            res.writeHead(200, {
        //                'Content-Type': 'text/plain'
        //            });
        //            return res.end(status);
        //        }
        //    });
        //});
    });
};