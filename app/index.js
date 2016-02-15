import 'babel-polyfill';
import React from 'react';
import { render } from 'react-dom';
import { createHistory, useBasename } from 'history';
import { Router, Route, Redirect, browserHistory } from 'react-router';

import App from './components/App.jsx'
//import Home from './components/Home.jsx'
import NotFoundPage from './components/NotFoundPage.jsx'
//import Utils from './utils';

window.React = React; // For React Developer Tools

//const history = useBasename(createHistory)({
//    basename: Utils.browserPath
//});

render((
    <Router history={browserHistory}>
        <Route name="home" path="/labs/logreaper" component={App} />
        <Redirect from="/?" to="home" />
    </Router>
), document.getElementById('content'));
