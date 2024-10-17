extends CharacterState

func Frame4():
	host.velocity.x += host.GetFacingInt() * 5 * parameters

func Frame28():
	var roll = host.GetRandom()
	
	var failChance = .9
	if powerModifier > 0:
		failChance -= powerModifier * 0.2
	if powerModifier < 0:
		failChance -= powerModifier * 0.03
	
	if roll > failChance * 100:
		host.ChangeState("Death45")
		host.stateInterruptable = false
		host.battleInstance.universalHitstop = 5
		
		var zoomMote = CameraZoomMote.new()
		zoomMote.SetDuration(3)
		zoomMote.desiredZoom = 2
		zoomMote.targetedObject = host
		zoomMote.instantSnapToZoom = true
		zoomMote.targetObjectOffset = Vector2(0, 60)
		host.battleInstance.AddMote(zoomMote)
