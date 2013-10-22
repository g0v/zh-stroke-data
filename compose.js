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
      var cp, data;
      cp = WordStroker.utils.sortSurrogates(source.val);
      data = WordStroker.utils.StrokeData();
      return data.get(cp[0].cp, function(json) {
        var part;
        part = WordStroker.utils.StrokeData.transform(json, source.matrix);
        if (source.indices) {
          result = result.concat(source.indices.map(function(val) {
            return part[val];
          }));
        } else {
          result = result.concat(part);
        }
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
