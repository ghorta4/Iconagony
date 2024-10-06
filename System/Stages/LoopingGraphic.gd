extends StageAsset

@export var loopX : bool = true
@export var loopY : bool = false

var loopIntervalX
var loopIntervalY

func _init():
	var mySprite = get("texture")
	
	loopIntervalX = mySprite.get_width()
	loopIntervalY = mySprite.get_height()


func Tick():
	var offset = stage.GetOffset()
	while  position.x > -loopIntervalX - offset.x:
		position.x -= loopIntervalX * 2
	
	while  position.x < -loopIntervalX * 2 - offset.x:
		position.x += loopIntervalX * 2
