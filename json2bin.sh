for f in `find ./json/ -type f | sort`; do
  echo converting $f
  node ./json2bin.js $f > ./raw/${f:6:${#f}-11} || break
done
