import { createStore, applyMiddleware } from 'redux'
import thunkMiddleware from 'redux-thunk'
//import createLogger from 'redux-logger'
import rootReducer from '../reducers/rootReducer'


let middleware = [thunkMiddleware];

if (process.env.NODE_ENV != 'production') {
    let createLogger = require('redux-logger');
    const loggerMiddleware = createLogger();
    middleware = [...middleware, loggerMiddleware]
}

const createStoreWithMiddleware = applyMiddleware(...middleware)(createStore);

export default function configureStore(initialState) {
    return createStoreWithMiddleware(rootReducer, initialState)
}