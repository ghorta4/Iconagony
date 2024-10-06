extends CharacterState


func OnEnter():
	super()
	var powerMult = 1
	if powerModifier < 0:
		powerMult = pow(0.8, -powerModifier)
	elif  powerModifier > 0:
		powerMult += powerModifier * 0.3
	
	if parameters == null:
		parameters = Vector2.ZERO
	
	host.velocity += parameters * 240 * powerMult
	host.ignoreProjectileHitboxes = true
	host.ignoreGrabHitboxes = true
	host.ignoreMeleeHitboxes = true

func OnExit():
	EndImmunity()

func Frame3():
#	host.ignoreMeleeHitboxes = true
	pass

func Frame14():
	EndImmunity()

func EndImmunity():
	host.ignoreProjectileHitboxes = false
	host.ignoreGrabHitboxes = false
	host.ignoreMeleeHitboxes = false
	pass
