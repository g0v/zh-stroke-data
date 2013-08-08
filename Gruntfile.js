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
          "./utils.stroke-words.js": "./coffee/utils.stroke-words.coffee",
          /* web */
          "./draw.js": "./coffee/draw.coffee",
          "./draw.canvas.js": "./coffee/draw.canvas.coffee",
          "./jquery.stroke-words.js": "./coffee/jquery.stroke-words.coffee",
          /* node */
          "./stroke2json.js": "./coffee/stroke2json.coffee"
        }
      }
    }
  });

  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.registerTask("default", ["coffee"]);
};
