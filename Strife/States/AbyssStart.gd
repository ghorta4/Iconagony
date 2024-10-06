extends CharacterState


func Frame16():
	if parameters == null:
		parameters = Vector2.ZERO
	host.velocity += (parameters * Vector2(1, 1.1) * (1 + powerModifier * 0.2) + Vector2.UP * 2) * 320
