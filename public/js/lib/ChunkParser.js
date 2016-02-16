(function() {
  var ChunkParser;

  ChunkParser = (function() {
    function ChunkParser(opts) {
      var _ref, _ref1;
      this.opts = opts;
      this.rollupRes = opts.rollupRes || void 0;
      this.idName = ((_ref = opts.identification) != null ? _ref.identifiedName : void 0) || void 0;
      this.idPattern = ((_ref1 = opts.identification) != null ? _ref1.identifiedRegexName : void 0) || void 0;
      this.keyedFormat = opts.format || void 0;
      this.Xreg = opts.Xreg || void 0;
      this.re = opts.re || void 0;
      this.chunk = opts.chunk || void 0;
      this.moment = opts.moment || void 0;
      this.keys = Object.keys(this.keyedFormat.value);
    }

    ChunkParser.prototype.parse = function() {
      var matches, self;
      self = this;
      matches = [];
      this.Xreg.forEach(this.chunk, self.re, function(m, i) {
        return matches.push(self.handleMatch(m));
      });
      return matches;
    };

    ChunkParser.prototype.handleMatch = function(m) {
      var sData, self;
      self = this;
      sData = void 0;
      if (m) {
        sData = {};
        self.keys.forEach(function(n) {
          if ((m[n] == null) && self.keyedFormat.value[n].required === true) {
            throw Error("" + n + " is required but was undefined @ line " + self.index);
          }
          if (self.keyedFormat.value[n].kind === 'integer') {
            if (m[n] === void 0 || m[n] === null) {
              return sData[n] = self.keyedFormat.value[n]["default"] || -1;
            } else {
              return sData[n] = +m[n];
            }
          } else if (self.keyedFormat.value[n].kind === 'array') {
            if (!sData[n]) {
              sData[n] = [];
            }
            if (m[n] != null) {
              if ((self.keyedFormat.value[n].replace != null) === true) {
                return sData[n].push(m[n].replace(/[\{\[\}\]]/g, ''));
              } else {
                return sData[n].push = m[n];
              }
            }
          } else if (self.keyedFormat.value[n].kind === 'date') {
            if (m[n] != null) {
              if (self.keyedFormat.value[n][self.idPattern]) {
                return sData[n] = +self.moment(m[n], self.keyedFormat.value[n][self.idPattern], 'en');
              } else {
                return sData[n] = +self.moment(m[n]);
              }
            }
          } else {
            if ((self.keyedFormat.value[n].replace != null) === true) {
              return sData[n] = m[n].replace(/[\{\[\}\]]/g, '') || self.keyedFormat.value[n]["default"];
            } else {
              return sData[n] = m[n] || self.keyedFormat.value[n]["default"];
            }
          }
        });
      }
      return sData;
    };

    return ChunkParser;

  })();

  if (typeof exports !== 'undefined') {
    exports['ChunkParser'] = ChunkParser;
  } else {
    this['logreaper'] || (this['logreaper'] = {});
    this['logreaper']['ChunkParser'] = ChunkParser;
  }

}).call(this);
