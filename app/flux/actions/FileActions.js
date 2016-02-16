import * as types   from '../constants/ActionTypes';
import fetch        from 'isomorphic-fetch';
import Uri          from 'jsuri';
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
