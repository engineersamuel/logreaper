import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { RouteHandler, Link } from "react-router";
import cx from "classnames";

import {
    Grid,
    Row,
    Col,
    Button,
    Input,
    Alert,
    ButtonGroup
} from "react-bootstrap";

// Custom Components
import Spacer               from "./Spacer.jsx";
import FileList             from "./file/FileList.jsx"
import FileNotIdentified    from "./file/FileNotIdentified.jsx"
import ParseProgress        from "./ParseProgress.jsx"
import ParseButton          from "./ParseButton.jsx"
import ViewSelector         from "./ViewSelector.jsx"
import Error                from "./Error.jsx"
import Dropzone             from "./file/Dropzone.jsx"
import Instructions         from "./Instructions.jsx"

// Flux
import { connect } from 'react-redux';
import {
    handleFile,
    parseFile,
    parseSeverities
} from '../flux/actions/ApiActions';

require('nvd3/build/nv.d3.css');
require('rc-slider/assets/index.css');
require('react-datagrid/index.css');
require('./Home.less');

class Home extends Component {
    constructor(props, context) {
        super(props, context);
        this._onDrop = this._onDrop.bind(this);
        this._onChange = this._onChange.bind(this);
        this._parse = this._parse.bind(this);
        this.state = {
            parseSeverities: {
                // name: bool
            }
        }
    }

    componentWillReceiveProps(nextProps) {
        // If we have incoming parseSeverities from redux and there are already parseSeverities in the state
        // make sure the right sevs are set to true
        if (nextProps.parseSeverities.length > 0 && _.keys(this.state.parseSeverities).length > 0) {
            this.setState({parseSeverities: _.chain(nextProps.file.identification.allSeverities).map(sev => [sev, _.includes(nextProps.parseSeverities, sev)]).fromPairs().value()});
        }
        // If parseSeverities isn't set, and the incoming props has it set, set it in the state so it can be rendered
        // as inline checkboxes
        else if (_.get(nextProps, 'file.identification.parseSeverities', []).length > 0) {
            this.setState({parseSeverities: _.chain(nextProps.file.identification.allSeverities).map(sev => [sev, _.includes(nextProps.file.identification.parseSeverities, sev)]).fromPairs().value()});
        } else {
            this.setState({parseSeverities: {}})
        }
    }

    _onDrop(files, e) {
        e.preventDefault();
        //this.props.dispatch(handleFile(e.dataTransfer.files[0]));
        this.props.dispatch(handleFile(files[0]));
    }
    _onChange(e) {
        e.preventDefault();
        this.props.dispatch(handleFile(e.target.files[0], _.filter(_.keys(this.state.parseSeverities), sev => this.state.parseSeverities[sev])));
    }
    _parse(action) {

        if (process.env.NODE_ENV == 'production') {
            // This fires for Omniture web analytics
            try {
                chrometwo_require(["analytics/main"], function (analytics) {
                    return analytics.trigger("LabsCompletion");
                });
            } catch (error) {
                console.error(error);
            }
        }
        this.props.dispatch(parseFile(this.props.file, _.filter(_.keys(this.state.parseSeverities), sev => this.state.parseSeverities[sev]), action));
    }

    _handleCheckboxClick(sev, e) {
        // Remove the sev from the list
        if (this.state.parseSeverities[sev]) {
            this.state.parseSeverities[sev] = false;
            this.setState(this.state.parseSeverities);
        } else {
            this.state.parseSeverities[sev] = true;
            this.setState(this.state.parseSeverities);
        }
        let severitiesSelected = _.chain(this.state.parseSeverities).keys().filter(k => this.state.parseSeverities[k]).value();
        this.props.dispatch(parseSeverities(severitiesSelected));
    }
    isSeverityChecked(sev){
        return this.state.parseSeverities[sev];
    }
    renderSeverityFilters(file, severities, error) {
        if ((file && file.progress == 1) && !error) return null;

        return _.map(severities, (sev) =>  {
            return (
                <label key={sev} className="checkbox-inline">
                    &nbsp;&nbsp;
                    <input type="checkbox" id={sev} name={sev} onChange={this._handleCheckboxClick.bind(this, sev)} checked={this.isSeverityChecked(sev)} />
                    &nbsp;{sev}
                </label>
            );
        });
    }

    render() {
        const { file, error } = this.props;

        return (
            <Grid>
                <div className="logreaper">
                    <h1><a style={{color: 'black'}} href="/labs/logreaper">Log Reaper</a></h1>
                    <Spacer />
                    <p>Log Reaper is a multi-purpose log analysis app with an emphasis on break/fix and identification of errors in
                        your log files.  When you parse a log you will be presented with a custom tailored view
                        for that particular log type, with automatic solution recommendations,  and with targeted analysis.
                        See Log Reaper's <a target="_blank" href="https://access.redhat.com/labsinfo/logreaper">info page</a> for more information.</p>
                    <Row>
                        <Col md={3}>
                            {/*multiple="true"*/}
                            <input id="file-input" type="file" name="files[]" onChange={this._onChange} />
                        </Col>
                        <Spacer />
                        <Col md={9}>
                            <Dropzone className="logreaper-dropzone"
                                      ref="fileDropRef"
                                      onDrop={this._onDrop}
                                      text={_.get(file, 'file.name', "Drop a log file here")}/>
                        </Col>
                    </Row>
                    <br />
                    <div className="clearfix"></div>
                    <FileList file={file}></FileList>
                </div>
                {this.renderSeverityFilters(file, _.keys(this.state.parseSeverities), error)}
                <Spacer />
                <ButtonGroup>
                    <ParseButton {...this.props} action="Visualize" parse={this._parse}></ParseButton>
                    <ParseButton {...this.props} action="Quick Analysis" parse={this._parse}></ParseButton>
                </ButtonGroup>
                <Spacer />
                <hr />

                {/* Handle errors */}
                <Error {...this.props}></Error>
                <FileNotIdentified {...this.props}></FileNotIdentified>

                {/* Display the parse progress when parsing*/}
                <ParseProgress {...this.props}></ParseProgress>

                {/* The view selected selects the proper view based on the file identification */}
                <ViewSelector {...this.props}></ViewSelector>

                {/* When no file present, give some instructions */}
                <Instructions {...this.props}></Instructions>
            </Grid>
        );
    }
}

Home.propTypes = {
    file: PropTypes.object,
    parseSeverities: PropTypes.array,
    error: PropTypes.object,
    userAction: PropTypes.string,
    dispatch: PropTypes.func.isRequired
};

function mapStateToProps(state) {

    return {
        file: state.file.file,
        parseSeverities: state.parseSeverities,
        error: state.error,
        userAction: state.userAction
    };
}

export default connect(mapStateToProps)(Home);

