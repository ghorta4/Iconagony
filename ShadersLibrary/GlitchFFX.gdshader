shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 AreaShape = vec2(1,1); //shape of the affected area
uniform float IntensityCap = 0.5; //so it looks nicer near the center. Default of 0.25.
uniform float FinalIntensityMultiplier = 10; //how strong the effect is. Default of 1.

uniform float GlitchDistance = 0.004; //How far color distorts by default. Default of 0.004.
uniform vec2 RedTakeOffset = vec2(1, 0.05); //How far to offset red colors.
uniform vec2 GreenTakeOffset = vec2(-1, 0.00); //How far to offset green colors.
uniform vec2 BlueTakeOffset = vec2(0, 0.2); //How far to offset blue colors.

//variables used for static generation
uniform float noiseAngle = 0; //angle at which we decide which pixels to move
uniform float pushAngle = 0; //which way we move the pixels we want. if it's equal to the noise angle, we move along the line that we pick all other pixels with
uniform float sampleScale = 0.00014; //The width of our distortion lines.
uniform float noiseScale = .000009; //how far we move the pixels.
uniform float noiseIntensity = 0.2; //used to determine what percentage of the sprite- i mean REGION- has noise at any given time.
uniform float realTimeScale = 10; //How fast to show distortion in regards to realtime. Default of 10.

uniform float currentTime = 0; //set this externally to sync the effect to the game.

//VHS Noise library from another project of mine. 4D voroni noise for super functionality.
vec3 VHSRandom(ivec3 position) //returns between 1 and 0;
	{
		int hi = position.x;
		hi += 214748364;
		hi = hi * hi;
		hi = hi ^ position.y;
		hi = hi * hi;
		hi = hi ^ position.z;
		hi = hi << 8 ^ hi;
		hi = hi * hi * hi;


		int cast1 = (hi >> 24) & 255;
		int cast2 = (hi >> 8) & 255;
		int cast3 = (hi >> 16) & 255;
		float f1 = float(cast1) / 255.0;
		float f2 = float(cast2) / 255.0;
		float f3 = float(cast3) / 255.0;
		return vec3(f1, f2, f3);
	}

float Cmod(float a, float b)
	{
		float r = mod(a, b);
		float whichOne = float(r > 0.0);
		return mix(r+b, r, whichOne);
	}

vec3 InnerQuadrantPosition(vec3 a, float b)
	{
		return vec3(Cmod(a.x,b) , Cmod(a.y,b), Cmod(a.z,b));
	}

ivec3 GetQuadrant(vec3 pos, float quadrantSize)
	{
		return ivec3(int(floor(pos.x / quadrantSize)), int(floor(pos.y / quadrantSize)), int(floor(pos.z / quadrantSize)));
	}

float DistToCellPoint(vec3 worldPos, ivec3 quadrantNumber, float cellSize)
	{
		vec3 cellPos = worldPos;
		vec3 QuadrantCenter = VHSRandom(quadrantNumber) + vec3(quadrantNumber);
		QuadrantCenter *= cellSize;
		vec3 diff = cellPos - QuadrantCenter;
		float dis = length(diff);
		return dis;
	}

vec3 VoronoiNoiseAtPosition(vec3 pos, float scale)
{
	float closest = 9999.0;
        vec3 closestCell = vec3(0,0,0);
        for (int x = -1; x <= 1; x++)
        {
            for (int y = -1; y <= 1; y++)
            {
                for (int z = -1; z <= 1; z++)
                {
                    ivec3 quadrantPos = GetQuadrant(pos, scale);
                    quadrantPos += ivec3(x,y,z);
                    float dis = DistToCellPoint(pos, quadrantPos, scale);
                    closestCell = mix(vec3(closestCell), vec3(quadrantPos), float(dis < closest));
                    closest = min(closest, dis);
                }
            }
        }
	return  VHSRandom(ivec3(closestCell));
}

vec3 SquareNoiseAtPosition(vec3 pos, float scale)
{
	ivec3 closestCell = GetQuadrant(pos, scale);
	return  VHSRandom(ivec3(closestCell));
}

void fragment() {
	vec2 myUV = UV;

	//Replace the UV with something to the left/right if we're in a randomly selected region
	float sampleLocation = (sin(noiseAngle) * myUV.x + cos(noiseAngle) * myUV.y) * sampleScale;
	vec3 noiseSample = VoronoiNoiseAtPosition(vec3(sampleLocation / TEXTURE_PIXEL_SIZE.x,sampleLocation / TEXTURE_PIXEL_SIZE.y ,currentTime + TIME * 0.01 * realTimeScale), 0.01);

	bool isStaticTarget = noiseSample.z  < noiseIntensity ;
	float turnOnMultiplier = float(isStaticTarget);
	float offset = ((noiseSample.y) - 0.5) * 2.0 ;
	offset *= clamp(FinalIntensityMultiplier, 0, 1);

	vec2 travel = vec2(cos(pushAngle),sin(pushAngle));
	vec2 UVOffset = travel * offset * turnOnMultiplier * noiseScale / TEXTURE_PIXEL_SIZE.x / 10000. ;

	vec4 myColor = texture(TEXTURE, UV);

	float distanceFromCenterOfObject = length((vec2(0.5,0.5) - UV) * AreaShape);
	float weakenOffCenterOfObject = min(IntensityCap, max(1.0 - pow(distanceFromCenterOfObject, 0.5) * 1.5,0));

	vec2 screenUV = SCREEN_UV + UVOffset * weakenOffCenterOfObject * clamp(FinalIntensityMultiplier, 0, 1);

	vec4 screenColor = texture(SCREEN_TEXTURE, screenUV);

	vec4 newColor = vec4(0,0,0,1);
	newColor.r = texture(SCREEN_TEXTURE, screenUV + RedTakeOffset * GlitchDistance).r;
	newColor.g = texture(SCREEN_TEXTURE, screenUV + GreenTakeOffset * GlitchDistance).g;
	newColor.b = texture(SCREEN_TEXTURE, screenUV + BlueTakeOffset * GlitchDistance).b;

	vec4 finalColor = mix(screenColor, newColor, clamp(FinalIntensityMultiplier * weakenOffCenterOfObject, 0, 1));

	finalColor.a = 1.0;

	COLOR = finalColor;
}