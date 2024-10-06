extends BattleInstanceMote
class_name ScreenShakeMote
var intensity = 1.0
var direction = Vector2.ONE

func _init():
	stateVariables.append("intensity")

func MyClass():
	return load("res://System/Motes/ShakeMote.gd")

func Tick():
	super()
	assignedInstance.main.cameraJostle += Vector2(randf() - 0.5, randf() - 0.5) * intensity
