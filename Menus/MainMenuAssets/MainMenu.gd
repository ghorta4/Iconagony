extends Node

var currentSequence : MenuSequenceEvents

enum MenuSequenceEvents {
	splash,
	opening,
	final
}

@onready var splashes = [$"%Muh"]
var currentSplash = 0

var currentSplashTimer = -0.6
const desiredSplashShowtime = 2.4
const splashFadeTime = 0.6

var openingTimer = 0

@export var finalVisualFlairModulate : Color

@onready var logoAnchor = $"%LogoAnchor"
@onready var logo = $"%Logo"

@onready var VFlair = $"%VFlair"
@onready var Ground = $"%ground"

@onready var ffx = $"%BlurFFX"

@onready var buttons = $"%Buttons"
@onready var mainButtons = $"%MainButtons"

@onready var levelSelect = $"%LevelSelect"
@onready var options = $"%OptionsMenu"

@onready var startingLogoPos : Vector2 = logoAnchor.position

func _ready() -> void:
	logo.visible = false
	buttons.visible = false
	VFlair.visible = false
	levelSelect.visible = false
	options.visible = false

func _process(delta: float) -> void:
	match currentSequence:
		MenuSequenceEvents.splash:
			HandleSplashScreen(delta)
		MenuSequenceEvents.opening:
			HandleOpening(delta)


func HandleSplashScreen(delta):
	currentSplashTimer += delta
	
	var fraction = 0
	if currentSplashTimer < splashFadeTime:
		fraction = currentSplashTimer / splashFadeTime
	elif  currentSplashTimer > desiredSplashShowtime - splashFadeTime:
		fraction = (desiredSplashShowtime - currentSplashTimer) / splashFadeTime
	else:
		fraction = 1
	
	splashes[currentSplash].modulate.a = fraction
	
	if currentSplashTimer > desiredSplashShowtime:
		currentSplash += 1
		if currentSplash >= splashes.size():
			currentSequence += 1
			$"Sounds/wooshBuildup".play()

const spinInDuration = 1.1
const animateDuration = 0.12
const blurFinishTime = 0.9
var openingSegment = 0 #0 is spinning in, 1 is opening, 2 is logo appearing
func HandleOpening(delta):
	openingTimer += delta
	
	match openingSegment:
		0:
			logo.visible = true
			var timeLeft = spinInDuration - openingTimer
			logoAnchor.position = startingLogoPos + Vector2.LEFT * 300 * timeLeft / spinInDuration
			logoAnchor.rotation = timeLeft / spinInDuration * -9.5
			if timeLeft <= 0:
				logoAnchor.position = startingLogoPos
				logoAnchor.rotation = 0
				openingSegment += 1
				openingTimer = 0
		1:
			var frame = openingTimer / animateDuration
			frame = clamp(round(lerpf(0, 2, openingTimer / animateDuration)) ,0, 2)
			logo.frame = frame
			
			if openingTimer > animateDuration:
				openingSegment += 1
				openingTimer = 0
				logo.frame = 3
				VFlair.visible = true
				Ground.visible = true
				$"Sounds/Ping".play()
				$"Sounds/Static".play()
				buttons.visible = true
		2:
			ffx.material.set_shader_parameter("FinalIntensityMultiplier", 1.0 - (openingTimer / blurFinishTime))
			if openingTimer > blurFinishTime:
				openingSegment += 1
				

func OpenLevelSelect():
	levelSelect.visible = true
	mainButtons.visible = false

func OpenOptions():
	options.visible = true
	mainButtons.visible = false

func RedisplayMain():
	mainButtons.visible = true

func UpdateLevelDisplay():
	var levelDesc = $"Buttons/LevelSelect/LevelDescription"
	levelDesc.text = LevelManager.QueuedShowhost.levelDescription
