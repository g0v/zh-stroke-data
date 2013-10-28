require! fs
CSV = require \csv
xs <- CSV!from(fs.read-file-sync(\tiebreak-results.csv \utf8), delimiter: \,).to.array
labels = xs.shift!
labels.shift!
ys = {}
for row in xs
  ch = row.shift!
  y = {}
  for l, i in labels
    y[l] = row[i]
  ys[][ch].push y
console.log JSON.stringify ys,,2
