extends CarouselElement

@export var curveIntensity : float = 0.55
@export var ignoreSuperTick : bool = false
func Tick():
	if not ignoreSuperTick:
		super()
	material.set_shader_parameter("curve", cos(myCurrentAngle) * curveIntensity)
	
	material.set_shader_parameter("inGameTime", stage.currentVisibleTime)

func Start():
	if not stage.previewMode:
		material.set_shader_parameter("realTimeScale", 0.01)
