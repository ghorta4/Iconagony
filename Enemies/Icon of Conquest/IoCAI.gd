extends CharacterObject

var wasStunnedLastTick = false
var stockpiledHealth = 100
func Tick():
	super()
	
	
	 #as per being an icon, randomly adjust health after recovering from stun...
	if wasStunnedLastTick && stunTicks <= 0:
		var maxPossibleRoll = min(MaxHP, HP + stockpiledHealth)
		var newRolledHP = floor(GetRandom() * maxPossibleRoll / 100.0)
		newRolledHP = (newRolledHP + 75) / (MaxHP + 75) * MaxHP
		newRolledHP = clamp(newRolledHP, 1, maxPossibleRoll)
		
		var diff = newRolledHP - HP
		stockpiledHealth -= diff
		HP = newRolledHP
		
		SpawnAfterImage(0.6, Color.WHITE)
	
	
	wasStunnedLastTick = stunTicks > 0
	
	if CanAct():
		DecideWhatMoveToUse()
		stateInterruptable = false


func DecideWhatMoveToUse():
	
	var targets = GetEnemiesSortedByDistance()
	if targets.size() == 0:
		return
	
	var target = targets[0]
	var distToTarget = position - target.position
	var shouldHeadLeft = (distToTarget.x > 0)
	distToTarget.x = abs(distToTarget.x)
	
	
	
	var shouldSleep = GetRandom() < distToTarget.x - 200 && GetRandom() < 50
	
	var myState = CurrentState()
	
	if myState.name == "Dash": #special dash actions here
		var facingTarget = ((position - target.position).x > 0) == flipX
		
		if not facingTarget || distToTarget.x < 150:
			ChangeState("DashSlash")
		return
	
	#stress based reactions
	
	if GetRandom() < -30 + GetStressPercent() * 60.:
		ChangeState("Idle")
		return
	
	if GetRandom() < GetStressPercent() * 30.:
		ChangeState("OverheadSlash")
		return
	
	
	if (distToTarget.x < 30 && not GetRandom() < 30): #Backstep slash
		flipX = shouldHeadLeft
		ChangeState("RetreatSlash")
		return
	
	
	if (distToTarget.x < 90): #Upper slash
		flipX = shouldHeadLeft
		ChangeState("OverheadSlash")
		return
	
	if (not shouldSleep):
		flipX = shouldHeadLeft
		ChangeState("DashStart")
		return
	
	ChangeState("Idle")
	flipX = flipX

func GetIdealStowedRandomSize() -> int:
	return 7

func CopyTo(new):
	super(new)
