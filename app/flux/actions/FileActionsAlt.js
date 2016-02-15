import alt from '../../alt';
import Uri from 'jsuri';
//import FilterSortActions from './FilterSortActions'
import Promise from "bluebird";
import { each, map } from 'lodash';
import { md5 } from "../../utils/fileUtils";
//Promise.longStackTraces();

import FileStore from "../stores/FileStore";

class FileActions {

    constructor() {
        //this.generateActions('loading', 'filesUpdated');
        this.generateActions('loading', 'filesUpdated');
    }


    handleFiles(files) {
        // Add extra information to each file
        each(files, (f) => {
            f.extra = {
                name: escape(f.name),
                nameNoExtension: f.name.substring(0, f.name.lastIndexOf('.')),
                extension: f.name.substring(f.name.lastIndexOf('.') + 1),
                size: f.size,
                date: f.lastModifiedDate,
                type: f.type || 'n/a',
                parsedLines: []
            }
        });
        this.filesUpdated(files);

        // Go ahead and set the files in the store

        // Get the formats file for identification
        let uri = new Uri();
        uri.setPath('/labs/logreaper/formats');
        Promise.resolve($.ajax({
            url: uri.toString(),
            type: "GET"
        })).then((response) => {
            // Go ahead now and hash each file
            return Promise.all(map(files, (f) => md5({file: f, returnAfterNChunks: 1}))).then(() => {

                each(files, (f) => console.debug(`Hashed file: ${f.name} with hash: ${f.extra.hash}`));
                this.filesUpdated(files);

            }).catch( err => console.error(err));
        }).catch( err => console.error(err));
    }
}

export default alt.createActions(FileActions);