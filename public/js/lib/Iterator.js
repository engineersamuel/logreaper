(function() {
  var ParsingArrayIterator;

  ParsingArrayIterator = (function() {
    function ParsingArrayIterator(opts) {
      var _ref, _ref1;
      this.opts = opts;
      this.index = -1;
      this.rollupRes = opts.rollupRes || void 0;
      this.idName = ((_ref = opts.identification) != null ? _ref.identifiedName : void 0) || void 0;
      this.idPattern = ((_ref1 = opts.identification) != null ? _ref1.identifiedRegexName : void 0) || void 0;
      this.keyedFormat = opts.format || void 0;
      this.Xreg = opts.Xreg || void 0;
      this.re = opts.re || void 0;
      this.arr = opts.arr || void 0;
      this.moment = opts.moment || void 0;
      this.stackIdx = 0;
      this.keys = Object.keys(this.keyedFormat.value) || [];
    }

    ParsingArrayIterator.prototype.hasNext = function(lastChunk) {
      var onLastElement, self;
      self = this;
      if (!self.arr) {
        return false;
      }
      if (lastChunk === void 0 || lastChunk === true) {
        return this.index + 1 < self.arr.length;
      } else {
        onLastElement = (this.index + 1) === self.arr.length;
        if (onLastElement === true) {
          throw {
            "class": 'ParsingArrayIteratorIterator',
            name: 'Needs more data',
            level: 'error',
            message: "ParsingArrayIteratorIterator needs more chunks from the ArrayBuffer, please load more.  lastChunk: " + lastChunk + ", arr.length: " + self.arr.length + ", current idx: " + self.index,
            htmlMessage: 'ParsingArrayIteratorIterator needs more chunks from the ArrayBuffer, please load more',
            toString: function() {
              return "" + this.name + ": " + this.message;
            }
          };
        } else {
          return (this.index + 1) < self.arr.length;
        }
      }
    };

    ParsingArrayIterator.prototype.hasPrevious = function() {
      return this.index > 0;
    };

    ParsingArrayIterator.prototype.current = function() {
      var self;
      self = this;
      return this.arr[this.index];
    };

    ParsingArrayIterator.prototype.forwardToEnd = function() {
      return this.index = this.arr.length;
    };

    ParsingArrayIterator.prototype.next = function(lastChunk) {
      var breakWhile, m, matchFound, peekedValue, sData, self, _ref, _ref1;
      self = this;
      if (this.hasNext(lastChunk)) {
        self.index = self.index + 1;
        m = self.Xreg.exec(self.current(), self.re);
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
          if (((_ref = self.rollupRes) != null ? _ref.length : void 0) > 0) {
            while (self.hasNext()) {
              peekedValue = this.arr[self.index + 1];
              breakWhile = false;
              matchFound = false;
              for (var j = self.stackIdx; j < self.rollupRes.length; j++) {
              // Attempt to match the peeked value from one of the stack trace regular expressions
              m = self.Xreg.exec(peekedValue, self.rollupRes[j]);
              //console.log("Attempting to match with regex: " + self.rollupRes[j] )

              // If m matches, we are within a sub matching expression
              if(m) {
                //console.log("m[message]: " + JSON.stringify(m.message));

                // Go ahead an increment the index immediately
                self.index = self.index + 1;

                // key to the field to rollup into which we know will already be initialized
                // TODO -- { and } can cause problems in the parsing, let's remove those for now
                sData[self.keyedFormat['rollupStackTo']].push(m[self.keyedFormat['rollupStackFrom']].replace(/[\{\[\}\]]/g, ''));

                // Break out of this for loop to stop matching
                matchFound = true
                break;

              // Otherwise break out of the while loop which means the index will not have been advanced and life resumes
              // as normal
              } else {
                // If there is no match found and we are at the end of the regex to test for the stack trace, break out
                // Of the while and resume normal flow
                if(!matchFound && (j === self.rollupRes.length - 1)) {

                  // Now attempt to match the line back to the main regex.  If unmatched, we know we have very
                  // unstructured data that we may want to rollup into the message
                  if(self.keyedFormat.rollupUnmatched === true) {
                    sub_m = self.Xreg.exec(peekedValue, self.re)
                    if(!sub_m && peekedValue != '') {
                      self.index = self.index + 1
                      //sData[self.keyedFormat['rollupStackTo']].push(peekedValue.replace(/[\{\[\}\]]/g, ''))
                      sData[self.keyedFormat['rollupStackTo']].push(peekedValue.replace(/[\{\}]/g, ''))
                    }
                  }

                  breakWhile = true;
                  break;
                }
              }
            }
            ;
              if (breakWhile) {
                break;
              }
            }
          }
        }
        return sData;
      }
      throw Error("Index out of bounds.  Requested element @ index: " + (self.index + 1) + " yet array length is " + ((_ref1 = self.arr) != null ? _ref1.length : void 0));
    };

    ParsingArrayIterator.prototype.prev = function() {
      var self;
      self = this;
      if (this.hasPrevious()) {
        self.index = self.index - 1;
        return self.current();
      }
      throw Error("Index out of bounds.  Requested element @ index: " + (self.index - 1));
    };

    return ParsingArrayIterator;

  })();

  if (typeof exports !== 'undefined') {
    exports['ParsingArrayIterator'] = ParsingArrayIterator;
  } else {
    this['logreaper'] || (this['logreaper'] = {});
    this['logreaper']['ParsingArrayIterator'] = ParsingArrayIterator;
  }

}).call(this);
