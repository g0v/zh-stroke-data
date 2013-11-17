loaders = require './loaders.ls'
loaders.XML    '../utf8/4e00.xml'  .then -> console.log JSON.stringify it
loaders.JSON   '../json/4e00.json' .then -> console.log JSON.stringify it
loaders.Binary '../bin/4e00.bin'   .fail -> console.log it
