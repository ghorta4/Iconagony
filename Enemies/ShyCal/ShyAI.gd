extends CharacterObject

func Tick():
	super()
	
	if CanAct():
		DecideWhatMoveToUse()
		stateInterruptable = false

func DecideWhatMoveToUse():
	var targets = GetEnemiesSortedByDistance()
	if targets.size() == 0:
		return
	#Approach if far out of range.
	var target = targets[0]
	var distToTarget = position - target.position
	
	if not IsOnGround():
		return
	
	if abs(distToTarget.x) < 50:
		if CurrentState().currentTick > 15:
			ChangeState("Atk1")
			return
		
		if CurrentState().currentTick < 12:
			ChangeState("Atk2")
			return
	
	if distToTarget.x * GetFacingInt() > 0 && CurrentState().currentTick > 15: #flip if wrong direction
		ChangeState("Turn")
		return
	

func GetIdealStowedRandomSize() -> int:
	return 8
