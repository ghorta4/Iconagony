extends GrabState

var zoomMote = null

func OnEnter():
	super()
	host.grabbee.sprite.rotation_degrees = 90 * host.GetFacingInt()
	host.ignoreMeleeHitboxes = true
	host.ignoreGrabHitboxes = true
	host.ignoreProjectileHitboxes = true
	zoomMote = null

func OnExit():
	host.ignoreMeleeHitboxes = false
	host.ignoreGrabHitboxes = false
	host.ignoreProjectileHitboxes = false

func Frame1():
	zoomMote = CameraZoomMote.new()
	zoomMote.SetDuration(75)
	zoomMote.desiredZoom = 1.3
	zoomMote.targetedObject = host
	zoomMote.zoomLerpSpeed = 6.0
	zoomMote.targetObjectOffset = Vector2(10, 6)
	host.battleInstance.AddMote(zoomMote)

func Frame20():
	zoomMote.desiredZoom = 1.9
	host.ShakeScreen(6, Vector2(1, 0.7), 12)


func Frame51():
	zoomMote.desiredZoom = 3.6
	host.ShakeScreen(12, Vector2(1, 0.7), 18)

func Frame92():
	if host.grabbee != null:
		host.grabbee.SP = max(host.grabbee.SP, host.grabbee.MaxSP * 0.85)

func Frame93():
	host.ShakeScreen(18, Vector2(1, 0.7), 24)
