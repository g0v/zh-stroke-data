(function() {
  var WordStroker;

  WordStroker = require("./js/utils.stroke-words");

  process.argv.forEach(function(path, index) {
    var result, rule;
    if (index === 0 || index === 1) {
      return;
    }
    result = [];
    rule = require(path);
    return rule.strokes.forEach(function(source, i) {
      var cp;
      cp = WordStroker.utils.sortSurrogates(source.val);
      return WordStroker.utils.StrokeData.get(cp[0], function(json) {
        result = result.concat(source.indices.map(function(val) {
          return json[val];
        }));
        if (i === rule.strokes.length - 1) {
          return console.log(JSON.stringify(result, null, "  "));
        }
      }, function() {
        return console.log({
          msg: "failed to compose character",
          path: path
        });
      });
    });
  });

}).call(this);

/*
//@ sourceMappingURL=compose.js.map
*/