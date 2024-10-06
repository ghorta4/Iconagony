extends CharacterState

@export var speed : float = 1.0
@export var startMovingAt : int = 1

func OnEnter():
	super()
	
	if stateMachine.stateIsRepeated:
		currentTick = startMovingAt - 1

func Tick():
	super()
	
	if currentTick == startMovingAt:
		var powerMult = 1
		if powerModifier < 0:
			powerMult = pow(0.8, -powerModifier)
		elif  powerModifier > 0:
			powerMult += powerModifier * 0.5
		if parameters == null:
			parameters = 100.0
		
		host.velocity += speed * Vector2.RIGHT * lerp(0.5, 1.0, parameters / 100.0) * powerMult * host.GetFacingInt() * 60.0
