extends Node

@onready var MoveSelect = $MoveSelection/Button
@onready var DirectionSelect = $MoveSelection/DirectionalWheel
@onready var player = $Strife
@onready var FlipButton = $MoveSelection/Flip
# Called when the node enters the scene tree for the first time.
func _ready():
	MoveSelect.pressed.connect(makePlayerJump)

func _physics_process(delta):
	pass
	#player.flipX = FlipButton.button_pressed

func makePlayerJump():
	player.ChangeState("Jump", DirectionSelect.GetData())

