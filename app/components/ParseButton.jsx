import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { Button } from "react-bootstrap";

import { parseFiles } from '../flux/actions/FileActions';

class ParseButton extends Component {
    constructor(props, context) {
        super(props, context);
        this._onClick = this._onClick.bind(this)
    }

    _onClick(e) {
        e.preventDefault();
        this.props.parse();
    }

    render() {
        let { file, error } = this.props;

        // If the file doesn't exist or the file does and it has completed parsing, don't show the parse
        if ((!file || file.progress == 1) && !error) return null;
        // If there is a file, but it has no identification, don't show the parse
        if (!_.get(file, 'identification.matched', false)) return null;

        // If any have a hash set
        //if (_.reduce(files, (bool, f) => bool || f.hash) == null) return null;

        let opts = { onClick: this._onClick };

        // If no hash yet disable the button
        if (file.hash == null) {
            opts.disabled = true;
        }
        return (
            <Button {...opts}>Parse</Button>
        );
    }
}

ParseButton.propTypes = {
    file: PropTypes.object,
    parse: PropTypes.func,
    error: PropTypes.object
};

export default ParseButton;