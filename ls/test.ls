#!/usr/bin/env lsc
require! fs
data = require './data'

stringify = -> JSON.stringify it, null, 2

do
  err, file <- fs.readFile '../utf8/4e00.xml', encoding: \utf8
  err, data <- data.fromXML file
  console.log stringify data
do
  err, file <- fs.readFile '../json/4e00.json', encoding: \utf8
  console.log stringify JSON.parse file
do
  err, bin <- fs.readFile '../bin/00.bin'
  err, data <- data.fromBinary bin
  console.log Object.keys(data)length
do
  err, txt <- fs.readFile '../examples/canvas-sprite/4e11.txt', encoding: \utf8
  err, data <- data.fromScanline txt
  for stroke in data
    console.log stroke.length

require! punycode
chars = punycode.ucs2.decode "敢有聽著󿌇唱歌"
console.log chars.map (.toString 16)

