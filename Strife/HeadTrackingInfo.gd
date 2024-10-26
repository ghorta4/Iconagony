class_name HeadTrackingInfo

const maxAngleSteps = 3

var position : Vector2
var spriteMapLocation : Vector2i #0, 0 is facing towards the camera. Extends out to 3,3- facing towards the side completely

var backgroundFacingSprite : bool
var reverseFromPlayerSprite : bool

var showBehindPlayer : bool

var expressionOverride : String

func Serialize() -> PackedByteArray:
	var data = {
		"positionX" : position.x,
		"positionY" : position.y,
		"spriteLocX" : spriteMapLocation.x,
		"spriteLocY" : spriteMapLocation.y,
		"backgroundFacingSprite" : backgroundFacingSprite,
		"reverseFromPlayerSprite" : reverseFromPlayerSprite,
		"showBehindPlayer" : showBehindPlayer,
		"expressionOverride" : expressionOverride
		}
	
	return var_to_bytes(data)

static func Deserialize(data : PackedByteArray) -> HeadTrackingInfo:
	var holster = HeadTrackingInfo.new()
	var dict = bytes_to_var(data)
	if dict == null:
		return null
	holster.position = Vector2(dict.positionX, dict.positionY)
	holster.spriteMapLocation = Vector2i(dict.spriteLocX, dict.spriteLocY)
	holster.backgroundFacingSprite = dict.backgroundFacingSprite
	holster.reverseFromPlayerSprite = dict.reverseFromPlayerSprite
	if dict.has("expressionOverride"): holster.expressionOverride = dict.expressionOverride
	if dict.has("showBehindPlayer"): holster.showBehindPlayer = dict.showBehindPlayer
	return holster
