loaders = require './loaders.ls'
loaders.XML    '../utf8/4e00.xml'  .then -> console.log JSON.stringify it
loaders.JSON   '../json/4e00.json' .then -> console.log JSON.stringify it
loaders.Binary '../bin/4e00.bin'   .fail -> console.log it

require './string.ls'
chars = "敢有聽著󿌇唱歌".sortSurrogates!
console.log chars.join ''
console.log chars.map (.codePointAt!toString 16)

