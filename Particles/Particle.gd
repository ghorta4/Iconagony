extends Node2D
class_name ParticleEffect

@export var maxLifetime : float = 1.0
@export var oneShot : bool = true

var battleInstance : BattleInstance
func Start():
	process_mode = Node.PROCESS_MODE_INHERIT
	for child in get_children():
		if child is CPUParticles2D:
			child.emitting = true
		if child is AudioStreamPlayer && (battleInstance == null || not battleInstance.isGhost):
			child.play()

func Resume():
	process_mode = Node.PROCESS_MODE_INHERIT

func Stop():
	process_mode = Node.PROCESS_MODE_DISABLED

func _init():
	Stop()
	

func _ready():
	if oneShot:
		var children = self.get_children()
		for child in children:
			if child is CPUParticles2D:
				child.one_shot = true

var timeAlive = 0.0
func Tick(delta : float):
	timeAlive += delta
	
	if timeAlive >= maxLifetime:
		queue_free()
