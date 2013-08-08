module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON("package.json"),
    coffee: {
      compile: {
        options: {
          sourceMap: true
        },
        files: {
          "./utils.stroke-words.js": "./coffee/utils.stroke-words.coffee",
          "./draw.js": "./coffee/draw.coffee",
          "./draw.canvas.js": "./coffee/draw.canvas.coffee",
          "./jquery.stroke-words.js": "./coffee/jquery.stroke-words.coffee"
        }
      }
    }
  });

  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.registerTask("default", ["coffee"]);
};
