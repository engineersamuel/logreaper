import alt                  from '../../alt'
import { decorate, bind }   from 'alt/utils/decorators'
//import FileActions          from '../actions/FileActions';
let FileActions        = require('../actions/FileActions');

@decorate(alt)
class FileStore {
    constructor() {
        //this.bindAction(FileActions.loading, this.onLoading);
        //this.bindAction(FileActions.filesUpdated, this.onFilesUpdated);
        //this.bindListeners({
        //    onLoading: FileActions.loading,
        //    onFilesUpdated: FileActions.filesUpdated
        //});

        this.state = {
            files: [],
            loading: false,
            err: null
        }
    }
    @bind(FileActions.loading)
    onLoading(loading) {
        this.setState({ loading: loading })
    }

    @bind(FileActions.filesUpdated)
    onFilesUpdated(files) {
        console.log("Files updated in stores");
        this.setState({
            files: files
        })
    }

}

export default alt.createStore(FileStore, 'FileStore');
