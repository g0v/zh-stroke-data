(function() {
  var WordStroker;

  WordStroker = require("./js/utils.stroke-words");

  process.argv.forEach(function(path, index) {
    if (index === 0 || index === 1) {
      return;
    }
    return WordStroker.utils.fetchStrokeJSONFromXml(path, function(json) {
      return console.log(JSON.stringify(json, null, "  "));
    }, function() {
      return console.log({
        msg: "failed to parse xml",
        path: path
      });
    });
  });

}).call(this);

/*
//@ sourceMappingURL=stroke2json.js.map
*/