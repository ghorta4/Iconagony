extends Node
class_name Main
@onready var battleScenePrefab = preload("res://System/Scenes/Battlefield.tscn")

@onready var mainHolster = $"%Main"
@onready var previewHolster = $"%Preview"

@onready var freezeFrame = $"%PreviewFreezeFrame"

@onready var Ears = $"Ears"

@onready var turnShader = $"%TurnShader"

@onready var pauseMenu = $"%PauseMenu"
@onready var combatNode = $"%Combat"

var mainScene : BattleInstance
var previewScene : BattleInstance

var resetSeed = true

var stageBackground : Stage

var manualCamPos = Vector2.ZERO;
var lethargicCameraPosition = Vector2.ZERO
var cameraJostle = Vector2.ZERO
var lethargicCameraZoom = 1.0

var recycledFoesCache = {}

var doNotAwardMoves = false

static var fullMoveDisplay = true

var paused = false

func _ready():
	ReplayManager.StartNewFile()
	stageBackground =  LevelManager.QueuedShowhost.background.instantiate()
	stageBackground.main = self
	add_child(stageBackground)
	Setup()
	remove_child(stageBackground)
	mainScene.camera.add_child(stageBackground)
	resetSeed = false
	


func _physics_process(delta):
	
	if Input.is_action_just_released("ui_text_completion_replace"):
		fullMoveDisplay = !fullMoveDisplay
	
	if Input.is_action_just_released("ui_cancel"):
		paused = !paused
		pauseMenu.visible = paused
		combatNode.process_mode = Node.PROCESS_MODE_INHERIT if not paused else Node.PROCESS_MODE_DISABLED
	
	if paused:
		return
	
	UpdateCamera(delta)
	
	stageBackground.Update(mainScene.realTimePassed)
	
	if makeFreezeFrameVisible && not mainScene.IsCurrentlyPlaying():
		freezeFrame.visible = true
	
	if mainScene.IsCurrentlyPlaying() || mainScene.showHost.levelEnded:
		freezeFrame.visible = false
	
	turnShader.visible = not mainScene.runRealtime && is_instance_valid(mainScene.focusedPlayer) && mainScene.focusedPlayer.stateInterruptable && not mainScene.readFromReplay

func ResetScene(replay : bool):
	mainScene.camera.remove_child(stageBackground)
	previewScene.queue_free()
	
	var stolenUI = mainScene.loadedUI
	
	mainScene.queue_free()
	
	mainScene = null
	previewScene = null
	
	Setup(stolenUI)
	stolenUI.RegenerateMoveObjects()
	mainScene.camera.add_child(stageBackground)
	mainScene.readFromReplay = replay
	previewScene.visible = false
	
	if not replay:
		ReplayManager.StartNewFile()

func Setup(transferedUI = null):
	#MOVE AND BACKPACK SETUP FOR TESTING
	#MoveManager.EquippedBackpack = preload("res://System/PlayerMoves/CustomBackpacks/DefaultPack.gd").new()
	
	mainScene = battleScenePrefab.instantiate()
	mainHolster.add_child(mainScene)
	mainScene.main = self
	if resetSeed:
		ReplayManager.SaveReplayParamsFromBattle(mainScene)
	else:
		ReplayManager.ApplyReplayParamsToBattle(mainScene)
	
	#Temporary team color setup
	var p1Material = ShaderMaterial.new()
	p1Material.shader = preload("res://System/Shaders/RecolorAndOutline.gdshader")
	mainScene.teamMaterials[0] = p1Material
	
	var enemyMaterial = ShaderMaterial.new()
	enemyMaterial.shader = preload("res://System/Shaders/RecolorAndOutline.gdshader")
	enemyMaterial.set_shader_parameter("replaceColor1", Color("686ed3"))
	enemyMaterial.set_shader_parameter("replaceColor2", Color("2e099a"))
	enemyMaterial.set_shader_parameter("outlineColor1", Color("30d1de"))
	enemyMaterial.set_shader_parameter("outlineColor2", Color("1b1365"))
	mainScene.teamMaterials[1] = enemyMaterial
	
	var enemyMaterial2 = ShaderMaterial.new()
	enemyMaterial2.shader = preload("res://System/Shaders/RecolorAndOutline.gdshader")
	enemyMaterial2.set_shader_parameter("replaceColor1", Color("6ed368"))
	enemyMaterial2.set_shader_parameter("replaceColor2", Color("099a2e"))
	enemyMaterial2.set_shader_parameter("outlineColor1", Color("d1de30"))
	enemyMaterial2.set_shader_parameter("outlineColor2", Color("13651b"))
	mainScene.teamMaterials[2] = enemyMaterial2
	#------------------------
	
	mainScene.loadedUI = transferedUI
	mainScene.Setup()
	
	previewScene = battleScenePrefab.instantiate()
	previewHolster.add_child(previewScene)
	previewScene.isGhost = true
	previewScene.copiedGame = mainScene
	previewScene.Setup()
	
	mainScene.loadedUI.ghostBattleInstance = previewScene
	mainScene.loadedUI.battleInstance = mainScene
	
	stageBackground.usedCamera = mainScene.camera
	stageBackground.Update(0)
	
	
	if mainScene.showHost.canEditMoveset:
		OwnedMovesManager.CountAvailableMovesBasedOnMoveset(mainScene.focusedPlayer.instancedMoves)
	
	var loadSuccess = OwnedMovesManager.LoadMoveset(mainScene.focusedPlayer, GameLoader.TestSavePath + "Moveset.cd")
	if not loadSuccess:
		MoveManager.LoadMovesetFromNames(mainScene.focusedPlayer.instancedMoves,["The Line", "RiskRain", "RiskRain", "RiskRain", "RiskRain", "RiskRain"],["Ascend", "Escapade"])
	OwnedMovesManager.CountAvailableMovesBasedOnMoveset(mainScene.focusedPlayer.instancedMoves)
	mainScene.loadedUI.RegenerateMoveObjects()

func ClearFreezeFrame():
	freezeFrame.visible = false
	makeFreezeFrameVisible = false

var lastFreezeFramePos = Vector2.ZERO
var makeFreezeFrameVisible = false
func ApplyFreezeFrame():
	makeFreezeFrameVisible = true
	
	var previewTex = previewHolster.get_texture().get_image()
	var asImage = Image.create(previewTex.get_width(), previewTex.get_height(), false, previewTex.get_format())
	var size = Rect2(0, 0, previewTex.get_width(), previewTex.get_height())
	asImage.blit_rect(previewTex, size, Vector2.ZERO)
	
	var finalTex = ImageTexture.create_from_image(asImage)
	
	freezeFrame.texture = finalTex
	
	lastFreezeFramePos = previewScene.camera.position
	memorizedMouseDelta = mouseDeltaCorrection
	
	mainScene.loadedUI.PlaySound("Thump2")

#Camera based functionality

var lastMousePos : Vector2 = Vector2.ZERO
var RMBPressedLastFrame = false
var mouseDeltaCorrection = Vector2.ZERO
var memorizedMouseDelta = Vector2.ZERO
var cameraPositionOverride = null
func UpdateCamera(delta):
	
	if cameraPositionOverride != null:
		pass
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mousePos = get_viewport().get_mouse_position()
		if not RMBPressedLastFrame:
			lastMousePos = mousePos
		RMBPressedLastFrame = true
		mouseDeltaCorrection = lastMousePos - mousePos
		manualCamPos += mouseDeltaCorrection
		lastMousePos = mousePos
	else:
		RMBPressedLastFrame = false
		memorizedMouseDelta = Vector2.ZERO
	
	mainScene.camera.position = GetDesiredCameraPosition(delta)
	previewScene.camera.position = mainScene.camera.position
	freezeFrame.position = mainScene.camera.position * -1 + lastFreezeFramePos - memorizedMouseDelta
	
	Ears.position = mainScene.camera.position
	
	var targetZoom = GetDesiredCameraZoom(delta)
	
	mainScene.camera.zoom = Vector2.ONE * targetZoom
	previewScene.camera.zoom = mainScene.camera.zoom
	stageBackground.SetZoom(targetZoom)
	lethargicCameraZoom = targetZoom

func GetDesiredCameraPosition(delta : float) -> Vector2:
	if UseAutomaticCameraControls():
		var usedCameraZoomMote = GetCameraZoomMote()
		
		var targetPos = mainScene.focusedPlayer.position + mainScene.focusedPlayer.velocity * delta * 6.0 + Vector2.UP * 100
		
		if usedCameraZoomMote != null && usedCameraZoomMote.targetedObject != null:
			var targetObj = usedCameraZoomMote.targetedObject
			targetPos = targetObj.position + usedCameraZoomMote.targetObjectOffset * Vector2(targetObj.GetFacingInt(),1)
		
		if cameraPositionOverride != null:
			targetPos = cameraPositionOverride
			manualCamPos = targetPos
			return cameraPositionOverride
		
		lethargicCameraPosition = lerp(lethargicCameraPosition, targetPos, delta * 4.0) + cameraJostle
		
		
		manualCamPos = lethargicCameraPosition 
		return lethargicCameraPosition
	
	
	var adjustedPos = manualCamPos
	adjustedPos.y = min(adjustedPos.y, 125)
	
	manualCamPos = adjustedPos
	return adjustedPos

func GetDesiredCameraZoom(delta : float) -> float:
	if not UseAutomaticCameraControls():
		return lerp(lethargicCameraZoom, 1.0, 5 * delta)
	
	var value = lethargicCameraZoom
	
	var zoomMote = GetCameraZoomMote()
	
	if zoomMote != null:
		value = lerp(value, zoomMote.desiredZoom, zoomMote.zoomLerpSpeed * delta)
	else:
		value = lerp(value, 1.0, 3 * delta)
	return value

func UseAutomaticCameraControls() -> bool:
	if mainScene != null && mainScene.showHost.levelEnded:
		return false
	if cameraPositionOverride != null:
		return true
	if not is_instance_valid(mainScene.focusedPlayer):
		return false
	return not mainScene.focusedPlayer.stateInterruptable || mainScene.readFromReplay

func GetCameraZoomMote() -> CameraZoomMote:
	var usedCameraZoomMote = null
	for mote in mainScene.moteList:
		if not mote is CameraZoomMote:
			continue
		
		if usedCameraZoomMote == null || usedCameraZoomMote.priority < mote.priority:
			usedCameraZoomMote = mote
	
	return usedCameraZoomMote
