(function() {
  $(function() {
    var Word, createWordAndView, createWordsAndViews, drawBackground, internalOptions, pathOutline;
    internalOptions = {
      dim: 2150,
      trackWidth: 150
    };
    Word = function(val, options) {
      var $canvas;
      this.options = $.extend({
        scales: {
          fill: 0.4,
          style: 0.25
        },
        updatesPerStep: 10,
        delays: {
          stroke: 0.25,
          word: 0.5
        }
      }, options, internalOptions);
      this.val = val;
      this.utf8code = escape(val).replace(/%u/, "");
      this.strokes = [];
      this.canvas = document.createElement("canvas");
      $canvas = $(this.canvas);
      $canvas.css("width", this.styleWidth() + "px");
      $canvas.css("height", this.styleHeight() + "px");
      this.canvas.width = this.fillWidth();
      this.canvas.height = this.fillHeight();
      return this;
    };
    Word.prototype.init = function() {
      this.currentStroke = 0;
      this.currentTrack = 0;
      return this.time = 0.0;
    };
    Word.prototype.width = function() {
      return this.options.dim;
    };
    Word.prototype.height = function() {
      return this.options.dim;
    };
    Word.prototype.fillWidth = function() {
      return this.width() * this.options.scales.fill;
    };
    Word.prototype.fillHeight = function() {
      return this.height() * this.options.scales.fill;
    };
    Word.prototype.styleWidth = function() {
      return this.fillWidth() * this.options.scales.style;
    };
    Word.prototype.styleHeight = function() {
      return this.fillHeight() * this.options.scales.style;
    };
    Word.prototype.drawBackground = function() {
      var ctx;
      ctx = this.canvas.getContext("2d");
      ctx.fillStyle = "#FFF";
      ctx.fillRect(0, 0, this.fillWidth(), this.fillHeight());
      return drawBackground(ctx, this.fillWidth());
    };
    Word.prototype.draw = function() {
      var ctx,
        _this = this;
      this.init();
      ctx = this.canvas.getContext("2d");
      ctx.strokeStyle = "#000";
      ctx.fillStyle = "#000";
      ctx.lineWidth = 5;
      requestAnimationFrame(function() {
        return _this.update();
      });
      return this.promise = $.Deferred();
    };
    Word.prototype.update = function() {
      var ctx, delay, i, stroke, _i, _ref,
        _this = this;
      if (this.currentStroke >= this.strokes.length) {
        return;
      }
      ctx = this.canvas.getContext("2d");
      stroke = this.strokes[this.currentStroke];
      if (this.time === 0.0) {
        this.vector = {
          x: stroke.track[this.currentTrack + 1].x - stroke.track[this.currentTrack].x,
          y: stroke.track[this.currentTrack + 1].y - stroke.track[this.currentTrack].y,
          size: stroke.track[this.currentTrack].size || this.options.trackWidth
        };
        ctx.save();
        ctx.beginPath();
        pathOutline(ctx, stroke.outline, this.options.scales.fill);
        ctx.clip();
      }
      for (i = _i = 1, _ref = this.options.updatesPerStep; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
        this.time += 0.02;
        if (this.time >= 1) {
          this.time = 1;
        }
        ctx.beginPath();
        ctx.arc((stroke.track[this.currentTrack].x + this.vector.x * this.time) * this.options.scales.fill, (stroke.track[this.currentTrack].y + this.vector.y * this.time) * this.options.scales.fill, (this.vector.size * 2) * this.options.scales.fill, 0, 2 * Math.PI);
        ctx.fill();
        if (this.time >= 1) {
          break;
        }
      }
      delay = 0;
      if (this.time >= 1.0) {
        ctx.restore();
        this.time = 0.0;
        this.currentTrack += 1;
      }
      if (this.currentTrack >= stroke.track.length - 1) {
        this.currentTrack = 0;
        this.currentStroke += 1;
        delay = this.options.delays.stroke;
      }
      if (this.currentStroke >= this.strokes.length) {
        return setTimeout(function() {
          return _this.promise.resolve();
        }, this.options.delays.word * 1000);
      } else {
        if (delay) {
          return setTimeout(function() {
            return requestAnimationFrame(function() {
              return _this.update();
            });
          }, delay * 1000);
        } else {
          return requestAnimationFrame(function() {
            return _this.update();
          });
        }
      }
    };
    drawBackground = function(ctx, dim) {
      ctx.strokeStyle = "#A33";
      ctx.beginPath();
      ctx.lineWidth = 10;
      ctx.moveTo(0, 0);
      ctx.lineTo(0, dim);
      ctx.lineTo(dim, dim);
      ctx.lineTo(dim, 0);
      ctx.lineTo(0, 0);
      ctx.stroke();
      ctx.beginPath();
      ctx.lineWidth = 2;
      ctx.moveTo(0, dim / 3);
      ctx.lineTo(dim, dim / 3);
      ctx.moveTo(0, dim / 3 * 2);
      ctx.lineTo(dim, dim / 3 * 2);
      ctx.moveTo(dim / 3, 0);
      ctx.lineTo(dim / 3, dim);
      ctx.moveTo(dim / 3 * 2, 0);
      ctx.lineTo(dim / 3 * 2, dim);
      return ctx.stroke();
    };
    pathOutline = function(ctx, outline, scale) {
      var path, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = outline.length; _i < _len; _i++) {
        path = outline[_i];
        switch (path.type) {
          case "M":
            _results.push(ctx.moveTo(path.x * scale, path.y * scale));
            break;
          case "L":
            _results.push(ctx.lineTo(path.x * scale, path.y * scale));
            break;
          case "C":
            _results.push(ctx.bezierCurveTo(path.begin.x * scale, path.begin.y * scale, path.mid.x * scale, path.mid.y * scale, path.end.x * scale, path.end.y * scale));
            break;
          case "Q":
            _results.push(ctx.quadraticCurveTo(path.begin.x * scale, path.begin.y * scale, path.end.x * scale, path.end.y * scale));
            break;
          default:
            _results.push(void 0);
        }
      }
      return _results;
    };
    createWordAndView = function(element, val, options) {
      var promise, word;
      promise = jQuery.Deferred();
      word = new Word(val, options);
      $(element).append(word.canvas);
      WordStroker.utils.fetchStrokeJSONFromXml("utf8/" + word.utf8code.toLowerCase() + ".xml", function(json) {
        word.strokes = json;
        return promise.resolve({
          drawBackground: function() {
            return word.drawBackground();
          },
          draw: function() {
            return word.draw();
          },
          remove: function() {
            return $(word.canvas).remove();
          }
        });
      }, function() {
        return promise.resolve({
          drawBackground: function() {
            return word.drawBackground();
          },
          draw: function() {
            var p;
            p = jQuery.Deferred();
            $(word.canvas).fadeTo("fast", 0.5, function() {
              return p.resolve();
            });
            return p;
          },
          remove: function() {
            return $(word.canvas).remove();
          }
        });
      });
      return promise;
    };
    createWordsAndViews = function(element, words, options) {
      return Array.prototype.map.call(words, function(word) {
        return createWordAndView(element, word, options);
      });
    };
    window.WordStroker || (window.WordStroker = {});
    return window.WordStroker.canvas = {
      Word: Word,
      createWordsAndViews: createWordsAndViews
    };
  });

}).call(this);

/*
//@ sourceMappingURL=draw.canvas.js.map
*/