extends CharacterState

@export var OtherIdleState : String = "IdleAir"
@export var InterruptabilityInterval : int = 15
@export var useDefaultAirIdleSwitching : bool = true
func Tick():
	super()
	if useDefaultAirIdleSwitching:
		if name == "Idle" && not host.IsOnGround():
			host.ChangeState(OtherIdleState)
			return
		if name == "IdleAir" && host.IsOnGround():
			host.ChangeState(OtherIdleState)
			return
	if currentRealTick > 1 && currentRealTick % InterruptabilityInterval == 0:
		host.stateInterruptable = true
