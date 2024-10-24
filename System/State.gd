extends Node

class_name ObjectState

#Simulations.
var stateVariablesList = ["animationName", "loopAnimation", "animationLength", "ticksPerFrame", "duration", "endless", "currentTick", "currentRealTick", "fallbackState",
"continueOnWait", "onEnterParticles", "particleEffect", "particleTick", "enterForce", "appliedForce", "appliedForceTick", "holdFrames", "overrideFallSpeed", "fallSpeed",
"preservedMomentum", "overrideFrictionCoefficient", "overrideAirFrictionCoefficient", "useFrictionOverrides" ,"screenShakeTick", "screenShakeDuration", "screenShakeDirection",
"screenShakeStrength"]

@export_group("Physics")
@export var enterForce : Vector2
@export var appliedForce : Vector2
@export var appliedForceTick : int = -1

@export var preservedMomentum : Vector2 = Vector2.ONE

@export var overrideFallSpeed : bool = false
@export var fallSpeed : float = 0

@export var overrideFrictionCoefficient : Vector2 = Vector2.ZERO
@export var overrideAirFrictionCoefficient : Vector2 = Vector2.ZERO
@export var useFrictionOverrides : bool = false

@export_group("Animation")
@export var animationName : String
@export var loopAnimation : bool
@export var animationLength : int = 1
@export var ticksPerFrame : int = 4

@export var duration : int = 10 #how many frames the move is in total, hanging on the last frame if it exceeds animation time...
@export var endless : bool = false

var currentTick = 0
var currentRealTick = 0 #ignores looping

@export_group("Flow")
@export var fallbackState : String = "Default"
@export var continueOnWait : bool = true #If waiting, do not interrupt this state and instead continue

@export_group("Particles")
@export var onEnterParticles : PackedScene
@export var onEnterParticlesOffset : Vector2
@export var particleEffect : PackedScene
@export var particleOffset : Vector2
@export var particleTick : int

@export_group("Audio")
@export var onEnterSFX : AudioStream
@export var enterSFXVolume : float = 0
@export var SFX : AudioStream
@export var SFXVolume : float = 0
@export var SFXTick : int

@export_group("FFX")
@export var screenShakeTick : int = -1
@export var screenShakeDuration : int = 6
@export var screenShakeDirection : Vector2 = Vector2.ONE
@export var screenShakeStrength : float = 3

var EnterSFXPlayer : AudioStreamPlayer
var SFXPlayer : AudioStreamPlayer

var framesWithAFunction = []
var cachedHitboxes = []
var cachedHurtboxes

var targetsHit : Dictionary = {} #Used to stop the same hitbox group from hitting someone twice. key is the group, and value is an array with the IDs of hit targets

var host : GameObject #the character/object using the state.
var stateMachine
var parameters #passed in parameters. IE directional plot, button toggles, etc...

var holdFrames : int = 0 #Used for stuff like landing lag to extend animations arbitrarily

func CopyTo(new):
	for variableName in stateVariablesList:
		new[variableName] = self[variableName]
	
	new.parameters = parameters
	
	new.targetsHit = {}
	for key in targetsHit:
		new.targetsHit[key] = []
		
		for value in targetsHit[key]:
			new.targetsHit[key].append(value)
	#targetsHit.duplicate(true)

func Tick():
	if holdFrames > 0:
		holdFrames -= 1
		return
	
	if currentTick == screenShakeTick && not host.isGhost:
		host.ShakeScreen(screenShakeStrength, screenShakeDirection, screenShakeDuration)
	
	if currentTick == SFXTick:
		PlaySFX()
	
	if currentTick == appliedForceTick:
		host.velocity += Vector2(host.GetFacingInt(), 1) * appliedForce
	
	if currentTick == particleTick:
		if particleEffect != null:
			host.SpawnParticleRelative(particleEffect, Vector2.ZERO + particleOffset)
	
	if currentTick > animationLength * ticksPerFrame && loopAnimation:
		currentTick = 0
		targetsHit = {} #Resets the array on loop so hitboxes can re-hit when an animation has to repeat
	if framesWithAFunction.has(currentTick):
		call("Frame" + str(currentTick))
	
	for box in cachedHitboxes:
		var boxState = (box.startFrame <= currentTick) && (box.startFrame + box.duration > currentTick)
		
		if boxState == false && box.active && not targetsHit.keys().has(box.hitGroup):
			box.PlayWhiffSFX()
		
		box.active = boxState
		
		#looping hitbox behavior here: To simulate getting hit again, un-use the hitbox, essentially, by clearing the 'targets hit' group
		if box.loopHitbox:
			var isResetTick = (currentTick - box.startFrame) % box.ticksPerLoop == 0
			if isResetTick:
				if not targetsHit.keys().has(box.hitGroup):
					box.PlayWhiffSFX()
				targetsHit.erase(box.hitGroup)
		
	
	currentTick += 1
	currentRealTick += 1

var initializedBefore = false

func Init():
	if initializedBefore:
		return
	
	var myMethods = get_method_list()
	for method in myMethods:
		var methodName = method.name
		
		if methodName.begins_with("Frame"):
			var endName = methodName.replace("Frame", "")
			
			if not endName.is_valid_int():
				continue
			
			var parseToInt = int(endName)
			
			framesWithAFunction.append(parseToInt)
	
	cachedHitboxes = []
	var myChildren = get_children()
	for child in myChildren:
		#if child is Hitbox:
		if child is Hitbox:
			cachedHitboxes.append(child)
			child.player = host
			child.host = self
			child.Init()
	
	cachedHurtboxes = []
	for child in myChildren:
		if child is Hurtbox:
			cachedHurtboxes.append(child)
	
	if cachedHurtboxes.size() <= 0:
		cachedHurtboxes = null
	
	if not host.isGhost:
		if SFX != null:
			SFXPlayer = AudioStreamPlayer.new()
			SFXPlayer.stream = SFX
			SFXPlayer.volume_db = SFXVolume
			add_child(SFXPlayer)
		
		if onEnterSFX != null:
			EnterSFXPlayer = AudioStreamPlayer.new()
			EnterSFXPlayer.stream = onEnterSFX
			EnterSFXPlayer.volume_db = enterSFXVolume
			add_child(EnterSFXPlayer)
	
	initializedBefore = true

func OnEnter():
	targetsHit = {}
	PlayEnterSFX()
	if onEnterParticles != null:
		host.SpawnParticleRelative(onEnterParticles, Vector2.ZERO + onEnterParticlesOffset)
	
	host.velocity *= preservedMomentum
	
	host.velocity += Vector2(host.GetFacingInt(), 1) * enterForce
	
	for box in cachedHitboxes:
		box.active = false
	pass

func OnExit():
	pass

func GetHurtboxes():
	return cachedHurtboxes

func PlayEnterSFX():
	if EnterSFXPlayer == null || host.isGhost:
		return
	
	EnterSFXPlayer.pitch_scale = RNGManager.GrabUnseededFloat(0.95, 1.08)
	EnterSFXPlayer.play()

func PlaySFX():
	if SFXPlayer == null || host.isGhost:
		return
	SFXPlayer.pitch_scale = RNGManager.GrabUnseededFloat(0.95, 1.08)
	SFXPlayer.play()

func OnHit(someone : GameObject, usedHitbox : HitboxData):
	var usedAngle = atan2(usedHitbox.knockbackDirection.y, usedHitbox.knockbackDirection.x)
	if usedHitbox.knockbackAwayFromCenter:
		var posDiff = someone.global_position - usedHitbox.global_position
		usedAngle = atan2(posDiff.y, posDiff.x)
	if not usedHitbox.autoAdjustParticleAngle:
		usedAngle = 0
	var particlePrefab = null
	if usedHitbox.particleEffect != null:
		particlePrefab = usedHitbox.particleEffect
	elif usedHitbox.allowFallbackParticles && host.defaultHitspark != null:
		particlePrefab = host.defaultHitspark
	
	if particlePrefab == null:
		return
	var targetPos = lerp(usedHitbox.particleOffset + usedHitbox.position, (host.position - someone.position) * -1 * Vector2(host.GetFacingInt(), 1), 0.65)
	var hitSpark = host.SpawnParticleRelative(particlePrefab, targetPos)
	hitSpark.rotation = usedAngle

func Restart(performOnEnter : bool = true):
	currentTick = 0
	currentRealTick = 0
	if performOnEnter:
		OnEnter()
