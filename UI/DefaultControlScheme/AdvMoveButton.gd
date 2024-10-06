extends ClickDragButton

class_name AdvancedMoveButton



var mouseOver = false

var pushFactor = 0.0 #used for that little slide on mouseover.

@onready var Back1 = $"HForm/Back"
@onready var Back2 = $"VForm/Back"

@onready var Text1 = $"HForm/Text"
@onready var Text2 = $"VForm/Text"

@onready var H = $"HForm"
@onready var V = $"VForm"

@onready var MouseOverSFX = $"MouseOver"

var mementoDisplay = []

#This is the click-and-drag functionality for pickup moves.
var activateClickDragTimer : bool = false
var clickDragTimer : float = 0
const clickDragTimerMax = 0.25


var rightClickDeleteActive : bool = false
var deleteTimer : float = 0.0
var deleteClicks = 0

func _ready():
	Text1.mouse_entered.connect(OnHoverStart)
	Text1.mouse_exited.connect(OnHoverEnd)
	Text1.pressed.connect(OnPressed)
	
	Text2.mouse_entered.connect(OnHoverStart)
	Text2.mouse_exited.connect(OnHoverEnd)
	Text2.pressed.connect(OnPressed)
	
	material = material.duplicate()

func _physics_process(delta):
	var rightButtonDown = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if activateClickDragTimer:
		clickDragTimer -= delta
		if clickDragTimer <= 0:
			activateClickDragTimer = false
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				MoveManager.grabbedMove = referencedMoveInstance
	
	var breakBeep = $BreakBeep
	if rightButtonDown && (mouseOver || rightClickDeleteActive):
		rightClickDeleteActive = true
		deleteTimer += delta
		breakBeep.pitch_scale = deleteTimer * 0.25 + 1
		
		if deleteTimer * 2 > sqrt(deleteClicks):
			deleteClicks += 1
			breakBeep.play()
	else:
		deleteTimer = 0
		rightClickDeleteActive = false
		deleteClicks = 0
		breakBeep.pitch_scale = 1
	
	if (mouseOver || UI.selectedMove == referencedMoveInstance) && Usable():
		pushFactor = lerp(pushFactor, 1.0, 0.13)
	else:
		pushFactor = lerp(pushFactor, 0.0, 0.13)
	
	if deleteTimer > 0:
		pushFactor = 1.0

func OnHoverStart():
	UI.hoveredButton = self
	if referencedMoveInstance.moveClassReference is BlankMove:
		UI.UpdateButtonFromMove(self, referencedMoveInstance) #Done so that dragged moves can appear over these slots
		return
	
	mouseOver = true
	
	UI.moveDescriptions.UpdateFromMoveInstance(referencedMoveInstance)
	
	MouseOverSFX.play()

func OnHoverEnd():
	
	mouseOver = false
	
	if UI.hoveredButton == self:
		UI.hoveredButton = null
	
	if referencedMoveInstance.moveClassReference is BlankMove:
		UI.UpdateButtonFromMove(self, referencedMoveInstance)

func OnPressed():
	if referencedMoveInstance.IsPickupMove(): #put an item in the held slot here.
		activateClickDragTimer = true
		clickDragTimer = clickDragTimerMax
		if not Usable():
			UI.selectedMove = referencedMoveInstance
	
	
	if not Usable():
		return
	UI.OnMoveSelected(referencedMoveInstance)

func Usable():
	if not is_instance_valid(player):
		return false
	return referencedMoveInstance.moveClassReference.IsUsable(player)
