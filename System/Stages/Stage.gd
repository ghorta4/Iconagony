extends Node2D
class_name Stage

var main : Main
var usedCamera : Camera2D

var AllAssets : Array[StageAsset] = []
var allParallaxLayers : Array[ParallaxLayer] = []

@export var previewMode : bool = false
var previewCameraOffset : Vector2 = Vector2.DOWN * 400
var previewCameraSpeed : Vector2 = Vector2.RIGHT * 15

@onready var Scroller = $"Scroller"

@export var carouselSize : float = 4096
var currentCarouselAngle = 0

var currentVisibleTime = 0 #in case of time dilating effects, such as slow-mo, this may not exactly line up with ticks.

func _ready():
	var allChildren = GetAllChildren(self)
	for child in allChildren:
		if child is ParallaxLayer:
			allParallaxLayers.append(child)
		if child is StageAsset:
			AllAssets.append(child)
			child.stage = self
		if child is Sprite2D:
			child.position.y -= 500
	
	for child in AllAssets:
		child.Start()
	



func _physics_process(delta):
	
	if previewMode:
		if Input.is_key_pressed(KEY_UP):
			previewCameraOffset.y += 600. * delta
		if Input.is_key_pressed(KEY_DOWN):
			previewCameraOffset.y -= 600. * delta
		
		if Input.is_key_pressed(KEY_LEFT):
			previewCameraSpeed.x = 15
		if Input.is_key_pressed(KEY_RIGHT):
			previewCameraSpeed.x = -15
		
		previewCameraOffset += previewCameraSpeed
		Update(delta)

func Update(newTime):
	currentVisibleTime = newTime
	
	var offset = GetOffset()
	#Scroller.scroll_offset = offset
	currentCarouselAngle = offset.x / carouselSize * PI / -2.0
	for asset in AllAssets:
		asset.Tick()
	
	if previewMode:
		$"Scroller".scroll_base_offset = offset


func GetAllChildren(object):
	var nodes : Array = []
	for N in object.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(GetAllChildren(N))
		else:
			nodes.append(N)
	return nodes

func GetOffset() -> Vector2:
	if previewMode:
		return previewCameraOffset
	else:
		if usedCamera == null:
			return Vector2.ZERO
		return (usedCamera.position * -1 + Vector2.UP * 250)

func SetZoom(value : float):
	for layer in allParallaxLayers:
		layer.motion_offset = Vector2(800, 0) * (1 - value) / (value) / 2 * (Vector2.ONE - layer.motion_scale) #HOLY SNAP I DIDNT THINK I COULD GET IT TO WORK I WAS JUST BANGING NUMBERS TOGETHER
