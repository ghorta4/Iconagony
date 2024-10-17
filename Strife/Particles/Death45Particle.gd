extends ParticleEffect

@onready var glowFFX = $"Glow"

func Tick(delta):
	super(delta)
	var aliveFraction = timeAlive/maxLifetime
	
	glowFFX.material.set_shader_parameter("FinalIntensityMultiplier", max(1.0 - aliveFraction, 0.0))
