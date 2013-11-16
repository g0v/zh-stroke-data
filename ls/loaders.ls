root = this

Q   = root.Q   or require \q
sax = root.sax or require \sax

# http://jsperf.com/alternative-isfunction-implementations/15
# Pure duck-typing implementation taken from Underscore.js.
is-function = ->
  it and it.constructor and it.call and it.apply

is-deferred = ->
  it and it.resolve and it.reject and it.promise

get = (path, data-type, d) ->
  d = Q.defer! if not is-deferred d
  if root.window # web
    $.ajax do
      type:      \GET
      url:       path
      data-type: data-type
      progress:  !-> d.notify  it
    .done        !-> d.resolve it
    .fail        !-> d.reject  it
  else # node
    require! fs
    err, data <- fs.read-file path, encoding: \utf8
    if err then d.reject err else d.resolve data
  d.promise

# web only, for now
get-binary = (path, d) ->
  d = Q.defer! if not is-deferred d
  d.promise

callbackify = (loader) ->
  (path, success, fail, progress) ->
    d = if is-deferred success then success else Q.defer!
    p = d.promise
    p.then     success  if is-function success
    p.fail     fail     if is-function fail
    p.progress progress if is-function progress
    loader path, d
    d.promise

XMLLoader = (path, d) !->
  p = get path, \text
  p.fail(-> d.reject it).progress(-> d.notify it)
  doc <- p.then
  ret      = []
  outlines = []
  tracks   = []
  var outline, track
  # thank you for this package! @isaacs
  strict = true
  parser = sax.parser strict
  parser.onopentag = (node) ->
    # parse path of the outline
    if outline
      switch node.name
        when \MoveTo
          outline.push do
            type: \M
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
        when \LineTo
          outline.push do
            type: \L
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
        when \CubicTo
          outline.push do
            type: \C
            begin:
              x: parseFloat node.attributes.x1
              y: parseFloat node.attributes.y1
            mid:
              x: parseFloat node.attributes.x2
              y: parseFloat node.attributes.y2
            end:
              x: parseFloat node.attributes.x3
              y: parseFloat node.attributes.y3
        when \QuadTo
          outline.push do
            type: \Q
            begin:
              x: parseFloat node.attributes.x1
              y: parseFloat node.attributes.y1
            end:
              x: parseFloat node.attributes.x2
              y: parseFloat node.attributes.y2
    # parse path of the track
    else if track
      switch node.name
        when \MoveTo
          track.push do
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
            size: if node.attributes.size then parseFloat(node.attributes.size) else null
    # not in any outline or track
    else
      if node.name is \Outline
        outline := []
      if node.name is \Track
        track := []
  # end of parser.onopentag
  parser.onclosetag = (name) ->
    if name is \Outline
      outlines.push outline
      outline := null
    if name is \Track
      tracks.push track
      track := null
  parser.onend = ->
    for i, outline of outlines
      track = tracks[i]
      ret.push do
        outline: outline
        track: track
    d.resolve ret
  parser.onerror = (err) ->
    d.reject err
  parser.write(doc).close!

JSONLoader = (path, d) !->

BinaryLoader = (path, d) !->

module.exports =
  XML:    callbackify XMLLoader
  JSON:   callbackify JSONLoader
  Binary: callbackify BinaryLoader
