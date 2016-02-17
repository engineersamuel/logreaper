import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"

import ApacheAccess     from './views/ApacheAccess.jsx';
import Lsof             from './views/Lsof.jsx';
import Log4j            from './views/Log4j.jsx';
import Log4jQuickView   from './views/Log4jQuickView.jsx';
import Vdsm             from './views/Vdsm.jsx';
import VdsmQuickView    from './views/VdsmQuickView.jsx';
import Syslog           from './views/Syslog.jsx';
import SyslogQuickView  from './views/SyslogQuickView.jsx';
import Spacer           from "./Spacer.jsx";

import FileIdenEnum             from './enums/FileIdenEnum';

class ViewSelector extends Component {

    //shouldComponentUpdate(nextProps, nextState) {
    //    return !shallowEqual(this.props.progress, nextProps.progress);
    //}

    allFilesParsed(files) {
        // Returns true if all files have been parsed
        let numIdentified = _.sumBy(files, f => _.get(f, 'identification.matched') ? 1 : 0);
        let numFinishedWithResults = 0;
        files.forEach(f => {
            if (f.progress  == 1 && f.parsedLines && (f.parsedLines.length > 0)) {
                numFinishedWithResults += 1;
            }
        });
        return numIdentified == numFinishedWithResults && (numFinishedWithResults > 0);
    }

    fileParsed(file) {
        if (file.progress == 1 && file.viewModelOpts != null && file.viewModelOpts.cfSize > 0) {
            return true
        }
        return false;
    }

    render() {
        const { file, userAction } = this.props;
        if (!file) return null;
        //if (!this.allFilesParsed(files)) return null;
        if (!this.fileParsed(file)) return null;

        switch (file.identification.identifiedName) {
            case FileIdenEnum.APACHE_ACCESS:
                return <ApacheAccess {...this.props}></ApacheAccess>;
                break;
            case FileIdenEnum.LSOF:
                return <Lsof {...this.props}></Lsof>;
                break;
            case FileIdenEnum.LOG4J:
                switch (userAction) {
                    case "Quick Analysis":
                        return <Log4jQuickView {...this.props}></Log4jQuickView>;
                        break;
                    default:
                        return <Log4j {...this.props}></Log4j>;
                        break;
                }
                break;
            case FileIdenEnum.VDSM:
                switch (userAction) {
                    case "Quick Analysis":
                        return <VdsmQuickView {...this.props}></VdsmQuickView>;
                        break;
                    default:
                        return <Vdsm {...this.props}></Vdsm>;
                        break;
                }
                break;
            case FileIdenEnum.SYSLOG:
                switch (userAction) {
                    case "Quick Analysis":
                        return <SyslogQuickView {...this.props}></SyslogQuickView>;
                        break;
                    default:
                        return <Syslog {...this.props}></Syslog>;
                        break;
                }
                break;
            default:
                return <span>Could not determine view to render</span>;

        }
    }
}

ViewSelector.propTypes = {
    file: PropTypes.object,
    userAction: PropTypes.string
};

export default ViewSelector;
