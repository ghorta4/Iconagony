extends CharacterState

var currentRepeats = 0

func _init():
	stateVariablesList.append_array(["currentRepeats"])

func CopyTo(new):
	super(new)

func Tick():
	super()
	if currentTick == 26 && currentRepeats <= powerModifier:
		if host.lateHitcancelTicks > 0:
			host.lateHitcancelTicks += 10
		host.SpawnAfterImage(0.2, Color(1,1,1,0.5))
		currentRepeats += 1
		currentRealTick = 16
		currentTick = 16
		host.position += Vector2(host.GetFacingInt() * 100, 0)
		host.flipX = !host.flipX
		host.velocity += Vector2(host.GetFacingInt(), 0) * enterForce
		host.PlaySound("Phase")


func OnEnter():
	super()
	currentRepeats = 0
