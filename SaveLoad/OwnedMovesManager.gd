class_name OwnedMovesManager

static var OwnedMovesLibrary : Dictionary = {} #Keys are move names. Values are sub tuples. Sub tuples are as follows: key is the move details,
# value is the number of copies, value2 is the number of copies remaining in the current moveset (for move adjustments


static func AddMoveToOwnedMoves(instance : MoveInstance):
	var moveName = instance.moveClassReference.name
	if moveName.is_empty():
		push_warning("Cannot add blank move to inventory.")
		return
	if not OwnedMovesLibrary.has(moveName):
		OwnedMovesLibrary[moveName] = []
	
	var subTup = OwnedMovesLibrary[moveName]# MoveModificationData.GenerateModDataFromMove(instance)
	
	var instanceData = MoveModificationData.GenerateModDataFromMove(instance)
	
	for pair in subTup:
		if pair[0].isEqualTo(instanceData):
			pair[1] += 1
			pair[2] += 1
			return
	
	subTup.append([instanceData, 1, 1]) #Adding something that wasn't there before

static func GetNumberOfMovesWithName(moveName : String) -> int:
	
	var count = 0
	
	for key in OwnedMovesLibrary.keys():
		if key == moveName:
			
			var tuple = OwnedMovesLibrary[key]
			
			for array in tuple:
				count += array[1]
			
			break
	
	return count

static func GetNumberOfMovesAvailableWithNameAndData(moveName : String, moveData : MoveModificationData) -> int:
	
	for key in OwnedMovesLibrary.keys():
		if key == moveName:
			
			var tuple = OwnedMovesLibrary[key]
			
			for array in tuple:
				if array[0].isEqualTo(moveData):
					return array[2]
			
			return 0
	
	
	return 0


static func CountAvailableMovesBasedOnMoveset(movesUsed : Array[MoveInstance]):
	for move in OwnedMovesLibrary:
		for detail in OwnedMovesLibrary[move]:
			if detail.size() == 2:
				detail.append(0)
			detail[2] = detail[1] #Moves available = max moves of this decor type owned
	
	for move in movesUsed:
		if move.moveLocation != MoveInstance.moveLocations.Sidepack && move.moveLocation != MoveInstance.moveLocations.Inventory:
			continue
		
		if move.moveClassReference is BlankMove:
			continue
		
		if not OwnedMovesLibrary.has(move.moveClassReference.name):
			push_warning("Player has move they do not own in their moveset. " + move.DebugReadout())
			continue
		
		var desiredLibrary = OwnedMovesLibrary[move.moveClassReference.name]
		
		var moveDetails = MoveModificationData.GenerateModDataFromMove(move)
		
		var moveFound = false
		for tuple in desiredLibrary:
			if tuple[0].isEqualTo(moveDetails):
				tuple[2] -= 1
				
				if tuple[2] < 0:
					push_warning("Player has too many moves in their moveset of a certain style. "  + move.DebugReadout())
				
				moveFound = true
				break
			
		
		if not moveFound:
			push_warning("Move with those details not found in owned move library. " + move.DebugReadout())


static func GetNextAvailableModDataForMove(moveName : String) -> MoveModificationData:
	if not OwnedMovesLibrary.has(moveName):
		return null
	
	var library = OwnedMovesLibrary[moveName]
	
	for subSet in library:
		if subSet[2] > 0:
			return subSet[0]
	
	return null



static func CheckMoveCountSafeguard():
	var moveLineCount = GetNumberOfMovesWithName("The Line")
	
	if moveLineCount <= 0:
		var toAdd = MoveManager.MoveInstanceFromString("The Line")
		var data = MoveModificationData.GenerateModDataFromMove(toAdd)
		data.ApplyTo(toAdd)
		AddMoveToOwnedMoves(toAdd)
	
	var moveAscendCount = GetNumberOfMovesWithName("Ascend")
	
	if moveAscendCount <= 0:
		var toAdd = MoveManager.MoveInstanceFromString("Ascend")
		var data = MoveModificationData.GenerateModDataFromMove(toAdd)
		data.ApplyTo(toAdd)
		AddMoveToOwnedMoves(toAdd)
	
	var moveEscapadeCount = GetNumberOfMovesWithName("Escapade")
	
	if moveEscapadeCount <= 0:
		var toAdd = MoveManager.MoveInstanceFromString("Escapade")
		var data = MoveModificationData.GenerateModDataFromMove(toAdd)
		data.ApplyTo(toAdd)
		AddMoveToOwnedMoves(toAdd)
	
	
	#var testy = MoveManager.MoveInstanceFromString("The Line")
	#var data = MoveModificationData.GenerateModDataFromMove(testy)
	#data.ApplyTo(testy)
	#testy.slottedMementos[0] = MoveManager.MementoLibrary["PaleGlass"]
	#AddMoveToOwnedMoves(testy)


static func SaveAllMoves(savePath : String):
	
	var replicantDict = OwnedMovesLibrary.duplicate(true)
	#Trims off the extra data relating to a temporary variable describing the number of each move we currently have. Which... doesn't matter for saves.
	for key in replicantDict:
		var value = replicantDict[key]
		
		for tuple in value:
			while tuple.size() > 2: 
				tuple.remove_at(2)
			
			tuple[0] = tuple[0].LibrarySerialize()
	
	var savedList = var_to_bytes(replicantDict)
	
	#savedList.compress(1)
	
	var file = FileAccess.open(savePath, FileAccess.WRITE) #be sure to have a handler if this is null
	file.store_buffer(savedList)
	file.close()

static func LoadAllMoves(loadPath : String):
	var loadedStream = FileAccess.get_file_as_bytes(loadPath)
	
	if loadedStream == null:
		push_warning("File load failure.")
		return
	
	var loadedList = bytes_to_var(loadedStream)
	
	if loadedList == null:
		push_warning("No save found.")
		return
	
	for key in loadedList: #restores encoded objects
		var value = loadedList[key]
		for tuple in value:
			tuple[0] = MoveModificationData.Deserialize(tuple[0])
			tuple.append(0)
	
	OwnedMovesLibrary = loadedList

static func SaveMoveset(moves : Array[MoveInstance], saveLocation : String):
	var validMoveTargets : Array[MoveInstance] = []
	for move in moves:
		if move.moveLocation == MoveInstance.moveLocations.Inventory || MoveInstance.moveLocations.Sidepack:
			validMoveTargets.append(move)
	
	MoveManager.SortInstancedMoves(validMoveTargets)
	
	var stowedAsData = MoveManager.SerializeMoveset(validMoveTargets)
	
	var file = FileAccess.open(saveLocation, FileAccess.WRITE) #be sure to have a handler if this is null
	file.store_buffer(stowedAsData)
	file.close()

#Returns if the load succeeded or not.
static func LoadMoveset(player : CharacterObject, loadPath : String) -> bool: 
	var loadedStream = FileAccess.get_file_as_bytes(loadPath)
	
	if loadedStream == null:
		push_warning("Moveset load failure.")
		return false
	
	var loadedList = null
	if loadedStream.size() >= 4:
		bytes_to_var(loadedStream)
	
	if loadedList == null:
		push_warning("No moveset found.")
		return false
	
	var tuple = MoveManager.DeserializeMoveset(loadedStream)
	
	MoveManager.EquippedBackpack = tuple[0]
	var parse : Array[MoveInstance] = []
	parse.append_array(tuple[1])
	player.instancedMoves = parse
	return true

static func DumpAllMoves():
	OwnedMovesLibrary = {}
	CheckMoveCountSafeguard()
