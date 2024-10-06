extends ParticleEffect

func _physics_process(delta: float) -> void:
	Tick(delta)

func Resume():
	pass

func Stop():
	pass

func _ready():
	Start()
