class_name MoveManager


static var EquippedBackpack : Backpack

static var MoveLibrary = {
	"Blank" : BlankMove.new(),
	"Wait" : MoveClass.PresetMove(-1)
} #Contains ALL moves in the game, whether the player has them or not. Key is the ID, value is the ingame info.

static var grabbedMove : MoveInstance # A move that's being click-dragged somewhere else.
#static var instancedMoves : Array[MoveInstance] = [] #An unsorted list with all moves in all different positions... good luck.
#static var previewInstancedMoves : Array[MoveInstance] = []


static var MementoLibrary = {
	
}

static var BackpackLibrary = {
	
}

static var DecorationsLibrary = { #Data is stored as follows: highest level are sub-libraries. Each contains an array with possible outcomes; those sub arrays
	#are ordered with elements as follows: 0 = output name, 1 = probability/weight, the rest are specific details such as colors or final values
	"Borders" : [
		["Default", 10.0, Color(0.2,0.2,0.2)],
		["Faded", 2.0, Color(0.06,0.06,0.06)],
		#["Emphasis", 0.5, Color(0.6,0.6,0.6)], #I hate the brightness on this one with a passion.
		["Silver", 0.1, Color("5e626d")],
		["Gold", 0.02, Color("5e626d")],
		["Neon", 0.0015, Color("91eb4c")],
		["Artic", 0.0015, Color("005291")],
		["Royal", 0.0015, Color("400a3f")],
	],
	"Foils" : [
		["None", 10.0],
		["Shiny", 0.1, Color.WHITE, 1.0], #Name, weight, foil color, foil desaturate
		["Aura", 0.04, Color("4e46ff"), 1.0],
		["Rainbow", 0.085, Color.WHITE, 0.0],
		["Corrupt", 0.02, Color("ff43c4"), .825],
		["Divine", 0.02, Color("d68c00"), .825],
		["Deep Sea", 0.02, Color("008d5b"), 0.715],
		["Glitched", 0.001, Color("1fb1ff"), 10.0]
	],
	"RainbowSheen" : [
		["Enabled", 0.0015],
		["Disabled", 0.9985]
	],
	"ScreenReflection" : [ 
		["Enabled", 0.005],
		["Disabled", 0.995]
	]
}


static func LoadMovesetFromNames(targetArray : Array, mainSet : Array[String], sidePack : Array[String]):
	targetArray.clear()
	
	var wait = MoveInstanceFromString("Wait")
	wait.moveLocation = MoveInstance.moveLocations.Fixed
	wait.infiniteUses = true
	targetArray.append(wait)
	
	var slot = 0
	for move in mainSet:
		var newMove = MoveInstanceFromString(move)
		newMove.moveLocation = MoveInstance.moveLocations.Inventory
		newMove.moveSlot = slot
		targetArray.append(newMove)
		slot += 1
	
	slot = 0
	for move in sidePack:
		var newMove = MoveInstanceFromString(move)
		newMove.moveLocation = MoveInstance.moveLocations.Sidepack
		newMove.moveSlot = slot
		targetArray.append(newMove)
		slot += 1
	
	FillMissingSlotsWithBlanks(targetArray)

static func FillMissingSlotsWithBlanks(targetArray):
	for i in EquippedBackpack.MaxMoveSlots:
		FillSlotWithBlankIfEmpty(MoveInstance.moveLocations.Inventory, i, targetArray)
	
	for i in EquippedBackpack.MaxSidepackSlots:
		FillSlotWithBlankIfEmpty(MoveInstance.moveLocations.Sidepack, i, targetArray)
	
	for i in EquippedBackpack.MaxPickupSlots:
		FillSlotWithBlankIfEmpty(MoveInstance.moveLocations.Pickups, i, targetArray)

static func FillSlotWithBlankIfEmpty(location : MoveInstance.moveLocations, slot : int, targetArray):
	var target = targetArray.filter(func(instance : MoveInstance) : return instance.moveLocation == location && instance.moveSlot == slot)
	
	if target.size() == 0:
		var newMove = MoveInstance.GenerateMoveInstance(BlankMove.new())
		newMove.moveLocation = location
		newMove.moveSlot = slot
		targetArray.append(newMove)

static func CleanupUnassignedMoves(targetArray : Array):
	var movesToCleanup = []
	for move in targetArray:
		if move.moveLocation == MoveInstance.moveLocations.Unassigned || move.moveLocation == MoveInstance.moveLocations.Trash:
			movesToCleanup.append(move)
	
	for move in movesToCleanup:
		targetArray.erase(move)

static func MoveInstanceFromString(moveName : String) -> MoveInstance:
	return MoveInstance.GenerateMoveInstance(MoveLibrary[moveName])



static func RelocateMove(framePerformed : int, targetLocation : MoveInstance.moveLocations, targetSlot : int, destinationLocation : MoveInstance.moveLocations, destinationSlot : int, targetArray,recordAction : bool = true): #For stuff like moving moves from the pickup area to the inventory. Formatted weirdly so that it can more easily be recorded for replays.
	if recordAction: ReplayManager.LogRelocatingMove(framePerformed, int(targetLocation), targetSlot, int(destinationLocation), destinationSlot)
	var oldSlotOccupant = GetMoveAtPosition(destinationLocation, destinationSlot, targetArray)
	
	var toMove = targetArray.filter(func(x) : return x.moveSlot == targetSlot && x.moveLocation == targetLocation)
	toMove[0].moveSlot = destinationSlot
	toMove[0].moveLocation = destinationLocation
	
	if destinationLocation != MoveInstance.moveLocations.Trash:
		oldSlotOccupant.moveSlot = targetSlot
		oldSlotOccupant.moveLocation = targetLocation
	
	if targetLocation == MoveInstance.moveLocations.Trash:
		CleanupUnassignedMoves(targetArray)
	else:
		FillSlotWithBlankIfEmpty(targetLocation, targetSlot, targetArray)
	
	SortInstancedMoves(targetArray)
	AdjustMoveLevels(targetArray)

static func ForceMoveRelocate(moveInstance : MoveInstance , destinationLocation : MoveInstance.moveLocations, destinationSlot : int, targetArray):
	moveInstance.moveLocation = destinationLocation
	moveInstance.moveSlot = destinationSlot
	
	var toClear = targetArray.filter(func(x) : return x.moveSlot == destinationSlot && x.moveLocation == destinationLocation)
	for clear in toClear:
		targetArray.erase(clear)
	
	targetArray.append(moveInstance)
	
	SortInstancedMoves(targetArray)
	AdjustMoveLevels(targetArray)

static func ManuallyBreakMoveAtPosition(framePerformed : int, targetLocation : MoveInstance.moveLocations, targetSlot : int, targetArray, recordAction : bool = true):
	RelocateMove(framePerformed, targetLocation, targetSlot, MoveInstance.moveLocations.Trash, 0, targetArray, recordAction)

static func BreakMoveAtPosition(targetLocation : MoveInstance.moveLocations, targetSlot : int, targetArray):
	var target = targetArray.filter(func(instance : MoveInstance) : return instance.moveLocation == targetLocation && instance.moveSlot == targetSlot)
	
	targetArray.erase(target[0])
	FillSlotWithBlankIfEmpty(targetLocation, targetSlot, targetArray)


static func GetMoveAtPosition(location : MoveInstance.moveLocations, slot : int, targetArray : Array) -> MoveInstance:
	for move in targetArray:
		if move.moveLocation == location && move.moveSlot == slot:
			return move
	return null

static func PutMoveAtPosition(instancedMove : MoveInstance ,location : MoveInstance.moveLocations, slot : int, targetArray : Array):
	var moveAtLocation = GetMoveAtPosition(location, slot, targetArray)
	if moveAtLocation == null:
		push_warning("Warning: Attempting to put a move at a slot that, like, doesn't have a blank, right? So it's probably 'out of bounds' or whatever.")
	
	if not moveAtLocation.moveClassReference is BlankMove:
		push_warning("Trying to slot one move over another. Delete the original move first.")
		return
	
	targetArray.erase(moveAtLocation) #Buh bye blank move!
	targetArray.append(instancedMove)
	instancedMove.moveLocation = location
	instancedMove.moveSlot = slot
	
	SortInstancedMoves(targetArray)




static func AdjustMoveLevels(targetArray : Array[MoveInstance]):
	for move in targetArray:
		move.moveLevel = 0
		move.infiniteUses = false
		move.maxUses = move.moveClassReference.defaultMaxUses
		
		if move.moveClassReference.displayName == "Wait":
			move.infiniteUses = true
	
	
	SortInstancedMoves(targetArray)
	
	EquippedBackpack.ApplyBackpackLevelChanges(targetArray)
	
	for move in targetArray:
		move.RecalculateMoveLevels(targetArray)

static func AppendMoveLibrary(TargetScene):
	var folders = TargetScene.get_children()
	var allMoves = []
	for folder in folders:
		var children = folder.get_children()
		for child in children:
			allMoves.append(child)
	
	for move in allMoves:
		MoveLibrary[move.name] = move

static func AppendMementoLibrary(TargetScene):
	var allMementos = []
	var children = TargetScene.get_children()
	for child in children:
		allMementos.append(child)
	
	for memento in allMementos:
		MementoLibrary[memento.GetExternalName()] = memento

static func AppendBackpackLibrary(TargetScene):
	var allBackpacks = []
	var children = TargetScene.get_children()
	for child in children:
		allBackpacks.append(child)
	
	for backpack in allBackpacks:
		BackpackLibrary[backpack.name] = backpack

static func SortInstancedMoves(targetArray):
	targetArray.sort_custom(MoveSortOrder)

static func MoveSortOrder(a : MoveInstance, b : MoveInstance) -> bool:
	var slotValuea = int(a.moveLocation)
	var slotValueb = int(b.moveLocation)
	
	if slotValuea == slotValueb:
		return a.moveSlot < b.moveSlot
	else:
		return slotValuea < slotValueb




static func SerializeMoveset(moveList : Array[MoveInstance]) -> PackedByteArray:
	SortInstancedMoves(moveList)
	var movesWithDetails = []
	
	movesWithDetails.append(MoveManager.EquippedBackpack.name)
	
	for move in moveList:
		var moveLoc = move.moveLocation
		
		if not [MoveInstance.moveLocations.Sidepack, MoveInstance.moveLocations.Inventory].has(moveLoc):
			continue
		
		var name = move.moveClassReference.name
		
		if name.is_empty():
			movesWithDetails.append([move.moveClassReference.name])
		else:
			movesWithDetails.append([move.moveClassReference.name, MoveModificationData.Serialize(move)])
	
	return var_to_bytes(movesWithDetails)


static func DeserializeMoveset(bytes : PackedByteArray):
	var output : Array = bytes_to_var(bytes)
	var packName = output[0]
	var usedBackpack : Backpack = MoveManager.BackpackLibrary[packName]
	
	output.remove_at(0)
	
	var finalMoveArray = []
	
	var currentlyTargetedSlot = 0
	var currentlyTargetedLocation = MoveInstance.moveLocations.Sidepack
	
	if usedBackpack.MaxSidepackSlots <= 0:
		currentlyTargetedLocation = MoveInstance.moveLocations.Inventory
	
	for stowedMove in output:
		var moveName = stowedMove[0]
		
		var generatedMove = null
		
		if moveName.is_empty():
			generatedMove = MoveManager.MoveInstanceFromString("Blank")
		else:
			
			var moveParams = stowedMove[1]
			
			generatedMove = MoveManager.MoveInstanceFromString(moveName)
			MoveModificationData.Deserialize(moveParams, generatedMove)
		
		generatedMove.moveLocation = currentlyTargetedLocation
		generatedMove.moveSlot = currentlyTargetedSlot
		
		currentlyTargetedSlot += 1
		
		if currentlyTargetedLocation == MoveInstance.moveLocations.Sidepack && currentlyTargetedSlot >= usedBackpack.MaxSidepackSlots:
			currentlyTargetedLocation = MoveInstance.moveLocations.Inventory
			currentlyTargetedSlot = 0
		
		finalMoveArray.append(generatedMove)
	
	var waitMove = MoveManager.MoveInstanceFromString("Wait")
	waitMove.moveLocation = MoveInstance.moveLocations.Fixed
	waitMove.moveSlot = 0
	finalMoveArray.append(waitMove)
	
	return [usedBackpack, finalMoveArray]
