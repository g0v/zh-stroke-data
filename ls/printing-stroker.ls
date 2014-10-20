class PrintingStroker
  @loaders = zh-stroke-data.loaders{
    xml:XML, json:JSON, bin:Binary, txt: Scanline
  }
  (str, options) ->
    options = $.extend do
      autoplay: off
      width: 86
      height: 86
      preload: 4chars
      poster: ''
      url: './json/'
      dataType: \json
      options
    @autoplay    = options.autoplay
    @preload     = options.preload
    @width       = options.width
    @height      = options.height
    @poster      = options.poster
    @url         = options.url
    @dataType    = options.dataType
    @dom-element = document.createElement \canvas
    @dom-element.width  = @width
    @dom-element.height = @height

    promises = for ch in str.sortSurrogates!
      @@loaders[@dataType] "#{@url}#{ch.codePointAt!toString 16}.#{@dataType}"
    Q.all(promises).then ~>
      max = 0
      chars = for i, char-data of it
        strokes = for j, data of char-data
          stroke = if @dataType is 'txt'
            new zh-stroke-data.ScanlineStroke data
              ..scale-x = @width  / 2048
              ..scale-y = @height / 2048
          else
            new zh-stroke-data.Stroke data
              ..scale-x = @width  / 2150
              ..scale-y = @height / 2150
        if strokes.length > max then max = strokes.length
        strokes
      @dom-element.width  = @width  * max
      @dom-element.height = @height * chars.length
      for i, c of chars
        i = +i
        for j of c
          j = +j
          for k from 0 to j
            c[+k]
              ..time = 1
              ..x = @width  * j
              ..y = @height * i
              ..render @dom-element.getContext \2d

(window.zh-stroke-data ?= {})
  ..PrintingStroker = PrintingStroker
