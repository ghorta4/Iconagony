extends BattleInstanceMote
class_name CameraZoomMote
var desiredZoom : float = 1.0
var zoomLerpSpeed : float = 0.5 #How fast to move to the new zoom. 0 is not at all, 1 is max.
var targetedObject : GameObject = null #Will change to centering the camera on an object if not null.
var targetObjectOffset : Vector2 = Vector2.ZERO #Changes where the camera is positioned, based on targeted object.

var priority = 0 #Highest priority overrides other nodes

#Unlike other motes, this one is handled by the main class instead of functiality in here, since only one should be active at a time.

func MyClass():
	return load("res://System/Motes/CameraGrabMote.gd")

func Tick():
	super()
