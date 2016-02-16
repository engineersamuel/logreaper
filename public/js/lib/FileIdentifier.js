(function() {
  var FileIdentifier;

  FileIdentifier = (function() {
    function FileIdentifier(formats, XRegExp) {
      this.formats = formats;
      this.XRegExp = XRegExp;
      this.output = {
        matched: false,
        identifiedName: void 0,
        identifiedRegexName: void 0,
        identifiedAfterIterations: void 0,
        format: void 0
      };
    }

    FileIdentifier.prototype.identify = function(rawText) {
      var BreakException, ctr, e, formatNames, gcIdx, n, self, splitText;
      self = this;
      splitText = "";
      if (typeof rawText === 'object') {
        splitText = rawText.toString().split(/\r?\n/);
      } else {
        splitText = rawText.split(/\r?\n/);
      }
      formatNames = Object.keys(self.formats);
      gcIdx = formatNames.indexOf("gc");
      if (gcIdx !== -1) {
        n = formatNames.splice(gcIdx, 1);
        formatNames.push(n[0]);
      }
      BreakException = {};
      try {
        ctr = 0;
        splitText.forEach(function(line) {
          line = line + '\n';
          ctr++;
          return formatNames.forEach(function(name) {
            var regexNames;
            regexNames = Object.keys(self.formats[name]['regex']);
            return regexNames.forEach(function(regexName) {
              var h, m, t, x;
              x = self.XRegExp(self.formats[name]['regex'][regexName]['pattern'], 'gim');
              m = x.exec(line);
              t = x.test(line);
              if (m) {
                if (self.formats[name]['regex'][regexName]['header'] != null) {
                  h = self.XRegExp(self.formats[name]['regex'][regexName]['header']);
                  if (self.XRegExp.isRegExp(h) && h.test(splitText[0]) === false) {
                    throw BreakException;
                  }
                }
                self.output.matched = true;
                self.output.firstLineMatched = line;
                self.output.identifiedName = name;
                self.output.identifiedRegexName = regexName;
                self.output.identifiedAfterIterations = ctr;
                self.output.format = self.formats[name];
                throw BreakException;
              }
            });
          });
        });
      } catch (_error) {
        e = _error;
        return self.output;
      }
      return self.output;
    };

    return FileIdentifier;

  })();

  if (typeof exports !== 'undefined') {
    exports['FileIdentifier'] = FileIdentifier;
  } else {
    this['logreaper'] || (this['logreaper'] = {});
    this['logreaper']['FileIdentifier'] = FileIdentifier;
  }

}).call(this);
