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
        promises = window.WordStroker.canvas.createWordsAndViews(this, words)
        promises.forEach (p) ->
          p.then (word) ->
            word.drawBackground()
        i = 0
        next = ->
          promises[i].then (word) ->
            word.draw().then next if i < promises.length
            i += 1
        next()
    ).data("strokeWords",
      play: null
    )
