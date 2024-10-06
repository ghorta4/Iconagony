extends ClickDragButton

class_name AdvancedMetaMoveButton



var mouseOver = false

@onready var Back = $"Back"
@onready var Text = $"Sub"

@onready var MouseOverSFX = $"MouseOver"

var mementoDisplay = []

#This is the click-and-drag functionality for pickup moves.
var activateClickDragTimer : bool = false
var clickDragTimer : float = 0
const clickDragTimerMax = 0.25


func _ready():
	Text.mouse_entered.connect(OnHoverStart)
	Text.mouse_exited.connect(OnHoverEnd)
	Text.pressed.connect(OnPressed)
	
	material = material.duplicate()

func _physics_process(delta):
	if activateClickDragTimer:
		clickDragTimer -= delta
		if clickDragTimer <= 0:
			activateClickDragTimer = false
			
			var moveAvailable = OwnedMovesManager.GetNumberOfMovesAvailableWithNameAndData(referencedMoveInstance.moveClassReference.name, MoveModificationData.GenerateModDataFromMove(referencedMoveInstance))
			
			if moveAvailable <= 0:
				return
			
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				MoveManager.grabbedMove = referencedMoveInstance

func OnHoverStart():
	UI.hoveredButton = self
	
	mouseOver = true
	
	UI.moveDescriptions.UpdateFromMoveInstance(referencedMoveInstance)
	
	MouseOverSFX.play()

func OnHoverEnd():
	
	mouseOver = false
	
	if UI.hoveredButton == self:
		UI.hoveredButton = null
	

func OnPressed():
	activateClickDragTimer = true
	clickDragTimer = clickDragTimerMax
	
	#UI.OnMoveSelected(referencedMoveInstance)
