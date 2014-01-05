// Generated by LiveScript 1.2.0
(function(){
  var AABB, Comp, Empty, Track, Stroke, Arrow, x$, ref$;
  AABB = (function(){
    AABB.displayName = 'AABB';
    var scan, prototype = AABB.prototype, constructor = AABB;
    scan = function(group, axis){
      var points, i$, len$, box, groups, g, d, p, result, anotherAxis;
      axis == null && (axis = 'x');
      switch (false) {
      case !!Array.isArray(group):
        throw new Error('not a group of AABBs');
      case group[0].min[axis] !== undefined:
        throw new Error('axis not found');
      default:
        points = [];
        for (i$ = 0, len$ = group.length; i$ < len$; ++i$) {
          box = group[i$];
          if (!box.isEmpty()) {
            points.push({
              box: box,
              value: box.min[axis],
              depth: 1
            });
            points.push({
              value: box.max[axis],
              depth: -1
            });
          }
        }
        points.sort(function(a, b){
          switch (false) {
          case !(a.value < b.value):
            return -1;
          case a.value !== b.value:
            return 0;
          case !(a.value > b.value):
            return 1;
          }
        });
        groups = [];
        g = [];
        d = 0;
        for (i$ = 0, len$ = points.length; i$ < len$; ++i$) {
          p = points[i$];
          d += p.depth;
          if (d !== 0) {
            if (p.box) {
              g.push(p.box);
            }
          } else {
            groups.push(g);
            g = [];
          }
        }
        result = [];
        anotherAxis = axis === 'x' ? 'y' : 'x';
        if (groups.length > 1) {
          for (i$ = 0, len$ = groups.length; i$ < len$; ++i$) {
            g = groups[i$];
            result = result.concat(scan(g, anotherAxis));
          }
        } else {
          result = groups;
        }
        return result;
      }
    };
    AABB.rdc = function(g){
      var xs, ys;
      xs = scan(g, 'x');
      ys = scan(g, 'y');
      if (xs.length > ys.length) {
        return xs;
      } else {
        return ys;
      }
    };
    function AABB(min, max){
      this.min = min != null
        ? min
        : {
          x: Infinity,
          y: Infinity
        };
      this.max = max != null
        ? max
        : {
          x: -Infinity,
          y: -Infinity
        };
      Object.defineProperty(this, "width", {
        get: function(){
          return this.max.x - this.min.x;
        }
      });
      Object.defineProperty(this, "height", {
        get: function(){
          return this.max.y - this.min.y;
        }
      });
      Object.defineProperty(this, "size", {
        get: function(){
          return this.width * this.height;
        }
      });
    }
    prototype.isEmpty = function(){
      return this.min.x >= this.max.x || this.min.y >= this.max.y;
    };
    prototype.clone = function(){
      return new AABB(this.min, this.max);
    };
    prototype.addPoint = function(pt){
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
    prototype.addBox = function(aabb){
      if (aabb.min.x < this.min.x) {
        this.min.x = aabb.min.x;
      }
      if (aabb.min.y < this.min.y) {
        this.min.y = aabb.min.y;
      }
      if (aabb.max.x > this.max.x) {
        this.max.x = aabb.max.x;
      }
      if (aabb.max.y > this.max.y) {
        return this.max.y = aabb.max.y;
      }
    };
    prototype.containPoint = function(pt){
      var ref$;
      return (this.min.x < (ref$ = pt.x) && ref$ < this.max.x) && (this.min.y < (ref$ = pt.y) && ref$ < this.max.y);
    };
    prototype.delta = function(box){
      return new AABB(this.min, box.min).size + new AABB(this.max, box.max).size;
    };
    prototype.render = function(canvas, color, width){
      var x$;
      color == null && (color = '#f00');
      width == null && (width = 10);
      x$ = canvas.getContext('2d');
      x$.strokeStyle = color;
      x$.lineWidth = width;
      x$.beginPath();
      x$.rect(this.min.x, this.min.y, this.width, this.height);
      x$.stroke();
      return x$;
    };
    return AABB;
  }());
  Comp = (function(){
    Comp.displayName = 'Comp';
    var prototype = Comp.prototype, constructor = Comp;
    function Comp(children, aabb){
      var i$, ref$, len$, child;
      this.children = children != null
        ? children
        : [];
      this.aabb = aabb != null
        ? aabb
        : new AABB;
      for (i$ = 0, len$ = (ref$ = this.children).length; i$ < len$; ++i$) {
        child = ref$[i$];
        child.parent = this;
        this.aabb.addBox(child.aabb);
      }
      this.computeLength();
      this.time = 0.0;
      this.x = this.y = 0;
      this.scaleX = this.scaleY = 1.0;
      this.parent = null;
    }
    prototype.computeLength = function(){
      return this.length = this.children.reduce(function(prev, current){
        return prev + current.length;
      }, 0);
    };
    prototype.childrenChanged = function(){
      var len, i$, ref$, len$, child;
      this.computeLength();
      len = 0;
      for (i$ = 0, len$ = (ref$ = this.children).length; i$ < len$; ++i$) {
        child = ref$[i$];
        len += child.time * child.length;
      }
      this.time = len / this.length;
      if ((ref$ = this.parent) != null) {
        ref$.childrenChanged();
      }
    };
    prototype.breakUp = function(strokeNums){
      var comps, this$ = this;
      strokeNums == null && (strokeNums = []);
      comps = [];
      strokeNums.reduce(function(start, len){
        var end;
        end = start + len;
        comps.push(new Comp(this$.children.slice(start, end)));
        return end;
      }, 0);
      return new Comp(comps);
    };
    prototype.hitTest = function(pt){
      var results;
      results = [];
      if (this.aabb.containPoint(pt)) {
        results.push(this);
      }
      return this.children.reduce(function(prev, child){
        return prev.concat(child.hitTest(pt));
      }, results);
    };
    prototype.beforeRender = function(ctx){};
    prototype.doRender = function(ctx){};
    prototype.afterRender = function(ctx){};
    prototype.render = function(canvas){
      var x, y, scaleX, scaleY, p, ctx, len, i$, ref$, len$, child;
      x = this.x;
      y = this.y;
      scaleX = this.scaleX;
      scaleY = this.scaleY;
      p = this.parent;
      while (p) {
        x += p.x;
        y += p.y;
        scaleX *= p.scaleX;
        scaleY *= p.scaleY;
        p = p.parent;
      }
      (ctx = canvas.getContext('2d')).setTransform(scaleX, 0, 0, scaleY, x, y);
      this.beforeRender(ctx);
      len = this.length * this.time;
      for (i$ = 0, len$ = (ref$ = this.children).length; i$ < len$; ++i$) {
        child = ref$[i$];
        if (len > 0) {
          if (child.length === 0) {
            continue;
          }
          child.time = Math.min(child.length, len) / child.length;
          child.render(canvas);
          len -= child.length;
        }
      }
      this.doRender(ctx);
      return this.afterRender(ctx);
    };
    return Comp;
  }());
  Empty = (function(superclass){
    var prototype = extend$((import$(Empty, superclass).displayName = 'Empty', Empty), superclass).prototype, constructor = Empty;
    function Empty(data){
      this.data = data;
      Empty.superclass.call(this);
    }
    prototype.computeLength = function(){
      return this.length = this.data.speed * this.data.delay;
    };
    prototype.render = function(){};
    return Empty;
  }(Comp));
  Track = (function(superclass){
    var prototype = extend$((import$(Track, superclass).displayName = 'Track', Track), superclass).prototype, constructor = Track;
    function Track(data, options){
      var ref$;
      this.data = data;
      this.options = options != null
        ? options
        : {};
      Track.superclass.call(this);
      (ref$ = this.options).trackWidth || (ref$.trackWidth = 150);
      (ref$ = this.data).size || (ref$.size = this.options.trackWidth);
    }
    prototype.computeLength = function(){
      return this.length = Math.sqrt(this.data.vector.x * this.data.vector.x + this.data.vector.y * this.data.vector.y);
    };
    prototype.doRender = function(ctx){
      var x$;
      x$ = ctx;
      x$.beginPath();
      x$.strokeStyle = '#000';
      x$.fillStyle = '#000';
      x$.lineWidth = 2 * this.data.size;
      x$.lineCap = 'round';
      x$.moveTo(this.data.x, this.data.y);
      x$.lineTo(this.data.x + this.data.vector.x * this.time, this.data.y + this.data.vector.y * this.time);
      x$.stroke();
      return x$;
    };
    return Track;
  }(Comp));
  Stroke = (function(superclass){
    var prototype = extend$((import$(Stroke, superclass).displayName = 'Stroke', Stroke), superclass).prototype, constructor = Stroke;
    function Stroke(data){
      var children, i$, to$, i, prev, current, aabb, ref$, len$, path;
      children = [];
      for (i$ = 1, to$ = data.track.length; i$ < to$; ++i$) {
        i = i$;
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
      for (i$ = 0, len$ = (ref$ = this.outline).length; i$ < len$; ++i$) {
        path = ref$[i$];
        if (path.x !== undefined) {
          aabb.addPoint(path);
        }
        if (path.end !== undefined) {
          aabb.addPoint(path.begin);
          aabb.addPoint(path.end);
        }
        if (path.mid !== undefined) {
          aabb.addPoint(path.mid);
        }
      }
      Stroke.superclass.call(this, children, aabb);
    }
    prototype.pathOutline = function(ctx){
      var i$, ref$, len$, path, results$ = [];
      for (i$ = 0, len$ = (ref$ = this.outline).length; i$ < len$; ++i$) {
        path = ref$[i$];
        switch (path.type) {
        case 'M':
          results$.push(ctx.moveTo(path.x, path.y));
          break;
        case 'L':
          results$.push(ctx.lineTo(path.x, path.y));
          break;
        case 'C':
          results$.push(ctx.bezierCurveTo(path.begin.x, path.begin.y, path.mid.x, path.mid.y, path.end.x, path.end.y));
          break;
        case 'Q':
          results$.push(ctx.quadraticCurveTo(path.begin.x, path.begin.y, path.end.x, path.end.y));
        }
      }
      return results$;
    };
    prototype.hitTest = function(pt){
      if (this.aabb.containPoint(pt)) {
        return [this];
      } else {
        return [];
      }
    };
    prototype.beforeRender = function(ctx){
      var x$;
      x$ = ctx;
      x$.save();
      x$.beginPath();
      this.pathOutline(ctx);
      return ctx.clip();
    };
    prototype.afterRender = function(ctx){
      return ctx.restore();
    };
    return Stroke;
  }(Comp));
  Arrow = (function(superclass){
    var prototype = extend$((import$(Arrow, superclass).displayName = 'Arrow', Arrow), superclass).prototype, constructor = Arrow;
    function Arrow(stroke, index){
      var track, data, angle, x, y;
      this.stroke = stroke;
      this.index = index;
      Arrow.superclass.call(this);
      track = stroke.children[0];
      data = track.data;
      this.vector = {
        x: data.vector.x / track.length,
        y: data.vector.y / track.length
      };
      angle = Math.atan2(this.vector.y, this.vector.x);
      angle = Math.PI / 2 > angle && angle >= -Math.PI / 2
        ? angle - Math.PI / 2
        : angle + Math.PI / 2;
      this.up = {
        x: Math.cos(angle),
        y: Math.sin(angle)
      };
      x = data.size / 2 * this.vector.x;
      y = data.size / 2 * this.vector.y;
      x += data.size * 2 / 3 * this.up.x;
      y += data.size * 2 / 3 * this.up.y;
      this.arrow = {
        rear: {
          x: x - 64 * this.vector.x,
          y: y - 64 * this.vector.y
        },
        tip: {
          x: x + 128 * this.vector.x,
          y: y + 128 * this.vector.y
        },
        text: {
          x: x + 64 * this.up.x,
          y: y + 64 * this.up.y
        },
        head: {
          x: x + 64 * this.vector.x,
          y: y + 64 * this.vector.y
        },
        edge: {
          x: x + 64 * this.vector.x + 32 * this.up.x,
          y: y + 64 * this.vector.y + 32 * this.up.y
        }
      };
    }
    prototype.computeLength = function(){
      return this.length = this.stroke.length;
    };
    prototype.doRender = function(ctx){};
    return Arrow;
  }(Comp));
  x$ = (ref$ = window.zhStrokeData) != null
    ? ref$
    : window.zhStrokeData = {};
  x$.AABB = AABB;
  x$.Comp = Comp;
  x$.Empty = Empty;
  x$.Track = Track;
  x$.Stroke = Stroke;
  x$.Arrow = Arrow;
  function extend$(sub, sup){
    function fun(){} fun.prototype = (sub.superclass = sup).prototype;
    (sub.prototype = new fun).constructor = sub;
    if (typeof sup.extended == 'function') sup.extended(sub);
    return sub;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
