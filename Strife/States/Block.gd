extends CharacterState

func OnEnter():
	super()
	IASA = 20
	
	if host.IsOnGround():
		animationName = "BlockH"
	else:
		animationName = "BlockA"
