extends CharacterState


func OnEnter():
	super()
	host.battleInstance.universalHitstop = 24
	host.scenematicGlobalPauseMove = true


func Frame24():
	host.scenematicGlobalPauseMove = false

func OnExit():
	super()
	host.ignoreGrabHitboxes = false
	host.ignoreMeleeHitboxes = false
	host.ignoreProjectileHitboxes = false
