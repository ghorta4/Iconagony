@tool
extends ColorRect

@export var plotSize : float = 100.0
@export var start : float = -1.0
@export var end : float = 1.0
@export var center : Vector2 = Vector2.ONE * 0.5
@export var radius : float = 0.45
@export var radiusMin :float = 0.1
@export var rotationOffset :float = 1.5

@onready var button = $DirectionSelect
@onready var line = $Line

var flipped = false

func _ready():
	PushPropertiesToMaterial()
	button.parent = self
	button.clampPos()
	UpdateLinePos()


func PushPropertiesToMaterial():
	var usedOffset = rotationOffset
	
	if flipped:
		usedOffset = PI - rotationOffset
	
	material.set_shader_parameter("circleCenter", center)
	material.set_shader_parameter("radius", radius)
	material.set_shader_parameter("radiusMin", radiusMin)
	material.set_shader_parameter("rotateOffset", usedOffset)
	material.set_shader_parameter("startAngle", start)
	material.set_shader_parameter("endAngle", end)

func UpdateLinePos():
	var buttonPos = button.position + button.size/2.0 - (size * (center * 2)) / 2.0
	var angleToCenter = atan2(buttonPos.y, buttonPos.x)
	var angleVec = Vector2(cos(angleToCenter), sin(angleToCenter))
	line.points = PackedVector2Array([ 
		angleVec * radiusMin * size + center * size,
		buttonPos + center * size
		 ])

func _process(_delta):
	PushPropertiesToMaterial()


func GetData():
	if button == null: #used in the case some other move has called this without it being prepared
		return null
	var dist = ((button.position + button.size /2.0) / size) - center
	dist /= radius
	dist = dist #graph is normally inverted because. IDk.
	return dist


func UpdateFacing(flip : bool):
	if flipped != flip:
		button.position.x = size.x - button.size.x - button.position.x
	
	flipped = flip
	
	PushPropertiesToMaterial()
	UpdateLinePos()
