extends Node
class_name Backpack

@export var displayName = "Backpack Name"
@export_multiline var displayDescription = "Description"

@export var MaxMoveSlots : int = 6 #Slots held on the left.
@export var MaxSidepackSlots : int = 2 #Slots held on top. Generally have special effects.
@export var MaxPickupSlots : int = 4 #Slots on the right. Not part of the inventory, but rather moves gained in-game.

func ApplyBackpackLevelChanges(_moveArray):
	pass
