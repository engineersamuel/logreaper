import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import Spacer from './Spacer.jsx'
import { Alert } from 'react-bootstrap'

import {
    exampleParseFile
} from '../flux/actions/FileActions';

class Instructions extends Component {
    constructor(props, context) {
        super(props, context);
    }

    clickExample(name, e) {
        e.preventDefault();
        this.props.dispatch(exampleParseFile(name))
    }

    render() {
        if (this.props.file) return null;

        return (
            <div>
                <Alert bsStyle="info">
                    <h3>Quick Start</h3>
                    <ul>
                        <li>Browse and select a file or drop a file into the drop zone (<span style={{color: 'black', 'fontWeight': 'bold'}}>Syslog, Log4j (JBoss/RHEVM, ect..), LSOF, Apache Access</span>)</li>
                        <li>Wait for the file to be identified, if it could not be identified you will see the message: <span style={{color: 'darkred', 'fontWeight': 'bold'}}>Could not Identify</span></li>
                        {/*<li>Feel free to leave a comment on the <a target='_blank' href='https://access.redhat.com/site/labsinfo/logreaper'>info page</a> requesting a particular log type be added</li>*/}
                        <li>Once Identified click the Parse button</li>
                        <li>The log will be parsed iteratively and you will be displayed a page containing analysis specific to the log type in question</li>
                        <li>See below for working examples you can play with!</li>
                    </ul>
                </Alert>

                <Spacer />

                <Alert bsStyle="info">
                    <h3>Examples</h3>
                    <ul>
                        <li><a className="pointer" onClick={this.clickExample.bind(this, 'jboss')}>JBoss Log</a>  This example deals with visualizing an Out of Memory situation with a JBoss server that leads to clustering issues.</li>
                        <li><a className="pointer" onClick={this.clickExample.bind(this, 'lsof')}>LSOF</a>  This example represents 'list open files' and is useful for analyzing a snapshot the current file descriptions.</li>
                    </ul>
                </Alert>

                {/*

                 <video id="MY_VIDEO_1" className="video-js vjs-default-skin" controls data-setup="{}">
                 <source src="/labs/logreaper/static/videos/logreaper_usage.mp4"  type="video/mp4" />
                 <source src="/labs/logreaper/static/videos/logreaper_usage.ogv"  type="video/ogg" />
                 <source src="/labs/logreaper/static/videos/logreaper_usage.webm"  type="video/webm" />
                 <p className="vjs-no-js">To view this video please enable JavaScript, and consider upgrading to a web browser that <a href="http://videojs.com/html5-video-support/" target="_blank">supports HTML5 video</a></p>
                 </video>

                */}

                {/*<p>
                    <strong>Download Video: </strong>
                    <a target="_blank" href="https://people.redhat.com/smendenh/logreaper_usage.ogv">Ogv</a> or
                    <a target="_blank" href="https://people.redhat.com/smendenh/logreaper_usage.mp4">MP4</a>
                </p>*/}

            </div>

        );
    }
}

Instructions.propTypes = {
    file: PropTypes.object
};

export default Instructions;