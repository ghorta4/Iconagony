@icon("res://System/System Icons/BoxIcon.png")
@tool
extends Node2D

class_name DrawableBox

@export var bounds : Vector2

func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()

func _draw():
	if Engine.is_editor_hint():
		DrawMe()

func DrawMe():
	var color = GetDrawColor()
	var origin = position - bounds * 0.5
	draw_rect(Rect2(origin, bounds), color, true)

func GetDrawColor():
	push_warning("This needs an override!")
	return Color(1,1,1,0.3)
