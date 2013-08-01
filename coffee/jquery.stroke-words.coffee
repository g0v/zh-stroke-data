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
        promises = window.WordStroker.canvas.createWordsAndViews(this, words, options)
        promises.forEach (p) ->
          p.then (word) ->
            word.drawBackground()
        ##
        # do the same as following lines with reduce
        ##
        # i = 0
        # next = ->
        #   if i < promises.length
        #     promises[i++].then (word) -> word.draw().then next
        # next()
        ##
        do promises.reduceRight (next, current) ->
          -> current.then (word) ->
            word.draw().then next
        , null
    ).data("strokeWords",
      play: null
    )
