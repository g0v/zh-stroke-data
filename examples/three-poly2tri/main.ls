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
scale = 0.2
dim   = 2150pt
cols  = 64chars
dst   = 10pt
boxes = []

scene = new THREE.Scene
w = window.innerWidth / scale
h = window.innerHeight / scale
box = new THREE.Box3 do
  new THREE.Vector3 0, -h, -50
  new THREE.Vector3 w,  0, 50
camera = new THREE.OrthographicCamera do
  box.min.x, box.max.x,
  box.max.y, box.min.y,
  1, 1000
camera.position.set 0, 0, 500
updateCamera = ->
  w = window.innerWidth / scale
  h = window.innerHeight / scale
  center = box.center!
  box.setFromCenterAndSize center, new THREE.Vector2 w, h
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

keys = {}
$ document .keydown    (e) -> keys[e.keyCode] = on
           .keyup      (e) -> keys[e.keyCode] = off
           .mousewheel (e, delta, dx, dy) ->
             scale := scale * Math.pow 1.1, delta

# render
render = ->
  x = 0
  y = 0
  if keys[37] is on then x -= dst / scale # left
  if keys[39] is on then x += dst / scale # right
  if keys[38] is on then y += dst / scale # up
  if keys[40] is on then y -= dst / scale # down
  box.min.x += x
  box.max.x += x
  box.min.y += y
  box.max.y += y
  updateCamera!
  box.expandByScalar 2 * dim
  for o in boxes
    p = new THREE.Vector3 o.position.x + dim/2, o.position.y - dim/2, 0
    v = box.containsPoint p
    o.load?! if v
    o.traverse -> it.visible = v
  box.expandByScalar -2 * dim
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
    offset = new THREE.Vector2 do
      +data.centroids[j].0
      -data.centroids[j].1
    m = new THREE.Matrix4
    m.makeTranslation -offset.x, -offset.y, 0
    shape = shape-from-outline outline
    # line and vertices
    points = shape.createPointsGeometry!
    points.applyMatrix m
    line = new THREE.Line do
      points
      new THREE.LineBasicMaterial color: line-color, lineWidth: 2
    line.position.set offset.x, offset.y, 0
    @add line
    for hole in shape.holes
      points = hole.createPointsGeometry!
      points.applyMatrix m
      line = new THREE.Line do
        points
        new THREE.LineBasicMaterial color: line-color, lineWidth: 2
      line.position.set offset.x, offset.y, 0
      @add line
    # the size of each particle decrease strangly
    #pgeo = points.clone!
    #particles = new THREE.ParticleSystem do
    #  pgeo
    #  new THREE.ParticleBasicMaterial color: color, size: 20, opacity: 0.5
    #particles.position.set offset.x, offset.y, 0
    #@add particles
    # triangulated
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
    geometry = new THREE.ShapeGeometry shape
    console.log = log
    # restored
    geometry.applyMatrix m
    mesh = THREE.SceneUtils.createMultiMaterialObject do
      geometry
      * new THREE.MeshLambertMaterial color: color
        new THREE.MeshBasicMaterial color: line-color, wireframe: true, transparent: true
    mesh.position.set offset.x + dim, offset.y, 0
    @add mesh

for i, ch of OrigChars
  x = ~~(+i % cols)
  y = ~~(+i / cols)
  obj = new THREE.Object3D
  obj.ch = ch
  obj.load = load
  obj.position.set x * 2 * dim, -y * dim, 0
  boxes.push obj
  scene.add obj
