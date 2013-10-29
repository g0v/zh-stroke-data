const CharComp = require \./char_comp.json

all = require \./combinations.json
console.log "CREATE TABLE tops (ch text, part int, ref_id int);";
console.log "CREATE INDEX ch_tops ON tops (ch);"
console.log "DELETE FROM tops;";

const ForceFirstChoice = "弋冖亠至周斤夾"
const ForceFirstChoiceChar = "胾"
const BlackListWhole = <[ '嬴' '盥' '迅' '進' '衢' '亟' '喬' '粵' '暹' ]>

for ch, cs of all
  comp = CharComp[ch]
  continue if cs.length != comp.length
  for ids, idx in cs
    if ids.length is 1 or comp[idx].c in ForceFirstChoice or ch in ForceFirstChoiceChar
      console.log "INSERT INTO tops VALUES ('#ch', #idx, #{ids.0});"
    else
      console.log "INSERT INTO tops VALUES ('#ch', #idx, (SELECT distances.id FROM distances LEFT JOIN diffs ON diffs.id = distances.id LEFT JOIN refs on refs.id = distances.id WHERE refs.whole NOT IN (#{ BlackListWhole * ',' }) AND refs.id IN (#{ ids * ',' }) ORDER BY diffs.diff * distance ASC LIMIT 1));"

console.log """
CREATE TABLE subsets (id int, ch text, part int, comp text, whole text, idx int, len int, x int, y int, w int, h int);
CREATE INDEX subsets_id on refs (id);
CREATE INDEX subsets_ch on refs (ch);
DELETE FROM subsets;
INSERT INTO subsets (SELECT id, ch, part, comp, whole, idx, len, x, y, w, h FROM refs WHERE id IN (SELECT ref_id FROM tops order by ref_id));
"""

