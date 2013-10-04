isCanvasSupported = () ->
  document.createElement("canvas")?.getContext("2d")

$ = jQuery

$.fn.extend
  strokeWords: (words, options) ->
    return null if words is undefined or words is ""

    options = $.extend(
      single: false
      pool_size: 4
      svg: !isCanvasSupported()
      progress: null
    , options)

    @each(() ->
      if options.svg
        window.WordStroker.raphael.strokeWords this, words
      else
        loaders = window.WordStroker.canvas.drawElementWithWords(this, words, options)
        index = 0
        loaded = 0
        do load = ->
          while index < loaders.length and loaded < options.pool_size
            ++loaded
            loaders[index++].load()
              .progress(options.progress)
              .then (word) ->
                word.drawBackground()
        do loaders.reduceRight (next, current) ->
          -> current.promise.then (word) ->
            word.draw().then ->
              --loaded
              load()
              word.remove() if options.single
              next?()
        , null
    ).data("strokeWords",
      play: null
    )
