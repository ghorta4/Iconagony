extends Node
class_name MoveClass

@export var displayName : String = "Unnamed Move"
@export_multiline var description : String = "Default move description. Gives information about how the move functions."
@export_multiline var flavorDesc : String = "Description that adds flavor text. Can be toggled off, so don't put important information here."

@export var groundedState : String = "Default"
@export var aerialState : String = "Default"

@export var defaultMaxUses : int = 10

@export var usability : MoveUsability = MoveUsability.Always

@export_multiline var pickupMoves : String = "" #Use line break to separate move names from the pickup weight

@export var maxMementos : int = 0 #Number of modifications that can be slotted.

enum MoveUsability {
	Always,
	AirOnly,
	GroundOnly
}

var tags = [] #An assortment of strings that define properties of the move. IE, grounded/aerial only, magic, etc. Set manually AND visible to the player.

@export var UIScene : PackedScene

static func PresetMove(moveID): #Used for playtesting
	var newMove = MoveClass.new()
	
	
	match (moveID):
		-1:
			newMove.displayName = "Wait"
			newMove.description = "Do nothing."
			newMove.flavorDesc = "A little patience goes a long way..."
			newMove.groundedState = "Idle"
			newMove.aerialState = "IdleAir"
			newMove.defaultMaxUses = -1
			newMove.UIScene = null
		0:
			newMove.displayName = "Ascend"
			newMove.description = "Jumps upwards. Good vertical movement, but poor horizontal utility."
			newMove.flavorDesc = "Good thing you can't break your legs. Or anything, really."
			newMove.groundedState = "Jump"
			newMove.aerialState = "Jump"
			newMove.defaultMaxUses = 20
			newMove.UIScene = preload("res://Strife/ActionUI/JumpPlot.tscn")
			newMove.color1 = Color(0.08, 0.12, 0.19)
		1:
			newMove.displayName = "Escapade"
			newMove.description = "Move quickly. Nearly instant."
			newMove.flavorDesc = "Why does an icon move? No concept is truly immutable- they're shaped by the world around them. To change position is to change your very existence."
			newMove.groundedState = "Dash"
			newMove.aerialState = "Dash"
			newMove.defaultMaxUses = 25
			newMove.UIScene = preload("res://UI/Slider/Slider.tscn")
			newMove.usability = MoveUsability.GroundOnly
		2:
			newMove.displayName = "The Line"
			newMove.description = "Basic horizontal strike. Has extremely high durability."
			newMove.flavorDesc = "\"I'll say it again: It's not a staff, it's a LINE!\"  \"A line is full of potential, possibilities. It's many things, whatever I wish it to be."
			newMove.groundedState = "Swipe1G"
			newMove.aerialState = "Swipe1A"
			newMove.defaultMaxUses = 20
			newMove.UIScene = null
		3:
			newMove = load("res://Strife/MoveClasses/Grindstone.gd").new()
			newMove.displayName = "Grindstone"
			newMove.description = "Lackluster overhead attack. In addition, boosts the level of the above move by 1, and reduces the level of the below move by 1."
			newMove.flavorDesc = "All systems are inherently balanced. But, why do we succeed? It's because we learn to break these systems."
			newMove.groundedState = "Swipe1G"
			newMove.aerialState = "Swipe1A"
			newMove.defaultMaxUses = 5
			newMove.UIScene = null
	
	
	return newMove

func IsUsable(player : CharacterObject):
	var grounded = player.IsOnGround()
	if (grounded == true && usability == MoveUsability.AirOnly) || (grounded == false && usability == MoveUsability.GroundOnly):
		return false
	
	return true

func GetUsedState(player : CharacterObject):
	if player.IsOnGround():
		return groundedState
	return aerialState

func OnPickup(): #For effects that need to do stuff like, say, trigger a flag.
	pass

func OnRemoved():
	pass

func MoveLevelProcessing(_myInstance : MoveInstance, _targetArray : Array[MoveInstance]): #This may sound like it wants you to calculate your own level... but it does not! Instead, it's asking you to make any adjustments to other levels,
#such as if the move's effect is to increase the level of the slot above. 
#Addendum: Nevermind it also handles certain cases of *adjusting* your own level, not setting it.
	pass
