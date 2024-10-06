extends CharacterState


func OnEnter():
	var stowedHitTargets = targetsHit
	super()
	targetsHit = stowedHitTargets
