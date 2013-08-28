(function() {
  $(function() {
    var Word, demoMatrix, drawBackground, drawElementWithWord, drawElementWithWords, internalOptions, pathOutline;
    internalOptions = {
      dim: 2150,
      trackWidth: 150
    };
    demoMatrix = [1, 0, 0, 1, 100, 100];
    Word = function(options) {
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
        },
        progress: null,
        source: "json"
      }, options, internalOptions);
      this.matrix = [this.options.scales.fill, 0, 0, this.options.scales.fill, 0, 0];
      this.myCanvas = document.createElement("canvas");
      $canvas = $(this.myCanvas);
      $canvas.css("width", this.styleWidth() + "px");
      $canvas.css("height", this.styleHeight() + "px");
      this.myCanvas.width = this.fillWidth();
      this.myCanvas.height = this.fillHeight();
      this.canvas = this.myCanvas;
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
    Word.prototype.drawBackground = function(canvas) {
      var ctx;
      this.canvas = canvas ? canvas : this.myCanvas;
      ctx = this.canvas.getContext("2d");
      ctx.fillStyle = "#FFF";
      ctx.fillRect(0, 0, this.fillWidth(), this.fillHeight());
      return drawBackground(ctx, this.fillWidth());
    };
    Word.prototype.draw = function(strokeJSON, canvas) {
      var ctx,
        _this = this;
      this.init();
      this.strokes = strokeJSON;
      this.canvas = canvas ? canvas : this.myCanvas;
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
      ctx.setTransform.apply(ctx, this.matrix);
      stroke = this.strokes[this.currentStroke];
      if (this.time === 0.0) {
        this.vector = {
          x: stroke.track[this.currentTrack + 1].x - stroke.track[this.currentTrack].x,
          y: stroke.track[this.currentTrack + 1].y - stroke.track[this.currentTrack].y,
          size: stroke.track[this.currentTrack].size || this.options.trackWidth
        };
        ctx.save();
        ctx.beginPath();
        pathOutline(ctx, stroke.outline);
        ctx.clip();
      }
      for (i = _i = 1, _ref = this.options.updatesPerStep; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
        this.time += 0.02;
        if (this.time >= 1) {
          this.time = 1;
        }
        ctx.beginPath();
        ctx.arc(stroke.track[this.currentTrack].x + this.vector.x * this.time, stroke.track[this.currentTrack].y + this.vector.y * this.time, this.vector.size * 2, 0, 2 * Math.PI);
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
    pathOutline = function(ctx, outline) {
      var path, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = outline.length; _i < _len; _i++) {
        path = outline[_i];
        switch (path.type) {
          case "M":
            _results.push(ctx.moveTo(path.x, path.y));
            break;
          case "L":
            _results.push(ctx.lineTo(path.x, path.y));
            break;
          case "C":
            _results.push(ctx.bezierCurveTo(path.begin.x, path.begin.y, path.mid.x, path.mid.y, path.end.x, path.end.y));
            break;
          case "Q":
            _results.push(ctx.quadraticCurveTo(path.begin.x, path.begin.y, path.end.x, path.end.y));
            break;
          default:
            _results.push(void 0);
        }
      }
      return _results;
    };
    drawElementWithWord = function(element, word, options) {
      var $loader, $word, promise, stroker;
      promise = jQuery.Deferred();
      stroker = new Word(options);
      $word = $("<div class=\"word\"></div>");
      $loader = $("<div class=\"loader\"><div style=\"width: 0\"></div><i class=\"icon-spinner icon-spin icon-large icon-fixed-width\"></i></div>");
      $word.append(stroker.canvas).append($loader);
      $(element).append($word);
      WordStroker.utils.StrokeData.source(options.source);
      WordStroker.utils.StrokeData.get(word.cp, function(json) {
        $loader.remove();
        return promise.resolve({
          drawBackground: function() {
            return stroker.drawBackground();
          },
          draw: function() {
            return stroker.draw(json);
          },
          remove: function() {
            return $(stroker.canvas).remove();
          }
        });
      }, function() {
        $loader.remove();
        return promise.resolve({
          drawBackground: function() {
            return stroker.drawBackground();
          },
          draw: function() {
            var p;
            p = jQuery.Deferred();
            $(stroker.canvas).fadeTo("fast", 0.5, function() {
              return p.resolve();
            });
            return p;
          },
          remove: function() {
            return $(stroker.canvas).remove();
          }
        });
      }, function(e) {
        if (e.lengthComputable) {
          $loader.find("> div").css("width", e.loaded / e.total * 100 + "%");
        }
        return promise.notifyWith(e, [e, word.text]);
      });
      return promise;
    };
    drawElementWithWords = function(element, words, options) {
      return WordStroker.utils.sortSurrogates(words).map(function(word) {
        return drawElementWithWord(element, word, options);
      });
    };
    window.WordStroker || (window.WordStroker = {});
    return window.WordStroker.canvas = {
      Word: Word,
      drawElementWithWords: drawElementWithWords
    };
  });

}).call(this);

/*
//@ sourceMappingURL=draw.canvas.js.map
*/