extends Node

class_name GameLoader

var initStarted = false

var timer = 0.0

static var TestSavePath

func _physics_process(delta: float) -> void:
	timer += delta
	if not initStarted:
		initStarted = true
		Init()

func Init():
	
	
	TestSavePath = "user://SaveSlot1/"
	#DirAccess.remove_absolute(TestSavePath + "OwnedMoves.vhs")
	DirAccess.make_dir_recursive_absolute(TestSavePath)
	
	preload("res://Particles/Particle.gd") #forces this script to load because otherwise godot tries its best to fucking misload everything fuck you godot fuck you fuck fuck
	
	load("res://Strife/StrifeScene.tscn")
	
	MoveManager.AppendMoveLibrary(preload("res://Strife/MoveBuilder.tscn").instantiate())
	MoveManager.AppendMementoLibrary(preload("res://System/Mementos/DefaultMementos.tscn").instantiate())
	MoveManager.AppendBackpackLibrary(preload("res://System/PlayerMoves/CustomBackpacks/BackpackBuilder.tscn").instantiate())
	
	LevelManager.AppendLevelLibrary(preload("res://Levels/LevelBuilder.tscn").instantiate())
	
	OwnedMovesManager.LoadAllMoves(TestSavePath + "OwnedMoves.vhs")
	OwnedMovesManager.CheckMoveCountSafeguard()
	OwnedMovesManager.SaveAllMoves(TestSavePath + "OwnedMoves.vhs")
	MoveManager.EquippedBackpack = MoveManager.BackpackLibrary["Basic"]
	
	
	
	#get_tree().change_scene_to_file("res://Menus/MainMenuAssets/MainMenu.tscn")
	
	
	LevelManager.QueuedShowhost = LevelManager.AvailableLevelPacks["Main"]["Debug"]
	get_tree().change_scene_to_file("res://System/Scenes/MainScene.tscn")
