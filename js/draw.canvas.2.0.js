(function() {
  $(function() {
    var $canvas, $holder, $word, Stroke, Track, Word, canvas, data, options, words;
    options = {
      dim: 2150,
      scales: {
        fill: 0.4,
        style: 0.25
      },
      delays: {
        stroke: 0.25,
        word: 0.5
      }
    };
    $holder = $("#holder");
    $word = $("#word");
    $canvas = $("<canvas></canvas>");
    $canvas.css("width", options.dim * options.scales.fill * options.scales.style + "pt");
    $canvas.css("height", options.dim * options.scales.fill * options.scales.style + "pt");
    canvas = $canvas.get()[0];
    canvas.width = options.dim * options.scales.fill;
    canvas.height = options.dim * options.scales.fill;
    $holder.append($canvas);
    data = WordStroker.utils.StrokeData({
      url: "./json/",
      dataType: "json"
    });
    Track = (function() {
      function Track(data, options) {
        this.data = data;
        this.options = options;
        this.length = Math.sqrt(this.data.vector.x * this.data.vector.x + this.data.vector.y * this.data.vector.y);
      }

      Track.prototype.render = function(canvas, percent) {
        var ctx, size;
        size = this.data.size || this.options.trackWidth;
        ctx = canvas.getContext("2d");
        ctx.beginPath();
        ctx.strokeStyle = "#000";
        ctx.fillStyle = "#000";
        ctx.lineWidth = 2 * size;
        ctx.lineCap = "round";
        ctx.moveTo(this.data.x, this.data.y);
        ctx.lineTo(this.data.x + this.data.vector.x * percent, this.data.y + this.data.vector.y * percent);
        return ctx.stroke();
      };

      return Track;

    })();
    Stroke = (function() {
      function Stroke(data, options) {
        var current, i, prev, _i, _ref;
        this.options = options;
        this.outline = data.outline;
        this.tracks = [];
        for (i = _i = 1, _ref = data.track.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
          prev = data.track[i - 1];
          current = data.track[i];
          this.tracks.push(new Track({
            x: prev.x,
            y: prev.y,
            vector: {
              x: current.x - prev.x,
              y: current.y - prev.y
            },
            size: prev.size
          }, this.options));
        }
        this.length = this.tracks.reduce(function(prev, current) {
          return prev + current.length;
        }, 0);
      }

      Stroke.prototype.pathOutline = function(ctx, outline) {
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

      Stroke.prototype.render = function(canvas, percent) {
        var ctx, len, track, _i, _len, _ref;
        ctx = canvas.getContext("2d");
        ctx.save();
        ctx.beginPath();
        this.pathOutline(ctx, this.outline);
        ctx.clip();
        len = this.length * percent;
        _ref = this.tracks;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          track = _ref[_i];
          if (len > 0) {
            track.render(canvas, Math.min(track.length, len) / track.length);
            len -= track.length;
          }
        }
        return ctx.restore();
      };

      return Stroke;

    })();
    Word = (function() {
      function Word(data, options) {
        var _this = this;
        this.options = $.extend({
          scale: 0.4,
          trackWidth: 150
        }, options);
        this.matrix = [this.options.scale, 0, 0, this.options.scale, 0, 0];
        this.strokes = [];
        data.map(function(strokeData) {
          return _this.strokes.push(new Stroke(strokeData, _this.options));
        });
        this.length = this.strokes.reduce(function(prev, current) {
          return prev + current.length;
        }, 0);
      }

      Word.prototype.render = function(canvas, percent) {
        var ctx, len, stroke, _i, _len, _ref, _results;
        ctx = canvas.getContext("2d");
        ctx.setTransform.apply(ctx, this.matrix);
        len = this.length * percent;
        _ref = this.strokes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          stroke = _ref[_i];
          if (len > 0) {
            stroke.render(canvas, Math.min(stroke.length, len) / stroke.length);
            _results.push(len -= stroke.length);
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      return Word;

    })();
    words = WordStroker.utils.sortSurrogates($word.val());
    return data.get(words[0].cp, function(json) {
      var pixel_per_second, step, time, update, word;
      word = new Word(json, {
        scale: options.scales.fill
      });
      pixel_per_second = 2000;
      step = word.length / pixel_per_second * 60;
      time = 0;
      update = function() {
        word.render(canvas, time);
        time += 1 / step;
        if (time < 1.0) {
          return requestAnimationFrame(update);
        }
      };
      return requestAnimationFrame(update);
    }, function(err) {
      return console.log("failed");
    }, null);
  });

}).call(this);

/*
//@ sourceMappingURL=draw.canvas.2.0.js.map
*/