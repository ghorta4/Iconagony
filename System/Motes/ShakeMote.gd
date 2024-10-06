extends PlayerMote
class_name ShakeMote
var intensity = 1.0

func _init():
	stateVariables.append("intensity")

func MyClass():
	return load("res://System/Motes/ShakeMote.gd")

func Tick():
	super()
	if assignedObject == null:
		return
	var yMult = 1
	if assignedObject is CharacterObject && assignedObject.IgnoreYShake == true:
		yMult = 0
	assignedObject.sprite.position = Vector2(RNGManager.GrabUnseededFloat(), RNGManager.GrabUnseededFloat() * yMult) * intensity * DurationFraction()
