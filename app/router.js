let Router = require('react-router');
let Utils = require('./utils');

function location() {
    if (typeof window !== 'undefined') {
        // As of FF 43 HistoryLocation no longer works, at least not with react-router 0.13
        if (Utils.browser == "firefox") {
            return Router.HashLocation;
        }
        return Router.HistoryLocation;
    }
}

module.exports = Router.create({
    routes: require('./routes'),
    location: location()
});