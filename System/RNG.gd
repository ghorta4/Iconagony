class_name RNGManager

var currentSeed : int = 42069
var currentSeedOffset : int = 0

static func VHSRandom(position : Vector3i) -> float: #A randomization function by yours truly.
	var hi = position.x;
	hi += 214748364;
	hi = hi * hi;
	hi = hi ^ position.y;
	hi = hi * hi;
	hi = hi ^ position.z;		hi = hi << 8 ^ hi;
	hi = hi * hi * hi;
	hi = hi << 16 ^ hi >> 16;
	var cast3 = hi & 65535;
	var f3 = float(cast3) / 65535.0;
	return f3;


func GrabSeededFloat(minn : float, maxn : float):
	currentSeedOffset += 1
	var random = RNGManager.VHSRandom(Vector3i(currentSeed, currentSeedOffset, currentSeed + currentSeedOffset))
	return random * (maxn - minn) + minn


static func GrabUnseededFloat(minn : float = -1, maxn : float = 1):
	return randf_range(minn, maxn)

