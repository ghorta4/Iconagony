extends Control
class_name VHSMenuButton
enum MainMenuButtonTypes {
	Quit,
	StartGame,
	Options,
	LevelSelect,
	Close,
	PickLevel,
	DoNothing, #temporary functionality
	DeleteData
}

@export var buttonType : MainMenuButtonTypes #lazy man's one script solution. very controversial in central europe
@export var buttonArgument : String #same as above. Used for things like picking specific levels so i dont have to make a better system

func _ready() -> void:
	
	
	match buttonType:
		MainMenuButtonTypes.LevelSelect:
			var button = $"Text"
			button.pressed.connect(OpenLevelSelectCall)
		MainMenuButtonTypes.Quit:
			var button = $"Text"
			button.pressed.connect(QuitCall)
		MainMenuButtonTypes.PickLevel:
			var button = $"Text"
			button.pressed.connect(SwitchLevelDisplay)
		MainMenuButtonTypes.Options:
			var button = $"Text"
			button.pressed.connect(OpenOptionsCall)
		MainMenuButtonTypes.Close:
			get("pressed").connect(CloseCall)
		MainMenuButtonTypes.StartGame:
			var button = $"Text"
			button.pressed.connect(StartGame)
		MainMenuButtonTypes.DeleteData:
			get("pressed").connect(DeleteSave)

func QuitCall():
	get_tree().quit()

func CloseCall():
	get_parent().visible = false
	
	get_tree().get_root().get_child(0).RedisplayMain()

func OpenLevelSelectCall():
	get_tree().get_root().get_child(0).OpenLevelSelect()

func OpenOptionsCall():
	get_tree().get_root().get_child(0).OpenOptions()

func SwitchLevelDisplay():
	LevelManager.QueuedShowhost = LevelManager.AvailableLevelPacks["Main"][buttonArgument]
	
	get_tree().get_root().get_child(0).UpdateLevelDisplay()

func StartGame():
	if LevelManager.QueuedShowhost == null:
		return
	get_tree().change_scene_to_file("res://System/Scenes/MainScene.tscn")

func DeleteSave():
	if Input.is_action_pressed("Shift"):
		DirAccess.remove_absolute(GameLoader.TestSavePath + "OwnedMoves.vhs")
		DirAccess.remove_absolute(GameLoader.TestSavePath + "Moveset.cd")
		OwnedMovesManager.DumpAllMoves()
		OwnedMovesManager.SaveAllMoves(GameLoader.TestSavePath + "OwnedMoves.vhs")
