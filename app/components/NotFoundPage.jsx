import React from "react";

export default class NotFoundPage extends React.Component {
    static getProps() {
        return {};
    }
    render() {
        return <div>
            <h3>Not found</h3>
            <p>The page you requested was not found.</p>
        </div>;
    }
}
