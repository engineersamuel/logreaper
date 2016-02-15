var request       = require("request");

// Load the webpack stats.json then load the index.js (express)
request({url: 'http://127.0.0.1:2992/labs/logreaper/_assets/stats.json', json: true}, function(err, response, stats) {
    if (err) return console.error(err);
    require("./bootstrap")({
        env: 'development',
        stats: stats,
        // I personally prefer a separateStylesheet for manipulating css in the browser
        separateStylesheet: true,
        index: 'index_dev',
        browserPath: '/labs/logreaper',
        prerender: false,
        defaultPort: 8080
    });

});