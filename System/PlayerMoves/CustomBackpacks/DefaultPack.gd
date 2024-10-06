extends Backpack

func ApplyBackpackLevelChanges(targetArray):
	super(targetArray)
	for move in targetArray:
		if move.moveLocation == MoveInstance.moveLocations.Sidepack:
			move.infiniteUses = true
			if move.moveSlot == 0:
				move.moveLevel += 1
			if move.moveSlot == 1:
				move.moveLevel += 2
