extends StageAsset
class_name GroundGlow
@onready var parent = get_parent()

func Tick():
	super()
	if stage.usedCamera != null:
		material.set_shader_parameter("overallWorldPos", stage.usedCamera.position * parent.motion_scale * -1)
		material.set_shader_parameter("cameraScale", stage.usedCamera.zoom.x)
	elif stage.previewMode:
		material.set_shader_parameter("overallWorldPos", stage.previewCameraOffset  * parent.motion_scale)
	material.set_shader_parameter("inGameTime", stage.currentVisibleTime)
	

func Start():
	if not stage.previewMode:
		material.set_shader_parameter("realTimeScale", 0.01)
