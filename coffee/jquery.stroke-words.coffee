isCanvasSupported = () ->
  document.createElement("canvas")?.getContext("2d")

$ = jQuery

$.fn.extend
  strokeWords: (words, options) ->
    return null if words is undefined or words is ""

    options = $.extend(
      svg: !isCanvasSupported()
    , options)

    this.each(() ->
      if options.svg
        window.WordStroker.raphael.strokeWords this, words
      else
        strokers = window.WordStroker.canvas.createWordsAndViews(this, words)
        strokers.forEach (stroker) ->
          stroker.drawBackground()
        i = 0
        next = ->
          strokers[i++].draw().then next if i < strokers.length
        next()
    ).data("strokeWords",
      play: null
    )
