import React, { Component } from 'react'
import { Provider } from 'react-redux'
import configureStore from '../flux/stores/configureStore'
import Home from './Home.jsx'

const store = configureStore();

export default class App extends Component {
    render() {
        return (
            <Provider store={store}>
                <Home />
            </Provider>
        )
    }
}