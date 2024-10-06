shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec3 targetColor1 : source_color = vec3(1,1,1);
uniform vec3 targetColor2 : source_color = vec3(0,0,0);
uniform vec3 newColor1 : source_color;
uniform vec3 newColor2 : source_color;

uniform bool enableRainbowSheen = false;
uniform vec3 foilModulate : source_color = vec3(1,1,1);
uniform float foilDesaturate = 0.0;
uniform bool enableFoilNoise = false;
uniform bool enableScreenReflection = false;

uniform float fillPercent = 0.5;

const float perlinLerpDistance = 10.06;
const float lerpMix = 0.9;

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

float Cmod(float a, float b) //modulo operator
	{
		float r = mod(a,b);
		float leftOrRight = float(r > 0.0);
		return (r+b) * (1.0 - leftOrRight) + r * leftOrRight;
	}

vec3 InnerQuadrantPosition(vec3 a, float b) 
	{
		return vec3(Cmod(a.x,b) , Cmod(a.y,b), Cmod(a.z,b));
	}

ivec3 GetQuadrant(vec3 pos, float quadrantSize) 
	{
		return ivec3(int(floor(pos.x / quadrantSize)), int(floor(pos.y / quadrantSize)),int(floor(pos.z / quadrantSize)));
	}

float DistToCellPoint(vec3 worldPos, ivec3 quadrantNumber, float cs) 
	{
		vec3 cellPos = worldPos;
		vec3 QuadrantCenter = VHSRandom(quadrantNumber) + vec3(quadrantNumber);
		QuadrantCenter *= cs;
		vec3 diff = cellPos - QuadrantCenter;
		float dis = length(diff);
		return dis;
	}

ivec3 ClosestCell(vec3 pos, float scale) {
		float closest = 9999.0;
        ivec3 closestCell = ivec3(0,0,0);
        for (int x = -1; x <= 1; x++) 
        {
            for (int y = -1; y <= 1; y++) 
            {
                for (int z = -1; z <= 1; z++) 
                {
                    ivec3 quadrantPos = GetQuadrant(pos, scale);
                    quadrantPos += ivec3(x,y,z);
                    float dis = DistToCellPoint(pos, quadrantPos, scale);
                    closestCell = ivec3(mix(vec3(closestCell), vec3(quadrantPos), float(dis < closest)));
                    closest = min(closest, dis);
                }
            }
        }
		return closestCell;
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

vec3 getLerpedPerlinNoiseAtPoint(vec3 worldPos, float cs) {
	vec3 val = getPerlinNoiseAtPoint(worldPos, cs);
	
	vec3 neighborLerp = vec3(0,0,0);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				neighborLerp += getPerlinNoiseAtPoint(worldPos + vec3(float(x), float(y), float(z)) * perlinLerpDistance, cs) * 1.0 / 27.0;
			}
		}
	}

	return mix(val, neighborLerp, lerpMix);
	}

vec3 rgb_to_hsv(float r,float g, float b) {
	//we make em HSL modifications so we need the HSL color
	//we need to find which is our brightest (and least bright) color
	float cmax = max(max(r, g), b);
	float cmin = min(min(r, g), b);
	float delta = cmax - cmin;
	//use that to calculate xxlumxx vibrance.
	float vib = (cmax + cmin)/2.0;
	//use that to calculate saturation
	float sat = 0.0;
	if (delta != 0.0) {
		sat = delta / cmax;
	}
	//finally, hue!
	float hue = 0.0;
	if (delta != 0.0){
		float valIfRMax = Cmod((g - b) / delta, 6.0) / 6.0;
		float valIfGMax = (((b - r) / delta) + 2.0) / 6.0;
		float valIfBMax = (((r - g) / delta) + 4.0)/ 6.0;
		hue = mix(valIfRMax, valIfGMax, float(g == cmax));
		hue = mix(hue, valIfBMax, float(b == cmax));
	}
	vib = cmax; //actually this is the real luminence LOL get trolled
	//now we can edit the color as we please
	return vec3(hue, sat, vib);
	}

vec3 hsv_to_rgb(float h,float s,float v){
    //based on code at
    //http://stackoverflow.com/questions/51203917/math-behind-hsv-to-rgb-conversion-of-colors
    float i = floor(h * 6.0);
    float f = h * 6.0 - i;
    float p = v * (1.0 - s);
    float q = v * (1.0 - f * s);
    float t = v * (1.0 - (1.0 - f) * s);

	int match = int(i) % 6;
	vec3 finalColor = vec3(v,t,p);
	finalColor = mix(finalColor, vec3(q,v,p), float(match == 1));
	finalColor = mix(finalColor, vec3(p,v,t), float(match == 2));
	finalColor = mix(finalColor, vec3(p,q,v), float(match == 3));
	finalColor = mix(finalColor, vec3(t,p,v), float(match == 4));
	finalColor = mix(finalColor, vec3(v,p,q), float(match == 5));
    return finalColor;
	}


void fragment() {
	vec3 originalColor = COLOR.rgb;
	
	COLOR.rgb = mix(COLOR.rgb, newColor1, float(originalColor == targetColor1));
	bool isColor2 = originalColor == targetColor2;
	COLOR.rgb = mix(COLOR.rgb, newColor2, float(isColor2));
	
	bool isCutoffSection = !isColor2 && UV.x > fillPercent;
	bool isIndicatorLine = UV.x > fillPercent && UV.x - TEXTURE_PIXEL_SIZE.x * 2. < fillPercent;
	float newA = min(0.5, COLOR.a);
	COLOR.a = mix(COLOR.a, newA, float(isCutoffSection && !isIndicatorLine));
	COLOR.rgb = mix(COLOR.rgb, vec3(0,0,0), float(isCutoffSection || isIndicatorLine) * 0.5);
	COLOR.rgb = mix(COLOR.rgb, vec3(0.7,0.7,0.7), float(isIndicatorLine) * 0.8);
	
	//Screen Reflection below
	vec4 screenSample = texture(SCREEN_TEXTURE, mix(UV, SCREEN_UV, 0.4));
	COLOR.rgb = mix(COLOR.rgb, screenSample.rgb, float(enableScreenReflection) * 0.08);
	
	vec3 hsv = rgb_to_hsv(COLOR.r, COLOR.g, COLOR.b);
	
	//Rainbow sheen effect below
	hsv.z += mix(0.0, 0.02, float(enableRainbowSheen));
	hsv.y = mix(hsv.y, 1.0, float(enableRainbowSheen) * 0.2);
	hsv.x += mix(0.0, sin(TIME * 1.15 + SCREEN_UV.x + SCREEN_UV.y * 0.4 + UV.x * 2.8 + UV.y * 1.9) * 0.1, float(enableRainbowSheen));
	hsv.x = fract(hsv.x);
	COLOR.rgb = hsv_to_rgb(hsv.x, hsv.y, hsv.z);
	
	//Foil noise effect below
	vec2 usedNoiseSampleUV = UV / TEXTURE_PIXEL_SIZE + SCREEN_UV / SCREEN_PIXEL_SIZE / 25.0;
	vec3 noiseSample = getLerpedPerlinNoiseAtPoint(vec3(usedNoiseSampleUV.x, usedNoiseSampleUV.y, TIME * 1.5), 4.);
	vec3 appliedNoise = (noiseSample - vec3(0.5, 0.5, 0.5)) * 2.;
	appliedNoise.x = max(appliedNoise.x, 0.);
	appliedNoise.y = max(appliedNoise.y, 0.);
	appliedNoise.z = max(appliedNoise.z, 0.);
	float avgNoise = (appliedNoise.x + appliedNoise.y + appliedNoise.z) / 3.0;
	appliedNoise = mix(appliedNoise, vec3(avgNoise) * foilModulate, foilDesaturate);
	COLOR.rgb = mix(COLOR.rgb,COLOR.rgb + appliedNoise, float(enableFoilNoise));
	
}
