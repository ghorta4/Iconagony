extends CharacterState

func OnEnter():
	if (host.velocity.x > 0) == (host.GetFacingInt() > 0):
		animationName = "HurtOTGF"
	else:
		animationName = "HurtOTGB"
	super()
