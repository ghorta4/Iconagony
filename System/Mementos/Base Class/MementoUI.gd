extends Control
class_name MementoUI
var parentButton
var mementoSlot : int = -1

func _ready():
	mouse_entered.connect(OnHoverStart)
	mouse_exited.connect(OnHoverEnd)
	

func OnHoverStart():
	parentButton.UI.viewedMementoHelper = self
	parentButton.OnHoverStart()

func OnHoverEnd():
	if parentButton.UI.viewedMementoHelper == self:
		parentButton.UI.viewedMementoHelper = null
	parentButton.OnHoverEnd()
