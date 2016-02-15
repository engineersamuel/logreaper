import React from "react";

export default class Spacer extends React.Component {
    shouldComponentUpdate(nextProps, nextState) {
        return false;
    }
    render() {
        return <div style={{marginBottom: this.props.size || 10}}></div>
    }
}