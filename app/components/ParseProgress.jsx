import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { ProgressBar } from "react-bootstrap";

import Spacer   from "./Spacer.jsx";

class ParseProgress extends Component {
    constructor(props, context) {
        super(props, context);
    }

    //shouldComponentUpdate(nextProps, nextState) {
    //    return !shallowEqual(this.props.progress, nextProps.progress);
    //}

    renderProgressBar(f) {
        if (f.progress == null) return null;
        return (
            <div key={f.hash}>
                <strong>{f.file.name}</strong>
                <ProgressBar striped={true} active={f.progress != 1} bsStyle="success" now={f.progress * 100} label="%(percent)s%"></ProgressBar>
            </div>
        );
    }

    render() {
        const { file } = this.props;
        if (!file || file.progress == 1) return null;
        return (
            <div>
                {this.renderProgressBar(file)}
            </div>
        );
    }
}

ParseProgress.propTypes = {
    file: PropTypes.object
};

export default ParseProgress;
