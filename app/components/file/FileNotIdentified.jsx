import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { RouteHandler, Link } from "react-router";
import cx from "classnames";
import { Grid, Row, Col, Button, Alert, Table } from "react-bootstrap";

import Spacer   from "../Spacer.jsx";
import Spinner  from "../Spinner.jsx";

class FileNotIdentified extends Component {
    constructor(props, context) {
        super(props, context);
    }

    render() {
        let { file, error } = this.props;

        // If the file doesn't exist or the file does and it has completed parsing, don't show the parse
        if (!file || file.progress == 1) return null;
        // If there is an error period, don't show the parse button
        if (error) return null;
        // If there is no identification period yet, return null
        if (!file.identification) return null;
        // If there is a file the the identification has matched return as we only want to handle when it didn't
        if (_.get(file, 'identification.matched', false)) return null;

        return (
            <Alert bsStyle="info">
                <strong>Could not identify {file.name}</strong> Please open an issue upstream at <a target="_blank" href="https://github.com/engineersamuel/logreaper/issues">https://github.com/engineersamuel/logreaper/issues</a>&nbsp;
                and attach a sanitized log file.
            </Alert>
        );
    }
}

FileNotIdentified.propTypes = {
    file: PropTypes.object,
    error: PropTypes.object
};

export default FileNotIdentified;
