module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON("package.json"),
    coffee: {
      compile: {
        options: {
          sourceMap: true
        },
        files: {
          /* both */
          "./js/utils.stroke-words.js": "./coffee/utils.stroke-words.coffee",
          /* web */
          "./js/draw.js": "./coffee/draw.coffee",
          "./js/draw.canvas.js": "./coffee/draw.canvas.coffee",
          "./js/jquery.stroke-words.js": "./coffee/jquery.stroke-words.coffee",
          /* node */
          "./stroke2json.js": "./coffee/stroke2json.coffee",
          "./compose.js": "./coffee/compose.coffee"
        }
      }
    }
  });

  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.registerTask("default", ["coffee"]);
};
