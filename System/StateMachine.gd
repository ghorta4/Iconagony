extends Node

class_name StateMachine

var currentState : ObjectState = null #uses a direct reference to the state for faster access
var host
var stateIsRepeated = false


func CopyTo(new):
	new.stateIsRepeated = stateIsRepeated
	new.currentState = new.get_node(NodePath(currentState.name))
	if currentState == null:
		new.currentState = null
		return
	currentState.CopyTo(new.currentState)

func Initialize():
	for state in get_children():
		state.host = host
		state.stateMachine = self
		state.Init()
	
	currentState = null
	stateIsRepeated = false
	
	host.ChangeState("Default")

func Tick():
	currentState.Tick()
	
	if currentState is CharacterState && currentState.isHurtState:
		if host.stunTicks <= 0:
			if host.IsOnGround():
				host.ChangeState("Idle")
			else:
				host.ChangeState("IdleAir")
			
		return
	
	if currentState.currentTick > currentState.duration && not currentState.endless:
		host.ChangeState(currentState.fallbackState)


func ChangeState(stateName : String, parameters = null, level : int = 0):
	var child = get_node_or_null(stateName)
	
	if child == null:
		push_warning("Could not find state of name " + stateName + "!")
		return
	
	if "powerModifier" in child:
		child.powerModifier = level
	
	stateIsRepeated = currentState != null && (currentState.name == child.name)
	
	if stateIsRepeated && currentState.continueOnWait:
		return
	
	var oldState = currentState
	
	
	currentState = child
	currentState.currentTick = 0
	currentState.currentRealTick = 0
	child.parameters = parameters
	
	if oldState != null:
		oldState.OnExit()
	
	child.OnEnter()

func GetCurrentFrame():
	var frameInAnimation = CurrentTick()/currentState.ticksPerFrame
	if currentState.loopAnimation:
		frameInAnimation %= currentState.animationLength
	frameInAnimation = min(frameInAnimation, currentState.animationLength)
	frameInAnimation = max(frameInAnimation, 0)
	
	return frameInAnimation

func CurrentTick():
	return currentState.currentTick

func GetHitboxes():
	var holster = []
	for box in currentState.cachedHitboxes:
		if box.active:
			holster.append(box)
	
	return holster
