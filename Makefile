COMPOSE = node ./compose.js
DIR_MISSING = ./missing
DIR_COMPOSED = ./json
DIR_STROKER = ./ls
STROKES_MISSING = $(wildcard $(DIR_MISSING)/*.json)
STROKES_COMPOSED = $(STROKES_MISSING:$(DIR_MISSING)/%=$(DIR_COMPOSED)/%)

$(DIR_COMPOSED)/%.json : $(DIR_MISSING)/%.json
	-$(COMPOSE) ./$< > ./$@

.js.ls :
	lsc -c $<

serve ::
	node ./static-here.js 8888 | $(MAKE) -C $(DIR_STROKER)

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

.SUFFIXES: .js .ls

components :: polyfill.js tiebreak-ad-hoc.js
	lsc ./components.ls > ./components.json

computed-missing :: components.json
	lsc ./computed-missing.ls > ./computed-missing.json

# tiebreak ::
## total-strokes/total-strokes.ls
## components.ls
## computed-missing.ls

tiebreak-pre1 ::
	createdb chars
## bzcat ../ttf2gis/Kai.ttf.sql.bz2 | psql chars
	perl orig-chars.pl | psql chars
	lsc gen-refs.ls | psql chars
	psql chars -f boxes.sql

tiebreak-pre2 ::
	perl plv8x-outlines.ls
	cd out && ls *.ls | xargs -P 8 -n 1 -- perl runner.pl && cd ..
	cd out && ls *.sql | xargs -P 8 -n 1 -- psql chars -f && cd ..

tiebreak-pre3 ::
	psql chars -f diff.sql
	cd sql-diff && ls *.sql | xargs -P 8 -n 1 -- psql chars -f && cd ..
	psql chars -f distance.sql
	psql chars -P t -f combinations.sql | perl -pe 's/^ /"/; s/ . /":/; if ($. == 1) { s/^/{/ } else {s/^"/,"/ }; s/^$/}/' > combinations.json

tiebreak ::
	lsc tiebreak.ls | psql chars
	psql chars -c "\copy (select ch,part,comp,whole,idx,len,x,y,w,h from subsets order by id) to 'tiebreak-results.csv' with csv header"

scale :: polyfill.js tiebreak-ad-hoc.js
	lsc tiebreak-results.ls > tiebreak-results.json
	lsc scale-missing.ls

