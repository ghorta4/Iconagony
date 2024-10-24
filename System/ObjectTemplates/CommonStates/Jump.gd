extends CharacterState

@export var jumpTick : int = 4
@export var jumpForce : float = 300

func Tick():
	super()
	
	if currentTick == jumpTick:
		var powerMult = 1
		if powerModifier < 0:
			powerMult = pow(0.8, -powerModifier)
		elif  powerModifier > 0:
			powerMult += powerModifier * 0.3
		
		if parameters == null:
			parameters = Vector2.UP * 1
		
		host.velocity += parameters * jumpForce * powerMult
		
