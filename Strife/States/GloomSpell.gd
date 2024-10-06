extends CharacterState

var myProjectile
@export var projectileOffset : Vector2 = Vector2.ZERO
@export var airVersion : bool = false

var zoomMote

func CopyTo(newguy):
	super(newguy)
	if myProjectile != null:
		newguy.myProjectile = host.battleInstance.FindObjectOfID(myProjectile.id)

func OnEnter():
	super()
	myProjectile = null
	
	if airVersion:
		canLandCancel = true
	
	zoomMote = null

func Frame1():
	myProjectile = host.SpawnProjectile(preload("res://Strife/Projectiles/GloomBlast.tscn"), projectileOffset)
	
	zoomMote = CameraZoomMote.new()
	zoomMote.SetDuration(60)
	zoomMote.desiredZoom = 1.5
	zoomMote.targetedObject = host
	zoomMote.zoomLerpSpeed = 3.0
	zoomMote.targetObjectOffset = Vector2(100, 0)
	host.battleInstance.AddMote(zoomMote)

func Frame55():
	if airVersion:
		canLandCancel = false

func Frame40():
	host.PlaySound("50Cal")

func Tick():
	super()
	
	if currentTick < 40 && myProjectile != null:
		myProjectile.position = host.position + projectileOffset * Vector2(host.GetFacingInt(), 1)
	
	
	if zoomMote != null && currentTick < 41:
		zoomMote.desiredZoom += 0.03
		if currentTick == 40:
			zoomMote.desiredZoom += 1.5

func OnExit():
	super()
	if currentTick < 40 && myProjectile != null:
		myProjectile.ChangeState("Dead")
