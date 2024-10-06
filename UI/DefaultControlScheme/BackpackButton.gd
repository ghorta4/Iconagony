extends Node


@onready var MouseOverSFX = $"MouseOver"

@onready var button = $"Sub"

var UI
var packInternalName

func _ready():
	button.mouse_entered.connect(OnHoverStart)
	button.pressed.connect(OnPressed)


func OnHoverStart():
	MouseOverSFX.play()


func OnPressed():
	UI.UpdatePackDisplay(packInternalName)
