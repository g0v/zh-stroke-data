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
scale = 0.1
dim = 2150
cols = 64
boxes = []

scene = new THREE.Scene
box = new THREE.Box3 do
  new THREE.Vector3 0, -window.innerHeight / scale, -50
  new THREE.Vector3 window.innerWidth / scale, 0, 50
camera = new THREE.OrthographicCamera do
  box.min.x, box.max.x,
  box.max.y, box.min.y,
  1, 1000
camera.position.set 0 0 500
updateCamera = ->
  camera.left   = box.min.x
  camera.right  = box.max.x
  camera.bottom = box.min.y
  camera.top    = box.max.y
  camera.updateProjectionMatrix!
light = new THREE.DirectionalLight 0xffffff
light.position.set 0 0 1
scene.add light

renderer = new THREE.WebGLRenderer antialias: on
renderer.setSize window.innerWidth, window.innerHeight
$ \#container .append renderer.domElement

# render
render = ->
  for o in boxes
    if o.load and box.containsPoint o.position
      #console.log o.position
      o.load!
  requestAnimationFrame render
  renderer.render scene, camera
requestAnimationFrame render

load = !->
  @load = null
  data <~ $.get "./a/#{@ch}.json"
  for j, outline of data?outlines
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
          break
      log.call console, data.ch, j
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
    mesh.position.set offset.x, offset.y, 0
    @add mesh

for i, ch of OrigChars
  x = ~~(+i % cols)
  y = ~~(+i / cols)
  obj = new THREE.Object3D
  obj.ch = ch
  obj.load = load
  obj.position.set x * dim, -y * dim, 0
  boxes.push obj
  scene.add obj
