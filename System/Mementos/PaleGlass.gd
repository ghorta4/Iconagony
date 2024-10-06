extends Memento

func GetExternalName() -> String:
	return "PaleGlass"

func ApplyLevelEffects(parentMove : MoveInstance, _MoveList : Array[MoveInstance]):
	parentMove.maxUses = 1
#	parentMove.maxUses = max(parentMove.maxUses, 1)
	parentMove.moveLevel += 1
