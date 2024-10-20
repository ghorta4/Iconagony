@tool
extends Node2D

var currentDrawCoordinates = null
var utilizedState
var currentlyDrawnSprite = null

var sprite : AnimatedSprite2D = null
var usedKey = null

func _ready() -> void:
	sprite = get_parent().get_node("Sprite")

func _process(_delta):
	if sprite == null:
		sprite = get_parent().get_node("Sprite")
	
	var currentSpritePath = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if currentSpritePath == null:
		return
	currentSpritePath = currentSpritePath.resource_path
	
	if currentlyDrawnSprite != currentSpritePath:
		currentlyDrawnSprite = currentSpritePath
		utilizedState = null
		
		var stateMachineChildren = get_parent().get_node("StateMachine").get_children()
		for state in stateMachineChildren:
			if state is GrabState && state.grabLocations.has(load(currentSpritePath)):
				utilizedState = state
				usedKey = load(currentSpritePath)
				break
	
	
	if utilizedState == null:
		currentDrawCoordinates = null
	else:
		currentDrawCoordinates = utilizedState.grabLocations[usedKey]
	
	queue_redraw()

func _draw():
	if currentDrawCoordinates == null:
		return
	
	draw_circle(currentDrawCoordinates, 4, Color(0.65,0.24,0.87,0.6), true)
