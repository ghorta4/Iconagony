@tool
extends Node
class_name HeadTrackingBuilder
@export var go_run_auto_head_position_generation:String

@export_group("Editable Fields")
@export var editedFile : String #read only
@export var usedSprite : String #read only
@export var position : Vector2 = Vector2.ZERO :
	set(value):
		position = value
		SaveChanges()
@export var spriteLocation : Vector2i = Vector2i.ZERO :
	set(value):
		value.x = clamp(value.x, -3, 3)
		value.y = clamp(value.y, -3, 3)
		spriteLocation = value
		SaveChanges()

@export var backgroundFacingSprite : bool = false :
	set(value):
		backgroundFacingSprite = value
		SaveChanges()

@export var reverseFromPlayerSprite : bool = false :
	set(value):
		reverseFromPlayerSprite = value
		SaveChanges()

@export var showBehindPlayer : bool = false :
	set(value):
		showBehindPlayer = value
		SaveChanges()

@export var expressionOverride : String = "" :
	set(value):
		expressionOverride = value
		SaveChanges()

#To capture the button press, add the connected signal func:
func _on_button_pressed(_text:String):
	AutoUpdateHeadTrackingFiles()

const initialPath = "res://Strife/HeadTrackingBuilder"
const normalPath = "res://Strife/Sprites"

#Related to dev tools
func AutoUpdateHeadTrackingFiles(_input = null):
	print("Starting head tracking file updates.")
	var strife = get_parent()
	if strife == null:
		print("Unable to get parent. Aborting.")
		return
	
	
	var directoriesToSearch = [initialPath]
	
	while directoriesToSearch.size() > 0:
		var targetDirectory = directoriesToSearch[0]
		print("Starting directory '" + targetDirectory + "'.")
		var head = DirAccess.open(targetDirectory)
		
		var subs = head.get_directories()
		for sub in subs:
			directoriesToSearch.append(targetDirectory + "/" + sub)
		
		var files = head.get_files()
		
		for file in files:
			if not file.ends_with(".png"):
				continue
			var fullPath = targetDirectory + "/" + file
			print("Now starting " + file + "...")
			var success = ProcessImageFile(fullPath)
			
			if success:
				head.remove(fullPath)
		
		directoriesToSearch.remove_at(0)
	

func ProcessImageFile(path : String):
	var image : CompressedTexture2D = load(path) 
	var imageObj = image.get_image()
	var size = image.get_size()
	
	var basePos = null
	var aimPos = null
	
	for x in size.x:
		for y in size.y:
			var pixel = imageObj.get_pixel(x, y)
			if pixel.a == 0:
				continue
			
			if pixel.r > 0.5:
				if basePos != null:
					print("Base position assigned twice in " + path + "! Aborting.")
					return false
				else:
					basePos = Vector2(x,y)
					continue
			elif pixel.b > 0.5:
				if aimPos != null:
					print("Aim position assigned twice in " + path + "! Aborting.")
					return false
				else:
					aimPos = Vector2(x,y)
					continue
	
	if basePos == null || aimPos == null:
		print("Cannot form aim details from " + path + ". Aborting.")
		return false
	
	var associatedPath = path.replace(initialPath, normalPath)
	var targetedAsset = load(associatedPath)
	
	if targetedAsset == null:
		print("Cannot find associated sprite for " + associatedPath + ".")
		return false
	
	print("Generating head position data for " + associatedPath + " with position " + str(basePos) + ", aim direction " + str(aimPos) + ".")
	
	var infoPath = associatedPath + ".info"
	var preexistingInfo = null
	if FileAccess.file_exists(infoPath):
		preexistingInfo = HeadTrackingInfo.Deserialize(FileAccess.get_file_as_bytes(infoPath))
	var editedTrackingInfo = HeadTrackingInfo.new()
	if preexistingInfo != null:
		print("Old data found. Overriding position data.")
		editedTrackingInfo = preexistingInfo
	else:
		print("Generating data from scratch.")
	
	
	editedTrackingInfo.position = basePos
	
	var posDiff = aimPos - basePos
	#var length = posDiff.length()
	
	editedTrackingInfo.reverseFromPlayerSprite = aimPos.x < basePos.x
	editedTrackingInfo.position = basePos
	editedTrackingInfo.spriteMapLocation = Vector2i( clamp(abs(posDiff.x / 10.0), 0, HeadTrackingInfo.maxAngleSteps), clamp(posDiff.y / 10.0, 0, HeadTrackingInfo.maxAngleSteps) )
	
	var serialized = editedTrackingInfo.Serialize()
	
	var file = FileAccess.open(infoPath, FileAccess.WRITE) #be sure to have a handler if this is null
	file.store_buffer(serialized)
	file.close()
	
	return true

var lastUsedSprite = null
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	
	var strife = get_parent()
	
	var currentSprite = strife.sprite.get_sprite_frames().get_frame_texture(strife.sprite.animation, strife.sprite.frame)
	if lastUsedSprite == currentSprite:
		return
	lastUsedSprite = currentSprite
	
	var output = strife.UpdateHeadGraphic()
	if output == null:
		editedFile = ""
		return
	
	ignoreSaving = true
	
	editedFile = output.infoPath
	var data : HeadTrackingInfo = output.data
	position = data.position
	spriteLocation = data.spriteMapLocation
	backgroundFacingSprite = data.backgroundFacingSprite
	reverseFromPlayerSprite = data.reverseFromPlayerSprite
	usedSprite = output.sprite
	if "showBehindPlayer" in data: showBehindPlayer = data.showBehindPlayer
	if "expressionOverride" in data && data.expressionOverride != null: expressionOverride = data.expressionOverride
	else: expressionOverride = ""
	ignoreSaving = false

var ignoreSaving = true
func SaveChanges():
	if ignoreSaving:
		return
	
	var holster : HeadTrackingInfo = HeadTrackingInfo.new()
	holster.position = position
	holster.spriteMapLocation = spriteLocation
	holster.backgroundFacingSprite = backgroundFacingSprite
	holster.reverseFromPlayerSprite = reverseFromPlayerSprite
	holster.showBehindPlayer = showBehindPlayer
	holster.expressionOverride = expressionOverride
	var serialized = holster.Serialize()
	
	var file = FileAccess.open(editedFile, FileAccess.WRITE) #be sure to have a handler if this is null
	file.store_buffer(serialized)
	file.close()
	
	var strife = get_parent()
	strife.cachedHeadSpriteInfos.erase(editedFile.replace(".info", ""))
	strife.UpdateHeadGraphic()
