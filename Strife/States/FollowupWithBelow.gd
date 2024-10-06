extends CharacterState

func Tick():
	super()
	if currentTick == duration - 2 || (host.lateHitcancelTicks <= 1 && host.lateHitcancelTicks > -1):
		TryToUseMoveBelow()


func TryToUseMoveBelow():
	var desiredLocation = host.lastQueuedMoveLocation
	var desiredMoveSlot = host.lastQueuedMoveSlot + 1
	if desiredLocation == MoveInstance.moveLocations.Sidepack:
		desiredLocation = MoveInstance.moveLocations.Inventory
		desiredMoveSlot = 0
	
	var nextMove = MoveManager.GetMoveAtPosition(desiredLocation, desiredMoveSlot, host.instancedMoves)
	
	if nextMove == null:
		host.stateInterruptable = true
		return
	if not nextMove.moveClassReference.IsUsable(host):
		host.stateInterruptable = true
		return
	host.stateInterruptable = false
	
	var usedData = null
	if nextMove.predictionMemorizedInput != null:
		usedData = nextMove.predictionMemorizedInput
	elif nextMove.relevantMoveControls != null:
		usedData = nextMove.relevantMoveControls.GetData()
	
	var moveToRemoveDurabilityOf = MoveManager.GetMoveAtPosition(desiredLocation, desiredMoveSlot, host.instancedMoves)
	if moveToRemoveDurabilityOf != null:
		moveToRemoveDurabilityOf.remainingUses -= 1
		
		if moveToRemoveDurabilityOf.remainingUses <= 0:
			var arrayToUse = host.instancedMoves
			MoveManager.BreakMoveAtPosition(moveToRemoveDurabilityOf.moveLocation, moveToRemoveDurabilityOf.moveSlot, arrayToUse)
			if not host.isGhost:
				host.battleInstance.loadedUI.RegenerateMoveObjects()
	
	var MidiDict = ReplayManager.replayFile.MIDI
	var battleInstanceTick = host.battleInstance.currentTick
	if not host.battleInstance.readFromReplay && not host.isGhost:
		if not MidiDict.has(battleInstanceTick):
			MidiDict[battleInstanceTick] = {}
		MidiDict[battleInstanceTick].extraData = usedData
	elif not host.isGhost && host.battleInstance.readFromReplay:
		usedData = MidiDict[battleInstanceTick].extraData
	host.ChangeState(nextMove.moveClassReference.GetUsedState(host), usedData, powerModifier + 1)
	host.lastQueuedMoveLocation = desiredLocation
	host.lastQueuedMoveSlot = desiredMoveSlot
