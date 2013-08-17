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
        svg: !isCanvasSupported(),
        progress: null
      }, options);
      return this.each(function() {
        var promises;
        if (options.svg) {
          return window.WordStroker.raphael.strokeWords(this, words);
        } else {
          promises = window.WordStroker.canvas.drawElementWithWords(this, words, options);
          if (!options.single) {
            promises.forEach(function(p) {
              return p.then(function(word) {
                return word.drawBackground();
              });
            });
            return promises.reduceRight(function(next, current) {
              return function() {
                return current.then(function(word) {
                  return word.draw().then(next);
                });
              };
            }, null)();
          } else {
            return promises.reduceRight(function(next, current) {
              return function() {
                return current.then(function(word) {
                  word.drawBackground();
                  return word.draw().then(function() {
                    if (next) {
                      word.remove();
                      return next();
                    }
                  });
                });
              };
            }, null)();
          }
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