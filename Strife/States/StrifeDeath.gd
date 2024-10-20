extends CharacterState

func OnEnter():
	super()
	host.stateInterruptable = false
