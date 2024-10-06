extends GameObject

class_name CharacterObject

#Related to game behavior
@export var internalName = "Name Me Something Unique"
@export var difficultyWeight : float = 1.0
@export var spawnWeight : float = 1.0
@export var spawnHeight : float = 0.0
@export var spawnHeightVariation : float = 0.0
#Battle related.
@export var MaxHP = 100.0
var HP = 100.0

@export var MaxSP = 100.0 #Stress points. Basically, enemies get stressed over time, or my certain moves. This can make them more aggressive instead of defensive, but is meant to debuff them.
var SP = 100.0

#Decor related
@export var IgnoreYShake = false #makes it ignore vibrations in the y direction

#State flow variables below

var wasAirborneLastFrame : bool = false
var stateInterruptable : bool = true

var stunTicks : int = 0
var lateHitcancelTicks : int = -1

#Simulation vars.
var queuedMoveInstance : MoveInstance
var queuedParams
var queuedFlip = false
var dueHurtstate #used over the span of a single frame, so dont ever worry about copying this. Used so being hit doesnt cancel a hitbox on the same frame, IE trading blows

var stowedRandomFloats = [] #Used so that randomness is more controlled and not just changing every frame based on what move the player does...

var recyclable : bool = false #used to cache and reuse foes
#HP display
var HPBar
var HPDisplay

#Variable related to the move pickup functionality.
@export_multiline var pickupMoves : String = "" #Use line break to separate move names from the pickup weight
var pickupMoveCache : Array[Array] = [[]] #for each internal array, first value is the move name, second is a float with move weight

func _init():
	stateVariablesList.append_array(["stunTicks", "wasAirborneLastFrame", "stateInterruptable", "lateHitcancelTicks", "HP", "MaxHP", "SP", "MaxSP",
	"queuedParams", "queuedFlip", "recyclable"])

func _ready() -> void:
	HPBar = get_node_or_null("HealthBar")
	HPDisplay = get_node_or_null("HealthBar/HPDisplay")
	super()

func Initialize():
	HP = MaxHP
	SP = MaxSP
	
	pickupMoveCache.clear()
	var pickupVars = pickupMoves.split("\n")
	var locationPointer = 0
	while locationPointer < pickupVars.size() - 1:
		var moveName = pickupVars[locationPointer]
		var weight = float(pickupVars[locationPointer + 1])
		
		pickupMoveCache.append([moveName, weight])
		locationPointer += 2
	
	super()

func Tick():
	var desiredRandomBufferSize = GetIdealStowedRandomSize()
	while  stowedRandomFloats.size() < desiredRandomBufferSize:
		stowedRandomFloats.append(battleInstance.GetRandom(0.0, 100.0))
	
	super()
	
	var grounded = IsOnGround()
	
	if wasAirborneLastFrame && IsOnGround():
		if stateMachine.currentState.isHurtState:
			ChangeState("HurtOTG")
		elif "canLandCancel" in stateMachine.currentState && stateMachine.currentState.canLandCancel:
			var lag = stateMachine.currentState.landCancelLag
			ChangeState("Landing")
			CurrentState().holdFrames = lag
			stateInterruptable = false
		
		
	
	wasAirborneLastFrame = not grounded
	
	if queuedMoveInstance != null:
		flipX = queuedFlip
		var moveLevel = 0
		
		#this queued move instance will be from our original self, so instead, since we may be the ghost, make sure it's our own move.
		
		queuedMoveInstance = MoveManager.GetMoveAtPosition(queuedMoveInstance.moveLocation, queuedMoveInstance.moveSlot, get("instancedMoves"))
		
		moveLevel = queuedMoveInstance.moveLevel
		if not queuedMoveInstance.infiniteUses:
			queuedMoveInstance.remainingUses -= 1
		if queuedMoveInstance.remainingUses <= 0 && not queuedMoveInstance.infiniteUses:
			moveLevel += 1
			MoveManager.BreakMoveAtPosition(queuedMoveInstance.moveLocation, queuedMoveInstance.moveSlot, get("instancedMoves")   )
			if not isGhost:
				battleInstance.loadedUI.RegenerateMoveObjects()
				
				battleInstance.universalHitstop += 3
				PlaySound("MoveBreak")
			SpawnParticleRelative(preload("res://Particles/GenericFFX/MoveBreak.tscn"), Vector2.ZERO)
		ChangeState(queuedMoveInstance.moveClassReference.GetUsedState(self), queuedParams, moveLevel)
		
		queuedMoveInstance = null
		queuedParams = null
		stateInterruptable = false
	
	var myState = CurrentState()
	
	if myState is CharacterState && not myState.isHurtState:
		stunTicks = 0
	
	if stunTicks > 0:
		lateHitcancelTicks = -1
		stunTicks -= 1
	
	if lateHitcancelTicks > 0 && hitstopTicks <= 0:
		lateHitcancelTicks -= 1
		if lateHitcancelTicks == 0:
			lateHitcancelTicks = -1
			stateInterruptable = true
	
	if stunTicks <=0 && HP <= 0 && hitstopTicks <= 0:
		Die()

func NonTimeSensitiveTick():
	super()
	UpdateHealthBar()

func UpdateHealthBar():
	if HPBar == null:
		return
	
	HPDisplay.max_value = MaxHP
	HPDisplay.value = HP
	
	if HP == MaxHP:
		HPBar.visible = false
	else:
		HPBar.visible = true

func CopyTo(new):
	super(new)
	new.queuedParams = queuedParams
	new.queuedFlip = queuedFlip
	new.stowedRandomFloats = stowedRandomFloats.duplicate()
	
	if queuedMoveInstance != null:
		new.queuedMoveInstance = MoveManager.GetMoveAtPosition(queuedMoveInstance.moveLocation, queuedMoveInstance.moveSlot, get("instancedMoves"))
	
	new.UpdateHealthBar()

func ChangeState(newStateName, parameters = null, level : int = 0):
	var state = CurrentState()
	if state == null:
		super(newStateName, parameters, level)
		return
	
	stateInterruptable = false
	
	var willInterruptOnNextStart = false
	if state is CharacterState && state.interruptOnExit:
		willInterruptOnNextStart = true
	
	super(newStateName, parameters, level)
	if willInterruptOnNextStart:
		stateInterruptable = true
	
	lateHitcancelTicks = -1

func HitBy(hitboxData : HitboxData):
	queuedFlip = null
	queuedParams = null
	queuedMoveInstance = null
	HP -= hitboxData.damage
	SP -= 0.5 * hitboxData.damage / MaxHP
	super(hitboxData)
	if IsOnGround():
		dueHurtstate = hitboxData.hurtState
	else:
		dueHurtstate = hitboxData.hurtStateAir
	#return
	stunTicks = hitboxData.stunTicks
	hitstopTicks = hitboxData.hitstopTicks
	stateInterruptable = false

func HitCallback(_whoWasHit : GameObject, finalHitboxData : HitboxData):
	if finalHitboxData.hitcancellable:
		var delay = finalHitboxData.hitcancelDelay
		if delay == 0:
			stateInterruptable = true
		else:
			lateHitcancelTicks = delay
	super(_whoWasHit, finalHitboxData)

func PostHurtboxUpdate():
	if dueHurtstate != null:
		ChangeState(dueHurtstate)
		dueHurtstate = null
		stateInterruptable = false

func GetEnemiesSortedByDistance():
	var enemies = battleInstance.allCharacters.duplicate()
	var toRemove = []
	for enemy in enemies:
		if enemy.team == team:
			toRemove.append(enemy)
			#enemies.erase(enemy)
	for remove in toRemove:
		enemies.erase(remove)
	
	if enemies.size() <= 0:
		return []
	
	enemies.sort_custom(func(a,b): return (a.position - position).length() < (b.position - position).length())
	return enemies

func GetStressPercent() -> float:
	return 1.0 - clamp(SP / MaxSP, 0, 1)

func GetIdealStowedRandomSize() -> int: #lower numbers make enemies more unpredictable in predictions, but it also entirely depends on how often they make random calls...
	return 2

func GetRandom():
	if stowedRandomFloats.size() > 0:
		var grabbed = stowedRandomFloats[0]
		stowedRandomFloats.remove_at(0)
		return grabbed
	var output = battleInstance.GetRandom(0.0, 100.0)
	return output

func Die():
	if disabled:
		return
	
	battleInstance.showHost.currentFoeKills += 1
	disabled = true
	SpawnParticleRelative(preload("res://Particles/GenericFFX/DeathBlast.tscn"), Vector2.ZERO)
	battleInstance.RefreshCaches()

func WinLevel():
	pass

func CanAct() -> bool:
	return stateInterruptable && hitstopTicks <= 0
