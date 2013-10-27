COMPOSE = node ./compose.js
DIR_MISSING = ./missing
DIR_COMPOSED = ./json
STROKES_MISSING = $(wildcard $(DIR_MISSING)/*.json)
STROKES_COMPOSED = $(STROKES_MISSING:$(DIR_MISSING)/%=$(DIR_COMPOSED)/%)

$(DIR_COMPOSED)/%.json : $(DIR_MISSING)/%.json
	-$(COMPOSE) ./$< > ./$@

main ::
	cat ./js/utils.stroke-words.js ./js/draw.js ./js/draw.canvas.js ./js/jquery.stroke-words.js > /Users/audreyt/w/moedict-webkit/js/jquery.strokeWords.js

comp ::
	wget -c https://raw.github.com/miaout17/moedict-component-testbed/master/single.fnt/char_comp.json
	lsc scale-missing.ls

try ::
	lsc scale-missing.ls

old :: $(STROKES_COMPOSED)

clean ::
	rm -f $(STROKES_COMPOSED)

components ::
	lsc ./components.ls > ./components.json

computed-missing ::
	lsc ./computed-missing.ls > ./computed-missing.json


# tiebreak ::
## total-strokes/total-strokes.pl
## components.ls
## computed-missing.ls
## gen-refs.ls
## boxes.sql
## plv8x-outlines.ls
## sql-diff/*
## tiebreak.ls
## scale-missing.ls
