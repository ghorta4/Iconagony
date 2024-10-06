extends Button

var UI

var mouseOver = false

var pushFactor = 0.0 #used for that little slide on mouseover.

func _init():
	mouse_entered.connect(OnHoverStart)
	mouse_exited.connect(OnHoverEnd)

func _physics_process(_delta):
	if UI == null:
		return
	
	if mouseOver:
		pushFactor = lerp(pushFactor, 1.0, 0.13)
	else:
		pushFactor = lerp(pushFactor, 0.0, 0.13)
	
	position.x = -21 + 10 * pushFactor

func OnHoverStart():
	mouseOver = true

func OnHoverEnd():
	mouseOver = false

func _pressed():
	if UI.followedPlayer == null:
		return
	
	UI.OnMoveSelected(MoveManager.GetMoveAtPosition(MoveInstance.moveLocations.Fixed, 0, UI.followedPlayer.instancedMoves))
