extends CharacterState

var foesTargeted = []
var originalPos = Vector2.ZERO
func OnEnter():
	foesTargeted.clear()
	originalPos = host.position
	super()

func CopyTo(o):
	super(o)
	o.foesTargeted.clear()
	for foe in foesTargeted:
		o.foesTargeted.append(foe)

func Tick():
	if currentTick > 10 && currentTick < 34:
		host.SpawnAfterImage(0.34, Color(0.14, 0.28, 0.94))
	super()


func Frame0():
	host.velocity += Vector2(host.GetFacingInt() * -10, 0)

func Frame13():
	host.velocity += Vector2(host.GetFacingInt() * 2800, 0)

func Frame16():
	TryTeleportToNewTarget()

func Frame33():
	TryTeleportToNewTarget()

func TryTeleportToNewTarget():
	if foesTargeted.size() >= 3:
		return
	
	var validTargets = host.GetEnemiesSortedByDistance(originalPos)
	var toTrim = []
	
	var rangeBoost = powerModifier + 40
	
	for target in validTargets:
		if foesTargeted.has(target.id):
			toTrim.append(target)
			continue
		
		if abs(target.position.x - host.position.x) > 100 + rangeBoost && (target.position - originalPos).length() > 200 + rangeBoost:
			toTrim.append(target)
			continue
	
	for trim in toTrim:
		validTargets.erase(trim)
	
	if validTargets.size() <= 0:
		return
	
	if foesTargeted.size() == 1 || foesTargeted.size() == 2:
		host.flipX = !host.flipX
	
	var target = validTargets[0]
	foesTargeted.append(target.id)
	host.velocity = Vector2(host.GetFacingInt() * 600, 0)
	host.position = target.position + Vector2.LEFT * 80 * host.GetFacingInt()
	currentRealTick = 17
	currentTick = 17

func OnExit():
	super()
	foesTargeted.clear()
