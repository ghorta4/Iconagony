extends CharacterState

var zoomMote = null

func OnEnter():
	super()
	host.scenematicGlobalPauseMove = true
	host.battleInstance.universalHitstop = 54
	
	zoomMote = CameraZoomMote.new()
	zoomMote.SetDuration(3)
	zoomMote.desiredZoom = 1.
	zoomMote.targetedObject = host
	zoomMote.zoomLerpSpeed = 10.0
	zoomMote.targetObjectOffset = Vector2(10, 0)
	host.battleInstance.AddMote(zoomMote)
	

func Tick():
	super()
	if zoomMote != null:
		zoomMote.desiredZoom = 1 + currentTick / 54.0 * 3.5
		zoomMote.targetObjectOffset = Vector2(10, 0) + Vector2(randf() - 0.5, randf() - 0.5) * (currentTick / 54. * 2 + 1) * 40
		
		if currentTick > 52:
			zoomMote.desiredZoom = 1

func Frame52():
	host.scenematicGlobalPauseMove = false
	if host.orlandoEnabled:
		pass
	else:
		host.orlandoLevel = powerModifier
	host.orlandoTrackedMoves = []
	host.orlandoEnabled = true

func OnExit():
	super()
	host.scenematicGlobalPauseMove = false
