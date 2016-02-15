import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { Alert } from "react-bootstrap";

class Error extends Component {
    constructor(props, context) {
        super(props, context);
    }

    render() {
        let { error } = this.props;
        if (!error) return null;

        return (
            <Alert bsStyle="warning">{error.message}</Alert>
        );
    }
}

Error.propTypes = {
    error: PropTypes.object
};

export default Error;