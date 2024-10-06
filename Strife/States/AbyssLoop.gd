extends CharacterState

@export var landingState : String = "Idle"

var stickyFoes = {} #x is ID, y is Vector2 with offset

@onready var finisherHitbox = $"EndHitbox"

func OnEnter():
	super()
	stickyFoes = {}

func CopyTo(new):
	super(new)
	
	new.stickyFoes = stickyFoes.duplicate(true)

func Tick():
	super()
	if host.IsOnGround():
		host.ChangeState(landingState)
	
	for key in stickyFoes:
		var otherGuy = host.battleInstance.FindCharacterOfID(key)
		if otherGuy == null:
			stickyFoes.erase(key)
			continue
		var theirState = otherGuy.CurrentState()
		if not theirState is CharacterState || not theirState.isHurtState:
			stickyFoes.erase(key)
			continue
		var value = stickyFoes[key]
		otherGuy.position = host.position + value * Vector2(-1, 1) + Vector2.DOWN * 50

func OnHit(target : GameObject, hitbox):
	super(target, hitbox)
	if not target is CharacterObject:
		return
	
	if stickyFoes.has(target.id):
		return
	
	stickyFoes[target.id] = host.position - target.position

func OnExit():
	host.flipX = !host.flipX
	for key in stickyFoes:
		var otherGuy = host.battleInstance.FindCharacterOfID(key)
		if otherGuy == null:
			stickyFoes.erase(key)
			continue
		var theirState = otherGuy.CurrentState()
		if not theirState is CharacterState || not theirState.isHurtState:
			stickyFoes.erase(key)
			continue
		otherGuy.HitBy(finisherHitbox.GetData()) 
	
	if stickyFoes.size() > 0:
		finisherHitbox.PlayHitSFX()
	
	super()
	var newState = host.CurrentState()
	newState.targetsHit[1] = []
	for key in stickyFoes:
		newState.targetsHit[1].append(key) 
	
	var endHitbox = newState.get_child(0)
	if endHitbox == null:
		return
	endHitbox.selfHitstopTicks = 12 if stickyFoes.size() == 0 else 0
	
	newState.Tick()
