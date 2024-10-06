#Stores properties of moves that would need to be saved beyond just its baseline information.

class_name MoveModificationData

var Borders : String = "Default"
var Foils : String = "None"
var RainbowSheen : String = "Disabled"
var ScreenReflection : String = "Disabled"

var mementos : Array[Memento] = [] 

func LibrarySerialize() -> PackedByteArray:
	var floatArray = []
	floatArray.append(0)
	
	var stringArray = []
	stringArray.append(Borders)
	stringArray.append(Foils)
	stringArray.append(RainbowSheen)
	stringArray.append(ScreenReflection)
	
	for memento in mementos:
		if memento == null:
			stringArray.append("None")
		else:
			stringArray.append(memento.GetExternalName())
	
	var allData = [floatArray, stringArray]
	
	var data = var_to_bytes(allData)
	
	return data

static func Serialize(moveInstance : MoveInstance) -> PackedByteArray:
	var floatArray = []
	floatArray.append(moveInstance.moveColor.a)
	if moveInstance.moveColor.a > 0:
		floatArray.append(moveInstance.moveColor.r)
		floatArray.append(moveInstance.moveColor.g)
		floatArray.append(moveInstance.moveColor.b)
	
	if moveInstance.visualAlterations.size() <= 0:
		moveInstance.visualAlterations = {"Borders" : "Default", "Foils" : "None", "RainbowSheen" : "Disabled", "ScreenReflection" : "Disabled"}
	
	var stringArray = []
	stringArray.append(moveInstance.visualAlterations["Borders"])
	stringArray.append(moveInstance.visualAlterations["Foils"])
	stringArray.append(moveInstance.visualAlterations["RainbowSheen"])
	stringArray.append(moveInstance.visualAlterations["ScreenReflection"])
	
	for memento in moveInstance.slottedMementos:
		if memento == null:
			stringArray.append("None")
		else:
			stringArray.append(memento.GetExternalName())
	
	var allData = [floatArray, stringArray]
	
	var data = var_to_bytes(allData)
	
	return data

static func Deserialize(serializedProperties : PackedByteArray, toModify : MoveInstance = null): #applies modifications to a base move. Returns movemoddata if toModify is null.
	var pulledData = bytes_to_var(serializedProperties)
	
	var floats = pulledData[0]
	var strings = pulledData[1]
	
	var usedColor = Color.TRANSPARENT
	if floats[0] > 0: 
		usedColor = Color(floats[1], floats[2],floats[3],floats[0])
	
	var moveModDataHolster = MoveModificationData.new()
	
	if toModify != null:
		toModify.moveColor = usedColor
		toModify.visualAlterations = {"Borders" : strings[0], "Foils" : strings[1], "RainbowSheen" : strings[2], "ScreenReflection" : strings[3]}
	
	moveModDataHolster.Borders = strings[0]
	moveModDataHolster.Foils = strings[1]
	moveModDataHolster.RainbowSheen = strings[2]
	moveModDataHolster.ScreenReflection = strings[3]
	for i in 4:
		strings.remove_at(0)
	
	var usedmementos : Array[Memento] = []
	for memento in strings:
		if memento == "None":
			usedmementos.append(null)
			continue
		
		var newMementoType = MoveManager.MementoLibrary[memento]
		usedmementos.append(newMementoType)
	
	if toModify != null:
		toModify.slottedMementos = usedmementos.duplicate()
	
	moveModDataHolster.mementos.clear()
	moveModDataHolster.mementos.append_array(usedmementos)
	return moveModDataHolster

static func GenerateModDataFromMove(moveInstance : MoveInstance) -> MoveModificationData:
	var newMoveModData = MoveModificationData.new()
	
	if moveInstance.visualAlterations.size() <= 0:
		moveInstance.visualAlterations = {"Borders" : "Default", "Foils" : "None", "RainbowSheen" : "Disabled", "ScreenReflection" : "Disabled"}
	
	newMoveModData.Borders = moveInstance.visualAlterations["Borders"]
	newMoveModData.Foils = moveInstance.visualAlterations["Foils"]
	newMoveModData.RainbowSheen = moveInstance.visualAlterations["RainbowSheen"]
	newMoveModData.ScreenReflection = moveInstance.visualAlterations["ScreenReflection"]
	
	for toCopy in moveInstance.slottedMementos:
		if toCopy == null:
			newMoveModData.mementos.append(null)
			continue
		newMoveModData.mementos.append(toCopy)
	
	return newMoveModData

var toComapare = ["Borders", "Foils", "RainbowSheen", "ScreenReflection"]
func isEqualTo(otherModData : MoveModificationData) -> bool:
	var allChecksPass = true
	
	for comparison in toComapare:
		allChecksPass = allChecksPass && get(comparison) == otherModData.get(comparison)
	
	for i in mementos.size():
		allChecksPass = allChecksPass && mementos[i] == otherModData.mementos[i] #replace with null check
	
	return allChecksPass

func ApplyTo(moveInstance : MoveInstance):
	moveInstance.visualAlterations = {"Borders" : Borders, "Foils" :Foils, "RainbowSheen" : RainbowSheen, "ScreenReflection" : ScreenReflection}
	
	moveInstance.slottedMementos.clear()
	for memento in mementos:
		if memento == null:
			moveInstance.slottedMementos.append(null)
			continue
		#var newMementoType = MoveManager.MementoLibrary[memento]
		#moveInstance.slottedMementos.append(newMementoType)
		moveInstance.slottedMementos.append(memento)
