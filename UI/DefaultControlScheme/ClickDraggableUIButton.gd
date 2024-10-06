extends Control
class_name ClickDragButton

var referencedMoveInstance : MoveInstance

var UI

var player

func Usable():
	if not is_instance_valid(player):
		return false
	return referencedMoveInstance.moveClassReference.IsUsable(player)
