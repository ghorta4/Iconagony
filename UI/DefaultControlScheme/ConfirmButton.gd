extends Button

var UI

var pushFactor = 0.0 #used for that little slide on mouseover.


func _physics_process(_delta):
	if UI.selectedMove != null && not MoveIsPreviewOnly():
		pushFactor = lerp(pushFactor, 0.0, 0.13)
	else:
		pushFactor = lerp(pushFactor, 1.0, 0.13)
	
	position.x = 685 + 200 * pushFactor


func _pressed():
	if not UI.CurrentMoveIsUsable():
		return
	
	UI.readyToSend = true
	UI.PlaySound("TurnEnd")


func MoveIsPreviewOnly():
	return UI.selectedMove.moveLocation == MoveInstance.moveLocations.Pickups
