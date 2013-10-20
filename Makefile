main ::
	cat ./js/utils.stroke-words.js ./js/draw.js ./js/draw.canvas.js ./js/jquery.stroke-words.js > /Users/audreyt/w/moedict-webkit/js/jquery.strokeWords.js

comp ::
	wget -c https://raw.github.com/miaout17/moedict-component-testbed/master/single.fnt/char_comp.json
	lsc scale-missing.ls
	sh compose.sh
try ::
	lsc scale-missing.ls
	node compose.js ./missing/6607.json > json/6607.json
