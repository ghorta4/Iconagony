class_name LevelManager

static var AvailableLevelPacks : Dictionary = {} #For better sorting later on

static var QueuedShowhost : Showhost
#By the way heads up. The packets containing level info are also the AIs responsible for running levels. It makes things more compact im sorry

static func AppendLevelLibrary(TargetScene, Sublibrary : String = "Main"):
	var allLevels = []
	var children = TargetScene.get_children()
	for child in children:
		allLevels.append(child)
	
	if not AvailableLevelPacks.keys().has(Sublibrary):
		AvailableLevelPacks[Sublibrary] = {}
	
	for level in allLevels:
		AvailableLevelPacks[Sublibrary][level.name] = level
