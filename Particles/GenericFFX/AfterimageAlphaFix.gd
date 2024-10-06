extends CPUParticles2D

var timer = 0.0
func _process(delta):
	timer += delta
	material.set_shader_parameter("manualAlphaAdjustment",color_ramp.sample(timer / lifetime).a * modulate.a * get_parent().modulate.a)
