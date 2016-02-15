import React, { Component } from "react"
import { findDOMNode }      from 'react-dom'
import cx                   from "classnames"

require("./Dropzone.css");

class Dropzone extends Component {
    constructor(props, context) {
        super(props, context);
        this.onDragLeave = this.onDragLeave.bind(this);
        this.onDragOver = this.onDragOver.bind(this);
        this.onDrop = this.onDrop.bind(this);
        this.onClick = this.onClick.bind(this);
        this.state = {
            isDragActive: false,
            fileDropped: false,
            file: null
        }
    }

    onDragLeave(e) {
        e.preventDefault();
        this.setState({ isDragActive: false });
    }

    onDragOver(e) {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'copy';
        this.setState({ isDragActive: true });
    }

    onDrop(e) {
        e.preventDefault();

        this.setState({ isDragActive: false });

        var files;
        if (e.dataTransfer)
            files = e.dataTransfer.files;
        else if (e.target)
            files = e.target.files;

        var maxFiles = (this.props.multiple) ? files.length : 1;
        for (var i = 0; i < maxFiles; i++)
            files[i].preview = URL.createObjectURL(files[i]);

        files = Array.prototype.slice.call(files, 0, maxFiles);
        this.setState({file: files[0]});

        if (this.props.onDrop) {
            this.props.onDrop(files, e);
        }
    }

    reset() {
        this.setState({file: null});
    }

    onClick() {
        if (this.props.supportClick === true)
            this.open();
    }

    open() {
        var fileInput = findDOMNode(this.refs.fileInput);
        fileInput.value = null;
        fileInput.click();
    }

    renderText() {
        if(!this.props.text) return null;
        return <span>{this.props.text}</span>
    }

    render() {
        let divClassesHash = {};
        // dropzone is always set now, but with the addition of another optional classname
        if (this.props.className) divClassesHash[this.props.className] = true;
        divClassesHash['dropzone'] = true;
        divClassesHash['drag-over'] = this.state.isDragActive;
        divClassesHash['active'] = this.state.isDragActive;

        let style = this.props.style || {
            width: this.props.size || 100,
            height: this.props.size || 100,
            borderStyle: this.state.isDragActive ? 'solid' : 'dashed'
        };

        let iconClasses = cx({
            'fa': true,
            'fa-arrow-down': !this.state.file,
            'fa-check': this.state.file
        });

        let inputStyle = {display: 'none'};

        return (
            <div className={cx(divClassesHash)} style={style} onClick={this.onClick} onDragLeave={this.onDragLeave} onDragOver={this.onDragOver} onDrop={this.onDrop}>
                <input type="file" style={inputStyle} multiple={this.props.multiple} ref='fileInput' onChange={this.onDrop} accept={this.props.accept}/>
                &nbsp;
                <i className={iconClasses}></i>
                &nbsp;
                {this.renderText()}
                {this.props.children}
            </div>
        );
    }

}

Dropzone.defaultProps = {
    supportClick: true,
    multiple: true
};

Dropzone.propTypes = {
    onDrop: React.PropTypes.func,
    size: React.PropTypes.number,
    style: React.PropTypes.object,
    supportClick: React.PropTypes.bool,
    accept: React.PropTypes.string,
    multiple: React.PropTypes.bool,
    text: React.PropTypes.string
};


export default Dropzone;
