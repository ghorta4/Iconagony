class_name Mote

#A special generic object that's put onto objects in a special list to perform tasks over time, such as sprite shaking, DoT, et cetera. Updated every frame. Can also be placed
#onto the battle manager for stuff like screen shakes...
var assignedObject : GameObject

var maxDuration = 5
var ticksLeft = 5

var ignoreHitstop : bool = true

var stateVariables = ["maxDuration", "ticksLeft", "ignoreHitstop"]

func CopyTo(new):
	for varName in stateVariables:
		if get(varName) is Vector2:
			var old = self[varName]
			new.set(varName, Vector2(old))
			continue
		
		new[varName] = self[varName]

func Tick():
	ticksLeft -= 1

func DurationFraction() -> float:
	return float(ticksLeft) / maxDuration

func SetDuration(length : int):
	maxDuration = length
	ticksLeft = length

func MyClass():
	return load("res://System/Motes/Mote.gd")
