const CharComp = require \./char_comp.json

all = require \./combinations.json
console.log "CREATE TABLE tops (ch text, part int, ref_id int);";
console.log "CREATE INDEX ch_tops ON tops (ch);"
for ch, cs of all
  comp = CharComp[ch]
  continue if cs.length != comp.length
  for ids, idx in cs
    if ids.length is 1
      console.log "INSERT INTO tops VALUES ('#ch', #idx, #{ids.0});"
    else
      console.log "INSERT INTO tops VALUES ('#ch', #idx, (SELECT id FROM diffs IN (#{ ids * ',' }) ORDER BY diff ASC LIMIT 1));"

console.log """
CREATE TABLE subsets (id int, ch text, part int, comp text, whole text, idx int, len int, x int, y int, w int, h int);
CREATE INDEX subsets_id on refs VALUES (id);
CREATE INDEX subsets_ch on refs VALUES (ch);
INSERT INTO subsets (SELECT id, ch, part, comp, whole, idx, len, x, y, w, h FROM refs WHERE id IN (SELECT id FROM tops order by id));
"""

