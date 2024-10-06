extends ProjectileObject

var currentTimeAlive : int = 0

func Tick():
	super()
	currentTimeAlive += 1
	
	var myState = CurrentState()
	if myState.name == "loop":
		sprite.rotation = currentTimeAlive * 0.15
		if (position.y > -20 || currentTimeAlive > 55):
			ChangeState("end")
	
	var inPath = GetAllHitInLine(position, velocity * frameLength, 5)
	
	for target in inPath:
		if target.team != team:
			ChangeState("end")
			break


func HitBy(hitbox : Hitbox):
	super(hitbox)
	AttemptToSwitchTeams(hitbox.player)
	currentTimeAlive = 0
