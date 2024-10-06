extends ObjectState

class_name CharacterState

@export_group("Frame Data")
@export var IASA : int = -1 #If you can interrupt a move before it's finished, this is when you can.

@export_group("Character Flow")
@export var canLandCancel : bool = true
@export var landCancelLag : int = 6

@export var interruptOnExit : bool = false
@export var isHurtState : bool = false

var inputs #A nebulous, context-sensitive variable used to allow fine control over moves.

var powerModifier : int = 0 #Moves may be subject to power modifiers. This variable will show the adjustment, generally values ranging from -1 to +3, although still plan for extremes.


func Tick():
	super()
	if IASA == currentTick:
		host.stateInterruptable = true
