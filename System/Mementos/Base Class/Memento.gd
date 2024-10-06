extends Node
#Class representing the little gems you slot into moves.
class_name Memento

@export var displayedName : String = "Unnamed"
@export_multiline var description : String = "Description that adds flavor text. Can be toggled off."

@export var spawnWeight : float = 1.
@export var displayTexture : Texture2D

func GetExternalName() -> String:
	return "Unused Memento"

func ApplyLevelEffects(_parentMove : MoveInstance, _MoveList : Array[MoveInstance]):
	pass
