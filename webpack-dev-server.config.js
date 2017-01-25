module.exports = require("./make-webpack-config")({
    env: "development",
    browserPath: '/labs/logreaper',
    devServer: true,
    // Set the path for webpack to set as the _assets path.  This is important to have the same domain as whatever
    // you are using to access the app in the browser.  You can get around this with proxying, but out of the box like
    // this just makes it easy to get started.
    publicPath: "http://localhost:8080/labs/logreaper/_assets/",
    separateStylesheet: true,
    devtool: "inline-source-map",
    //devtool: "source-map",
    debug: true
});