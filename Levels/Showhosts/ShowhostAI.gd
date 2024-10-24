extends Node
class_name  Showhost
#This class runs functions in battles. IE, deciding what enemies to spawn, how often, difficulty, stage background, etc...
#BTW, this is one of those things that get copied over to ghost game. So... yeah. Track variables my bro

@export_group("Level Select Info")
#Internal name is node name.
@export var levelName : String
@export_multiline var levelDescription : String

@export var ingameShownTitle : String
@export var ingameShownSubtitle : String
@export_group("Required Scenes")
@export var playerCharacter : PackedScene
@export var background : PackedScene

@export_group("Other Flags")
@export var canEditMoveset : bool
@export var forceInfiniteTimer : bool
@export var useDefaultIntro : bool
@export var spawnFoesClose : bool
@export_group("Battle Info")

@export var UsedFoes : Array[PackedScene] 
var InstancedTemplateFoes : Dictionary = {}

#in ticks
@export var enemySpawningEnabled : bool = false
@export var minDelayBetweenSpawns : int = 180
@export var maxDelayBetweenSpawns : int = 360
@export var initialSpawnDelay : int = 100

@export var difficultyAccruementPerTick : float = 0.03
@export var difficultyIncreaseOverTime : float = 0.01 #Amount increase every 1000 ticks
@export var maxFoesSpawnedAtOnce : int = 6
@export var initialAccruedDifficulty : float = -1.0

var currentlyRemainingDelay : int = 0
var accruedDifficulty : float = 0.0

@export var maxFoesPresent : int = 30

@export_group("Win State")
@export var foeKillsToWin = -1 #-1 is disabled, positive is the number of foes to slay
var currentFoeKills = 0
@export_group("Other")

@export_multiline var stateVariables : String = ""
var stateVariablesList = []

var battleInstance : BattleInstance
var isGhost : bool = false

var levelEnded : bool = false

var instantiatedFoes = []


var stowedRandomFloats = [] #Used so that randomness is more controlled and not just changing every frame based on what move the player does...


var movesCollected = []

func Tick():
	
	if not levelEnded && foeKillsToWin > 0 && currentFoeKills >= foeKillsToWin:
		WinLevel()
	
	RunIntroSequence()
	while  stowedRandomFloats.size() < 500:
		stowedRandomFloats.append(battleInstance.GetRandom(-100.0, 100.0))
	
	RefreshCaches()
	
	TickFoeSpawning()
	


func RefreshCaches():
	var foesToErase = []
	for foe in instantiatedFoes:
		if foe == null or not is_instance_valid(foe) || foe.disabled:
			foesToErase.append(foe)
	
	for foe in foesToErase:
		instantiatedFoes.erase(foe)

func CopyTo(new : Showhost):
	for varName in stateVariablesList:
		if get(varName) is Vector2:
			var old = self[varName]
			new.set(varName, Vector2(old))
			continue
		
		new[varName] = self[varName]
	
	new.isGhost = true
	
	new.InstancedTemplateFoes = InstancedTemplateFoes
	
#	new.instantiatedFoes.clear()
	for foe in instantiatedFoes:
		new.instantiatedFoes.append(new.battleInstance.FindObjectOfID(foe.id))
	
	new.RefreshCaches()
	
	new.stowedRandomFloats.clear()
	for f in stowedRandomFloats:
		new.stowedRandomFloats.append(f)

func Initialize():
	var allNewVariables = stateVariables.split("\n")
	for v in allNewVariables:
		if v.is_empty():
			continue
		stateVariablesList.append(v)
	
	stateVariablesList.append_array(["enemySpawningEnabled", "minDelayBetweenSpawns", "maxDelayBetweenSpawns", "initialSpawnDelay", "difficultyAccruementPerTick",
	"difficultyIncreaseOverTime", "maxFoesSpawnedAtOnce", "initialAccruedDifficulty", "currentlyRemainingDelay", "maxFoesPresent", "accruedDifficulty",
	"currentFoeKills", "levelEnded"])
	
	if not isGhost:
		var instancedSet = []
		for foe in UsedFoes:
			instancedSet.append(foe.instantiate())
		
		for foe in instancedSet:
			InstancedTemplateFoes[foe.internalName] = foe
			foe.isTemplate = true
			foe.Initialize()
		
		currentlyRemainingDelay = initialSpawnDelay
		accruedDifficulty = initialAccruedDifficulty
	
	movesCollected = []

func SetupGame():
	if forceInfiniteTimer:
		battleInstance.focusedPlayer.infiniteTime = true
	if canEditMoveset:
		battleInstance.focusedPlayer.ignoreMoveGeneration = true
		battleInstance.loadedUI.PushToEditingMode()
	
	if useDefaultIntro:
		battleInstance.focusedPlayer.ChangeState("Intro1")
		battleInstance.hideDisplay = true

func TickFoeSpawning():
	if not enemySpawningEnabled || introSpawningSuppression:
		return
	
	currentlyRemainingDelay -= 1
	accruedDifficulty += difficultyAccruementPerTick + battleInstance.currentTick / 1000.0 * difficultyIncreaseOverTime
	if currentlyRemainingDelay > 0:
		return
	
	currentlyRemainingDelay = round((GetRandom() + 100.0) / 200.0 * (maxDelayBetweenSpawns - minDelayBetweenSpawns) + minDelayBetweenSpawns)
	
	var enemiesSpawned = 0
	var totalSpawnWeight = GetTotalSpawnWeight()
	
	var spawnSide = sign(GetRandom())
	while true:
		if enemiesSpawned >= maxFoesSpawnedAtOnce:
			break
		
		if instantiatedFoes.size() >= maxFoesPresent:
			break
		
		if accruedDifficulty <= 0:
			break
		
		var pickedFoeToSpawn = (GetRandom() + 100.0) / 200.0 * totalSpawnWeight
		var foeTemplate = null
		for enemy in InstancedTemplateFoes.values():
			pickedFoeToSpawn -= enemy.spawnWeight
			if not pickedFoeToSpawn <= 0:
				continue
			
			foeTemplate = enemy
			break
		
		if foeTemplate == null:
			push_warning("Couldn't spawn a foe? How strange...")
			return
		
		var foe = battleInstance.SpawnObject(foeTemplate, true)
		
		foe.team = 1
		foe.material = battleInstance.teamMaterials[foe.team]
		
		var spawnCloseMult = 1
		if spawnFoesClose:
			spawnCloseMult = 0.1
		
		foe.position.x += GetRandom() * spawnCloseMult
		foe.position.x += 500 * spawnSide * spawnCloseMult + battleInstance.focusedPlayer.position.x
		
		foe.position.y -= foe.spawnHeight
		foe.position.y += GetRandom() * foe.spawnHeightVariation / 100.0
		
		foe.isGhost = isGhost
		
		instantiatedFoes.append(foe)
		#need a position function here
		
		accruedDifficulty -= foe.difficultyWeight
		
		enemiesSpawned += 1
		
		


func GetTotalSpawnWeight() -> float:
	var total = 0.0
	
	for foe in InstancedTemplateFoes.values():
		total += foe.spawnWeight
	
	return total


func GetRandom():
	
	if stowedRandomFloats.size() > 0:
		var grabbed = stowedRandomFloats[0]
		stowedRandomFloats.remove_at(0)
		return grabbed
	var output = battleInstance.GetRandom(-100.0, 100.0)
	return output

var introSpawningSuppression : bool = false

const introDuration = 250
const introPart1Duration = 160
func RunIntroSequence():
	if not useDefaultIntro || isGhost:
		return
	
	var tick = battleInstance.currentTick
	var main = battleInstance.main
	if tick < introDuration:
		introSpawningSuppression = true
		battleInstance.runRealtime = true
		if tick < introPart1Duration:
			main.cameraPositionOverride = Vector2((200 - tick) * 12, -200)
		else:
			main.cameraPositionOverride = lerp(main.cameraPositionOverride, Vector2.UP * 150, 6.0/60.0)
			if tick == introDuration - 78:
				battleInstance.focusedPlayer.ChangeState("Intro2")
			
			if tick == introDuration - 1:
				battleInstance.runRealtime = false
				battleInstance.focusedPlayer.RefreshPickupMoves()
	elif tick == introDuration:
		main.manualCamPos = main.cameraPositionOverride
		main.lethargicCameraPosition = main.manualCamPos
		main.cameraPositionOverride = null
		introSpawningSuppression = false
		battleInstance.runRealtime = false
		battleInstance.hideDisplay = false
		if not battleInstance.readFromReplay:
			main.previewScene.RestartPreview()

func WinLevel():
	levelEnded = true
	battleInstance.focusedPlayer.WinLevel()
	
	PickGainedMoves(false)

func LoseLevel():
	levelEnded = true
	
	PickGainedMoves(true)

func PickGainedMoves(penaltyCollection : bool):
	if isGhost:
		return
	for move in battleInstance.focusedPlayer.instancedMoves:
		if not [MoveInstance.moveLocations.Sidepack, MoveInstance.moveLocations.Inventory].has(move.moveLocation):
			continue
		
		if move.tags.has("Pickup"):
			movesCollected.append(move)
	
	if penaltyCollection && movesCollected.size() > 0:
		var pickedMove =(GetRandom() + 100) / 200.0
		pickedMove *= movesCollected.size()
		pickedMove = floor(pickedMove)
		pickedMove = clamp(pickedMove, 0, movesCollected.size() - 1)
		
		movesCollected = [movesCollected[pickedMove]]
	
	if battleInstance.main.doNotAwardMoves:
		return
	
	for move in movesCollected:
		OwnedMovesManager.AddMoveToOwnedMoves(move)
	
	OwnedMovesManager.SaveAllMoves(GameLoader.TestSavePath + "OwnedMoves.vhs")
