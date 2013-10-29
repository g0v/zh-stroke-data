# TODO: pack composited strokes
for f in `find ./json/ -type f | cut -c 8- | awk '{ print substr( $0, length($0) - 6, 2 ) }' | sort -u`; do
  echo packinging $f
  node ./pack.js $f > ./bin/${f}.bin || break
done
