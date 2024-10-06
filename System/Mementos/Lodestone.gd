extends Memento

func GetExternalName() -> String:
	return "Lodestone"

func ApplyLevelEffects(parentMove : MoveInstance, _MoveList : Array[MoveInstance]):
	parentMove.maxUses *= 2
#	parentMove.maxUses = max(parentMove.maxUses, 1)
	parentMove.moveLevel -= 1
