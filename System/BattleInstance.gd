extends Node2D
class_name BattleInstance
#Important metadata.
var main : Main

var showHost : Showhost

var readFromReplay : bool = false

var isGhost : bool = false
var copiedGame : BattleInstance
var currentTick : int = 0
var nextAvailableObjectID : int = 0 #used for object tracking.

var realTimePassed : float = 0 #time after accounting for effects like timestop (where some characters might still be able to move).

var gameWonTimer : float = 0 #so that game win state can be forced to loop a lil faster due to it slowing down

@onready var particles = $Particles
@onready var camera = $Camera2D

var RNG = RNGManager.new()
#Caches
var allObjects : Array[GameObject] = [] #only ever add/remove characters from this, then refresh caches to update everything else
var allCharacters : Array[CharacterObject] = []

var focusedPlayer : CharacterObject

#Motes
var moteList : Array[Mote] = []

#Graphical stuff
var teamMaterials : Dictionary = {} #Should exist in base instance only, as preview should just have every individual object copy materials over
var universalHitstop : int = 0
#UI
var loadedUI
var hideDisplay = false

const frameLength = 1.0 / 60.0

var tempTimer = 0.0
var wasPausedLastTick = false

var canThrowFreezeframe = false
var freezeFrameNextTick = false

var ignorePlayerInputs = false
var runRealtime = false

var gameSpeed = 1.0
var paused = false
func _physics_process(delta):
	
	if isGhost && copiedGame.readFromReplay == false && copiedGame.wasPausedLastTick:
		visible = true
	elif isGhost:
		visible = false
	
	var levelEnded = showHost != null && showHost.levelEnded
	
	if levelEnded:
		gameWonTimer += delta
		runRealtime = true
	
	paused = true
	
	
	if runRealtime || levelEnded || readFromReplay:
		paused = false
	
	if isGhost && (currentTick > copiedGame.currentTick + 120 || gameWonTimer >= 2.0) && copiedGame != null && copiedGame.paused && not readFromReplay:
		RestartPreview()
	
	tempTimer += delta * gameSpeed
	
	while tempTimer > frameLength:
		tempTimer -= frameLength
		
		if IsCurrentlyPlaying() || isGhost || runRealtime:
			paused = false
			TickGame()
			ResumeParticles()
	
	UpdateQueuedActions()
	
	if MoveIsSelected() && not runRealtime && not levelEnded: #The runRealtime check prevents the game from running double speed in the intro or something... yeah. kinda fucked up
		#The player selected a move, so add it to the log!
		if not readFromReplay:
			ReplayManager.LogMove(currentTick, loadedUI.selectedMove.moveLocation, loadedUI.selectedMove.moveSlot, loadedUI.GetFlip(),loadedUI.GetData())
		
		loadedUI.Clear()
		TickGame()
		paused = false
		ResumeParticles()
	
	if not runRealtime && focusedPlayer != null && focusedPlayer.CanAct() && not wasPausedLastTick && not isGhost && not levelEnded:
		PauseParticles()
		loadedUI.PlaySound("TurnStart")
	
	if not isGhost && not wasPausedLastTick && paused && loadedUI != null && not levelEnded:
		loadedUI.RefreshMoveButtons()
	
	if loadedUI != null:
		loadedUI.SetDesiredVisibility(not hideDisplay && not levelEnded)
		#loadedUI.visible = not hideDisplay
	
	wasPausedLastTick = paused

func _init():
	RNG.currentSeed = randi_range(-2147483647, 2147483647)

func MoveIsSelected() -> bool:
	return loadedUI != null && ((loadedUI.readyToSend && loadedUI.selectedMove != null) || readFromReplay) && focusedPlayer.CanAct()

func IsCurrentlyPlaying():
	return focusedPlayer != null && not focusedPlayer.CanAct()

func UpdateQueuedActions():
	var readFromInput = loadedUI != null && focusedPlayer != null && not readFromReplay
	
	if readFromInput:
		if loadedUI.selectedMove != null:
			var move = loadedUI.selectedMove
			if not move.moveClassReference.IsUsable(focusedPlayer):
				move = MoveManager.GetMoveAtPosition(MoveInstance.moveLocations.Fixed, 0, focusedPlayer.instancedMoves) #The wait move.
			#var targetstate = move.moveClassReference.GetUsedState(focusedPlayer) #move.moveClassReference.groundedState if focusedPlayer.IsOnGround() else move.moveClassReference.aerialState
			focusedPlayer.queuedParams = loadedUI.GetData()
			focusedPlayer.queuedFlip = loadedUI.GetFlip()
			focusedPlayer.queuedMoveInstance = move #move instance needs to be from the ghost, not from the real player
		else:
			focusedPlayer.queuedMoveInstance = null
	
	if readFromReplay:
		var moveRelocationsThisFrame = ReplayManager.FetchRelocatingMoveData(currentTick)
		if moveRelocationsThisFrame != null:
			for relocation in moveRelocationsThisFrame:
				MoveManager.RelocateMove(currentTick, relocation[0], relocation[1], relocation[2], relocation[3], focusedPlayer.instancedMoves, false)
		
		
		var inputThisFrame = ReplayManager.FetchMoveData(currentTick)
		
		var endReplay = currentTick > ReplayManager.FinalFrameOfReplay() && focusedPlayer.stateInterruptable
		
		if endReplay:
			readFromReplay = false
		#	main.previewScene.RestartPreview()
		
		if inputThisFrame != null && inputThisFrame.has("moveLocation"):
			var usedMove = MoveManager.GetMoveAtPosition(inputThisFrame["moveLocation"], inputThisFrame["moveSlot"], focusedPlayer.instancedMoves)
			focusedPlayer.queuedMoveInstance = usedMove
			focusedPlayer.queuedParams = inputThisFrame["extraData"]
			focusedPlayer.queuedFlip = inputThisFrame["flip"]


func Setup():
	if not isGhost:
		focusedPlayer = SpawnObject(load("res://Strife/StrifeScene.tscn"))
		MoveManager.LoadMovesetFromNames(focusedPlayer.instancedMoves, ["The Line"], ["Ascend", "Escapade"])
		#MoveManager.LoadMovesetFromNames(focusedPlayer.instancedMoves, [], [])
		MoveManager.AdjustMoveLevels(focusedPlayer.instancedMoves)
		for move in focusedPlayer.instancedMoves:
			move.remainingUses = move.maxUses
		
		focusedPlayer.material = teamMaterials[0]
#		for i in 1:
#			
#			var newObj = SpawnObject(preload("res://Enemies/Icon of Conquest/Icon of Conquest.tscn"))
#			newObj.position +=  - 90 * i * Vector2.RIGHT #+ Vector2.RIGHT * 250
#			newObj.team = 1#(i % 2) + 1
#			newObj.material = teamMaterials[newObj.team]
		
		
#		for i in 0:
#			
#			var newObj = SpawnObject(preload("res://Enemies/Unlocking Runoff/UnlockingRunoff.tscn"))#
#			newObj.position +=  - 70 * i * Vector2.RIGHT + Vector2.RIGHT * 150
#			newObj.team = 1#(i % 2) + 1
#			newObj.material = teamMaterials[newObj.team]
		
#		for i in 0:
#			
#			var newObj = SpawnObject(preload("res://Enemies/Acrophilia/Acrophilia.tscn"))#
#			newObj.position +=  - 120 * i * Vector2.RIGHT + Vector2.RIGHT * 250 + Vector2.UP * 10 * (20 + i)
#			newObj.team = 1#(i % 2) + 1
#			newObj.material = teamMaterials[newObj.team]
		
		if loadedUI == null:
			loadedUI = preload("res://UI/DefaultControlScheme/StrifeUI.tscn").instantiate()
			get_parent().get_parent().get_parent().find_child("UI", false).add_child(loadedUI)
		
		loadedUI.followedPlayer = focusedPlayer
		loadedUI.Init()
		
		showHost = LevelManager.QueuedShowhost.duplicate()
		showHost.battleInstance = self
		add_child(showHost)
		showHost.Initialize()
	
	TickGame()
	
	if not isGhost:
		showHost.SetupGame()
		focusedPlayer.stateInterruptable = true

func RefreshCaches():
	var toRemove = []
	for object in allObjects:
		if object.disabled:
			toRemove.append(object)
	
	for object in toRemove:
		allObjects.erase(object)
		RecycleObject(object)
	
	allCharacters = []
	for object in allObjects:
		if object.disabled:
			continue
		if object is CharacterObject:
			allCharacters.append(object)
	
	if showHost != null:
		showHost.RefreshCaches()

func TickGame():
	if universalHitstop > 0:
		universalHitstop -= 1
		
		for object in allObjects:
			object.DramaticFreezeFrameTick()
		return
	
	currentTick += 1
	
	if showHost != null:
		if showHost.levelEnded:
			gameSpeed *= 0.96
			if gameSpeed <= 0.1:
				gameSpeed = 0
		showHost.Tick()
	
	#mote update here
	if not isGhost:
		main.cameraJostle = Vector2.ZERO
	
	UpdateMotes()
	
	#physics update here
	for object in allObjects:
		if object.hitstopTicks > 0:
			object.hitstopTicks -= 1
			object.NonTimeSensitiveTick()
		else:
			object.Tick()
	
	#hitbox processing here
	for object in allObjects:
		if object.disabled:
			continue
		var hitboxes = object.GetHitboxes()
		
		if hitboxes.size() <= 0:
			continue
		
		var validTargets = []
		for other in allObjects:
			if other.team != object.team:
				validTargets.append(other)
		
		var attackerHitDictionary = object.CurrentState().targetsHit
		for target in validTargets:
			if target.disabled:
				continue
			if (target.ignoreMeleeHitboxes && object is CharacterObject) || (target.ignoreProjectileHitboxes && object.treatAsProjectile):
				continue
			
			var hurtboxes = target.GetHurtboxes()
			var stateHurtboxes = target.CurrentState().GetHurtboxes()
			if stateHurtboxes != null:
				hurtboxes = stateHurtboxes
			var connectingBoxes = []
			for hitbox in hitboxes:
				if hitbox.isGrabBox && target.ignoreGrabHitboxes:
					continue
				
				if hitbox.isGrabHit && target.grabber != object:
					continue
				
				var hasKey = attackerHitDictionary.has(hitbox.hitGroup)
				if hasKey == true:
					if attackerHitDictionary[hitbox.hitGroup].has(target.id):
						continue
				for hurtbox in hurtboxes:
					var hitrect = Rect2(object.global_position - hitbox.bounds * Vector2(0.5, 0.5) + hitbox.position * Vector2(object.GetFacingInt() * 2, 1), hitbox.bounds)
					var hurtrect = Rect2(2 * hurtbox.position * Vector2(target.GetFacingInt(), 1) + target.global_position - hurtbox.bounds * 0.5, hurtbox.bounds)
					if hurtrect.intersects(hitrect) || hitbox.isGrabHit:
						connectingBoxes.append(hitbox)
			
			if connectingBoxes.size() <= 0:
				continue
			
			var highest = connectingBoxes[0]
			
			for box in connectingBoxes:
				if box.hitPriority >= highest.hitPriority:
					highest = box
			
			target.HitBy(highest.GetData())
			
			highest.PlayHitSFX()
			
			if not attackerHitDictionary.has(highest.hitGroup):
				attackerHitDictionary[highest.hitGroup] = []
			attackerHitDictionary[highest.hitGroup].append(target.id)
	
	for object in allObjects:
		object.PostHurtboxUpdate()
	
	for particle in particles.get_children():
		particle.Tick(frameLength)
	
	realTimePassed += frameLength
	
	if freezeFrameNextTick:
		main.ApplyFreezeFrame()
		freezeFrameNextTick = false
	if isGhost && canThrowFreezeframe && focusedPlayer != null && focusedPlayer.stateInterruptable && copiedGame.loadedUI.selectedMove != null:
		canThrowFreezeframe = false
		freezeFrameNextTick = true
	#cleanup here
	
	#... don't cleanup as a ghost so we can reuse stuff
	if isGhost:
		return
	
	var toClear = []
	for object in allObjects:
		if object.disabled:
			toClear.append(object)
	
	for object in toClear:
		allObjects.erase(object)
		RecycleObject(object)
		#object.queue_free()



func SpawnObject(scene, recyclable : bool = false):
	var created = null
	
	if scene is PackedScene:
		created = scene.instantiate()
		created.objectOrigin = "packedScene"
	else:
		if main.recycledFoesCache.has(scene.internalName) && main.recycledFoesCache[scene.internalName].size() > 0:
			created = main.recycledFoesCache[scene.internalName].pop_back()
			showHost.InstancedTemplateFoes[scene.internalName].CopyTo(created)
			created.objectOrigin = "recycled"
		else:
			created = scene.duplicate()
			created.objectOrigin = "scene"
	
	created.id = nextAvailableObjectID
	nextAvailableObjectID += 1
	
	allObjects.append(created)
	add_child(created)
	
	created.battleInstance = self
	RefreshCaches()
	created.isGhost = isGhost
	
	if created is CharacterObject:
		created.recyclable = recyclable
	return created

func RestartPreview():
	if copiedGame == null:
		push_warning("No game to use for preview.")
		return

	tempTimer = 0
	gameWonTimer = 0
	main = copiedGame.main
	
	main.ClearFreezeFrame()
	canThrowFreezeframe = true
	freezeFrameNextTick = false
	
	currentTick = copiedGame.currentTick
	realTimePassed = copiedGame.realTimePassed
	
	RNG.currentSeed = copiedGame.RNG.currentSeed
	RNG.currentSeedOffset = copiedGame.RNG.currentSeedOffset
	
	nextAvailableObjectID = copiedGame.nextAvailableObjectID
	
	teamMaterials = copiedGame.teamMaterials
	
	var allParticles = particles.get_children()
	for particle in allParticles:
		particle.queue_free()
	
	
	#Relating to the showhost.
	if showHost != null:
		showHost.queue_free()
	showHost = copiedGame.showHost.duplicate()
	showHost.battleInstance = self
	add_child(showHost)
	
	ignorePlayerInputs = copiedGame.ignorePlayerInputs
	runRealtime = copiedGame.runRealtime
	gameSpeed = copiedGame.gameSpeed
	
	RefreshCaches()
	
	#Generating objects is the slowest part of restarting a replay. As such, if we can, recycle old objects from the game instead of deleting and respawning them.
	var objectsToFree = allObjects.duplicate()
	var objectsToDuplicate = copiedGame.allObjects.duplicate()
	var recyclingPairs = {}
	for toFree in objectsToFree:
		for possiblePair in copiedGame.allObjects:
			if possiblePair.id == toFree.id:
				recyclingPairs[toFree] = possiblePair
				objectsToDuplicate.erase(possiblePair)
				break
	
	#I COULD just delete everything and make it from scratch. But this below code is SO much faster.
	for key in recyclingPairs.keys():
		objectsToFree.erase(key)
	
	for object in objectsToFree:
		RecycleObject(object)
		allObjects.erase(object)
	
	for key in recyclingPairs:
		var value = recyclingPairs[key]
		if key == null:
			objectsToDuplicate.append(value)
			continue
		value.CopyTo(key)
	
	#=========================================================
	for object in objectsToDuplicate:
		if object.disabled:
			continue
		
		var new = object.duplicate(7) #the 4 is a flag used to suppress errors that aren't important by specifying what we need copied.
		new.battleInstance = self
		allObjects.append(new)
		add_child(new)
		object.CopyTo(new)
	
	
	for object in allObjects:
		if is_instance_valid(object) && object.id == copiedGame.focusedPlayer.id:
			focusedPlayer = object
			break
		
	
	ResumeParticles()
	
	RefreshCaches()
	
	copiedGame.showHost.CopyTo(showHost)
	showHost.Initialize()
	
	copiedGame.loadedUI.followedPreviewPlayer = focusedPlayer
	
	if not copiedGame.readFromReplay:
		copiedGame.loadedUI.PlaySound("Thump")

func SpawnParticle(particle : PackedScene, pposition : Vector2, direction : Vector2):
	var newParticle = particle.instantiate()
	
	newParticle.battleInstance = self
	newParticle.position = pposition
	
	var usedDir = direction
	if direction.x < 0:
		newParticle.scale = Vector2(-1,1)
		usedDir *= -1
	
	newParticle.rotation = atan2(usedDir.y, usedDir.x)
	
	particles.add_child(newParticle)
	
	newParticle.Start()
	
	if isGhost:
		newParticle.modulate.a *= 0.5
	
	return newParticle

func RecycleObject(target):
	target.id = -1
	
	if not "recyclable" in target || not target.recyclable || GameLoader.forceDisableObjectRecycling:
		target.queue_free()
		return
	
	remove_child(target)
	if not main.recycledFoesCache.has(target.internalName):
		main.recycledFoesCache[target.internalName] = []
	
	main.recycledFoesCache[target.internalName].append(target)

func PauseParticles():
	for child in particles.get_children():
		child.Stop()

func ResumeParticles():
	for child in particles.get_children():
		child.Resume()

func GetRandom(minn, maxn) -> float:
	return RNG.GrabSeededFloat(minn, maxn)

func FindObjectOfID(id : int) -> GameObject:
	for obj in allObjects:
		if obj.id == id:
			return obj
	return null

func AddMote(newMote : BattleInstanceMote):
	newMote.assignedInstance = self
	moteList.append(newMote)

func UpdateMotes():
	var toRemove = []
	for mote in moteList:
		if mote.ignoreHitstop:
			mote.Tick()
			if mote.ticksLeft <= 0:
				toRemove.append(mote)
	
	for trash in toRemove:
		moteList.erase(trash)

func FindCharacterOfID(id : int) -> GameObject:
	for obj in allCharacters:
		if obj.id == id:
			return obj
	return null
