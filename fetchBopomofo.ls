#!/usr/bin/env lsc
request = require('superagent-promise')(require('superagent'), Promise)
fs = require \fs-promise
path = require \path
global <<< require 'prelude-ls'



bopomofoPrefix = "http://stroke-order.learningweb.moe.edu.tw/provideStrokeInfo.do?bpm="
bopomofoPostfix = "&useAlt=1"

codePointFromBig5 =
  "#{0xA374}": 0x3105
  "#{0xA375}": 0x3106
  "#{0xA376}": 0x3107
  "#{0xA377}": 0x3108
  "#{0xA378}": 0x3109
  "#{0xA379}": 0x310A
  "#{0xA37A}": 0x310B
  "#{0xA37B}": 0x310C
  "#{0xA37C}": 0x310D
  "#{0xA37D}": 0x310E
  "#{0xA37E}": 0x310F
  "#{0xA3A1}": 0x3110
  "#{0xA3A2}": 0x3111
  "#{0xA3A3}": 0x3112
  "#{0xA3A4}": 0x3113 # ㄓ
  "#{0xA3A5}": 0x3114
  "#{0xA3A6}": 0x3115
  "#{0xA3A7}": 0x3116 # ㄖ
  "#{0xA3A8}": 0x3117
  "#{0xA3A9}": 0x3118
  "#{0xA3AA}": 0x3119
  "#{0xA3AB}": 0x311A
  "#{0xA3AC}": 0x311B
  "#{0xA3AD}": 0x311C
  "#{0xA3AE}": 0x311D
  "#{0xA3AF}": 0x311E
  "#{0xA3B0}": 0x311F
  "#{0xA3B1}": 0x3120
  "#{0xA3B2}": 0x3121
  "#{0xA3B3}": 0x3122
  "#{0xA3B4}": 0x3123
  "#{0xA3B5}": 0x3124
  "#{0xA3B6}": 0x3125
  "#{0xA3B7}": 0x3126
  "#{0xA3B8}": 0x3127
  "#{0xA3B9}": 0x3128
  "#{0xA3BA}": 0x3129

bopomofos = keys codePointFromBig5 |> map (str) -> +str

write = (filename) -> (content) ->
  console.log "write #filename"
  fs.writeFile filename, content

read = (big5, alt = false) ->
  if 0xA374 <= big5 < 0xA3A1
    then uri = "#bopomofoPrefix#{big5 - 0xA374 + 1}"
    else uri = "#bopomofoPrefix#{big5 - 0xA3A1 + 12}"
  uri = "#uri#{if alt then bopomofoPostfix else ''}"
  console.log "fetch #{big5.toString(16)} from #uri"
  request
    .get uri
    .then (res) -> res.text

delay = (ms) -> (o) -> new Promise (resolve) -> setTimeout (-> resolve o), ms

readAndWrite = (big5) ->
  p = read big5
  p.then write path.resolve(__dirname, \data, "#{big5.toString(16)}.xml")
  p.then write path.resolve(__dirname, \utf8, "#{codePointFromBig5[big5].toString(16)}.xml")
  if (big5 is 0xA3A4) or (big5 is 0xA3A7) then
    p = p.then delay(1000) .then -> read big5, true
    p.then write path.resolve(__dirname, \data, "#{big5.toString(16)}_alt.xml")
    p.then write path.resolve(__dirname, \utf8, "#{codePointFromBig5[big5].toString(16)}_alt.xml")
  p

go = fold do
  (p, big5) -> p.then (-> readAndWrite big5) .then delay(1000)
  Promise.resolve!

go bopomofos .then -> console.log 'done!'

