(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var $canvas, $holder, $word, AABB, Comp, Stroke, Track, canvas, data, options, words;
    options = {
      dim: 2150,
      scales: {
        fill: 0.4,
        style: 0.5
      },
      delays: {
        stroke: 0.25,
        word: 0.5
      }
    };
    $holder = $("#holder");
    $word = $("#word");
    $canvas = $("<canvas></canvas>");
    $canvas.css("width", options.dim * options.scales.fill * options.scales.style + "px");
    $canvas.css("height", options.dim * options.scales.fill * options.scales.style + "px");
    canvas = $canvas.get()[0];
    canvas.width = canvas.offsetWidth = options.dim * options.scales.fill;
    canvas.height = canvas.offsetHieght = options.dim * options.scales.fill;
    $holder.append($canvas);
    data = WordStroker.utils.StrokeData({
      url: "./json/",
      dataType: "json"
    });
    AABB = (function() {
      function AABB(min, max) {
        this.min = min != null ? min : {
          x: Infinity,
          y: Infinity
        };
        this.max = max != null ? max : {
          x: -Infinity,
          y: -Infinity
        };
        Object.defineProperty(this, "width", {
          get: function() {
            return this.max.x - this.min.x;
          }
        });
        Object.defineProperty(this, "height", {
          get: function() {
            return this.max.y - this.min.y;
          }
        });
        Object.defineProperty(this, "size", {
          get: function() {
            return this.width * this.height;
          }
        });
      }

      AABB.prototype.clone = function() {
        return new AABB(this.min, this.max);
      };

      AABB.prototype.addPoint = function(pt) {
        if (pt.x < this.min.x) {
          this.min.x = pt.x;
        }
        if (pt.y < this.min.y) {
          this.min.y = pt.y;
        }
        if (pt.x > this.max.x) {
          this.max.x = pt.x;
        }
        if (pt.y > this.max.y) {
          return this.max.y = pt.y;
        }
      };

      AABB.prototype.containPoint = function(pt) {
        return pt.x > this.min.x && pt.y > this.min.y && pt.x < this.max.x && pt.y < this.max.y;
      };

      AABB.prototype.delta = function(box) {
        return new AABB(this.min, box.min).size + new AABB(this.max, box.max).size;
      };

      AABB.prototype.render = function(canvas) {
        var ctx;
        ctx = canvas.getContext("2d");
        ctx.strokeStyle = "#F00";
        ctx.lineWidth = 10;
        ctx.beginPath();
        ctx.rect(this.min.x, this.min.y, this.width, this.height);
        return ctx.stroke();
      };

      return AABB;

    })();
    Comp = (function() {
      function Comp(children, aabb) {
        var _this = this;
        this.children = children != null ? children : [];
        this.aabb = aabb;
        if (!this.aabb) {
          this.aabb = new AABB;
          this.children.forEach(function(child) {
            _this.aabb.addPoint(child.aabb.min);
            return _this.aabb.addPoint(child.aabb.max);
          });
        }
        this.length = this.children.reduce(function(prev, current) {
          return prev + current.length;
        }, 0);
        this.gaps = this.children.reduce(function(results, current) {
          return results.concat([results[results.length - 1] + current.length / _this.length]);
        }, [0]);
        this.gaps.shift();
      }

      Comp.prototype.breakUp = function(strokeNums) {
        var comps,
          _this = this;
        if (strokeNums == null) {
          strokeNums = [];
        }
        comps = [];
        strokeNums.reduce(function(start, len) {
          var end;
          end = start + len;
          comps.push(new Comp(_this.children.slice(start, end)));
          return end;
        }, 0);
        return new Comp(comps);
      };

      Comp.prototype.hitTest = function(pt) {
        var results;
        results = [];
        if (this.aabb.containPoint(pt)) {
          results.push(this);
        }
        return this.children.reduce(function(prev, child) {
          return prev.concat(child.hitTest(pt));
        }, results);
      };

      Comp.prototype.render = function(canvas, percent, matrix) {
        var child, ctx, len, _i, _len, _ref, _results;
        if (matrix == null) {
          matrix = [1, 0, 0, 1, 0, 0];
        }
        ctx = canvas.getContext("2d");
        ctx.setTransform.apply(ctx, matrix);
        len = this.length * percent;
        _ref = this.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          if (len > 0) {
            child.render(canvas, Math.min(child.length, len) / child.length, matrix);
            _results.push(len -= child.length);
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      return Comp;

    })();
    Track = (function() {
      function Track(data, options) {
        var _base;
        this.data = data;
        this.options = options != null ? options : {};
        (_base = this.options).trackWidth || (_base.trackWidth = 150);
        this.length = Math.sqrt(this.data.vector.x * this.data.vector.x + this.data.vector.y * this.data.vector.y);
        this.aabb = new AABB;
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
    Stroke = (function(_super) {
      __extends(Stroke, _super);

      function Stroke(data) {
        var aabb, children, current, i, path, prev, _i, _j, _len, _ref, _ref1;
        children = [];
        for (i = _i = 1, _ref = data.track.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
          prev = data.track[i - 1];
          current = data.track[i];
          children.push(new Track({
            x: prev.x,
            y: prev.y,
            vector: {
              x: current.x - prev.x,
              y: current.y - prev.y
            },
            size: prev.size
          }));
        }
        this.outline = data.outline;
        aabb = new AABB;
        _ref1 = this.outline;
        for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
          path = _ref1[_j];
          if ("x" in path) {
            aabb.addPoint(path);
          }
          if ("end" in path) {
            aabb.addPoint(path.begin);
            aabb.addPoint(path.end);
          }
          if ("mid" in path) {
            aabb.addPoint(path.mid);
          }
        }
        Stroke.__super__.constructor.call(this, children, aabb);
      }

      Stroke.prototype.pathOutline = function(ctx) {
        var path, _i, _len, _ref, _results;
        _ref = this.outline;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          path = _ref[_i];
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

      Stroke.prototype.hitTest = function(pt) {
        if (this.aabb.containPoint(pt)) {
          return [this];
        } else {
          return [];
        }
      };

      Stroke.prototype.render = function(canvas, percent, matrix) {
        var ctx;
        ctx = canvas.getContext("2d");
        ctx.save();
        ctx.beginPath();
        this.pathOutline(ctx);
        ctx.clip();
        Stroke.__super__.render.call(this, canvas, percent, matrix);
        return ctx.restore();
      };

      return Stroke;

    })(Comp);
    words = WordStroker.utils.sortSurrogates($word.val());
    return data.get(words[0].cp, function(json) {
      var hits, strokes, update, word;
      strokes = json.map(function(strokeData) {
        return new Stroke(strokeData);
      });
      word = new Comp(strokes, []);
      word = word.breakUp([4, 4, 4]);
      hits = [];
      $(canvas).mousemove(function(e) {
        var mouse, pos;
        pos = $(this).offset();
        mouse = {
          x: (e.pageX - pos.left) / options.scales.fill / options.scales.style,
          y: (e.pageY - pos.top) / options.scales.fill / options.scales.style
        };
        return hits = word.hitTest(mouse);
      });
      update = function() {
        var draw;
        canvas.width = canvas.width;
        word.render(canvas, 1, [options.scales.fill, 0, 0, options.scales.fill, 0, 0]);
        draw = function(o, canvas) {
          var c, _i, _len, _results;
          if (o.aabb) {
            return o.aabb.render(canvas);
          } else if (Array.isArray(o)) {
            _results = [];
            for (_i = 0, _len = o.length; _i < _len; _i++) {
              c = o[_i];
              _results.push(draw(c, canvas));
            }
            return _results;
          }
        };
        draw(hits, canvas);
        return requestAnimationFrame(update);
      };
      return requestAnimationFrame(update);
      /*
      pixel_per_second = 2000
      step = word.length / pixel_per_second * 60
      i = 0
      before = time = 0
      update = ->
        word.render canvas, time
        before = time
        time += 1 / step
        if time < 1.0
          if before < word.strokeGaps[i] and word.strokeGaps[i] < time
            setTimeout ->
              ++i
              requestAnimationFrame update
            , 500
          else
            requestAnimationFrame update
      requestAnimationFrame update
      */

      /*
      inc = false
      dec = false
      $(document)
        .keydown (e) ->
          dec = true if e.which is 37
          inc = true if e.which is 39
        .keyup (e) ->
          dec = false if e.which is 37
          inc = false if e.which is 39
      prev = time = 0
      step = 0.0025
      update = ->
        if prev isnt time
          canvas.width = canvas.width # clear rect
          word.render canvas, time
        prev = time
        time += step if inc
        time = 1.0 if time > 1.0
        time -= step if dec
        time = 0 if time < 0
        requestAnimationFrame update
      requestAnimationFrame update
      */

    }, function(err) {
      return console.log("failed");
    }, null);
  });

}).call(this);
