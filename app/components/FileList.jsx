import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { RouteHandler, Link } from "react-router";
import cx from "classnames";
import { Grid, Row, Col, Button, Alert, Table } from "react-bootstrap";

import Spacer   from "./Spacer.jsx";
import Spinner  from "./Spinner.jsx";

class FileList extends Component {
    constructor(props, context) {
        super(props, context);
    }

    renderHash(f) {
        if (f.hash == null) return <Spinner />;
        return f.hash;
    }
    renderIdentification(f) {
        if (f.identification == null) return <Spinner />;
        if (f.identification.matched == false) {
            return <Alert bsStyle="warn">Failed to identify</Alert>
        } else {

            return <span>{f.identification.identifiedName}:{f.identification.identifiedRegexName}</span>
        }
    }

    renderRow(f) {
        return (
            <tr key={f.file.name}>
                <td>{f.file.name}</td>
                <td>{f.file.size}</td>
                <td>{(new Date(f.file.lastModified)).toString()}</td>
                <td>{this.renderHash(f)}</td>
                <td>{this.renderIdentification(f)}</td>
            </tr>
        )
    }

    render() {
        const { file } = this.props;
        if (file == null || file.progress == 1) return null;
        return (
            <Table responsive={true} bordered={false} striped={true} hover={true} condensed={true}>
                <thead>
                <tr>
                    <th>Name</th>
                    <th>Size</th>
                    <th>Last Modified</th>
                    <th>Hash</th>
                    <th>Parser</th>
                </tr>
                </thead>
                <tbody>
                    {this.renderRow(file)}
                </tbody>
            </Table>

        );
    }
}

FileList.propTypes = {
    file: PropTypes.object
};

export default FileList;
