@tool
extends DrawableBox
class_name Hitbox

@export_group("Damage and Hit")
@export var damage : int = 10

@export var useDefaultDamagePowerScaling : bool = true #To make things quicker, automatically account for power changes by increasing attack damage.
@export var damageIncreasePerLevel : float = 0.3 #Power increase: damage * (this * level + 1)
@export var damageReductionFactor : float = 0.8  #Power decrease: this ^ penalty levels

@export var hitGroup : int = 0 #Can't be hit by the same hit group more than once per attack.
@export var hitPriority : int = 0 #if hit by multiple hitboxes, only account for the one with the highest priority.

@export var knockbackDirection : Vector2 = Vector2.ONE
@export var knockbackForce : float = 100.0

@export var knockbackAwayFromCenter : bool = false

@export var inheritAttackersSpeedOnHitPercent : float = 0.2

@export var stunTicks : int = 10
@export var hitstopTicks : int = 2
@export var selfHitstopTicks : int = 0

@export var hurtState : String = "HurtGL"
@export var hurtStateAir : String = "HurtA"

@export_group("Frame Data")
@export var startFrame : int = 1
@export var duration : int = 2

@export var hitcancellable : bool = true #on hit, shorten the move
@export var hitcancelDelay : int = 3 #continue the move for this many frames before player/unit can act again

@export var loopHitbox : bool = false #Resets the hit group every so often.
@export var ticksPerLoop : int = 3 #Resets the hitbox on this interval

@export_group("Audio")
@export var hitSound : AudioStream
@export var hitSoundVolume : float = 0
@export var bassSound : AudioStream
@export var bassSoundVolume : float = 0
@export var whiffSound : AudioStream
@export var whiffSoundVolume : float = 0
@export var playWhiffOnHit : bool = false
var hitSoundPlayer : AudioStreamPlayer
var bassSoundPlayer : AudioStreamPlayer
var whiffSoundPlayer : AudioStreamPlayer

@export_group("Particles")
@export var allowFallbackParticles : bool = true
@export var autoAdjustParticleAngle : bool = true
@export var particleEffect : PackedScene
@export var particleOffset : Vector2

@export_group("Grabbing")
@export var isGrabBox : bool = false
@export var isGrabHit : bool = false

var active = false #set my other scripts to determine whether or not to draw this, and when to include it in used hitboxes
var player # A slight misnomer. This is a player for players' hitboxes, but is a projectile if the hitbox is on a projectile!
var host

var stateVariables = ["damage", "useDefaultDamagePowerScaling", "damageIncreasePerLevel", "damageReductionFactor", "hitGroup", "hitPriority", "startFrame", "duration",
"hitcancellable", "hitcancelDelay", "active", "bounds", "position", "knockbackDirection", "knockbackForce", "stunTicks", "hurtState", "hitstopTicks", "selfHitstopTicks", "hurtStateAir",
"loopHitbox", "ticksPerLoop", "inheritAttackersSpeedOnHitPercent", "knockbackAwayFromCenter", "allowFallbackParticles", "autoAdjustParticleAngle", "particleOffset", "particleEffect",
"isGrabBox", "isGrabHit"]

func CopyTo(new):
	for variableName in stateVariables:
		new[variableName] = self[variableName]

#Nuke this in the web build
func DrawMe():
	if Engine.is_editor_hint():
		var list = NodeSelection.SelectedNodes
		if (self in list):
			super()
		return
	if not active:
		return
	var color = GetDrawColor()
	var origin = GetOrigin()
	draw_rect(Rect2(origin - bounds * 0.5, bounds), color, true)

func GetOrigin():
	var origin = player.global_position + position * Vector2(2 * player.GetFacingInt() - 1, 1)
	return origin 

func GetDrawColor():
	if isGrabBox:
		return Color(0.75, 0.4, 0.1, 0.4)
	if isGrabHit:
		return Color(0.66, 0.04, 0.04, 0.4)
	
	return Color(0.96, 0.1, 0.1, 0.4)

func GetData() -> HitboxData:
	var newHolder = HitboxData.new()
	CopyTo(newHolder)
	newHolder.player = player
	
	if useDefaultDamagePowerScaling:
		var powerMod = 1
		var level = 0
		if host is CharacterState:
			level = host.powerModifier
		
		if player is ProjectileObject:
			level = player.creatorMoveLevel
		
		if level > 0:
			powerMod = 1 + level * damageIncreasePerLevel
		if level < 0:
			powerMod = pow(damageReductionFactor, abs(level))
		
		newHolder.damage *= powerMod
	
	return newHolder

func Init():
	if not player.isGhost:
		if hitSound != null:
			hitSoundPlayer = AudioStreamPlayer.new()
			hitSoundPlayer.stream = hitSound
			hitSoundPlayer.volume_db = hitSoundVolume
			add_child(hitSoundPlayer)
		
		if bassSound != null:
			bassSoundPlayer = AudioStreamPlayer.new()
			bassSoundPlayer.stream = bassSound
			bassSoundPlayer.volume_db = bassSoundVolume
			add_child(bassSoundPlayer)
		
		if whiffSound != null:
			whiffSoundPlayer = AudioStreamPlayer.new()
			whiffSoundPlayer.stream = whiffSound
			whiffSoundPlayer.volume_db = whiffSoundVolume
			add_child(whiffSoundPlayer)

func PlayHitSFX():
	if player.isGhost:
		return
	if hitSoundPlayer != null:
		hitSoundPlayer.pitch_scale = RNGManager.GrabUnseededFloat(0.95, 1.08)
		hitSoundPlayer.play()
	if bassSoundPlayer != null:
		bassSoundPlayer.pitch_scale = RNGManager.GrabUnseededFloat(0.95, 1.08)
		bassSoundPlayer.play()
	
	if playWhiffOnHit:
		PlayWhiffSFX()

func PlayWhiffSFX():
	if player.isGhost:
		return
	if whiffSoundPlayer != null:
		whiffSoundPlayer.pitch_scale = RNGManager.GrabUnseededFloat(0.95, 1.08)
		whiffSoundPlayer.play()
