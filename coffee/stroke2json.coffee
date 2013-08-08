# this code runs in node
WordStroker = require "./utils.stroke-words"

process.argv.forEach (path, index) ->
  return if index is 0 or index is 1
  WordStroker.utils.fetchStrokeJSONFromXml(
    path,
    (json) ->
      console.log JSON.stringify json, null, "  "
    , () ->
      console.log
        msg: "failed to parse xml"
        path: path
  )
