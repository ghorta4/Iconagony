extends Node2D

class_name GameObject

#testing
var objectOrigin = "unset"

@export_group("Simulation")
@export_multiline var stateVariables : String = ""
var stateVariablesList = ["fallSpeed", "groundFrictionCoefficient", "airFrictionCoefficient", "flipX", "velocity", "position", "team", "id", "speedLimits", "ignoreMeleeHitboxes",
"ignoreProjectileHitboxes", "ignoreGrabHitboxes", "treatAsProjectile", "hitstopTicks", "disabled", "visible", "material", "defaultHitspark"]

var id : int = -1

var isGhost : bool = false
var disabled : bool = false #If true, do not copy over to predictions. Also queue for cleanup.
var moteList : Array = []

var isTemplate : bool = false #used for showhost management.

@export_group("Physics")
#position is built in
var velocity : Vector2
@export var fallSpeed : float = 988
@export var groundFrictionCoefficient : Vector2 = Vector2(0.05, 0.01)#How fast an object slows down
@export var airFrictionCoefficient : Vector2 = Vector2(0.05, 0.01)#How fast an object slows down

@export var speedLimits : Vector2 = Vector2(1000, 1000)

var flipX : bool #facing left/right

@export_group("Gameplay")
var team = 0

var hitstopTicks = 0
#Visual Refences
@onready var sprite : AnimatedSprite2D = $Sprite

#Important references regarding states
@onready var stateMachine = $StateMachine

#Preset important boxes, like collision and hurtbox
@onready var movementBox = $MovementBox
@onready var hurtBox = $HurtBox

#Immunities
@export var ignoreMeleeHitboxes : bool = false
@export var ignoreProjectileHitboxes : bool = false
@export var ignoreGrabHitboxes : bool = false
@export var treatAsProjectile : bool = false

@export_group("FFX")
@export var defaultHitspark : PackedScene


@onready var Sounds : Node2D = $Sounds

var hitboxDataDue = [] #all hitboxes that need to be recieved 

var battleInstance : BattleInstance
#Simulation
#----------------------
func CopyTo(new):
	if new.sprite != null && sprite != null:
		new.sprite.rotation = sprite.rotation
	
	for varName in stateVariablesList:
		if get(varName) is Vector2:
			var old = self[varName]
			new.set(varName, Vector2(old))
			continue
		
		new[varName] = self[varName]
	
	new.isGhost = true
	
	new.moteList = []
	for mote in moteList:
		var newMote = mote.MyClass().new()
		mote.CopyTo(newMote)
		newMote.assignedObject = new
		new.moteList.append(newMote)
	
	new.stateMachine.host = new
	
	if stateMachine != null:
		stateMachine.CopyTo(new.stateMachine)
	else:
		new.ChangeState("Default")

#Motes
#----------------------

func AddMote(mote : Mote):
	mote.assignedObject = self
	moteList.append(mote)

#Physics
#----------------------
const FPS = 60.0
const frameLength = 1.0 / FPS

func _ready():
	Initialize()

func Initialize():
	var allNewVariables = stateVariables.split("\n")
	for v in allNewVariables:
		if v.is_empty():
			continue
		stateVariablesList.append(v)
	
	if not isTemplate:
		stateMachine.host = self
		stateMachine.Initialize()

func Tick():
	if disabled:
		visible = false
		return
	
	PositionPhysicsUpdate()
	stateMachine.Tick()
	NonTimeSensitiveTick()

func NonTimeSensitiveTick():
	sprite.position = Vector2.ZERO #Resets position for the sake of sprite shaking.
	sprite.scale = Vector2(GetFacingInt(), 1)
	UpdateDisplayedFrame()
	
	var toRemove = []
	for mote in moteList:
		if mote.ignoreHitstop || hitstopTicks <= 0:
			mote.Tick()
			if mote.ticksLeft <= 0:
				toRemove.append(mote)
	
	for trash in toRemove:
		moteList.erase(trash)

func DramaticFreezeFrameTick():
	pass

func PositionPhysicsUpdate():
	
	var usedFallspeed = fallSpeed
	
	var currentState = CurrentState()
	if currentState != null:
		if currentState.overrideFallSpeed:
			usedFallspeed = currentState.fallSpeed
	
	if not IsOnGround():
		velocity += Vector2.DOWN * usedFallspeed * frameLength
	
	if IsOnGround():
		if currentState.useFrictionOverrides:
			velocity *= Vector2.ONE - currentState.overrideFrictionCoefficient
		else:
			velocity *= Vector2.ONE - groundFrictionCoefficient
	else:
		if currentState.useFrictionOverrides:
			velocity *= Vector2.ONE - currentState.overrideAirFrictionCoefficient
		else:
			velocity *= Vector2.ONE - airFrictionCoefficient
	
	position += velocity * frameLength
	
	GroundCollision()
	
	if abs(velocity.x) > speedLimits.x:
		velocity.x = sign(velocity.x) * speedLimits.x
	if abs(velocity.y) > speedLimits.y:
		velocity.y = sign(velocity.y) * speedLimits.y
	pass

func GroundCollision():
	if GetY() > 0:
		position.y = -GetLowestY()
		velocity.y = 0

func IsOnGround():
	return GetY() >= 0

func GetLowestY():
	return movementBox.bounds.y/2.0 + movementBox.position.y * 2

func GetY():
	return position.y + GetLowestY()

#Directionality
#----------------------

func GetFacingInt():
	return -1 if flipX else 1

func SetFacing(dir : int):
	flipX = dir < 0
#States
#----------------------

func ChangeState(newStateName, parameters = null, moveLevel : int = 0):
	stateMachine.ChangeState(newStateName, parameters, moveLevel)

func CurrentState() -> ObjectState:
	return stateMachine.currentState

func UpdateDisplayedFrame():
	var animName = stateMachine.currentState.animationName
	sprite.animation = animName
	
	var currentFrame = stateMachine.GetCurrentFrame()
	sprite.frame = currentFrame


#Combat
#----------------------
func GetHitboxes():
	return stateMachine.GetHitboxes()

func GetHurtboxes():
	return [hurtBox]

func LineIntersectsBox(start : Vector2, travel : Vector2, width : float, rect : Rect2) -> bool:
	var hit = false
	
	var endpoints = [ [rect.position, rect.size * Vector2(1,0)], [rect.position, rect.size * Vector2(0,1)], 
	[rect.position + rect.size * Vector2(1,0), rect.size * Vector2(0,1)], [rect.position + rect.size * Vector2(0,1), rect.size * Vector2(1,0)] ]
	#Above code takes the rect, and transforms it into a series of coordinates that represent each of the lines that form the outline of the hitbox.
	
	for pair in endpoints:
		var closest = Geometry2D.get_closest_points_between_segments(start, start+travel, pair[0], pair[0] + pair[1])
		var dist = closest[0].distance_to(closest[1])
		if dist < width:
			hit = true
		if hit:
			break
	
	
	return hit

func GetAllHitInLine(start : Vector2, travel : Vector2, lineWidth : float):
	return ConditionalHitInLine(start, travel, lineWidth, true, true, false, false, false)

func ConditionalHitInLine(start : Vector2, travel : Vector2, lineWidth : float, friendlyFire : bool = false, checkSelf : bool = false, useMeleeImmunity : bool = true, useProjectileImmunity : bool = false, useGrabImmunity : bool = false):
	var hit = []
	for otherObject in battleInstance.allObjects:
		if otherObject.disabled:
			continue
		if otherObject == self && not checkSelf:
			continue
		if not friendlyFire && otherObject.team == team:
			continue
		if otherObject.ignoreMeleeHitboxes && useMeleeImmunity:
			continue
		if otherObject.ignoreProjectileHitboxes && useProjectileImmunity:
			continue
		if otherObject.ignoreGrabHitboxes && useGrabImmunity:
			continue
		
		var hurtboxes = otherObject.GetHurtboxes()
		
		for box in hurtboxes:
			var hurtrect = Rect2(2 * box.position * Vector2(otherObject.GetFacingInt(), 1) + otherObject.global_position - box.bounds * 0.5, box.bounds)
			if LineIntersectsBox(start, travel, lineWidth, hurtrect):
				hit.append(otherObject)
				break
	
	return hit

func HitBy(hitboxData : HitboxData):
	
	var theirFacing = hitboxData.player.GetFacingInt()
	velocity = lerp(hitboxData.player.velocity, velocity, 1 - hitboxData.inheritAttackersSpeedOnHitPercent)
	var direction = hitboxData.knockbackDirection
	if hitboxData.knockbackAwayFromCenter:
		var attackerFacingInt = hitboxData.player.GetFacingInt()
		direction = position - (hitboxData.player.position + hitboxData.position * Vector2(attackerFacingInt, 1))
		if attackerFacingInt == -1:
			direction.x *= -1
	velocity += direction.normalized() * hitboxData.knockbackForce * Vector2(theirFacing, 1)
	SetFacing(theirFacing * -1)
	hitboxData.player.HitCallback(self, hitboxData)
	
	var shakeMote = ShakeMote.new()
	shakeMote.SetDuration(hitboxData.stunTicks + hitboxData.hitstopTicks)
	shakeMote.intensity = sqrt((hitboxData.stunTicks + hitboxData.hitstopTicks) * 10)
	AddMote(shakeMote)
	hitstopTicks = hitboxData.hitstopTicks
	hitboxData.player.hitstopTicks = hitboxData.selfHitstopTicks

func HitCallback(whoWasHit : GameObject, finalHitboxData : HitboxData):
	hitstopTicks += finalHitboxData.selfHitstopTicks
	CurrentState().OnHit(whoWasHit, finalHitboxData)
	pass

func SpawnProjectile(scene, posOffset : Vector2, spawnRelative : bool = true) -> GameObject:
	
	var spawned = battleInstance.SpawnObject(scene)
	spawned.team = team
	
	if spawnRelative:
		spawned.position = position + posOffset * Vector2(GetFacingInt(), 1)
		spawned.flipX = flipX
	else:
		spawned.position = posOffset
	
	#Assign a level to the projectile if a characterstate is spawning it, which have levels that increase power.
	if spawned is ProjectileObject:
		spawned.creator = self
		var myState = CurrentState()
		if myState is CharacterState:
			spawned.creatorMoveLevel = myState.powerModifier
	
	return spawned

func PostHurtboxUpdate():
	pass

func AttemptToSwitchTeams(_newOwner : GameObject):
	pass
#Particles
#----------------------
func SpawnParticle(particle : PackedScene, pos : Vector2, direction : Vector2):
	return battleInstance.SpawnParticle(particle, pos, direction)

func SpawnParticleRelative(particle : PackedScene, offset : Vector2):
	return SpawnParticle(particle, position + offset * Vector2(GetFacingInt(), 1), Vector2(GetFacingInt(), 0))

func SpawnAfterImage(duration : float = 0.4, color = Color.WHITE):
	var newParticle = SpawnParticleRelative(preload("res://Particles/GenericFFX/Afterimage.tscn"), Vector2.ZERO)
	var child = newParticle.get_children()[0]
	newParticle.maxLifetime = duration
	child.texture = sprite.get_sprite_frames().get_frame_texture(sprite.animation, sprite.frame)
	child.lifetime = duration
	child.color *= color * sprite.modulate
	child.material = material.duplicate()
	newParticle.scale = sprite.scale

#FFX
func ShakeScreen(screenShakeStrength : float, screenShakeDirection : Vector2, screenShakeDuration : int):
	var newShakeMote = ScreenShakeMote.new()
	newShakeMote.intensity = screenShakeStrength
	newShakeMote.direction = screenShakeDirection
	newShakeMote.SetDuration(screenShakeDuration)
	battleInstance.AddMote(newShakeMote)

#Sounds
func PlaySound(sfxname : String):
	if not isGhost:
		Sounds.get_node(sfxname).play()
