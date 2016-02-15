module.exports = require("./make-webpack-config")({
    env: "development",
    browserPath: '/labs/logreaper',
    devServer: true,
    separateStylesheet: true,
    devtool: "eval-source-map",
    //devtool: "source-map",
    debug: true
});