extends Button

class_name MoveButton

var referencedMoveInstance : MoveInstance

var UI

var mouseOver = false

var pushFactor = 0.0 #used for that little slide on mouseover.

var player

func _init():
	mouse_entered.connect(OnHoverStart)
	mouse_exited.connect(OnHoverEnd)
	
	material = material.duplicate()

func _physics_process(_delta):
	if (mouseOver || UI.selectedMove == referencedMoveInstance) && Usable():
		pushFactor = lerp(pushFactor, 1.0, 0.13)
	else:
		pushFactor = lerp(pushFactor, 0.0, 0.13)

func OnHoverStart():
	mouseOver = true
	
	UI.moveDescriptions.UpdateFromMoveInstance(referencedMoveInstance)
	UI.hoveredButton = self

func OnHoverEnd():
	mouseOver = false
	
	UI.moveDescriptions.Defocus(referencedMoveInstance)
	if UI.hoveredButton == self:
		UI.hoveredButton = null

func _pressed():
	
	if not Usable():
		return
	UI.OnMoveSelected(referencedMoveInstance)

func Usable():
	return referencedMoveInstance.moveClassReference.IsUsable(player)
