extends CharacterState
class_name GrabState
@export var grabLocations : Dictionary

@export var desiredFollowupFrame : int = 4 #If someone is grabbed by this time, then move to the desired followup frame
@export var desiredFollowupState : String

func Tick():
	super()
	
	if desiredFollowupFrame == currentTick && host.grabbee != null:
		host.ChangeState(desiredFollowupState, parameters, powerModifier)
		host.stateInterruptable = false
