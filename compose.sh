for f in `find ./missing/ -type f | sort`; do
  echo composing $f
  node ./compose.js $f > ./json/${f:10:${#f}-10} || break
done
