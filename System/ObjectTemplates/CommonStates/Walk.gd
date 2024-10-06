extends CharacterState

@export var InterruptabilityInterval : int = 15
@export var WalkSpeed : float = 1.0
func Tick():
	super()
	host.velocity.x += host.GetFacingInt() * WalkSpeed * 0.5
	if currentRealTick > 1 && currentRealTick % InterruptabilityInterval == 0:
		host.stateInterruptable = true
