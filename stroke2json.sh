for f in `find ./utf8/ -type f | sort`; do
  echo parsing $f
  node ./stroke2json.js $f > ./json/${f:7:4}.json || break
done
