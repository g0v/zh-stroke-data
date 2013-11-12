<- $
OrigChars <- $.get '../../orig-chars.json'

shift-float = ->
  parseFloat @shift!

shape-from-outline = ->
  shape = new THREE.Shape
  path = new THREE.Path
  current = shape
  tokens = it.split ' '
  tokens.shift-float = shift-float
  while tokens.length
    switch tokens.shift!
      when \M
        current.moveTo tokens.shift-float!, tokens.shift-float!
      when \L
        while tokens.length > 1
          current.lineTo tokens.shift-float!, tokens.shift-float!
          if tokens.0 is \Z
            if current isnt shape
              shape.holes.push path
              path = new THREE.Path
            current = path
            break
  shape

# main
scale = 0.025
dim = 2150
cols = 20
start = 0
count = 240

scene = new THREE.Scene
camera = new THREE.OrthographicCamera do
  0, window.innerWidth / scale,
  0, -window.innerHeight / scale,
  1, 1000
camera.position.set 0 0 500
light = new THREE.DirectionalLight 0xffffff
light.position.set 0 0 1
scene.add light

renderer = new THREE.WebGLRenderer antialias: on
renderer.setSize window.innerWidth, window.innerHeight
$ \#container .append renderer.domElement

# render
render = ->
  requestAnimationFrame render
  renderer.render scene, camera
requestAnimationFrame render

failed = []
for let i from start til count
  c = OrigChars[i]
  data <- $.get "./a/#c.json"
  for j, outline of data?outlines
    x = ~~(i % cols)
    y = ~~(i / cols)
    # bad triangulation is not an error,
    # dont bother to catch it
    color = 0xffcc00
    line-color = 0xee6600
    # trap console.log
    log = console.log
    console.log = (...args) ->
      for str in args
        if str.match /triangulate/
          color := 0x330000
          line-color := 0xff0000
          failed.push do
            ch: data.ch
            outline: j
          break
      log.apply console, args
    geometry = new THREE.ShapeGeometry shape-from-outline outline
    console.log = log
    # restored
    offset = new THREE.Vector2 do
      +data.centroids[j].0
      -data.centroids[j].1
    m = new THREE.Matrix4
    m.makeTranslation -offset.x, -offset.y, 0
    geometry.applyMatrix m
    mesh = THREE.SceneUtils.createMultiMaterialObject do
      geometry
      * new THREE.MeshLambertMaterial color: color
        new THREE.MeshBasicMaterial color: line-color, wireframe: true, transparent: true
    mesh.position.set x * dim + offset.x, -y * dim + offset.y, 0
    scene.add mesh
  console.log failed if i is count - 1
