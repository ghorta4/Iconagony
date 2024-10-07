extends GroundGlow


var lastUsedTime = 0
func Tick():
	super()
	
	if not stage.previewMode:
		if stage.main.mainScene.paused:
			process_mode = ProcessMode.PROCESS_MODE_DISABLED
		else:
			process_mode = ProcessMode.PROCESS_MODE_INHERIT
			set("speed_scale", stage.main.mainScene.gameSpeed)
