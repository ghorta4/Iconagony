extends CharacterState

func OnEnter():
	host.taleFromDownUnderTicks = 60
	super()
	host.velocity += parameters * 80
	
	host.taleFromDownUnderLevel = powerModifier


func Tick():
	host.taleFromDownUnderTicks = 60
	super()

func OnExit():
	super()
	host.sprite.z_index = 6
