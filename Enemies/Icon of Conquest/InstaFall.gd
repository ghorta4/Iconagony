extends CharacterState

func OnEnter():
	super()
	host.position.y = -1 * host.GetLowestY()
	host.velocity.y = 0
	host.ChangeState("FallRecover")
