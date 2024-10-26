extends IdleState


func Tick():
	super()
	
	host.velocity.x = 0
	if currentTick > 1 && currentTick < 8:
		host.position += Vector2(3,0) * host.GetFacingInt()
	
	if currentTick > 10 && currentTick < 16:
		host.position += Vector2(0.4,0) * host.GetFacingInt()

func Frame2():
	host.PlaySound("Move1")

func Frame8():
	holdFrames = 4
	host.stateInterruptable = true
	#if host.battleInstance.currentTick < 6:

func Frame10():
	host.PlaySound("Move2")

func Frame17():
	holdFrames = 4
	host.stateInterruptable = true
