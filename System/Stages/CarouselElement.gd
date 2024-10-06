extends StageAsset
class_name CarouselElement

@export var carouselMovement = Vector2(300, 20)
@export var carouselAngleOffset : float = 0
@export var carouselSizeDilation : float = 0.2
var myCurrentAngle : float = 0
var initialPos
var initialScale

func _init():
	initialPos = position
	initialScale = scale


func Tick():
	super()
	myCurrentAngle = stage.currentCarouselAngle + carouselAngleOffset
	position = initialPos + Vector2(cos(myCurrentAngle), sin(myCurrentAngle)) * carouselMovement
	scale = initialScale * (sin(myCurrentAngle) * carouselSizeDilation + 1)
	
	z_index = floor(sin(myCurrentAngle) * 1000.0)
