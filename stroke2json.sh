for f in `find ./utf8/ -type f`; do
  node ./stroke2json.js $f > ./json/${f:7:4}.json
done
