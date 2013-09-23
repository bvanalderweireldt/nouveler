module.exports = function(grunt) {

  // Configuration goes here
  grunt.initConfig({
      pkg: grunt.file.readJSON('package.json'),

    // Coffee to JS compilation
    coffee: {
      compile: {
        files: {
          'web/index.js' : 'web/index.coffee'
        }
      }
    },
    //Less Compilation 
    less: {
      production: {
        options: {
          paths: ["assets/css"],
          yuicompress: true
        },
        files: {
          "web/style.css": "web/style.less"
        }
      }
    },
    watch: {
      files: ['web/*.less', 'web/*.coffee'],
      tasks: ['coffee', 'less']
    } 
  });
  // Load plugins here
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-watch');
  // Define your tasks here
  grunt.registerTask('default', ['coffee', 'less', 'watch']);
};
