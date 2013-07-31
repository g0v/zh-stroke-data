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
        window.WordStroker.canvas.
          createWordsAndViews(this, words).
          forEach (word) ->
            word.draw()
    ).data("strokeWords",
      play: null
    )
