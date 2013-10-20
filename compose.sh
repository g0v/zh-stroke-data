for f in `find ./missing/ -type f | grep json$ | sort`; do
  echo composing $f
  node ./compose.js $f > ./json/${f:10:${#f}-10} || true
done
