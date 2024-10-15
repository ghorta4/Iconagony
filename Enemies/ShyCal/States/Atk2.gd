extends CharacterState

func Frame39():
	if host.stunTicks > 0:
		return
	host.ChangeState("Idle")
	host.CurrentState().currentTick = 10
	host.CurrentState().currentRealTick = 10
