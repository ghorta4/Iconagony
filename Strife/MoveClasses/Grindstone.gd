extends MoveClass

class_name GrindstoneMoveClass

func MoveLevelProcessing(myInstance : MoveInstance,targetArray : Array[MoveInstance]): 
	if not myInstance.moveLocation == MoveInstance.moveLocations.Inventory:
		if myInstance.moveLocation == MoveInstance.moveLocations.Sidepack:
			for otherMove in targetArray:
				if not otherMove.moveLocation == MoveInstance.moveLocations.Inventory:
					continue
				var maxSlots = MoveManager.EquippedBackpack.MaxMoveSlots
				if otherMove.moveSlot < floor(maxSlots / 2.0):
					otherMove.moveLevel += (myInstance.moveLevel + 1)
				if otherMove.moveSlot > ceil(maxSlots / 2.0):
					otherMove.moveLevel -= (myInstance.moveLevel + 1)
		return
	for otherMove in targetArray:
		if not otherMove.moveLocation == myInstance.moveLocation:
			continue
		if otherMove.moveSlot == myInstance.moveSlot - 1: #above by 1
			otherMove.moveLevel += 1
		if otherMove.moveSlot == myInstance.moveSlot + 1: #below by 1
			otherMove.moveLevel -= 1
