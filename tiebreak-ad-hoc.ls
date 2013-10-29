rules =
  * test:
      comp:  (is \肉)
      whole: (isnt \瘸)
    out:
      len: -> \4
  * test:
      comp: (is \阝)
    out:
      len: -> \3
  * test:
      whole: (in <[ 迴 遐 ]>)
    out:
      idx: -> \0
  * test:
      whole: (in <[ 育 ]>)
    out:
      idx: -> \3

AdHocFilter = (part) ->
  out = part{part, comp, whole, idx, len, x, y, w, h}
  for rule in rules
    result = true
    for k, test of rule.test => result and= test part[k]
    if result
      for k, change of rule.out => out[k] = change part[k]
  out

@.TiebreakAdHoc = AdHocFilter
module?exports = AdHocFilter
