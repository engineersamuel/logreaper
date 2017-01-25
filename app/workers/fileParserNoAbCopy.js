var isFirefox, utf82ab;

importScripts('/labs/logreaper/static/js/lib/xregexp-all-min.js');

importScripts('/labs/logreaper/static/js/lib/stringview.js');

importScripts('/labs/logreaper/static/js/lib/moment.min.js');

importScripts('/labs/logreaper/static/js/lib/FileIdentifier.js');

importScripts('/labs/logreaper/static/js/lib/Iterator.js');

importScripts('/labs/logreaper/static/js/lib/ChunkParser.js');

utf82ab = function(str) {
    var buf, bufView;
    buf = new ArrayBuffer(str.length);
    bufView = new Uint8Array(buf);
    for (var i=0, strLen=str.length; i<strLen; i++) {
        bufView[i] = str.charCodeAt(i);
    };
    return buf;
};

isFirefox = false;

if (navigator.userAgent.indexOf('Firefox') !== -1 && parseFloat(navigator.userAgent.substring(navigator.userAgent.indexOf('Firefox') + 8)) >= 3.6) {
    isFirefox = true;
}

self.addEventListener('message', function(e) {
    var blobSlice, chunkSize, chunks, content, ctr, currentChunk, dur, fi, fileId, frOnerror, handleChunk, handleChunkAsync, leftOverString, loadChunkAsync, loadChunkSync, output, p, parseSeverityLabels, parseSeverityValues, reader, ref, severityField, start, sub_ctr, totalChunks, x;
    switch (e.data.cmd) {
        case 'identify':
            blobSlice = e.data.file.slice || e.data.file.mozSlice || e.data.file.webkitSlice;
            chunkSize = 1024 * 1024;
            reader = void 0;
            content = new StringView(reader.readAsArrayBuffer(blobSlice.call(e.data.file, 0, chunkSize)));
            fi = new logreaper.FileIdentifier(e.data.formats, XRegExp);
            output = fi.identify(content.toString());
            self.postMessage({
                cmd: 'identificationComplete',
                result: output,
                hash: e.data.hash
            });
            self.close();
            break;
        case 'parse':
            p = void 0;
            blobSlice = e.data.file.slice || e.data.file.mozSlice || e.data.file.webkitSlice;
            chunkSize = 1024 * 1024 * 1;
            chunks = Math.ceil(e.data.file.size / chunkSize);
            currentChunk = 0;
            leftOverString = void 0;
            fileId = e.data.identification;
            parseSeverityLabels = e.data.parseSeverities;
            severityField = e.data.severityField;
            parseSeverityValues = [];
            if (((ref = fileId.format.value[severityField]) != null ? ref.values : void 0) != null) {
                fileId.format.value[severityField].values.forEach(function(v) {
                    if (parseSeverityLabels.indexOf(v.label) === -1) {
                        return v.values.forEach(function(value) {
                            return parseSeverityValues.push(value);
                        });
                    }
                });
            }
            self.postMessage({
                cmd: 'initialMetadata',
                totalChunks: chunks
            });
            ctr = 0;
            sub_ctr = 0;
            dur = 0;
            start = Date.now();
            totalChunks = chunks;
            x = XRegExp.cache(fileId.format['regex'][fileId.identifiedRegexName]['pattern'], 'gim');
            handleChunk = function(result) {
                var err, error, msg, parsedLines, ref1, ref2, ref3;
                content = new StringView(result);
                p = new logreaper.ChunkParser({
                    chunk: content.toString(),
                    moment: moment,
                    Xreg: XRegExp,
                    re: x,
                    format: fileId.format,
                    identification: fileId
                });
                parsedLines = p.parse();
                msg = {
                    cmd: 'parsingProgress',
                    hash: e.data.hash,
                    progress: currentChunk / totalChunks,
                    linesParsed: sub_ctr,
                    chunksParsed: currentChunk
                };
                self.postMessage(msg);
                try {
                    return parsedLines.forEach(function(r) {
                        if ((r != null) && (parseSeverityValues != null ? parseSeverityValues.indexOf(r[severityField]) : void 0) === -1) {
                            r.fileName = decodeURIComponent(e.data.name).replace(/[\(\) ]+/g, "");
                            if (!(r == null)) {
                                self.postMessage({
                                    cmd: 'lineParsed',
                                    hash: e.data.hash,
                                    parsedLine: JSON.stringify(r)
                                });
                            }
                        }
                        return sub_ctr++;
                    });
                } catch (error) {
                    err = error;
                    return self.postMessage({
                        cmd: 'error',
                        data: JSON.stringify(e)
                    });
                } finally {
                    currentChunk++;
                    if (currentChunk < chunks) {
                        if (isFirefox === true) {
                            loadChunkSync();
                        } else {
                            loadChunkAsync();
                        }
                    } else {
                        self.postMessage({
                            cmd: 'parsingComplete',
                            hash: e.data.hash
                        });
                        if (typeof window !== "undefined" && window !== null) {
                            if ((ref1 = window.logreaper) != null) {
                                ref1.ChunkParser = null;
                            }
                        }
                        if (typeof window !== "undefined" && window !== null) {
                            if ((ref2 = window.logreaper) != null) {
                                ref2.FileIdentifier = null;
                            }
                        }
                        if (typeof window !== "undefined" && window !== null) {
                            if ((ref3 = window.logreaper) != null) {
                                ref3.Iterator = null;
                            }
                        }
                        self.close();
                    }
                }
            };
            frOnerror = function(err) {
                return cb(err);
            };
            handleChunkAsync = function(fevt) {
                return handleChunk(fevt.target.result);
            };
            loadChunkAsync = function() {
                var end, fileReader;
                fileReader = new FileReader();
                fileReader.onload = handleChunkAsync;
                fileReader.onerror = frOnerror;
                start = currentChunk * chunkSize;
                end = ((start + chunkSize) >= e.data.file.size ? e.data.file.size : start + chunkSize);
                return fileReader.readAsArrayBuffer(blobSlice.call(e.data.file, start, end));
            };
            loadChunkSync = function() {
                var end, fileReader;
                fileReader = new FileReaderSync();
                start = currentChunk * chunkSize;
                end = ((start + chunkSize) >= e.data.file.size ? e.data.file.size : start + chunkSize);
                return handleChunk(fileReader.readAsArrayBuffer(blobSlice.call(e.data.file, start, end)));
            };
            if (isFirefox) {
                return loadChunkSync();
            } else {
                return loadChunkAsync();
            }
            break;
        case 'status':
            return void 0;
        case 'stop':
            return self.close();
    }
}, false);
