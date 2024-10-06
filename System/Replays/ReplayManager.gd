class_name ReplayManager

static var replayFile : ReplayFile

static func StartNewFile():
	replayFile = ReplayFile.new()


static func LogMove(frame : int, location : int, slot : int, flip : bool, extraData):
	replayFile.MIDI[frame] = {"moveLocation" : location, "moveSlot" : slot, "extraData" : extraData,  "flip" : flip}

static func LogRelocatingMove(frame : int, startLocation : int , startSlot : int, finalLocation : int, finalSlot : int):
	if not replayFile.MoveRelocations.has(frame):
		replayFile.MoveRelocations[frame] = []
	replayFile.MoveRelocations[frame].append([startLocation, startSlot, finalLocation, finalSlot])


static func FetchMoveData(tick : int):
	if not replayFile.MIDI.has(tick):
		return null
	return replayFile.MIDI[tick]

static func FetchRelocatingMoveData(tick : int):
	if not replayFile.MoveRelocations.has(tick):
		return null
	return replayFile.MoveRelocations[tick]

static func FinalFrameOfReplay() -> int:
	var maxa = 0
	for key in replayFile.MIDI.keys():
		if key > maxa:
			maxa = key
			
	
	return maxa


static func ApplyReplayParamsToBattle(instance : BattleInstance):
	instance.RNG.currentSeed = replayFile.RNGSeed

static func SaveReplayParamsFromBattle(instance : BattleInstance):
	replayFile.RNGSeed = instance.RNG.currentSeed
