@tool
extends CharacterObject

@export_group("Strife Specific")
var cachedHeadSpriteInfos : Dictionary = {}
var cachedHeadSprites : Dictionary = {}
var currentExpression = "Neutral"


@onready var gungeousArm = $"Sprite/GungeousArm"



var instancedMoves : Array[MoveInstance] = []

var lastQueuedMoveLocation : MoveInstance.moveLocations
var lastQueuedMoveSlot : int
var canPollMoves = false

var levelEnded : bool = false
#Actual game stuff below
var greyHealth = 9999999.0;
const greyHealthDecay = 0.2
var greyHealthWaitBeforeDecay = 0
const greyHealthDefaultWait = 45
#Below are turn timer related variables
var timeLeftThisTurn = defaultTurnTime #in seconds
var infiniteTime = false
var ignoreMoveGeneration = false

const defaultTurnTime = 90.0

#Move Related
var scenematicGlobalPauseMove = false

#tale from Down Under
var taleFromDownUnderTicks = 0
var taleFromDownUnderExhaustion = 0
var taleFromDownUnderLevel = 0
const maxTaleFromDownUnderExaustion = 480

#Orlando Beats
var orlandoLevel = 0
var orlandoEnabled = false
var orlandoTrackedMoves = []

func _init() -> void:
	cachedHeadSpriteInfos = {}
	cachedHeadSprites = {}
	super()

func Initialize():
	super()
	gungeousArm.visible = false
	greyHealth = MaxHP


func CopyTo(new):
	new.instancedMoves.clear()
	for move in instancedMoves:
		var newInstance = MoveInstance.new()
		move.CopyTo(newInstance)
		new.instancedMoves.append(newInstance)
	
	super(new)
	
	new.gungeousArm.visible = gungeousArm.visible
	new.canPollMoves = true
	
	new.orlandoTrackedMoves = []
	for move in orlandoTrackedMoves:
		new.orlandoTrackedMoves.append(move)
	
	new.cachedHeadSpriteInfos = cachedHeadSpriteInfos
	new.cachedHeadSprites = cachedHeadSprites
	
	MoveManager.AdjustMoveLevels(new.instancedMoves)

func _physics_process(delta: float):
	if not stateInterruptable || infiniteTime:
		return
	timeLeftThisTurn -= delta
	timeLeftThisTurn = max(timeLeftThisTurn, 0)

func NonTimeSensitiveTick():
	super()
	UpdateHeadGraphic()

func Tick():
	#Tale from Down Under
	TFDUMacro()
	
	taleFromDownUnderExhaustion = max(0, taleFromDownUnderExhaustion - 1)
	taleFromDownUnderTicks = max(0, taleFromDownUnderTicks - 1)
	
	#Orlando Beats
	var shouldShowOrlando = orlandoEnabled && not isGhost
	$Shaders/Orlando.visible = shouldShowOrlando
	
	
	UpdateGreyHealth()
	MoveManager.AdjustMoveLevels(instancedMoves)
	if stateInterruptable && (canPollMoves || not isGhost): #Do move stuff here
		RefreshPickupMoves()
		canPollMoves = false
		timeLeftThisTurn = defaultTurnTime #awooga
	
	
	if stunTicks > 0:
		z_index = -5
	else:
		z_index = 5
	
	if queuedMoveInstance != null:
		lastQueuedMoveLocation = queuedMoveInstance.moveLocation
		lastQueuedMoveSlot = queuedMoveInstance.moveSlot
		
	
	UpdateExpression()
	
	super()

func HitBy(hitbox : HitboxData):
	
	if levelEnded:
		return
	#Block processing
	var myState = CurrentState()
	if myState.name == "Block":
		myState.currentTick = 0
		myState.currentRealTick = 0
		
		match hitbox.hurtState:
			"HurtGH":
				myState.animationName = "BlockH"
			"HurtGM":
				myState.animationName = "BlockM"
			"HurtGL":
				myState.animationName = "BlockL"
			"HurtA":
				myState.animationName = "BlockA"
		
		if IsOnGround() && myState.animationName == "BlockA" && velocity.y >= 0:
			myState.animationName = "BlockM"
		
		myState.IASA = max(1, myState.IASA - myState.powerModifier - 1)
		HP -= hitbox.damage * pow(0.5, myState.powerModifier + 2)
		velocity.x +=  hitbox.player.GetFacingInt() * hitbox.knockbackForce * 0.3
		flipX = hitbox.player.position.x > position.x
		SpawnParticle(preload("res://Strife/Particles/BlockSpark.tscn"), (position + hitbox.player.position + hitbox.position * Vector2(hitbox.player.GetFacingInt(), 1)) / 2.0, Vector2.RIGHT)
		PlaySound("Block")
		return
	
	if hitbox.damage > 0:
		angerCooldown = 120
	
	super(hitbox)

func ChangeState(newStateName, parameters = null, level : int = 0):
	
	#we can tell if a move has been selected, or if this is just a followup state, by checking if queuedMoveInstance is null or not.
	if orlandoEnabled && queuedMoveInstance != null:
		var usedMove = queuedMoveInstance.moveClassReference.name
		var alreadyUsed = orlandoTrackedMoves.has(usedMove)
		var levelBoost = orlandoLevel + 1
		if alreadyUsed:
			orlandoEnabled = false
			SpawnParticleRelative(preload("res://Strife/Particles/orlandoReverb.tscn"), Vector2.ZERO)
			PlaySound("OrlandoCrash2")
			if levelBoost >= 0:
				levelBoost += 1
			else:
				levelBoost -= 1
		else:
			orlandoTrackedMoves.append(usedMove)
		level += levelBoost
	
	super(newStateName, parameters, level)


func UpdateGreyHealth():
	if stunTicks <= 0:
		greyHealthWaitBeforeDecay -= 1
		if greyHealthWaitBeforeDecay <= 0:
			greyHealth -= greyHealthDecay
			greyHealthWaitBeforeDecay = 0
		
	else:
		greyHealthWaitBeforeDecay = greyHealthDefaultWait
	greyHealth = max(greyHealth, HP)
	pass

func UpdateHealthBar():
	pass

func GetIdealStowedRandomSize() -> int:
	return 100

func RefreshPickupMoves(): #Has awkward isGhost checks to prevent desyncing from the real game drawing random numbers.
	if battleInstance.runRealtime:
		return
	if ignoreMoveGeneration:
		return
	var pickupList = GetAvailablePickupMovePool()
	var totalWeight = GetTotalWeightFromPickupPool(pickupList)
	
	var numberMovesToGrab = floor(totalWeight) #base the number of moves we can get on the size of the move pool (using move weights)
	
	#ruined library boost
	for move in instancedMoves:
		if move.moveClassReference.name == "RuinedLib":
			numberMovesToGrab += 1
	
	
	numberMovesToGrab = clamp(numberMovesToGrab, 1, MoveManager.EquippedBackpack.MaxPickupSlots)
	
	if not isGhost:
		var movesToCleanup = []
		for move in instancedMoves:
			if move.moveLocation == MoveInstance.moveLocations.Pickups:
				movesToCleanup.append(move)
		
		for move in movesToCleanup:
			instancedMoves.erase(move)
		
		MoveManager.FillMissingSlotsWithBlanks(instancedMoves)
	
	var dummyArray : Array[MoveInstance] = []
	for i in numberMovesToGrab:
		var newMoveName = GetRandomMoveNameFromPool(pickupList, totalWeight)
		var newMove = MoveManager.MoveInstanceFromString(newMoveName)
		
		
		#move modifications here
		ApplyMoveRandomization(newMove)
		newMove.RecalculateMoveLevels(dummyArray) #empty array means it ignores neighbors
		
		newMove.remainingUses = newMove.maxUses
		
		if not isGhost:
			MoveManager.PutMoveAtPosition(newMove, MoveInstance.moveLocations.Pickups, i, instancedMoves)
		
		newMove.tags.append("Pickup")
		
		MoveManager.CleanupUnassignedMoves(instancedMoves)
	if not isGhost:
		battleInstance.loadedUI.RegenerateMoveObjects()

func GetRandomMoveNameFromPool(pickupList, totalWeight : float):
	
	var selectedMoveLocation = GetRandom() * totalWeight / 100.0
	var selectedMoveName = null
	var selectedPickupLocation = 0
	while true:
		if pickupList.size() <= selectedPickupLocation:
			push_warning("Uh oh this isn't supposed to appear. Looking beyond length of the pickup list!")
			return
		var nextKVP = pickupList[selectedPickupLocation]
		if selectedMoveLocation < nextKVP[1]:
			selectedMoveName = nextKVP[0]
			break
		else:
			selectedMoveLocation -= nextKVP[1]
		
		selectedPickupLocation += 1
	
	return selectedMoveName

func GetAvailablePickupMovePool() -> Array:
	var totalList = []
	for character in battleInstance.allCharacters:
		totalList.append_array(character.pickupMoveCache)
	
	for move in instancedMoves:
		if not move.moveLocation == MoveInstance.moveLocations.Inventory:
			continue
		var pickupVars = move.moveClassReference.pickupMoves.split("\n")
		var locationPointer = 0
		while locationPointer < pickupVars.size() - 1:
			var moveName = pickupVars[locationPointer]
			var weight = float(pickupVars[locationPointer + 1])
			
			totalList.append([moveName, weight])
			locationPointer += 2
		
	
	return totalList

func GetTotalWeightFromPickupPool(totalPool) -> float:
	var counter = 0
	for entry in totalPool:
		counter += entry[1] #Add the weight value of the entry.
	
	return counter

func ApplyMoveRandomization(targetMove : MoveInstance):
	#first, memento modifications
	var counter = 0
	
	
	var totalMementoWeight = 0
	for memento in MoveManager.MementoLibrary:
		var selectedMemento = MoveManager.MementoLibrary[memento]
		totalMementoWeight += selectedMemento.spawnWeight
	
	for mementoSlot in targetMove.slottedMementos:
		
		var shouldAddMemento = GetRandom() < 5
		
		if shouldAddMemento:
			var pickedMementoLocation = 0
			var selectedMementoByWeight = GetRandom() / 100 * totalMementoWeight
			
			while true:
				if MoveManager.MementoLibrary.size() <= pickedMementoLocation:
					push_warning("Uh oh this isn't supposed to appear. Looking beyond length of the memento list!")
					return
				var nextMemento = MoveManager.MementoLibrary.values()[pickedMementoLocation]
				if selectedMementoByWeight < nextMemento.spawnWeight:
					break
				else:
					selectedMementoByWeight -= nextMemento.spawnWeight
				pickedMementoLocation += 1
			
			targetMove.slottedMementos[counter] = MoveManager.MementoLibrary.values()[pickedMementoLocation]
		
		counter += 1
	
	#second, visual modifications
	for subArray in MoveManager.DecorationsLibrary:
		var variationsArray = MoveManager.DecorationsLibrary[subArray]
		var totalWeight = 0.0
		for variation in variationsArray:
			totalWeight += variation[1] #weight slot
		
		var targetWeight = GetRandom() / 100.0 * totalWeight
		var selectedAltLocation = 0
		while true:
			if variationsArray.size() <= selectedAltLocation:
				push_warning("Uh oh this isn't supposed to appear. Looking beyond length of the variations list!")
				return
			var nextKVP = variationsArray[selectedAltLocation]
			if targetWeight < nextKVP[1]:
				break
			else:
				targetWeight -= nextKVP[1]
			selectedAltLocation += 1
		
		targetMove.visualAlterations[subArray] = variationsArray[selectedAltLocation][0] #stores the name to make it resilient to additions to the array later on
	pass


func TFDUMacro():
	var myState = CurrentState()
	if taleFromDownUnderTicks > 0 && (not "isHurtState" in myState || not myState.isHurtState):
		taleFromDownUnderTicks = 0
	
	if taleFromDownUnderTicks > 0 && taleFromDownUnderExhaustion < maxTaleFromDownUnderExaustion / 2.0 && HP <= 0:
		ignoreMeleeHitboxes = true
		ignoreGrabHitboxes = true
		ignoreProjectileHitboxes = true
		var exhaustDegrade = (taleFromDownUnderExhaustion - maxTaleFromDownUnderExaustion/2.0) / maxTaleFromDownUnderExaustion * 2
		HP = MaxHP * pow(1.5, taleFromDownUnderLevel) * 0.2 * exhaustDegrade
		taleFromDownUnderTicks = 0
		taleFromDownUnderExhaustion = maxTaleFromDownUnderExaustion
		ChangeState("TFDU2")
		return true
	return false

var head
func UpdateHeadGraphic():
	if head == null:
		head = get_node("Sprite/Head")
	
	if head == null:
		return
	var currentSprite : Texture2D = sprite.get_sprite_frames().get_frame_texture(sprite.animation, sprite.frame)
	var spritePath = currentSprite.resource_path
	var hasCachedData = cachedHeadSpriteInfos.has(spritePath)
	if not hasCachedData:
		var infoPath = spritePath + ".info"
		var exists = FileAccess.file_exists(infoPath)
		if exists == null:
			cachedHeadSpriteInfos[spritePath] = null
		else:
			cachedHeadSpriteInfos[spritePath] = HeadTrackingInfo.Deserialize(FileAccess.get_file_as_bytes(infoPath))
	
	var locationData : HeadTrackingInfo = cachedHeadSpriteInfos[spritePath]
	
	if locationData == null:
		head.visible = false
		return null
	else:
		head.visible = true
	var usedExpression = currentExpression
	if not locationData.expressionOverride.is_empty():
		usedExpression = locationData.expressionOverride
	var targetFaceSpritePath = HeadTrackingBuilder.normalPath + "/Heads/Face/" + usedExpression +"/"
	var spriteName = "Faces"
	var backgroundAddition = 0 if not locationData.backgroundFacingSprite else 28
	spriteName += str(locationData.spriteMapLocation.x +( locationData.spriteMapLocation.y + 3) * 4 + 1 + backgroundAddition)
	var fullSpritePath = targetFaceSpritePath + spriteName + ".png"
	cachedHeadSprites = {} #---------------------------------------------------------
	if not cachedHeadSprites.has(currentSprite.resource_path):
		var asset : CompressedTexture2D = null
		
		var webOverride = OS.get_name() == "Web"
		if webOverride:
			asset = load(fullSpritePath)
		
		if not webOverride && FileAccess.file_exists(fullSpritePath):
			asset = load(fullSpritePath)
		if asset == null:
			push_warning("Failed to load asset at path '" + fullSpritePath +'.')
			return null
		cachedHeadSprites[currentSprite.resource_path] = asset
	var usedSprite = cachedHeadSprites[currentSprite.resource_path]
	head.texture = usedSprite
	head.position = locationData.position - currentSprite.get_size() / 2.0
	head.flip_h = locationData.reverseFromPlayerSprite
	
	if locationData.showBehindPlayer:
		head.z_index = -2
	else:
		head.z_index = 2
	return {"infoPath" : spritePath + ".info", "data" : locationData, "sprite" : fullSpritePath}

var angerCooldown = 0
func UpdateExpression(): #called as tick
	angerCooldown = max(angerCooldown- 1, 0)
	if angerCooldown > 0:
		currentExpression = "Angry"
		return
	
	
	currentExpression = "Neutral"

func DramaticFreezeFrameTick():
	super()
	if scenematicGlobalPauseMove:
		stateMachine.Tick()
		NonTimeSensitiveTick()

func ReleaseGrabbee():
	grabbee.sprite.rotation_degrees = 0
	super()

func Die():
	if TFDUMacro():
		return
	
	if levelEnded:
		return
	#var myState = CurrentState()
	if taleFromDownUnderTicks > 0:
		ChangeState("DeathUT")
	else:
		ChangeState("Death")
	levelEnded = true
	battleInstance.showHost.LoseLevel()

func WinLevel():
	super()
	levelEnded = true
	if not isGhost:
		battleInstance.loadedUI.isWinUI = true
		battleInstance.loadedUI.PlaySound("StageWin")
