extends CharacterState

var myParticle = null
var zoomMote
func Frame22():
	myParticle = host.SpawnParticle(preload("res://Strife/Particles/DarkAgeBuildup.tscn"), Vector2.ZERO, Vector2.RIGHT)
	if host.isGhost:
		myParticle.fishFFX.visible = false
	UpdateParticlePos()

func OnEnter():
	super()
	zoomMote = null
	
	zoomMote = CameraZoomMote.new()
	zoomMote.SetDuration(45)
	zoomMote.desiredZoom = 1.3
	zoomMote.targetedObject = host
	zoomMote.zoomLerpSpeed = 1.0
	host.battleInstance.AddMote(zoomMote)

func Tick():
	super()
	if myParticle != null:
		UpdateParticlePos()


func Frame45():
	if myParticle != null:
		myParticle.endSequence = true

func OnExit():
	if myParticle != null:
		myParticle.queue_free()
		myParticle = null

func UpdateParticlePos():
	myParticle.position = host.position + Vector2(15 * host.GetFacingInt(), 10)
