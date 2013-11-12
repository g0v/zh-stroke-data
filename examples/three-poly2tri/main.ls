<- $
OrigChars <- $.get '../../orig-chars.json'
console.log OrigChars

shift-float = ->
  parseFloat @shift!

shapes-from-outline = ->
  for stroke in it
    shape = new THREE.Shape
    path = new THREE.Path
    current = shape
    tokens = stroke.split ' '
    while tokens.length
      switch tokens.shift!
        when \M
          current.moveTo shift-float.call(tokens), shift-float.call(tokens)
        when \L
          while tokens.length > 1
            current.lineTo shift-float.call(tokens), shift-float.call(tokens)
            if tokens.0 is \Z
              if current isnt shape
                shape.holes.push path
                path = new THREE.Path
              current = path
              break
    shape
