extends Control

@onready var nameTag = $"%Name"
@onready var descTag = $"%Desc"
@onready var flavorTag = $"%Flavor"
@onready var tagsTag = $"%Tags" #No snarky joke here
@onready var levelTag = $"%Level"
@onready var durabilityTag = $"%Durability"
@onready var mementoTag = $"%Memento"

@onready var container = $"%Container"
@onready var InHandMove = $"%InHandMove"
@onready var MementoBox = $"%MementoBox"

@onready var mainBlock = $"%MainDetailBlock"
@onready var descriptionBlock = $"%Description2"

var viewedMove : MoveInstance

var UI

func _process(_delta):
	visible = MoveManager.grabbedMove != null || viewedMove != null
	
	var viewport = get_viewport()
	var viewportSize = viewport.get_visible_rect().size
	var mousePos = viewport.get_mouse_position()
	
	position = viewport.get_mouse_position() + Vector2.RIGHT * 15
	
	mainBlock.visible = Main.fullMoveDisplay
	descriptionBlock.visible = UI.battleInstance.showHost.canEditMoveset
	
	
	#Memento visibility
	if viewedMove != null && UI.viewedMementoHelper != null:
		var numberOfSlots = viewedMove.slottedMementos.size()
		var selectedMementoLocation = UI.viewedMementoHelper.mementoSlot
		if selectedMementoLocation < 0 || selectedMementoLocation >= numberOfSlots:
			MementoBox.visible = false
		else:
			MementoBox.visible = true
			var viewedMemento = viewedMove.slottedMementos[selectedMementoLocation]
			if viewedMemento != null:
				mementoTag.text = viewedMove.slottedMementos[selectedMementoLocation].description
			else:
				mementoTag.text = "<Empty Memento Slot>"
	else:
		MementoBox.visible = false
	
	#positioning
	
	if mousePos.x > viewportSize.x / 2.0 && MoveManager.grabbedMove == null:
		position.x -= container.size.x + 20
	
	if position.y + container.size.y > viewportSize.y && MoveManager.grabbedMove == null:
		position.y = viewportSize.y - container.size.y
	
	if MoveManager.grabbedMove == null:
		container.visible = UI.hoveredButton != null && not UI.hoveredButton.referencedMoveInstance.moveClassReference is BlankMove
		InHandMove.visible = false
	else:
		container.visible = false
		InHandMove.visible = true
		UpdateGrabbedButtonGraphic()
	

func UpdateFromMoveInstance(inst : MoveInstance):
	viewedMove = inst
	
	var data = inst.moveClassReference
	
	nameTag.text = data.displayName
	descTag.text = data.description
	flavorTag.text = data.flavorDesc
	
	tagsTag.text = "Tag functionality TBD"
	
	levelTag.text = "LV " +str (inst.moveLevel)
	durabilityTag.text = str(inst.remainingUses) + "/" + str(inst.maxUses)
	if inst.infiniteUses:
		durabilityTag.text = "∞" 
	
#	container.visible = true

#func Defocus(inst : MoveInstance):
#	if viewedMove == inst:
#		container.visible = false

func UpdateGrabbedButtonGraphic():
	$"InHandMove/Back".material.set_shader_parameter("targetColor2", Color("#e0e0e0"))
	$"InHandMove/Back".material.set_shader_parameter("newColor2", Vector3(0,0,0))
	$"InHandMove/Text".text = MoveManager.grabbedMove.moveClassReference.displayName
