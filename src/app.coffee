
FizzyText = ->
  message: "dat.gui"
  speed: 0.8
  displayOutline: false
  explode: ->

window.onload = ->
  text = new FizzyText()
  gui = new dat.GUI()
  gui.add text, "message"
  gui.add text, "speed", -5, 5
  gui.add text, "displayOutline"
  gui.add text, "explode"


SCREEN_WIDTH = window.innerWidth
SCREEN_HEIGHT = window.innerHeight

renderer = undefined
container = undefined
stats = undefined

controls = undefined

camera = undefined
scene = undefined
cameraOrtho = undefined
sceneRenderTarget = undefined

uniformsNoise = undefined
uniformsNormal = undefined
uniformsTerrain = undefined

heightMap = undefined
normalMap = undefined
quadTarget = undefined

directionalLight = undefined
pointLight = undefined

terrain = undefined

textureCounter = 0

animDelta = 0
animDeltaDir = -1
lightVal = 0
lightDir = 1

clock = new THREE.Clock()

morph = undefined
morphs = []

updateNoise = yes

animateTerrain = no

textMesh1 = undefined

mlib = {}


init = ->

  # MORPHS
  addMorph = (geometry, speed, duration, x, y, z) ->

    material = new THREE.MeshLambertMaterial
      color: 0xffaa55
      morphTargets: true
      vertexColors: THREE.FaceColors
 
    meshAnim = new THREE.MorphAnimMesh(geometry, material)
    meshAnim.speed = speed
    meshAnim.duration = duration
    meshAnim.time = 600 * Math.random()
    meshAnim.position.set x, y, z
    meshAnim.rotation.y = Math.PI / 2
    meshAnim.castShadow = true
    meshAnim.receiveShadow = false
    scene.add meshAnim
    morphs.push meshAnim
    renderer.initWebGLObjects scene

  morphColorsToFaceColors = (geometry) ->
    if geometry.morphColors and geometry.morphColors.length
      colorMap = geometry.morphColors[0]
      i = 0
      while i < colorMap.colors.length
        geometry.faces[i].color = colorMap.colors[i]
        i++

  container = document.getElementById("container")

  sceneRenderTarget = new THREE.Scene()
  cameraOrtho = new THREE.OrthographicCamera(SCREEN_WIDTH / -2, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, SCREEN_HEIGHT / -2, -10000, 10000)
  cameraOrtho.position.z = 100
  sceneRenderTarget.add cameraOrtho
  camera = new THREE.PerspectiveCamera(40, SCREEN_WIDTH / SCREEN_HEIGHT, 2, 4000)
  camera.position.set -1200, 800, 1200
  controls = new THREE.TrackballControls(camera)
  controls.target.set 0, 0, 0
  controls.rotateSpeed = 1.0
  controls.zoomSpeed = 0.7
  controls.panSpeed = 0.8
  controls.noZoom = false
  controls.noPan = false
  controls.staticMoving = false
  controls.dynamicDampingFactor = 0.15
  controls.keys = [65, 83, 68]
  scene = new THREE.Scene()
  scene.fog = new THREE.Fog(0xffffff, 2000, 4000)
  scene.add new THREE.AmbientLight(0x111111)
  directionalLight = new THREE.DirectionalLight(0xffffff, 1.15)
  directionalLight.position.set 500, 2000, 0
  scene.add directionalLight
  pointLight = new THREE.PointLight(0xffffff, 1.5)
  pointLight.position.set 0, 0, 0
  scene.add pointLight
  normalShader = THREE.NormalMapShader
  rx = 256
  ry = 256
  pars =
    minFilter: THREE.LinearMipmapLinearFilter
    magFilter: THREE.LinearFilter
    format: THREE.RGBFormat

  heightMap = new THREE.WebGLRenderTarget(rx, ry, pars)
  normalMap = new THREE.WebGLRenderTarget(rx, ry, pars)
  uniformsNoise =
    time:
      type: "f"
      value: 1.0

    scale:
      type: "v2"
      value: new THREE.Vector2(1.5, 1.5)

    offset:
      type: "v2"
      value: new THREE.Vector2(0, 0)

  uniformsNormal = THREE.UniformsUtils.clone(normalShader.uniforms)
  uniformsNormal.height.value = 0.05
  uniformsNormal.resolution.value.set rx, ry
  uniformsNormal.heightMap.value = heightMap
  vertexShader = document.getElementById("vertexShader").textContent
  specularMap = new THREE.WebGLRenderTarget(2048, 2048, pars)
  diffuseTexture1 = THREE.ImageUtils.loadTexture("textures/terrain/grasslight-big.jpg", null, ->
    loadTextures()
    applyShader THREE.LuminosityShader, diffuseTexture1, specularMap
  )
  diffuseTexture2 = THREE.ImageUtils.loadTexture("textures/terrain/backgrounddetailed6.jpg", null, loadTextures)
  detailTexture = THREE.ImageUtils.loadTexture("textures/terrain/grasslight-big-nm.jpg", null, loadTextures)
  diffuseTexture1.wrapS = diffuseTexture1.wrapT = THREE.RepeatWrapping
  diffuseTexture2.wrapS = diffuseTexture2.wrapT = THREE.RepeatWrapping
  detailTexture.wrapS = detailTexture.wrapT = THREE.RepeatWrapping
  specularMap.wrapS = specularMap.wrapT = THREE.RepeatWrapping
  terrainShader = THREE.ShaderTerrain["terrain"]
  uniformsTerrain = THREE.UniformsUtils.clone(terrainShader.uniforms)
  uniformsTerrain["tNormal"].value = normalMap
  uniformsTerrain["uNormalScale"].value = 3.5
  uniformsTerrain["tDisplacement"].value = heightMap
  uniformsTerrain["tDiffuse1"].value = diffuseTexture1
  uniformsTerrain["tDiffuse2"].value = diffuseTexture2
  uniformsTerrain["tSpecular"].value = specularMap
  uniformsTerrain["tDetail"].value = detailTexture
  uniformsTerrain["enableDiffuse1"].value = true
  uniformsTerrain["enableDiffuse2"].value = true
  uniformsTerrain["enableSpecular"].value = true
  uniformsTerrain["uDiffuseColor"].value.setHex 0xffffff
  uniformsTerrain["uSpecularColor"].value.setHex 0xffffff
  uniformsTerrain["uAmbientColor"].value.setHex 0x111111
  uniformsTerrain["uShininess"].value = 30
  uniformsTerrain["uDisplacementScale"].value = 150 # height of the hills
  uniformsTerrain["uRepeatOverlay"].value.set 6, 6
  params = [["heightmap", document.getElementById("fragmentShaderNoise").textContent, vertexShader, uniformsNoise, false], ["normal", normalShader.fragmentShader, normalShader.vertexShader, uniformsNormal, false], ["terrain", terrainShader.fragmentShader, terrainShader.vertexShader, uniformsTerrain, true]]
  i = 0

  while i < params.length
    material = new THREE.ShaderMaterial
      uniforms: params[i][3]
      vertexShader: params[i][2]
      fragmentShader: params[i][1]
      lights: params[i][4]
      fog: true
    mlib[params[i][0]] = material
    i++

  plane = new THREE.PlaneGeometry SCREEN_WIDTH, SCREEN_HEIGHT
  quadTarget = new THREE.Mesh plane, new THREE.MeshBasicMaterial color: 0x000000
  quadTarget.position.z = -500
  sceneRenderTarget.add quadTarget
  geometryTerrain = new THREE.PlaneGeometry(6000, 6000, 256, 256)
  geometryTerrain.computeFaceNormals()
  geometryTerrain.computeVertexNormals()
  geometryTerrain.computeTangents()
  terrain = new THREE.Mesh(geometryTerrain, mlib["terrain"])
  terrain.position.set 0, -125, 0
  terrain.rotation.x = -Math.PI / 2
  terrain.visible = false
  scene.add terrain
  renderer = new THREE.WebGLRenderer()
  renderer.setSize SCREEN_WIDTH, SCREEN_HEIGHT
  renderer.setClearColor scene.fog.color, 1
  renderer.domElement.style.position = "absolute"
  renderer.domElement.style.top = "0px"
  renderer.domElement.style.left = "0px"
  container.appendChild renderer.domElement
  renderer.gammaInput = true
  renderer.gammaOutput = true
  stats = new Stats()
  container.appendChild stats.domElement
  onWindowResize()
  window.addEventListener "resize", onWindowResize, false
  document.addEventListener "keydown", onKeyDown, false
  #renderer.autoClear = yes
  #renderTargetParameters =
  #  minFilter: THREE.LinearFilter
  #  magFilter: THREE.LinearFilter
  #  format: THREE.RGBFormat
  #  stencilBuffer: false

  #renderTarget = new THREE.WebGLRenderTarget(SCREEN_WIDTH, SCREEN_HEIGHT, renderTargetParameters)
  #effectBloom = new THREE.BloomPass(0.6)
  #effectBleach = new THREE.ShaderPass(THREE.BleachBypassShader)
  #hblur = new THREE.ShaderPass(THREE.HorizontalTiltShiftShader)
  #vblur = new THREE.ShaderPass(THREE.VerticalTiltShiftShader)
  #bluriness = 6
  #hblur.uniforms["h"].value = bluriness / SCREEN_WIDTH
  #vblur.uniforms["v"].value = bluriness / SCREEN_HEIGHT
  #hblur.uniforms["r"].value = vblur.uniforms["r"].value = 0.5
  #effectBleach.uniforms["opacity"].value = 0.65
  #composer = new THREE.EffectComposer(renderer, renderTarget)
  #renderModel = new THREE.RenderPass(scene, camera)
  #vblur.renderToScreen = true
  #composer = new THREE.EffectComposer(renderer, renderTarget)
  #composer.addPass renderModel
  #composer.addPass effectBloom
  #composer.addPass hblur
  #composer.addPass vblur
  loader = new THREE.JSONLoader()
  startX = -3000
  loader.load "models/animated/parrot.js", (geometry) ->
    morphColorsToFaceColors geometry
    addMorph geometry, 250, 500, startX - 500, 500, 700
    addMorph geometry, 250, 500, startX - Math.random() * 500, 500, -200
    addMorph geometry, 250, 500, startX - Math.random() * 500, 500, 200
    addMorph geometry, 250, 500, startX - Math.random() * 500, 500, 1000

  loader.load "models/animated/flamingo.js", (geometry) ->
    morphColorsToFaceColors geometry
    addMorph geometry, 500, 1000, startX - Math.random() * 500, 350, 40

  loader.load "models/animated/stork.js", (geometry) ->
    morphColorsToFaceColors geometry
    addMorph geometry, 350, 1000, startX - Math.random() * 500, 350, 340

  
  # PRE-INIT
  renderer.initWebGLObjects scene


#
onWindowResize = (event) ->
  SCREEN_WIDTH = window.innerWidth
  SCREEN_HEIGHT = window.innerHeight
  renderer.setSize SCREEN_WIDTH, SCREEN_HEIGHT
  camera.aspect = SCREEN_WIDTH / SCREEN_HEIGHT
  camera.updateProjectionMatrix()

#
onKeyDown = (event) ->
  switch event.keyCode
    when 78 #N
      lightDir *= -1
    when 77 #M
      animDeltaDir *= -1

#
applyShader = (shader, texture, target) ->
  shaderMaterial = new THREE.ShaderMaterial
    fragmentShader: shader.fragmentShader
    vertexShader: shader.vertexShader
    uniforms: THREE.UniformsUtils.clone shader.uniforms
  
  shaderMaterial.uniforms["tDiffuse"].value = texture
  sceneTmp = new THREE.Scene()
  meshTmp = new THREE.Mesh(new THREE.PlaneGeometry(SCREEN_WIDTH, SCREEN_HEIGHT), shaderMaterial)
  meshTmp.position.z = -500
  sceneTmp.add meshTmp
  renderer.render sceneTmp, cameraOrtho, target, true

#
loadTextures = ->
  textureCounter += 1
  if textureCounter is 3
    terrain.visible = true
    document.getElementById("loading").style.display = "none"

#
animate = ->
  requestAnimationFrame animate
  render()
  stats.update()

render = ->
  delta = clock.getDelta()
  if terrain.visible
    controls.update()
    time = Date.now() * 0.001
    fLow = 0.1
    fHigh = 0.8
    lightVal = THREE.Math.clamp(lightVal + 0.5 * delta * lightDir, fLow, fHigh)
    valNorm = (lightVal - fLow) / (fHigh - fLow)
    scene.fog.color.setHSL 0.52, 0.2, lightVal
    renderer.setClearColor scene.fog.color, 1
    directionalLight.intensity = THREE.Math.mapLinear(valNorm, 0, 1, 0.1, 1.15)
    pointLight.intensity = THREE.Math.mapLinear(valNorm, 0, 1, 0.9, 1.5)
    uniformsTerrain["uNormalScale"].value = THREE.Math.mapLinear(valNorm, 0, 1, 0.6, 3.5)
    if updateNoise
      animDelta = THREE.Math.clamp(animDelta + 0.00075 * animDeltaDir, 0, 0.05)
      
      # anim
      uniformsNoise["time"].value += delta * animDelta
      uniformsNoise["offset"].value.x += 0 * 0.05
      uniformsTerrain["uOffset"].value.x = 4 * uniformsNoise["offset"].value.x
      quadTarget.material = mlib["heightmap"]
      renderer.render sceneRenderTarget, cameraOrtho, heightMap, true
      quadTarget.material = mlib["normal"]
      renderer.render sceneRenderTarget, cameraOrtho, normalMap, true
    
    #updateNoise = false;
    i = 0

    while i < morphs.length
      morph = morphs[i]
      morph.updateAnimation 1000 * delta
      morph.position.x += morph.speed * delta
      morph.position.x = -1500 - Math.random() * 500  if morph.position.x > 2000
      i++
    renderer.render scene, camera

init()
animate()
