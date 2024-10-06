extends GameObject
class_name ProjectileObject

@export var deflectable : bool = true
@export var intangible : bool = false

var creatorMoveLevel : int = 0 #Used to allow projectiles to be strengthened with normal move level scaling... or something like that.
var creator

func _init():
	stateVariablesList.append_array(["creatorMoveLevel", "deflectable", "intangible"])

func CopyTo(new):
	super(new)
	if is_instance_valid(creator):
		new.creator = new.battleInstance.FindCharacterOfID(creator.id)
	else:
		disabled = true

func HitBy(hitboxData : HitboxData):
	if intangible:
		return
	
	super(hitboxData)

func AttemptToSwitchTeams(newOwner : GameObject):
	if not deflectable:
		return
	if newOwner is CharacterObject:
		material = newOwner.material
		team = newOwner.team
	elif newOwner is ProjectileObject:
		if newOwner.creator == null:
			return
		material = newOwner.creator.material
		team = newOwner.team
