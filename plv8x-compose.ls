#!/usr/bin/env plv8x -d chars -r
# This is run in plv8x context.
# This script composes '洗' and '金' into '鍌'.
# [ 457657.6806886383, 352634.7839090064, 430059.6740397433 ]
# [ 198.4428614657994, 284.9924591104733, 198.4428614657994 ]
x18644 = scale \幕 10 3 18 20 66 212
x18655 = scale \蕃 3 12 86 17 156 213
#x105108 = scale \嚮 0 12 21 8 219 106
#x105108 = scale \響 0 12 21 8 219 106

#SELECT id, ST_AREA(ST_difference(st_makevalid(outlines), (select g from ttf where g.ch = refs.ch)))
$ -> geo(x18644, x18655)

function whole-of (id)
  {whole} = plv8.execute("select * from refs where id = '#id';").0
  return whole
function ref (id)
  {whole, idx, len, x, y, w, h} = plv8.execute("select * from refs where id = '#id';").0
  return scale whole, idx, len, x, y, w, h
function ttf => "(SELECT g FROM ttf WHERE ch = '#it')"
/*
xi3 = scale('洗', 0, 9, 28, 11, 213, 119)
jin1 = scale('金', 0, 8, 22, 122, 216, 121) # 457657.6806886383
xian2 = scale('銜', 3, 8, 22, 122, 216, 121)
xian4 = scale('鏖', 11, 8, 22, 122, 216, 121)
xian3 = "(SELECT g FROM ttf WHERE ch = '鍌')"
$ -> sel(
  "st_area(ST_INTERSECTION(st_makevalid(ST_Collect(#xi3, #jin1)), #xian3)) / st_area(st_makevalid(ST_Collect(#xi3, #jin1))) * ST_HausdorffDistance(st_makevalid(ST_Collect(#xi3, #jin1)), #xian3)
  "
  "st_area(ST_INTERSECTION(st_makevalid(ST_Collect(#xi3, #xian2)), #xian3)) / st_area(st_makevalid(ST_Collect(#xi3, #xian2)))"
  "st_area(ST_INTERSECTION(st_makevalid(ST_Collect(#xi3, #xian4)), #xian3)) / st_area(st_makevalid(ST_Collect(#xi3, #xian4)))"
)

*/

/*
$ ->
  out = {}
  for {ch} in plv8.execute "select distinct ch from refs"
    cands = []
    for {part} in plv8.execute "select distinct part from refs where ch = '#ch'"
      comps = plv8.execute "select * from refs where ch = '#ch' and part = #part"
      ids = []
      for {id} in comps
        ids.push id
      cands.push ids
    out[ch] = cands
  return out

*/
function $ (cb)
  return try cb! catch e => e.toString!

function sel (...sql)
  if sql.length is 1
    return plv8.execute """select (#sql) _""" .0._
  return plv8.execute """select (ARRAY[#{ sql * ', '}]) _""" .0._

function txt (...sql)
  if sql.length is 1
    return plv8.execute """select st_astext(#sql) _""" .0._
  plv8.execute """select st_astext(st_collect(ARRAY[
    #{sql * ', '}
  ])) _""" .0._
function geo (...sql)
  if sql.length is 1
    return plv8.execute """select st_asgeojson(st_rotate(ST_FlipCoordinates(st_translate(st_scale(
      #sql
    , 0.001, 0.001), 21.2416976, 121.4509512)),pi()/2*3,121.4509512,24.4416976)) _""" .0._
  plv8.execute """select st_asgeojson(st_rotate(ST_FlipCoordinates(st_translate(st_scale(st_collect(ARRAY[
    #{sql * ', '}
  ]), 0.001, 0.001), 21.2416976, 121.4509512)),pi()/2*3,121.4509512,24.4416976)) _""" .0._

function scale (ch, idx, len, x, y, w, h)
  const S = 256
  const T = 2048
  field = \strokes
  field = \outlines
  slice = if Number(len) then "#field[#{idx+1}:#{idx+len}]" else "#field"
  mo = try plv8.execute """
    select st_asgeojson(box2d(
      st_collect(#slice)
    )) _ from strokes where ch = '#ch';
  """ .0._
  return null unless mo
  try {coordinates:[[[min-x,min-y],,[max-x,max-y],]]} = JSON.parse mo
  return null unless max-x
  w-new = w / S
  h-new = h / S
  w-old = (max-x - min-x) / T
  h-old = (max-y - min-y) / T
  w-ratio = w-new / w-old
  h-ratio = h-new / h-old
  x2048 = x / S*T
  y2048 = y / S*T
  x-ratio = - min-x * w-ratio + x2048
  y-ratio = - min-y * h-ratio + y2048
  return """(SELECT
    ST_Translate(
      ST_Scale(
          ST_COLLECT(#slice),
          #w-ratio, #h-ratio
      ),
          #x-ratio, #y-ratio
    )
    FROM strokes WHERE ch = '#ch'
  )"""
