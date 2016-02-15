let React = require('react');
let Router = require('react-router');
let { Route, DefaultRoute, NotFoundRoute, Redirect } = Router;

import App from './components/App.jsx'
import Home from './components/Home.jsx'
import NotFoundPage from './components/NotFoundPage.jsx'

let browserPath = require("./utils.js").browserPath;

// See make-webpack-config.js for BROWSER_PATH, which is set in the index.js and index.ejs
module.exports = (
    <Route handler={App}>
        <Route name="home" path={browserPath} handler={Home} />
        <Redirect from="/?" to="home" />
        <Route path="*" component={NotFoundPage} />
    </Route>
);
