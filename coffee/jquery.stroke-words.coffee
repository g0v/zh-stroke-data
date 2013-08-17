isCanvasSupported = () ->
  document.createElement("canvas")?.getContext("2d")

$ = jQuery

$.fn.extend
  strokeWords: (words, options) ->
    return null if words is undefined or words is ""

    options = $.extend(
      single: false
      svg: !isCanvasSupported()
      progress: null
    , options)

    @each(() ->
      if options.svg
        window.WordStroker.raphael.strokeWords this, words
      else
        promises = window.WordStroker.canvas.drawElementWithWords(this, words, options)
        ##
        # do the same as following lines with reduce
        ##
        # i = 0
        # next = ->
        #   if i < promises.length
        #     promises[i++].then (word) -> word.draw().then next
        # next()
        ##
        if not options.single
          promises.forEach (p) ->
            p.then (word) ->
              word.drawBackground()
          do promises.reduceRight (next, current) ->
            -> current.then (word) ->
              word.draw().then next
          , null
        else
          do promises.reduceRight (next, current) ->
            -> current.then (word) ->
              do word.drawBackground
              word.draw().then ->
                if next
                  do word.remove
                  do next
          , null
    ).data("strokeWords",
      play: null
    )
