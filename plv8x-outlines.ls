#!/usr/bin/env plv8x -d chars -r
# This is run in plv8x context.
function ref (id)
  {whole, idx, len, x, y, w, h} = plv8.execute("select * from refs where id = '#id';").0
  return scale whole, idx, len, x, y, w, h

$ ->
  results = 0
  for {id} in plv8.execute "select id from refs order by id"
    plv8.execute "UPDATE refs SET outlines = #{ ref id } WHERE id = #id AND outlines IS NULL"
    results++
  return results

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
