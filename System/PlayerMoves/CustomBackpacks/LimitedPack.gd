extends Backpack

func ApplyBackpackLevelChanges(targetArray):
	super(targetArray)
	for move in targetArray:
		if move.moveLocation == MoveInstance.moveLocations.Sidepack:
			move.infiniteUses = true
			move.moveLevel -= 1
		
		if move.moveLocation == MoveInstance.moveLocations.Inventory:
			if move.moveSlot > 3:
				move.moveLevel -= 1
