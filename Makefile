COMPOSE = node ./compose.js
DIR_MISSING = ./missing
DIR_COMPOSED = ./json
STROKES_MISSING = $(wildcard $(DIR_MISSING)/*.json)
STROKES_COMPOSED = $(STROKES_MISSING:$(DIR_MISSING)/%=$(DIR_COMPOSED)/%)

$(DIR_COMPOSED)/%.json : $(DIR_MISSING)/%.json
	-$(COMPOSE) ./$< > ./$@

.js.ls :
	lsc -c $<

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

components :: polyfill.js tiebreak-ad-hoc.js
	lsc ./components.ls > ./components.json

computed-missing ::
	lsc ./computed-missing.ls > ./computed-missing.json

scale :: polyfill.js tiebreak-ad-hoc.js
	lsc tiebreak-results.ls > tiebreak-results.json
	lsc scale-missing.ls

# tiebreak ::
## total-strokes/total-strokes.pl
## components.ls
## computed-missing.ls
## perl orig-chars.pl | psql chars
## lsc gen-refs.ls | psql chars
## psql chars -f boxes.sql
## perl plv8x-outlines.ls
## cd out && ls *.ls | xargs -P 8 -n 1 -- perl runner.pl && cd ..
## cd out && ls *.sql | xargs -P 8 -n 1 -- psql chars -f && cd ..
## bzcat ../ttf2gis/Kai.ttf.sql.bz2 | psql chars
## psql chars -f diff.sql
## cd sql-diff && ls *.sql | xargs -P 8 -n 1 -- psql chars -f && cd ..
## psql chars -f combinations.sql > combinations.json
## lsc tiebreak.ls
## lsc tiebreak-results.ls > tiebreak-results.json
## lsc scale-missing.ls
