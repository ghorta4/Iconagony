class_name MoveInstance

var moveClassReference : MoveClass
#Like the move class, except it contains specific information, such as modifiers or durability specific to the move.

var remainingUses : int = 1
var maxUses : int = 1
var infiniteUses : bool = false #can be toggled on by the backpack to allow it to be used infinitely.

var moveLocation : moveLocations = moveLocations.Unassigned
var relevantMoveControls : Node
var predictionMemorizedInput

var moveSlot : int = 0 #Relative location of the move. For example, when in the inventory, this means which position the move's slotted in.

var moveLevel : int = 0 #Calculated mid-game.

var moveColor : Color = Color.TRANSPARENT
var stateVariables = ["moveClassReference", "remainingUses", "infiniteUses", "moveLocation", "moveSlot", "moveLevel", "maxUses"]

var tags = [] #Transient. Tied to move instance, not the move itself- although later on, some moves may share tags for cool functionality.

var visualAlterations : Dictionary = { #Key is the parameter name, value is the adjustment
	
}
var slottedMementos : Array[Memento] = [] #Array. Mementos are stored by node reference for ease of access. The original nodes can be found in the Move Manager.
#Null mementos represent blank slots.

enum moveLocations { #The order of these is used to determine move sorting order. Basically, higher up here means level-affecting processes happen first
	Unassigned,
	Sidepack, #Moves in individual slots, which gain flat power bonuses and act differently.
	Inventory, #Moves on the player's default list.
	Unslotted, #Moves that are free and floating about.
	Storage, #Moves in special storage slots that can't be used in battle but are retrieved after the battle.
	Fixed, #Moves that aren't part of the normal kit. IE wait.
	Pickups, #Moves you can gain mid-combat.
	Trash, #To delete
}

func CopyTo(new):
	for variable in stateVariables:
		new[variable] = get(variable)
	
	new.slottedMementos.clear()
	for memento in slottedMementos:
		new.slottedMementos.append(memento)
	if relevantMoveControls != null:
		new.predictionMemorizedInput = relevantMoveControls.GetData()

static func GenerateMoveInstance(moveClass : MoveClass):
	var newGuy = MoveInstance.new()
	newGuy.moveClassReference = moveClass
	newGuy.remainingUses = moveClass.defaultMaxUses
	newGuy.maxUses = moveClass.defaultMaxUses
	
	for i in moveClass.maxMementos:
		newGuy.slottedMementos.append(null)
	
	return newGuy

func RecalculateMoveLevels(targetArray):
	moveClassReference.MoveLevelProcessing(self, targetArray)
	
	for memento in slottedMementos:
		if memento == null:
			continue
		memento.ApplyLevelEffects(self, targetArray)
	
	remainingUses = min(remainingUses, maxUses)

func IsPickupMove() -> bool:
	return moveLocation == moveLocations.Pickups

func DebugReadout() -> String:
	return moveClassReference.name + " | " + str(moveLocation) + " : " + str(moveSlot)
