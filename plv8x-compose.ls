#!/usr/bin/env plv8x -d chars -r
# This is run in plv8x context.
# This script composes '洗' and '金' into '鍌'.
# INSERT INTO refs VALUES  ('鍌', '洗', '洗', 0, 9, 213, 119);
$ -> geo(
  scale('洗', 0, 9, 28, 11, 213, 119)
  scale('金', 0, 8, 22, 122, 216, 121)
  scale('銜', 3, 8, 22, 122, 216, 121)
  scale('鏖', 11, 8, 22, 122, 216, 121)
);

function $ (cb)
  return try cb! catch e => e.toString!

function geo (...sql)
  plv8.execute """select st_asgeojson(st_rotate(ST_FlipCoordinates(st_translate(st_scale(st_collect(ARRAY[
    #{sql * ', '}
  ]), 0.001, 0.001), 21.2416976, 121.4509512)),pi()/2*3,121.4509512,24.4416976)) _""" .0._

function scale (ch, idx, len, x, y, w, h)
  const S = 256
  const T = 2048
  mo = plv8.execute """
    select st_asgeojson(box2d(
      st_collect(outlines[#{idx+1}:#{idx+len}])
    )) _ from strokes where ch = '#ch';
  """ .0._
  {coordinates:[[[min-x,min-y],,[max-x,max-y],]]} = JSON.parse mo
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
          ST_COLLECT(outlines[#{idx+1}:#{idx+len}]),
          #w-ratio, #h-ratio
      ),
          #x-ratio, #y-ratio
    )
    FROM strokes WHERE ch = '#ch'
  )"""
