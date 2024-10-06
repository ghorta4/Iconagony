extends ProjectileObject

@onready var lineDisplay = $"Sprite/Line2D"
@onready var hittingBox = $"StateMachine/Default/Hitbox"
func Tick():
	velocity *= 0.97
	var forceY0 = false
	if velocity.y * frameLength + position.y >= 0 && velocity.y > 0:
		velocity.y *= -1
		position.y = 0
		creatorMoveLevel += 1
		PlaySound("Bounce")
		hitstopTicks = 3
		forceY0 = true
	super()
	if forceY0:
		position.y = 0
	if CurrentState().name == "Default":
		UpdateBulletForm()


func CopyTo(new):
	super(new)
	new.sprite.visible = sprite.visible

func UpdateBulletForm():
	var aimVector = velocity.normalized()
	var lineSize = velocity.length() / 100.
	var facingV2 = Vector2(GetFacingInt(), 1)
	var start = aimVector * lineSize / 2.0 * facingV2
	var end = aimVector * lineSize / -2.0  * facingV2
	
	if hitstopTicks > 0:
		lineDisplay.points = PackedVector2Array([Vector2.LEFT, Vector2.RIGHT])
		lineDisplay.width = 5
	else:
		lineDisplay.points = PackedVector2Array([start, end])
		lineDisplay.width = 3
	
	var toHit = ConditionalHitInLine((velocity * facingV2 * -1 * frameLength) * 0 + position , velocity * 2 * frameLength, 3, false, false, false, true, false)
	
	var shouldDie = false
	
	hittingBox.knockbackDirection = velocity * facingV2
	hittingBox.knockbackForce = velocity.length() * 0.2
	for hit in toHit:
		hit.HitBy(hittingBox.GetData())
		shouldDie = true
	
	if shouldDie:
		CurrentState().get_child(0).PlayHitSFX()
		sprite.visible = false
		ChangeState("Dying")
