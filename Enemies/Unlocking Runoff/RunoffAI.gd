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
	
	var wrongFlip = GetRandom() > 90.0 - SP / 15.0
	
	var shouldHeadLeft = (distToTarget.x > 0) != (wrongFlip) #Intentionally head the wrong way sometimes...
	
	var jumpRandom = GetRandom()
	
	if not IsOnGround():
		if (distToTarget.y < 50 && jumpRandom > 10.0) || (jumpRandom > 90.0):
			ChangeState("DivebombStart")
			queuedFlip = flipX
			return
		
		return
	
	#stress based reactions
	
	if GetRandom() < -30 + GetStressPercent() * 60.:
		ChangeState("Idle")
		return
	
	if GetRandom() < GetStressPercent() * 4.:
		ChangeState("Thrust")
		return
	
	if (distToTarget.y > 70 && jumpRandom > 80.0) || (jumpRandom > 95.0): #Jumping
		flipX = shouldHeadLeft
		ChangeState("Jump")
		return
	
	if abs(distToTarget.x) > 85 - SP / 3.0:
		flipX = shouldHeadLeft
		ChangeState("Walk")
		return
	
	var skipNext = GetRandom()
	if distToTarget.y < 20 && skipNext > 30.0:
		flipX = shouldHeadLeft
		ChangeState("Thrust")
		return
	
	if distToTarget.y < 90:
		flipX = shouldHeadLeft
		ChangeState("Sweep")
		return
	
	ChangeState("Idle")
	flipX = flipX

func GetIdealStowedRandomSize() -> int:
	return 8
