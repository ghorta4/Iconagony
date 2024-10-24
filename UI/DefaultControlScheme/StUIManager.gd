extends Node

@onready var MovesHolster = $Moves
@onready var MovesetEditor = $"%MovesetEditor"

var ButtonPrefab = preload("res://UI/DefaultControlScheme/AdvButton.tscn")
var MoveDescPrefab = preload("res://UI/DefaultControlScheme/MoveViewWindow.tscn")
var MementoPrefab = preload("res://System/Mementos/MementoGem.tscn")

@onready var facingButton = $"AlwaysOn/Facing"

@onready var timer = $"%Timer"
@onready var subtimer = $"%SubTimer"

@onready var HPGrey = $"%BackAndGrey"
@onready var HPGreyPreview = $"%PreviewGrey"
@onready var HPMain = $"%HP"
@onready var HPPreview = $"%PreviewHP"

@onready var FlairLayer = $"%VisualFlair"
@onready var Wheel = $"%Circle"
@onready var LethalIndicator = $"%LethalIndicator"

@onready var WaitSFX = $"%WaitAmbiance"

var lethalStartPos = Vector2.ZERO

var allActiveButtons : Array[AdvancedMoveButton] = [] #Array with all buttons.
var moveDescriptions : Control

var moveControls #ways to manipulate a move, such as an XY plot or a slider

var followedPlayer : CharacterObject
var followedPreviewPlayer : CharacterObject

var selectedMove : MoveInstance #used to communicate with the rest of the game...

var battleInstance : BattleInstance
var ghostBattleInstance
var readyToSend = false

var previewUpdateCooldown = 0.0
var previewUpdateQueued = false

const maxPreviewCooldown = 0.45

const screenHeight = 500.0
const screenWidth = 800.0

const deleteHoldTimerMax = 2.5

var hoveredButton : ClickDragButton #Used to keep track of what's currently selected for move-dragging.

var viewedMementoHelper : MementoUI

var DecorScrollDistance = 0.0;

var startingMovesetEditorPosition = Vector2.ZERO
func _ready():
	InitMovesetEditor()
	$AlwaysOn/Confirm.UI = self
	$AlwaysOn/Wait.UI = self
	lethalStartPos = LethalIndicator.position

func Init():
	MovesetEditor.visible = false
	
	moveDescriptions = MoveDescPrefab.instantiate()
	add_child(moveDescriptions)
	moveDescriptions.visible = false
	moveDescriptions.UI = self
	
	RegenerateMoveObjects()
	
	WaitSFX.play()
	
	$LevelEndDisplay/Replay/Text.pressed.connect(ReplayLevel)
	
	$LevelEndDisplay/Return/Text.pressed.connect(ExitGame)
	
	var endDisplayChildren = $LevelEndDisplay.get_children()
	
	for child in endDisplayChildren:
		child.visible = false

var lastFlip = false
var dataLastFrame
var flipLastFrame
var smoothMouse = Vector2.ZERO
var desiredPushL = 0.0
var desiredPushR = 0.0
var desiredPushT = 0.0

#Yanderedev bless this code! Amen!

#Satan: My child will organize code snippets into blocks for ease of analysis
#Jesus:
func _physics_process(delta):
	TickWinLoseUI()
	TickIntro()
	#save load le epic icon
	leEpicFaceTimer -= delta
	leEpicFaceTimer = max(leEpicFaceTimer, 0.0)
	$"%yuhGuy".self_modulate.a = clamp(leEpicFaceTimer, 0.0, 1.0)
	
	if not is_instance_valid(followedPlayer):
		return
	
	UpdateMovesetEditor(delta)
	
	var decorIntensity = 1.0
	#UI Display stuff here
	var timeLeft = followedPlayer.timeLeftThisTurn
	UpdateTimerDisplay()
	
	if not battleInstance.showHost.levelEnded:
		RunTimerSounds()
	#HP
	var HPFract = followedPlayer.HP / followedPlayer.MaxHP
	HPMain.value = HPFract
	decorIntensity += (1 - HPFract) * 0.5
	HPGrey.value = followedPlayer.greyHealth / followedPlayer.MaxHP
	if followedPreviewPlayer != null && is_instance_valid(followedPreviewPlayer):
		HPPreview.value = followedPreviewPlayer.HP / followedPreviewPlayer.MaxHP
		HPGreyPreview.value = followedPreviewPlayer.greyHealth / followedPreviewPlayer.MaxHP
		LethalIndicator.visible = HPPreview.value <= 0
		LethalIndicator.position = lethalStartPos + (Vector2.RIGHT * randf() + Vector2.UP * randf()) * 5
	else:
		HPPreview.value = HPMain.value
		HPGreyPreview.value = HPGrey.value
		LethalIndicator.visible = false
	
	if battleInstance.readFromReplay:
		HPPreview.value = HPMain.value
		HPGreyPreview.value = HPGrey.value
		LethalIndicator.visible = false
	#timer color
	var timers = [timer, subtimer]
	for stimer in timers:
		if timeLeft < 10.0:
			var pulse = max(0, (timeLeft - 9.5) * 2)
			var fract = timeLeft / 10.0
			stimer.self_modulate = Color(0.2 * fract + 0.8, fract - pulse, fract - pulse)
			
			decorIntensity +=( pulse + (1-fract)) * 0.6
		else:
			stimer.self_modulate = Color.WHITE
	
	#SFX
	WaitSFX.volume_db = -25 + (1 - timeLeft / 30.0) * 14
	if battleInstance.readFromReplay || !followedPlayer.stateInterruptable:
		WaitSFX.volume_db = -9999
	
	#Force turn end here
	if followedPlayer.timeLeftThisTurn <= 0 && followedPlayer.stateInterruptable && not battleInstance.showHost.levelEnded:
		if selectedMove == null || not selectedMove.moveClassReference.IsUsable(followedPlayer):
			#selectedMove = MoveManager.GetMoveAtPosition(MoveInstance.moveLocations.Fixed, 0, followedPlayer.instancedMoves)
			OnMoveSelected(MoveManager.GetMoveAtPosition(MoveInstance.moveLocations.Fixed, 0, followedPlayer.instancedMoves))
		readyToSend = true
		PlaySound("TurnEnd")
	
	#Move grabbing and dragging/dropping functionality.
	#do something when letting go of a move.
	if MoveManager.grabbedMove != null:
		var lmbDown = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if not lmbDown:
			var grabbedMove = MoveManager.grabbedMove
			if hoveredButton == null:
				MoveManager.grabbedMove = null
			else:
				if hoveredButton.referencedMoveInstance.moveClassReference is BlankMove:
					
					var validOldTargets = allActiveButtons.filter(func(x) : return x.referencedMoveInstance == grabbedMove)
					if validOldTargets.size() > 0:
						var oldButton = validOldTargets[0]
						oldButton.referencedMoveInstance = hoveredButton.referencedMoveInstance #swap!
					
					if battleInstance.showHost.canEditMoveset:
						MoveManager.ForceMoveRelocate(grabbedMove, hoveredButton.referencedMoveInstance.moveLocation, hoveredButton.referencedMoveInstance.moveSlot, followedPlayer.instancedMoves)
						OwnedMovesManager.CountAvailableMovesBasedOnMoveset(followedPlayer.instancedMoves)
						UpdateOwnedMoveButtonsCountFeatures()
						if currentMetaMove != null:
							OnMetaMoveSelected(currentMetaMove)
					else:
						MoveManager.RelocateMove(battleInstance.currentTick, grabbedMove.moveLocation, grabbedMove.moveSlot, hoveredButton.referencedMoveInstance.moveLocation, hoveredButton.referencedMoveInstance.moveSlot, followedPlayer.instancedMoves)
					
					
					hoveredButton.referencedMoveInstance = grabbedMove
					if not grabbedMove.moveClassReference.IsUsable(followedPlayer):
						selectedMove = null
					MoveManager.AdjustMoveLevels(followedPlayer.instancedMoves)
					previewUpdateQueued = true
					RefreshMoveButtons()
					PlaySound("Slotted")
				MoveManager.grabbedMove = null
				
	
	
	DeleteRightClickMoves()
	
	
	var currentFlip = GetFlip()
	if lastFlip != currentFlip && moveControls != null:
		moveControls.UpdateFacing(currentFlip)
	
	lastFlip = GetFlip()
	
	SetMoveButtonsPosition(delta)
	
	var data = GetData()
	if ((typeof(data) != typeof(dataLastFrame)) || (data != dataLastFrame) || (flipLastFrame != GetFlip()) || (previewUpdateQueued && previewUpdateCooldown <= 0)):
		RefreshPreview()
	dataLastFrame = data
	flipLastFrame = GetFlip()
	
	previewUpdateCooldown -= delta
	
	if Input.is_action_just_released("ui_accept") && CurrentMoveIsUsable():
		readyToSend = true
		PlaySound("TurnEnd")
	
	#Decor
	FlairLayer.visible = not battleInstance.readFromReplay
	var decorZoom = 1 - timeLeft / 120.0
	FlairLayer.rotation_degrees = -35 * decorZoom
	FlairLayer.scale = Vector2.ONE * (1 + decorZoom * 0.4)
	
	DecorScrollDistance += delta * 0.9 * decorIntensity
	FlairLayer.material.set_shader_parameter("offset", Vector2(DecorScrollDistance, 0))
	Wheel.rotation_degrees = DecorScrollDistance * -75

func RefreshMoveButtons():
	for button in allActiveButtons:
		UpdateButtonFromMove(button, button.referencedMoveInstance)

func SetMoveButtonsPosition(delta : float):
	var viewportSize = Vector2(800, 500) #Vector2(get_viewport().size)
	var mousePos = (get_viewport().get_mouse_position() / viewportSize)
	
	
	var ignoreMouse = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	desiredPushL = lerp(desiredPushL, float(mousePos.x > 0.3 || ignoreMouse) , delta * 12)
	desiredPushR = lerp(desiredPushR, float(mousePos.x < 0.7 || mousePos.y > 0.85 ||mousePos.y < 0.35 || ignoreMouse ) , delta * 12)
	desiredPushT = lerp(desiredPushT, float(mousePos.y < 0.285 && mousePos.x > 0.22 && mousePos.x < 0.73 && not ignoreMouse) , delta * 12)
	
	for button in allActiveButtons:
		var instance = button.referencedMoveInstance
		var pushOverride = instance == selectedMove || button.deleteTimer > 0
		if instance.moveLocation == MoveInstance.moveLocations.Inventory:
			var usedPush = desiredPushL if not pushOverride else 0
			button.position.x = button.pushFactor * 30 - 40 - usedPush * 200
			button.position.y = instance.moveSlot * 40 + 100
		
		if instance.moveLocation == MoveInstance.moveLocations.Pickups:
			var usedPush = desiredPushR if not pushOverride else 0
			button.position.x = button.pushFactor * -30 + 570 + usedPush * 200
			button.position.y = instance.moveSlot * 40 + 200
			
			if followedPlayer.ignoreMoveGeneration:
				button.visible = false
		
		if instance.moveLocation == MoveInstance.moveLocations.Sidepack:
			var usedPush = desiredPushT if not pushOverride else 1
			const travelVec = Vector2(cos(deg_to_rad(25)), sin(deg_to_rad(25)))
			button.position.x = -50 + travelVec.x * 300 * usedPush + instance.moveSlot * 86
			button.position.y = -100 + travelVec.y * 300 * usedPush
			button.position -= travelVec * 50
		
		if button.deleteTimer > 0:
			button.rotation = randf_range(-1.0, 1.0) * button.deleteTimer / deleteHoldTimerMax * 0.3
		else:
			button.rotation = 0

#Old prototyping code. =================================================================
func GenerateMoveInstanceWithoutBody(moveID) -> MoveInstance:
	if not moveID in MoveManager.MoveLibrary:
		push_warning("Cannot find move of ID " + moveID + ".")
		return
	
	var relevantMove = MoveManager.MoveLibrary[moveID]
	var newMoveInstance = MoveInstance.GenerateMoveInstance(relevantMove)
	followedPlayer.instancedMoves.append(newMoveInstance)
	
	return newMoveInstance

func GenerateMoveInstance(moveID) -> MoveInstance:
	var newMoveInstance = GenerateMoveInstanceWithoutBody(moveID)
	
	if newMoveInstance == null:
		return
	
	var physicalButton = ButtonPrefab.instantiate()
	physicalButton.player = followedPlayer
	
	physicalButton.UI = self
	
	MovesHolster.add_child(physicalButton)
	allActiveButtons.append(physicalButton)
	
	UpdateButtonFromMove(physicalButton, newMoveInstance)
	
	
	return newMoveInstance
#=======================================================================================
func RegenerateMoveObjects():
	for button in allActiveButtons:
		button.queue_free()
	
	allActiveButtons.clear()
	
	for move in followedPlayer.instancedMoves:
		if move.moveLocation == MoveInstance.moveLocations.Fixed:
			continue
		
		var physicalButton = ButtonPrefab.instantiate()
		physicalButton.player = followedPlayer
		
		physicalButton.UI = self
		
		MovesHolster.add_child(physicalButton)
		allActiveButtons.append(physicalButton)
		
		UpdateButtonFromMove(physicalButton, move)


func UpdateButtonFromMove(button, moveInstance : MoveInstance):
	if not is_instance_valid(followedPlayer):
		return
	
	var buttonType = "InGame"
	
	if button is AdvancedMetaMoveButton:
		buttonType = "MetaMoveDisplay"
	
	
	var targetText = null
	var buttons = null
	match  buttonType:
		"InGame":
			targetText = button.Text1
			buttons = [button.Text1, button.Text2]
		"MetaMoveDisplay":
			targetText = button.Text
			buttons = [button.Text]
	
	
	var classRef = moveInstance.moveClassReference
	targetText.text = classRef.displayName
	button.referencedMoveInstance = moveInstance
	
	
	if buttonType == "InGame":
		if moveInstance.relevantMoveControls == null && moveInstance.moveClassReference.UIScene != null:
			moveInstance.relevantMoveControls = moveInstance.moveClassReference.UIScene.instantiate()
	
	var nameColor = Color(0.95, 0.95, 0.95)#classRef.textColor
	var nameColor2 = nameColor
	nameColor = lerp(nameColor, Color.DIM_GRAY, 0.4)
	
	var backColor = Color.BLACK#classRef.color1
	
	var backColor2 = Color(0.3,0.3, 0.3)
	if moveInstance.visualAlterations.has("Borders"):
		var bordersLibrary = MoveManager.DecorationsLibrary["Borders"]
		var usedBorder = bordersLibrary.filter(func(x) : return x[0] == moveInstance.visualAlterations["Borders"])[0]
		backColor2 = usedBorder[2] #The third element of the appropriate border.
	#Basically, look into the decor library, under the borders table, and grab the element by name.
	
	for sub in buttons:
		sub.disabled = false
		
		var shouldDisable = false
		
		if buttonType == "InGame" && (not moveInstance.moveClassReference.IsUsable(followedPlayer) && not moveInstance.IsPickupMove()):
			shouldDisable = true
		
		if buttonType == "MetaMoveDisplay":
			var movesAvailable =  OwnedMovesManager.GetNumberOfMovesAvailableWithNameAndData(button.referencedMoveInstance.moveClassReference.name, MoveModificationData.GenerateModDataFromMove(button.referencedMoveInstance))
			if movesAvailable <= 0:
				shouldDisable = true
			
			button.get_node("Back2/InstancesLeft").text = "x" + str(movesAvailable)
		
		if shouldDisable:
			backColor = lerp(backColor, Color(0.3, 0.3, 0.3), 0.6)
			backColor2 = lerp(backColor2, Color(0.3, 0.3, 0.3), 0.6)
			
			if moveInstance.moveClassReference == BlankMove:
				backColor2 = Color.BLACK
			
			nameColor2 = lerp(nameColor2, Color(0.2, 0.2, 0.2), 0.7)
			nameColor = lerp(nameColor, Color(0.2, 0.2, 0.2), 0.7)
			sub.disabled = true
	
		sub.add_theme_color_override("font_color", nameColor)
		sub.add_theme_color_override("font_pressed_color", nameColor2)
		sub.add_theme_color_override("font_pressed_color", nameColor2)
	
	if moveInstance.visualAlterations.has("RainbowSheen") && moveInstance.visualAlterations["RainbowSheen"] == "Enabled":
		button.material.set_shader_parameter("enableRainbowSheen", true)
		backColor += Color(0.05, 0.05, 0.05)
	
	if moveInstance.visualAlterations.has("ScreenReflection") && moveInstance.visualAlterations["ScreenReflection"] == "Enabled":
		button.material.set_shader_parameter("enableScreenReflection", true)
	
	if moveInstance.visualAlterations.has("Foils") && moveInstance.visualAlterations["Foils"] != "None":
		button.material.set_shader_parameter("enableFoilNoise", true)
		var foilStats = MoveManager.DecorationsLibrary["Foils"].filter(func(x) : return x[0] == moveInstance.visualAlterations["Foils"])[0]
		button.material.set_shader_parameter("foilModulate", foilStats[2])
		button.material.set_shader_parameter("foilDesaturate", foilStats[3])
	
	if buttonType == "InGame":
		if moveInstance.moveLocation == MoveInstance.moveLocations.Sidepack:
			button.H.visible = false
			button.V.visible = true
			
			button.H.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.V.mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			button.H.visible = true
			button.V.visible = false
			
			button.V.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.H.mouse_filter = Control.MOUSE_FILTER_PASS
	
	if moveInstance.moveClassReference is BlankMove:
		
		button.modulate.a = 0.6
		
		var moveLevel = moveInstance.moveLevel
		if moveLevel > 0:
			moveLevel = "+" + str(moveLevel)
		else:
			moveLevel = str(moveLevel)
		button.Text1.text = "(" + moveLevel + ")"
		
		if moveInstance.moveLocation == MoveInstance.moveLocations.Pickups:
			button.Text1.text = ""
		
		if hoveredButton == button && MoveManager.grabbedMove != null:
			button.Text1.text = MoveManager.grabbedMove.moveClassReference.displayName
			
			button.modulate.a += 0.15
	else:
		button.modulate.a = 1
	
	button.material.set_shader_parameter("newColor1", backColor)
	button.material.set_shader_parameter("newColor2", backColor2)
	button.material.set_shader_parameter("targetColor2", Color("e0e0e0"))
	
	if buttonType == "InGame":
		button.Text2.text = button.Text1.text
	
	button.material.set_shader_parameter("fillPercent", float(moveInstance.remainingUses) /  moveInstance.maxUses)
	
	#Memento setup
	for oldMem in button.mementoDisplay:
		oldMem.queue_free()
	
	button.mementoDisplay.clear()
	
	#space of 12 for each memento, give it nice stacking
	const xTravel = 8
	var desiredMementoAreaWidth = moveInstance.slottedMementos.size() * xTravel
	const sidepackXTravel = 8
	var desiredWidthIfSidepack = moveInstance.slottedMementos.size() * sidepackXTravel
	
	var counter = 0
	for memento in moveInstance.slottedMementos:
		var newVisualAide = MementoPrefab.instantiate()
		button.mementoDisplay.append(newVisualAide)
		button.add_child(newVisualAide)
		
		if moveInstance.moveLocation != MoveInstance.moveLocations.Sidepack:
			
			newVisualAide.position = Vector2(240 - desiredMementoAreaWidth + xTravel * counter, 26 + (counter % 2) * xTravel )
		else:
			newVisualAide.position = Vector2(226 - desiredWidthIfSidepack + sidepackXTravel * counter, 128 + counter* sidepackXTravel / 2.0 - desiredWidthIfSidepack / 2.0 )#- sidepackXTravel * counter
		
		if memento != null:
			newVisualAide.get_child(0).texture = memento.displayTexture
		
		newVisualAide.parentButton = button
		newVisualAide.mementoSlot = counter
		counter += 1
	
	#SFX Related
	if buttonType == "InGame":
		button.MouseOverSFX.pitch_scale = max(1.0 - 0.06 * moveInstance.moveSlot, 0.001)

func OnMoveSelected(move : MoveInstance):
	if not followedPlayer.stateInterruptable:
		return
	
	var usable = move.moveClassReference.IsUsable(followedPlayer)
	
	if (not usable):
		return
	
	if selectedMove == move:
		RefreshPreview()
		PlaySound("SelectCronch")
		return
	
	if move.moveLocation != MoveInstance.moveLocations.Pickups:
		PlaySound("Select")
		PlaySound("SelectCronch")
	else:
		PlaySound("Select2")
	
	selectedMove = move
	
	if moveControls != null:
		MoveControlsToHidden()
	
	var moveClass = move.moveClassReference
	if moveClass.UIScene != null:
		
		moveControls = move.relevantMoveControls
		if is_instance_valid(moveControls) && moveControls.get_parent() != null:
			moveControls.get_parent().remove_child(moveControls)
		
		$MoveControls.add_child(moveControls)
		
		moveControls.UpdateFacing(GetFlip())
	
	RefreshPreview()

func DeleteRightClickMoves():
	var moveToDelete = null
	var usedButton = null
	for button in allActiveButtons:
		if button.deleteTimer >= deleteHoldTimerMax:
			moveToDelete = button.referencedMoveInstance
			usedButton = button
			break
	
	if moveToDelete == null:
		return
	
	var breakParticle = preload("res://Particles/uniqueUIFfx/MoveBreak.tscn")
	breakParticle = breakParticle.instantiate()
	breakParticle.position = usedButton.position + usedButton.pivot_offset
	add_child(breakParticle)
	
	MoveManager.ManuallyBreakMoveAtPosition(battleInstance.currentTick ,moveToDelete.moveLocation, moveToDelete.moveSlot, followedPlayer.instancedMoves, not battleInstance.readFromReplay)
	
	RegenerateMoveObjects()
	if selectedMove != null && selectedMove.relevantMoveControls != null:
		selectedMove.relevantMoveControls.queue_free()
	selectedMove = null
	
	if battleInstance.showHost.canEditMoveset:
		OwnedMovesManager.CountAvailableMovesBasedOnMoveset(followedPlayer.instancedMoves)
		UpdateOwnedMoveButtonsCountFeatures()
		for button in cachedSubMoveSelectButtons:
			UpdateButtonFromMove(button, button.referencedMoveInstance)


func GetData():
	if moveControls == null:
		return null
	
	return moveControls.GetData()

func GetFlip() -> bool:
	return facingButton.button_pressed

func CurrentMoveIsUsable() -> bool:
	return selectedMove != null && selectedMove.moveClassReference.IsUsable(followedPlayer) && !selectedMove.moveLocation == MoveInstance.moveLocations.Pickups

func Clear():
	MoveControlsToHidden()
	readyToSend = false
	selectedMove = null

func MoveControlsToHidden():
	if moveControls == null:
		return
	moveControls.get_parent().remove_child(moveControls)
	$HiddenControls.add_child(moveControls)

func RefreshPreview():
	if battleInstance.runRealtime || battleInstance.showHost.levelEnded || battleInstance.readFromReplay:
		return
	
	if previewUpdateCooldown <= 0:
		previewUpdateCooldown = maxPreviewCooldown
		battleInstance.UpdateQueuedActions()
		ghostBattleInstance.RestartPreview()
		previewUpdateQueued = false
	elif previewUpdateCooldown < maxPreviewCooldown:
		previewUpdateQueued = true

@onready var SFXNode = $"SFX"
func PlaySound(sfxname : String):
	var target = SFXNode.get_node(sfxname)
	target.play()

var lastSecondUsed = 0
func RunTimerSounds():
	var timeLeft = followedPlayer.timeLeftThisTurn
	var currentSecond = floor(timeLeft)
	var currentSubSecond = fmod(floor(timeLeft * 10), 10)
	if currentSecond < lastSecondUsed && currentSecond < 10:
		if currentSecond == 9:
			PlaySound("Timer2")
		PlaySound("Timer")
	
	if currentSubSecond == 9 && currentSecond < 3:
		PlaySound("Timer3")
	
	lastSecondUsed = currentSecond

func UpdateTimerDisplay():
	var timeLeft = followedPlayer.timeLeftThisTurn
	timer.visible = not battleInstance.readFromReplay && not followedPlayer.infiniteTime
	timer.text = "- %02d:%02d:%02d.%02d" % [0, floor(timeLeft / 60.0), floor(fmod(timeLeft, 60)), floor(fmod(timeLeft, 1.) * 100)]
	subtimer.text = "%02d:%02d.%02d" % [floor(timeLeft / 60.0), floor(fmod(timeLeft, 60)), floor(fmod(timeLeft, 1.) * 100)]

func PushToEditingMode():
	MovesetEditor.visible = true


func SetDesiredVisibility(mevisible):
	$DecorAndDisplay.visible = mevisible
	$Moves.visible = mevisible
	$AlwaysOn.visible = mevisible
	#$MovesetEditor.visible = mevisible

func TickIntro():
	var shouldDisplay = battleInstance.currentTick < Showhost.introPart1Duration + 15 && battleInstance.showHost.useDefaultIntro
	$IntroDisplay.visible = shouldDisplay
	
	if not shouldDisplay:
		return
	
	var percentToDisplay = float(battleInstance.currentTick) / Showhost.introPart1Duration * 2.0 
	percentToDisplay = clampf(percentToDisplay, 0, 1)
	var mainLab = $"IntroDisplay/main"
	var subLab = $"IntroDisplay/subtitle"
	mainLab.visible_ratio = clampf(percentToDisplay * 1.3, 0.0, 1.0)
	subLab.visible_ratio = percentToDisplay
	mainLab.text = battleInstance.showHost.ingameShownTitle
	subLab.text = battleInstance.showHost.ingameShownSubtitle
	var soundFrequency = max(mainLab.text.length(), subLab.text.length()) * 1.3
	soundFrequency = max( int(Showhost.introPart1Duration / soundFrequency), 1)
	if battleInstance.currentTick % soundFrequency == 0 && percentToDisplay < 1.0:
		PlaySound("TextTick")


var isWinUI = false
var lastUsedTimer = 0.0
func TickWinLoseUI():
	var endDisplay = $LevelEndDisplay
	
	if not battleInstance.showHost.levelEnded:
		endDisplay.visible = false
		return
	
	endDisplay.visible = true
	
	var wontimer = battleInstance.gameWonTimer
	
	endDisplay.get_node("main").text = battleInstance.showHost.ingameShownTitle
	if isWinUI:
		endDisplay.get_node("texta").text = "Devouring Complete"
	else:
		endDisplay.get_node("texta").text = "Devouring failed."
	
	if CompareTimerDelta(1.0, lastUsedTimer, wontimer):
		$LevelEndDisplay/main.visible = true
		PlaySound("BellTiss")
	if CompareTimerDelta(1.8, lastUsedTimer, wontimer):
		$LevelEndDisplay/texta.visible = true
		PlaySound("BellTiss")
	if CompareTimerDelta(2.6, lastUsedTimer, wontimer):
		$LevelEndDisplay/Return.visible = true
		$LevelEndDisplay/Replay.visible = true
		PlaySound("BellTiss")
	if CompareTimerDelta(3.4, lastUsedTimer, wontimer):
		$LevelEndDisplay/obtained.visible = true
		PlaySound("BellTiss")
	
	
	var isPickupRewardUpdateTick = false
	
	var perPickupCounter = 0
	
	for pickup in battleInstance.showHost.movesCollected:
		isPickupRewardUpdateTick = isPickupRewardUpdateTick || CompareTimerDelta(3.4 + 0.1 * perPickupCounter, lastUsedTimer, wontimer)
		perPickupCounter += 1
	
	if perPickupCounter == 0:
		endDisplay.get_node("obtained").text = "No new moves."
	
	if isPickupRewardUpdateTick:
		
		PlaySound("TextTick")
		
		var maxShown = (wontimer - 3.4 ) / 0.1
		var counter = 0
		var collectedMovesString = ""
		for move in battleInstance.showHost.movesCollected:
			
			if counter != 0:
				collectedMovesString += "\n"
			
			collectedMovesString += "  " + move.moveClassReference.displayName + " obtained."
			
			counter += 1
			
			if counter >= maxShown:
				break
	
		endDisplay.get_node("obtained").text = collectedMovesString
	
	lastUsedTimer = wontimer

func CompareTimerDelta(goal ,first, second) -> bool:
	return first <= goal && second > goal

func ReplayLevel():
	battleInstance.main.doNotAwardMoves = true
	battleInstance.main.ResetScene(true)


#Please god be the last thing I have to add I did NOT plan this UI out appropriately

@onready var LRSwitch = $"%LR"
@onready var ExitButton = $"%Exit"
@onready var Restart = $"%Restart"
@onready var CenterCam = $"%CenterCam"
@onready var BPackButton = $"%Backpack"
@onready var SelectMoves = $"%SelectMoves"
@onready var Save = $"%Save"

func InitMovesetEditor():
	LRSwitch.pressed.connect(ToggleEditorUI)
	
	ExitButton.pressed.connect(OpenExitMenu)
	Restart.pressed.connect(ResetGame)
	CenterCam.pressed.connect(ResetCamera)
	BPackButton.pressed.connect(OpenBackpackMenu)
	SelectMoves.pressed.connect(OpenMoveSelectMenu)
	Save.pressed.connect(OpenSaveMenu)
	
	$"%BPSwitchOn".pressed.connect(SwitchPack)
	
	$"%ExitClicker".pressed.connect(ExitGame)
	
	startingMovesetEditorPosition = MovesetEditor.position
	
	
	$"%Savepack".get_node("Sub").pressed.connect(SaveCall)
	$"%Loadpack".get_node("Sub").pressed.connect(LoadCall)
	
	HideSubmenus()

var isHidingMovesetEditor : bool = true
var desiredMovesetHide = 1.0


func UpdateMovesetEditor(delta):
	var target = 0.0
	if isHidingMovesetEditor:
		target = 1.0
	desiredMovesetHide = lerp(desiredMovesetHide , target, delta * 6)
	
	MovesetEditor.position = startingMovesetEditorPosition + Vector2.RIGHT * (MovesetEditor.size.x - 35) * desiredMovesetHide


func ToggleEditorUI():
	isHidingMovesetEditor = !isHidingMovesetEditor
	LRSwitch.scale = Vector2(1 if isHidingMovesetEditor else -1 , 1)
	PlaySound("Select")

func ResetCamera():
	battleInstance.main.manualCamPos = followedPlayer.position
	PlaySound("DrumKick")

func ResetGame():
	var oldInstancedMoves = battleInstance.focusedPlayer.instancedMoves
	battleInstance.main.ResetScene(false)
	battleInstance.main.manualCamPos = Vector2.ZERO
	
	battleInstance.focusedPlayer.instancedMoves = oldInstancedMoves
	
	RegenerateMoveObjects()
	
	PlaySound("Bells")

func OpenExitMenu():
	PlaySound("Select2")
	isHidingMovesetEditor = false
	
	HideSubmenus()
	$"%ExitEditor".visible = true
	
	LRSwitch.scale = Vector2(1 if isHidingMovesetEditor else -1 , 1)

func OpenMoveSelectMenu():
	PlaySound("Select2")
	isHidingMovesetEditor = false
	
	HideSubmenus()
	$"%MoveSelect".visible = true
	UpdateMoveButtonsFromOwnedMoves()
	
	LRSwitch.scale = Vector2(1 if isHidingMovesetEditor else -1 , 1)


func OpenBackpackMenu():
	PlaySound("Select2")
	isHidingMovesetEditor = false
	
	HideSubmenus()
	$"%BackpackSelect".visible = true
	UpdateBackpackButtons()
	
	LRSwitch.scale = Vector2(1 if isHidingMovesetEditor else -1 , 1)

func OpenSaveMenu():
	PlaySound("Select2")
	isHidingMovesetEditor = false
	
	HideSubmenus()
	$"%SaveOptions".visible = true
	
	LRSwitch.scale = Vector2(1 if isHidingMovesetEditor else -1 , 1)


func ExitGame():
	get_tree().change_scene_to_file("res://Menus/MainMenuAssets/MainMenu.tscn")

func HideSubmenus():
	var submenus = $"%Submenus".get_children()
	for child in submenus:
		child.visible = false


var cachedMoveSelectButtons = []

func UpdateMoveButtonsFromOwnedMoves():
	var moveTemplate = $"%MoveTemplate"
	
	for button in cachedMoveSelectButtons:
		button.queue_free()
	
	cachedMoveSelectButtons = []
	
	var moveContainer = $"%MoveContainer"
	
	var lastGivenSlot = 1000
	
	for metaMove in OwnedMovesManager.OwnedMovesLibrary:
		var newMoveButton = moveTemplate.duplicate()
		var button = newMoveButton.get_node("Sub")
		button.text = MoveManager.MoveLibrary[metaMove].displayName
		moveContainer.add_child(newMoveButton)
		newMoveButton.visible = true
		newMoveButton.referencedMoveInternalName = metaMove
		newMoveButton.UI = self
		newMoveButton.player = followedPlayer
		newMoveButton.assignedSlot = lastGivenSlot
		lastGivenSlot += 1
		cachedMoveSelectButtons.append(newMoveButton)
	
	UpdateOwnedMoveButtonsCountFeatures()

func UpdateOwnedMoveButtonsCountFeatures(): #Dimming when out of moves, changing the number display of available moves, etc
	for button in cachedMoveSelectButtons:
		button.UpdateDisplay()

var cachedSubMoveSelectButtons = []
var currentMetaMove
func OnMetaMoveSelected(internalName : String):
	
	currentMetaMove = internalName
	var moveTemplate = $"%SubMoveTemplate"
	
	for button in cachedSubMoveSelectButtons:
		button.queue_free()
	
	cachedSubMoveSelectButtons = []
	
	var subMoveContainer = $"%SubMoveContainer"
	
	var lastGivenSlot = 100000
	var targetLibrary = OwnedMovesManager.OwnedMovesLibrary[internalName]
	
	
	#clear submoves
	#var toErase = []
	#for move in followedPlayer.instancedMoves:
	#	if move.moveSlot >= 100000:
	#		toErase.append(move)
	
	#for erase in toErase:
	#	followedPlayer.instancedMoves.erase(toErase)
	
	for subMove in targetLibrary:
		
		
		var newMoveButton = moveTemplate.duplicate()
		var button = newMoveButton.get_node("Sub")
		button.text = MoveManager.MoveLibrary[internalName].displayName
		subMoveContainer.add_child(newMoveButton)
		newMoveButton.visible = true
		newMoveButton.referencedMoveInstance = MoveManager.MoveInstanceFromString(internalName)
		
		var details = subMove[0]
		details.ApplyTo(newMoveButton.referencedMoveInstance)
		
		newMoveButton.UI = self
		newMoveButton.player = followedPlayer
		newMoveButton.referencedMoveInstance.moveSlot = lastGivenSlot
		newMoveButton.referencedMoveInstance.moveLocation = MoveInstance.moveLocations.Pickups
		lastGivenSlot += 1
		cachedSubMoveSelectButtons.append(newMoveButton)
		
		UpdateButtonFromMove(newMoveButton, newMoveButton.referencedMoveInstance)


var cachedBackpackSelectButtons = []
var currentlySelectedPack = null
func UpdateBackpackButtons():
	var backpackTemplate = $"%BackpackButtonTemplate"
	
	for button in cachedBackpackSelectButtons:
		button.queue_free()
	
	cachedBackpackSelectButtons = []
	
	var packContainer = $"%PackContainer"
	
	for key in MoveManager.BackpackLibrary:
		var newBackpackButton = backpackTemplate.duplicate()
		var button = newBackpackButton.get_node("Sub")
		var value = MoveManager.BackpackLibrary[key]
		button.text = value.displayName
		packContainer.add_child(newBackpackButton)
		newBackpackButton.visible = true
		newBackpackButton.packInternalName = key
		newBackpackButton.UI = self
		
		cachedBackpackSelectButtons.append(newBackpackButton)

func UpdatePackDisplay(internalName : String):
	currentlySelectedPack = internalName
	var selectedPack = MoveManager.BackpackLibrary[internalName]
	$"%BackpackName".text = selectedPack.displayName
	$"%BackpackDesc".text = selectedPack.displayDescription
	$"%BPSwitchOn".visible = true

func SwitchPack():
	var usedBackpack = MoveManager.BackpackLibrary[currentlySelectedPack]
	MoveManager.EquippedBackpack = usedBackpack
	followedPlayer.instancedMoves.clear()
	MoveManager.LoadMovesetFromNames(followedPlayer.instancedMoves, [], [])
	MoveManager.AdjustMoveLevels(followedPlayer.instancedMoves)
	
	RegenerateMoveObjects()
	
	OwnedMovesManager.CountAvailableMovesBasedOnMoveset(followedPlayer.instancedMoves)
	if currentMetaMove != null:
		OnMetaMoveSelected(currentMetaMove) #refreshes the display of the hidden menu

var leEpicFaceTimer = 0.0

func SaveCall():
	OwnedMovesManager.SaveMoveset(followedPlayer.instancedMoves, GameLoader.TestSavePath + "Moveset.cd")
	leEpicFaceTimer = 1.0

func LoadCall():
	OwnedMovesManager.LoadMoveset(followedPlayer, GameLoader.TestSavePath + "Moveset.cd")
	leEpicFaceTimer = 1.0
	
	OwnedMovesManager.CountAvailableMovesBasedOnMoveset(followedPlayer.instancedMoves)
	if currentMetaMove != null:
		OnMetaMoveSelected(currentMetaMove) #refreshes the display of the hidden menu
	
	RegenerateMoveObjects()
	pass
