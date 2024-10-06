extends CharacterObject


var facingAngle : float = 0 #radians
var repsTillFireSelf = 3 # varies from 2 to 4

func CopyTo(new):
	super(new)
	if new.sprite != null && sprite != null:
		new.sprite.rotation = facingAngle
		new.sprite.modulate = sprite.modulate

func Tick():
	
	super()
	
	var myState = CurrentState()
	if myState is CharacterState && myState.isHurtState:
		fallSpeed = 450
	else:
		fallSpeed = 0
	
	AIFunctions()
	


func AIFunctions():
	var myState = CurrentState()
	
	var targets = GetEnemiesSortedByDistance()
	if targets.size() == 0:
		return
	
	var target = targets[0]
	var distToTarget = position - target.position
	var shouldHeadLeft = (distToTarget.x > 0)
	distToTarget.x = abs(distToTarget.x)
	
	if myState.name == "Fire" || myState.name == "FireSelf":
			myState.target = target
	
	if CanAct():
		if repsTillFireSelf <= 0:
			repsTillFireSelf = int((GetRandom() * 3. / 100.0) + 1)
			ChangeState("FireSelf")
			return
		
		if myState.name == "Fire":
			myState.Restart(false)
			stateInterruptable = false
			repsTillFireSelf -= 1
			return
		
		if distToTarget.length() < 500 && distToTarget.x < 300:
			flipX = shouldHeadLeft
			ChangeState("Hang")
			return
	
	
	if myState.name == "Idle": #This is how this guy moves
		flipX = shouldHeadLeft
		
		velocity -= distToTarget.normalized() * Vector2(2 * GetFacingInt() * -1, 0.5) * 220 * frameLength
		return
	
