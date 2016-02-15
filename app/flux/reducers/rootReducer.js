import { combineReducers } from 'redux';

import {
    FILE_ADDED,
    FILE_HASHED,
    FILE_IDENTIFIED,
    FILE_PARSED,
    FILE_PARSE_PROGRESS,
    PARSE_SEVERITIES,
    ERROR
} from '../constants/ActionTypes';

//const initialState = {
//    files: {} // The files read from input come in as type FileList
//};

function error(state = null, action) {
    switch(action.type) {
        case ERROR:
            return action.err;
            break;
        default:
            return state;
    }
}

function parseSeverities(state = [], action) {
    switch(action.type) {
        case PARSE_SEVERITIES:
            // There is no CRUD in the interface particularly, when state is set, selected severities are dispatched,
            // so no slicing, just override
            return action.severities;
            break;
        default:
            return state;
    }
}

function file(state = {}, action) {
    switch(action.type) {
        case FILE_ADDED:
            return Object.assign({}, state, {
                file: action.file
            });
            break;
        case FILE_HASHED:
            return Object.assign({}, state, {
                //files: [
                //    ...state.files.slice(0, action.fileIdx),
                //    Object.assign({}, state.files[action.fileIdx], {hash: action.hash}),
                //    ...state.files.slice(action.fileIdx + 1)
                //]

                file: Object.assign({}, state.file, {hash: action.hash})
            });
            break;
        case FILE_IDENTIFIED:
            return Object.assign({}, state, {
                file: Object.assign({}, state.file, {identification: action.iden})
            });
            break;
        case FILE_PARSE_PROGRESS:
            return Object.assign({}, state, {
                file: Object.assign({}, state.file, {progress: action.progress})
            });
            break;
        case FILE_PARSED:
            return Object.assign({}, state, {
                file: Object.assign({}, state.file, {viewModelOpts: action.viewModelOpts})
            });
            break;
        default:
            return state;
    }
}

//function fileParsed(state = {}, action) {
//    switch(action.type) {
//        case FILE_PARSED:
//            return Object.assign({}, state, {
//                viewModelOpts: action.viewModelOpts
//            });
//        default:
//            return state;
//    }
//}

const rootReducer = combineReducers({
    file,
    parseSeverities,
    error
    //fileParsed
    //fileHashed,
    //fileIdentified,
    //fileParsedOutputs,
    //fileParseProgress
});

export default rootReducer;