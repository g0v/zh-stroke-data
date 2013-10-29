rules =
  * test: comp:  (is \艹)
    out: len: -> \4
  * test:
      comp:  (is \肉)
      whole: (isnt \瘸)
    out: len: -> \4
  * test:
      comp:  (is \肉)
      w:   -> it < @.h / 2
    out: len: -> \4
  * test: comp:  (is \阝)
    out: len: -> \3
  * test: whole: (in \迴遐)
    out: idx: -> \0
  * test: whole: (in \育)
    out: idx: -> \3
  * test: comp:  (is \)
    out: len: -> \3
  * test: comp: (is \雚)
    out: len: -> \18

AdHocFilter = (part) ->
  out = part{part, comp, whole, idx, len, x, y, w, h}
  for rule in rules
    result = true
    for k, test of rule.test => result and= test.call part, part[k]
    if result
      for k, change of rule.out => out[k] = change part[k]
  out

@.TiebreakAdHoc = AdHocFilter
module?exports = AdHocFilter
