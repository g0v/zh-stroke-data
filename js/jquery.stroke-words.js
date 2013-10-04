(function() {
  var $, isCanvasSupported;

  isCanvasSupported = function() {
    var _ref;
    return (_ref = document.createElement("canvas")) != null ? _ref.getContext("2d") : void 0;
  };

  $ = jQuery;

  $.fn.extend({
    strokeWords: function(words, options) {
      if (words === void 0 || words === "") {
        return null;
      }
      options = $.extend({
        single: false,
        pool_size: 4,
        svg: !isCanvasSupported(),
        progress: null
      }, options);
      return this.each(function() {
        var index, load, loaded, loaders;
        if (options.svg) {
          return window.WordStroker.raphael.strokeWords(this, words);
        } else {
          loaders = window.WordStroker.canvas.drawElementWithWords(this, words, options);
          index = 0;
          loaded = 0;
          (load = function() {
            var _results;
            _results = [];
            while (index < loaders.length && loaded < options.pool_size) {
              ++loaded;
              _results.push(loaders[index++].load().progress(options.progress).then(function(word) {
                return word.drawBackground();
              }));
            }
            return _results;
          })();
          return loaders.reduceRight(function(next, current) {
            return function() {
              return current.promise.then(function(word) {
                return word.draw().then(function() {
                  --loaded;
                  load();
                  if (options.single) {
                    word.remove();
                  }
                  return typeof next === "function" ? next() : void 0;
                });
              });
            };
          }, null)();
        }
      }).data("strokeWords", {
        play: null
      });
    }
  });

}).call(this);

/*
//@ sourceMappingURL=jquery.stroke-words.js.map
*/