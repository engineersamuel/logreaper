export default class File {

    constructor(file, hash) {
        this.file = file;
        this.hash = hash;
        this.identification = null;
        this.parsedLines = [];
        this.progress = null;
        this.viewModelOpts = null;
    }
}