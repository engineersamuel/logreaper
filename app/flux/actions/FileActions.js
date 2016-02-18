import * as types   from '../constants/ActionTypes';
import fetch        from 'isomorphic-fetch';
import Uri          from 'jsuri';

import ViewModelApacheAccess    from '../../viewModels/ViewModelApacheAccess.coffee';
import ViewModelLsof            from '../../viewModels/ViewModelLsof.coffee';
import ViewModelLog4j           from '../../viewModels/ViewModelLog4j.coffee';
import ViewModelVdsm            from '../../viewModels/ViewModelVdsm.coffee';
import ViewModelSyslog          from '../../viewModels/ViewModelSyslog.coffee';
import FileIdenEnum             from '../../components/enums/FileIdenEnum';

import {default as ReaperFile} from '../../models/File';
import {
    md5,
    identify,
    parse,
    handleSeverities
} from "../../utils/fileUtils";

export function userAction(userAction) {
    return {
        type: types.USER_ACTION,
        userAction
    }
}

export function error(err) {
    return {
        type: types.ERROR,
        err
    }
}

export function fileSeverities(severities) {
    return {
        type: types.PARSE_SEVERITIES,
        severities
    }
}

export function fileAdded(file) {
    return {
        type: types.FILE_ADDED,
        file
    }
}

export function fileParseProgress(progress) {
    return {
        type: types.FILE_PARSE_PROGRESS,
        progress
    }
}

export function fileHashed(hash) {
    return {
        type: types.FILE_HASHED,
        hash
    }
}

export function fileIdentified(iden) {
    return {
        type: types.FILE_IDENTIFIED,
        iden
    }
}

// This is how you would handle an array of arrays
//export function fileParsed(parsedLines, fileIdx) {
//    return {
//        type: types.FILE_PARSED,
//        parsedLines,
//        fileIdx
//    }
//}

export function fileParsed(viewModelOpts) {
    return {
        type: types.FILE_PARSED,
        viewModelOpts
    }
}

// No longer used, but an example on how to handle multiple files
//export function handleFiles(files) {
//    return function (dispatch) {
//        _.each(files, f => dispatch(fileAdded(new ReaperFile(f))));
//
//        // Get the formats file for identification
//        let uri = new Uri();
//        uri.setPath('/labs/logreaper/formats');
//
//        // TODO -- lookup the fetch error handler
//        return fetch(uri.toString())
//            .then(response => response.json())
//            .then(formats => {
//
//                Promise.all(_.map(files, (f) => md5({file: f, returnAfterNChunks: 1}))).then((hashes) => {
//
//                    _.each(hashes, (hash, idx) => dispatch(fileHashed(hash, idx)) );
//
//                    return Promise.all(_.map(files, f => identify({file: f, formats: formats})))
//
//                }).then((ids) => {
//
//                    _.each(ids, (iden, idx) => dispatch(fileIdentified(iden, idx)) );
//
//                }).catch( err => console.error(err));
//
//            })
//    }
//
//}

export function handleFile(file) {
    return function (dispatch) {
        // Reset the error
        dispatch(error(null));
        // Reset the parseSeverities
        dispatch(parseSeverities([]));
        // Add the file to the list
        dispatch(fileAdded(new ReaperFile(file)));
        // Get the formats file for identification
        let uri = new Uri();
        uri.setPath('/labs/logreaper/formats');

        // TODO -- lookup the fetch error handler
        return fetch(uri.toString())
            .then(response => response.json())
            .then(formats => {
                md5({file: file, returnAfterNChunks: 1}).then((hash) => {
                   dispatch(fileHashed(hash));
                    return identify({file: file, formats: formats})
                }).then((iden) => {
                    handleSeverities(iden);
                    dispatch(fileIdentified(iden));
                }).catch( err => {
                    console.error(err.stack);
                    dispatch(error(err));
                });
            })
    }
}

// No longer used, but an example on how to handle multiple files
//export function parseFiles(files) {
//    return function (dispatch) {
//        return Promise.all(_.map(files, (f, idx) => parse({file: f, fileIdx: idx, dispatch: dispatch, fileParseProgress: fileParseProgress}))).then((outputs) => {
//
//            _.each(outputs, (viewModelOpts, idx) => dispatch(fileParsed(viewModelOpts)) );
//
//        }); //.catch( err => console.error(err));
//    }
//}

export function parseFile(file, severities, action) {
    return function (dispatch) {
        // Reset the error
        dispatch(error(null));
        // Set the severities to parse
        dispatch(parseSeverities(severities));
        // Set the action to the action [Visualize, Quick Analysis]
        dispatch(userAction(action));

        parse({file: file, dispatch: dispatch, fileParseProgress: fileParseProgress, parseSeverities: severities}).then((viewModelOpts) => {
            dispatch(fileParsed(viewModelOpts));
        }).catch( err => {
            console.error(err.stack);
            dispatch(error(err));
        });
    }
}

export function parseSeverities(severities) {
    return function (dispatch) {
        dispatch(fileSeverities(severities));
    }
}

function getTheUri(uri) {
    return fetch(uri.toString()).then(response => response.json() )
}

export function exampleParseFile(name) {
    //file, parsedLines, severities, action="Visualize"
    return function (dispatch) {
        if (!_.includes(['jboss', 'lsof'], name)) {
            return dispatch(error(new Error(`${name} is not a valid example.`)));
        }

        // Reset the error
        dispatch(error(null));
        // Set the action to the action [Visualize, Quick Analysis]
        dispatch(userAction('Visualize'));

        // Set the progress to 1 to ensure the UI is handling things accordingly
        dispatch(fileParseProgress(1));

        let promises = [
            getTheUri(new Uri(`/labs/logreaper/static/examples/${name}/file.json`).toString()),
            getTheUri(new Uri(`/labs/logreaper/static/examples/${name}/lines.json`).toString()),
            getTheUri(new Uri(`/labs/logreaper/static/examples/${name}/severities.json`).toString())
        ];
        Promise.all(promises).then((results) => {
            if (!results || results.length != 3) {
                return dispatch(error(new Error('Unable to pull information for example.  Please refresh this page and try again later.')));
            }

            // Set the severities to parse
            dispatch(parseSeverities(results[2] || []));

            // TODO -- Left off here -- need to test this
            dispatch(fileIdentified(results[0].identification));

            let viewModel = {};
            switch (results[0].identification.identifiedName) {
                case FileIdenEnum.APACHE_ACCESS:
                    viewModel = new ViewModelApacheAccess();
                    break;
                case FileIdenEnum.LSOF:
                    viewModel = new ViewModelLsof();
                    break;
                case FileIdenEnum.LOG4J:
                    viewModel = new ViewModelLog4j();
                    break;
                case FileIdenEnum.VDSM:
                    viewModel = new ViewModelVdsm();
                    break;
                case FileIdenEnum.SYSLOG:
                    viewModel = new ViewModelSyslog();
                    break;
                default:
                    return reject(new Error(`Unable to parse the example, no applicable view model for ${file.identification.identifiedName}`))
            }
            viewModel.parse(results[0], results[1], results[2]).then(() => {
                dispatch(fileParsed(viewModel.generateOpts()));
            }).catch(err => {
                console.error(err.stack);
                dispatch(error(err));
            });

        });

    }
}
