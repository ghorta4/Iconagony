extends ClickDragButton

var referencedMoveInternalName

@onready var Sub = $"Sub"
@onready var MouseOverSFX = $"MouseOver"

var mouseOver = false

var activateClickDragTimer : bool = false
var clickDragTimer : float = 0
const clickDragTimerMax = 0.25

var assignedSlot = 0

var moveIsInvalid = false

func _ready():
	Sub.mouse_entered.connect(OnHoverStart)
	Sub.mouse_exited.connect(OnHoverEnd)
	Sub.pressed.connect(OnPressed)
	
	#material = material.duplicate()

func _physics_process(delta):
	if activateClickDragTimer:
		clickDragTimer -= delta
		if clickDragTimer <= 0:
			activateClickDragTimer = false
			
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && not moveIsInvalid:
				referencedMoveInstance = UpdateFeignedMoveInstance()
				MoveManager.grabbedMove = referencedMoveInstance



func OnHoverStart():
	UI.hoveredButton = self
	referencedMoveInstance = UpdateFeignedMoveInstance()
	
	mouseOver = true
	
	UI.moveDescriptions.UpdateFromMoveInstance(referencedMoveInstance)
	
	MouseOverSFX.play()

func OnHoverEnd():
	
	mouseOver = false
	
	if UI.hoveredButton == self:
		UI.hoveredButton = null
	

func OnPressed():
	UpdateFeignedMoveInstance()
	
	activateClickDragTimer = true
	clickDragTimer = clickDragTimerMax
	
	UI.OnMetaMoveSelected(referencedMoveInstance.moveClassReference.name)

func UpdateFeignedMoveInstance() -> MoveInstance:
	
	
	if referencedMoveInstance != null && referencedMoveInstance.moveLocation == MoveInstance.moveLocations.Pickups:
		UI.followedPlayer.instancedMoves.erase(referencedMoveInstance)
	
	referencedMoveInstance = MoveManager.MoveInstanceFromString(referencedMoveInternalName)
	referencedMoveInstance.moveLocation = MoveInstance.moveLocations.Pickups
	referencedMoveInstance.moveSlot = assignedSlot
	UI.followedPlayer.instancedMoves.append(referencedMoveInstance)
	
	var appropriateModifications = OwnedMovesManager.GetNextAvailableModDataForMove(referencedMoveInternalName)
	
	if appropriateModifications == null:
		moveIsInvalid = true
	else:
		appropriateModifications.ApplyTo(referencedMoveInstance)
		moveIsInvalid = false
	
	return referencedMoveInstance

func UpdateDisplay():
	var appropriateModifications = OwnedMovesManager.GetNextAvailableModDataForMove(referencedMoveInternalName)
	
	if appropriateModifications == null:
		modulate = Color(0.4,0.4,0.4,1)
	else:
		modulate = Color.WHITE
