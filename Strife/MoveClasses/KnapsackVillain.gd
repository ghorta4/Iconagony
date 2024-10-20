extends MoveClass

class_name KnapsackVillainMoveClass

func MoveLevelProcessing(myInstance : MoveInstance,targetArray : Array[MoveInstance]): 
	if not myInstance.moveLocation == MoveInstance.moveLocations.Inventory:
		if myInstance.moveLocation == MoveInstance.moveLocations.Sidepack:
			for otherMove in targetArray:
				if not otherMove.moveLocation == MoveInstance.moveLocations.Inventory:
					continue
				var isValidTarget = otherMove.tags.has("Pickup")
				if isValidTarget:
					otherMove.moveLevel += myInstance.moveLevel + 1
		return
	for otherMove in targetArray:
		if not otherMove.moveLocation == myInstance.moveLocation:
			continue
		var isValidTarget = otherMove.tags.has("Pickup")
		if otherMove.moveSlot == myInstance.moveSlot - 1 && isValidTarget: #above by 1
			otherMove.moveLevel += 1
		if otherMove.moveSlot == myInstance.moveSlot + 1 && isValidTarget: #below by 1
			otherMove.moveLevel += 1
