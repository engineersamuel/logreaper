let browserPath = '/labs/logreaper';
let env = "development";
let packageJson = require("../package.json");

if (ENV == "production") {
    env = "production";
}

module.exports = {
    browserPath: browserPath,
    env: env,
    version: packageJson.version
};