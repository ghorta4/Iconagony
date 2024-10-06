extends CharacterState

@export var projectileOffset : Vector2 = Vector2.ZERO
@export var airVersion : bool = false

func OnEnter():
	super()
	
	if airVersion:
		canLandCancel = true

func OnExit():
	StopGunArm()

func Frame8():
	StartGunArm()

func Frame19():
	StopGunArm()
	var particleAim = Vector2(cos(host.gungeousArm.rotation), sin(host.gungeousArm.rotation)) * Vector2(host.GetFacingInt(), 1)
	host.SpawnParticle(preload("res://Strife/Particles/GunFireSpark.tscn"), projectileOffset + host.position + particleAim * 10, particleAim)
	var myProjectile = host.SpawnProjectile(preload("res://Strife/Projectiles/Guns/Bullet.tscn"), projectileOffset)
	if parameters == null:
		parameters = Vector2.RIGHT
	myProjectile.velocity = parameters * 2600.0

func StartGunArm():
	if parameters == null:
		parameters = Vector2.RIGHT
	
	var rotation = atan2(parameters.y, parameters.x)
	if host.flipX:
		rotation = PI - rotation
	host.gungeousArm.visible = true
	host.gungeousArm.rotation = rotation
	
	host.gungeousArm.position = Vector2(cos(rotation), sin(rotation)) * 2
	if airVersion:
		host.gungeousArm.position += Vector2(7, -7)
	else:
		host.gungeousArm.position += Vector2.DOWN * 1

func StopGunArm():
	host.gungeousArm.visible = false
