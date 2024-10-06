extends CharacterState


func OnEnter():
	super()
	if parameters == null:
		parameters = Vector2.ZERO
	host.velocity += parameters * 320
