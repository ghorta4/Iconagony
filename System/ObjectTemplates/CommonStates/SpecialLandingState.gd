extends CharacterState

@export var landingState : String = "Idle"

func Tick():
	super()
	if host.IsOnGround():
		host.ChangeState(landingState)
