module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON("package.json"),
    coffee: {
      compile: {
        options: {
          sourceMap: true
        },
        files: {
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
