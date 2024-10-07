extends CharacterState

#Author's note: never ever change the ticks per frame from 1. otherwise it looks really weird.

const fireTick = 8
var target : CharacterObject = null

var myBolt : GameObject = null

@export var isFireSelfVersion : bool = false

const fireSelfWindup : int = 15

func CopyTo(new):
	super(new)
	
	if target != null:
		new.target = new.host.battleInstance.FindCharacterOfID(target.id)
	else:
		new.target = null
	
	
	if myBolt != null:
		new.myBolt = new.host.battleInstance.FindObjectOfID(myBolt.id)
	else:
		new.myBolt = null

func Tick():
	super()
	
	if target == null:
		return
	var posDiff = host.position - target.position
	
	var lerpStrength = 0.05
	var spinny = 0
	
	if holdFrames > 0 && isFireSelfVersion:
		spinny = 2 * PI * pow(float(holdFrames) / fireSelfWindup, 2)
		lerpStrength = 1
	
	var newAngle = lerp_angle(host.facingAngle, posDiff.angle() + PI/2 + spinny, lerpStrength)
	host.facingAngle = newAngle
	host.sprite.rotation = host.facingAngle
	
	if currentTick < fireTick && myBolt != null:
		UpdateBoltPosition()
		if isFireSelfVersion:
			host.sprite.modulate.a = float(fireTick - currentTick) / fireTick
	elif currentTick == fireTick:
		myBolt.velocity = Vector2(cos(newAngle + PI/2), sin(newAngle + PI/2)) * 210
		if isFireSelfVersion:
			host.sprite.modulate.a = 0
			host.ignoreMeleeHitboxes = true
			host.ignoreGrabHitboxes = true
			host.ignoreProjectileHitboxes = true
		else:
			myBolt = null
	
	if isFireSelfVersion && myBolt != null && currentTick > fireTick:
		host.position = myBolt.position
		
		if myBolt.CurrentState().name != "loop" && myBolt.CurrentState().name != "Default":
			host.ChangeState("Unfurl")
			host.sprite.rotation = 0
			host.facingAngle = 0
			EndImmunity()
	
	if currentTick == duration - 1 && not isFireSelfVersion:
		host.stateInterruptable = true

func EndImmunity():
	host.ignoreMeleeHitboxes = false
	host.ignoreGrabHitboxes = false
	host.ignoreProjectileHitboxes = false

func Frame1():
	myBolt = host.SpawnProjectile(load("res://Enemies/Acrophilia/Projectiles/AcroBomb.tscn"), Vector2.ZERO)
	myBolt.material = host.material
	UpdateBoltPosition()

func UpdateBoltPosition():
	myBolt.position = host.position
	var targetAngle = host.facingAngle + PI / 2
	myBolt.position += Vector2(cos(targetAngle), sin(targetAngle)) * float(currentTick - fireTick / 4.0) / fireTick * 70

func OnExit():
	super()
	host.sprite.modulate.a = 1
	var newState = host.CurrentState()
	if newState.name != "FireSelf" && newState.name != "Fire":
		host.sprite.rotation = 0
		host.facingAngle = 0
	else:
		newState.target = target
	
	EndImmunity()

func OnEnter():
	if isFireSelfVersion:
		holdFrames = fireSelfWindup
		host.PlaySound("Windup")
