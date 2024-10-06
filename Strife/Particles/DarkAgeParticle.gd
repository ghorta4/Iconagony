extends ParticleEffect

@onready var fishFFX = $"Fisheye"
@onready var flames = $"Flames"

var endSequence = false
var dilation = 1.0
func Tick(delta):
	super(delta)
	var aliveFraction = timeAlive/maxLifetime
	
	if not endSequence:
		fishFFX.material.set_shader_parameter("FinalIntensityMultiplier", -0.4 * aliveFraction)
		flames.scale_amount_max = .25 * (1 + timeAlive/maxLifetime * 3)
		flames.scale_amount_min = .05 * (1 + timeAlive/maxLifetime * 3)
	else:
		flames.visible = false
		dilation = lerp(dilation, 0.0, 0.3)
		fishFFX.material.set_shader_parameter("FinalIntensityMultiplier", dilation)
	
