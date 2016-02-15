import SparkMD5 from 'spark-md5';

let FileParserWorker            = require("worker!../workers/fileParser");
let FileParserNoAbCopyWorker    = require("worker!../workers/fileParserNoAbCopy");

import ViewModelApacheAccess    from '../viewModels/ViewModelApacheAccess.coffee';
import ViewModelLsof            from '../viewModels/ViewModelLsof.coffee';
import ViewModelLog4j           from '../viewModels/ViewModelLog4j.coffee';
import ViewModelVdsm            from '../viewModels/ViewModelVdsm.coffee';
import ViewModelSyslog          from '../viewModels/ViewModelSyslog.coffee';
import FileIdenEnum             from '../components/enums/FileIdenEnum';

export function truthy(obj) {
    if (obj === void 0) {
        return false;
    } else if (_.isBoolean(obj)) {
        return obj;
    } else if (_.isString(obj)) {
        if (_.includes(['YES', 'Yes', 'yes', 'Y', 'y', '1', 'true', 'TRUE', 'ok', 'OK', 'Ok'], obj)) {
            return true;
        } else {
            return false;
        }
    } else if (_.isNumber(obj)) {
        return parseInt(obj) === 1;
    } else {
        return false;
    }
};

export function handleSeverities(iden) {
    // Currently the only two fields ever parsed to look at 'severity' values is severity (log4j type logs) and status (apache).
    // This could be made much more dynamic in the future either through the yaml or code.
    let severityValues = _.get(iden, 'format.value.severity.values') || _.get(iden, 'format.value.status.values');
    if (severityValues)  {
        // Defines which severities should be parsed out by default, this can be changed manually in the UI where applicable.
        iden.parseSeverities = _.chain(severityValues).filter(f => truthy(f.ignore) === false).map(v => v.label).flatten().uniq().value();
        // Defines all available severities to parse
        iden.allSeverities = _.chain(severityValues).map(v => v.label).flatten().uniq().value();
    }
}

export function identify(opts) {
    return new Promise((resolve, reject) => {
        let worker = new FileParserWorker();
        worker.postMessage({cmd: 'identify', 'formats': opts.formats, 'file': opts.file});
        worker.onmessage = (e) => {
            resolve(e.data.result)
        };
    })
}

export function md5(opts) {
    return new Promise((resolve, reject) => {

        let blobSlice, chunkSize, chunks, currentChunk, frOnerror, frOnload, loadNext, spark;
        blobSlice = File.prototype.slice || File.prototype.mozSlice || File.prototype.webkitSlice;
        chunkSize = 1048576;
        chunks = Math.ceil(opts.file.size / chunkSize);
        currentChunk = 0;
        frOnload = function(e) {
            let result, terminateEarly;
            result = e.target.result;
            spark.append(result);
            currentChunk++;
            terminateEarly = (opts.returnAfterNChunks != null) && (currentChunk >= opts.returnAfterNChunks);
            if ((currentChunk < chunks) && !terminateEarly) {
                loadNext();
            } else {
                return resolve(spark.end());
            }
        };
        frOnerror = function(err) {
            console.error(err);
            return resolve({error: err});
        };
        loadNext = function() {
            let end, fileReader, start;
            fileReader = new FileReader();
            fileReader.onload = frOnload;
            fileReader.onerror = frOnerror;
            start = currentChunk * chunkSize;
            end = ((start + chunkSize) >= opts.file.size ? opts.file.size : start + chunkSize);
            return fileReader.readAsArrayBuffer(blobSlice.call(opts.file, start, end));
        };
        spark = new SparkMD5.ArrayBuffer();
        console.debug(`Hashing file ${opts.file.name}`);
        loadNext();
    });
}

export function parse(opts) {
    return new Promise((resolve, reject) => {
        let worker = new FileParserNoAbCopyWorker();
        let parsedLines = [];
        let parseSeverities = opts.parseSeverities || opts.file.identification.parseSeverities;
        let totalChunks = 0;
        let linesParsed = 0;
        let start = Date.now();
        let dur = 0;
        let progress = null;
        //# The serialization of File does not include any extra properties, have to set those separately
        worker.onmessage = (e) => {
            switch (e.data.cmd) {
                case 'log-debug':
                    console.debug(JSON.stringify(e.data));
                    break;
                case 'log-error':
                    console.error(JSON.stringify(e.data));
                    break;
                case 'error':
                    console.error("[ERROR] " + (JSON.stringify(e, null, ' ')));
                    break;
                case 'initialMetadata':
                    totalChunks += e.data.totalChunks;
                    console.debug(`Initial metadata, total chunks: ${totalChunks}`);
                    break;
                case 'parsingProgress':
                    linesParsed += e.data.linesParsed;
                    progress = e.data.progress;
                    console.debug(`progress: ${e.data.progress}`);
                    opts.dispatch(opts.fileParseProgress(e.data.progress, opts.fileIdx));

                    //self.linesProgressIndicator.setProgress(progress);
                    //self.linesProgressIndicator.setValue(e.data.chunksParsed + " chunks parsed");
                    break;
                case 'lineParsed':
                    try {
                        parsedLines.push(JSON.parse(e.data.parsedLine));
                    } catch (_error) {
                        console.error(e.data.parsedLine);
                        console.error("Failed to JSON.parse line above, continuing...");
                    }
                    break;
                case 'parsingComplete':
                    dur = Date.now() - start;
                    console.debug(`Parsing complete in: ${dur}`);
                    opts.dispatch(opts.fileParseProgress(1, opts.fileIdx));

                    let viewModel = {};
                    switch (opts.file.identification.identifiedName) {
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
                            return reject(new Error(`Unable to complete the parsing of the file as there is no applicable view model for ${opts.file.identification.identifiedName}`))
                    }
                    viewModel.parse(opts.file, parsedLines, parseSeverities).then(() => {
                        resolve(viewModel.generateOpts());
                    }).catch(e => reject(e));
            }
        };
        worker.onerror = (e) => {
            console.error(`onError: ${JSON.stringify(e)}`);
            return resolve({error: e});
        };
        if (_.get(opts, 'parseSeverities', []).length > 0) {
            console.debug(`Parsing out ${JSON.stringify(opts.parseSeverities)} from ${opts.file.file.name}`);
        }
        let payload = {
            cmd: 'parse',
            file: opts.file.file,
            name: opts.file.file.name,
            hash: opts.file.hash,
            identification: opts.file.identification,
            parseSeverities: parseSeverities,
            severityField: opts.file.identification.format.severityField || "severity"
        };
        worker.postMessage(payload)
    });
}

