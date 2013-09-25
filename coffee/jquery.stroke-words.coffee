isCanvasSupported = () ->
  document.createElement("canvas")?.getContext("2d")

$ = jQuery

$.fn.extend
  strokeWords: (words, options) ->
    return null if words is undefined or words is ""

    options = $.extend(
      single: false
      sequential: false
      svg: !isCanvasSupported()
      progress: null
    , options)

    @each(() ->
      if options.svg
        window.WordStroker.raphael.strokeWords this, words
      else
        loaders = window.WordStroker.canvas.drawElementWithWords(this, words, options)
        if not options.sequential
          promises = loaders.map (loader) ->
            loader.load().progress(options.progress)
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
              p.then (word) -> word.drawBackground()
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
        else
          do loaders.reduceRight (next, current) ->
            -> current.load().progress(options.progress).then (word) ->
              word.drawBackground()
              word.draw().then next
          , null
    ).data("strokeWords",
      play: null
    )
