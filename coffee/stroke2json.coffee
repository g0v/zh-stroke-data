# this code runs in node
WordStroker = require "./utils.stroke-words"

path = "utf8/767c.xml" # 發

console.log "parsing " + path

WordStroker.utils.fetchStrokeJSONFromXml(
  path,
  (json) ->
    console.log json
  , () ->
    console.log "failed"
)
