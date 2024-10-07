shader_type canvas_item;

uniform float gridSize = 64.;
uniform vec2 overallWorldPos = vec2(0,0);
uniform float cameraScale = 1.0;

uniform float realTimeScale = 1.0;
uniform float inGameTime = 0;
uniform float timeScale = 1.0;

uniform vec3 glowColor : source_color;

uniform float brightness = 0.3;
uniform float brightnessCut = 0.3;

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
	hi = hi << 16 ^ hi >> 16;
	
	
	int cast1 = (hi >> 24) & 255;
	int cast2 = (hi >> 8) & 255;
	int cast3 = (hi >> 16) & 255;
	float f1 = float(cast1) / 255.0;
	float f2 = float(cast2) / 255.0;
	float f3 = float(cast3) / 255.0;
	return vec3(f1, f2, f3);
	}

ivec3 GetQuadrant(vec3 pos, float quadrantSize) 
	{
		return ivec3(int(floor(pos.x / quadrantSize)), int(floor(pos.y / quadrantSize)),int(floor(pos.z / quadrantSize)));
	}


vec3 getPerlinNoiseAtPoint(vec3 worldPos, float cs) {
	ivec3 myQuadrant = GetQuadrant(worldPos, cs);
	
	vec3 output = vec3(0,0,0);
	
	for(int x = 0; x <= 1; x++) {
		for(int y = 0; y <= 1; y++) {
			for(int z = 0; z <= 1; z++) {
				ivec3 quad = myQuadrant + ivec3(x,y,z);
				vec3 vhsRand = VHSRandom(ivec3(quad.x, quad.y, quad.z));
				vec3 difference = vec3(quad) * cs - worldPos;
				float distFactor = (cs - abs(difference.z)) * (cs - abs(difference.y)) * (cs - abs(difference.x));
				vec3 toAdd = distFactor / cs / cs / cs * (vhsRand);
				output += toAdd;
			}
		}
	}
	
	return output;
	}

void fragment() {
	float T =  (TIME * realTimeScale + inGameTime) * timeScale;
	
	vec2 usedNoiseSampleUV = SCREEN_UV / SCREEN_PIXEL_SIZE - overallWorldPos * cameraScale;
	vec3 noiseSample = getPerlinNoiseAtPoint(vec3(usedNoiseSampleUV.x, sin(usedNoiseSampleUV.y) + usedNoiseSampleUV.y * 0.3 , T), gridSize);
	usedNoiseSampleUV.x += sin(usedNoiseSampleUV.x / 40.67 + cos(T/ 10.1 + sin(usedNoiseSampleUV.y / 100.0))) * 40.;
	noiseSample += getPerlinNoiseAtPoint(vec3(usedNoiseSampleUV.x, usedNoiseSampleUV.y , T) * 0.294, gridSize * .42);
	usedNoiseSampleUV.y += sin(usedNoiseSampleUV.y / 40.24) * 40.;
	
	noiseSample += getPerlinNoiseAtPoint(vec3(usedNoiseSampleUV.x, usedNoiseSampleUV.y , T) * 0.94, gridSize * 6.42);
	
	noiseSample /= 3.0;
	noiseSample = vec3(noiseSample.x * glowColor.x, noiseSample.x * glowColor.y, noiseSample.y * glowColor.z) * (noiseSample.z * brightness - brightnessCut);
	COLOR.rgb += noiseSample;
}