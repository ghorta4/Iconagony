shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 AreaShape = vec2(1,1); //shape of the affected area
uniform float IntensityCap = 0.5; //so it looks nicer near the center. Default of 0.25.
uniform float FinalIntensityMultiplier = 1; //how strong the effect is. Default of 1.
uniform vec3 MultShift = vec3(1.0, 1.0, 1.3); //Multaplicative changes applied to the HSV. Applied first.
uniform vec3 FlatShift = vec3(0.5, 0.5, 0); //Additive changes to the HSV. Applied second.

float Cmod(float a, float b) //modulo operator
	{
		float r = mod(a,b);
		float leftOrRight = float(r > 0.0);
		return (r+b) * (1.0 - leftOrRight) + r * leftOrRight;
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
    float r;
    float g;
    float b;

    float i = floor(h * 6.0);
    float f =(h * 6.0 - i);
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
	vec4 myColor = texture(TEXTURE, UV);
	
	vec2 screenUV = SCREEN_UV;
	
	float distanceFromCenterOfObject = length((vec2(0.5,0.5) - UV) * AreaShape);
	float weakenOffCenterOfObject = min(IntensityCap, max(1.0 - pow(distanceFromCenterOfObject, 0.5) * 1.5,0));
	
	float usedMultiplier = clamp(FinalIntensityMultiplier * weakenOffCenterOfObject, 0, 1);
	
	vec4 screenColor = texture(SCREEN_TEXTURE, screenUV);
	
	//Alright, let's modify some colors baby
	vec4 oldColor = screenColor;
	vec3 hsv = rgb_to_hsv(oldColor.x, oldColor.y, oldColor.z);
	
	hsv *= MultShift;
	hsv += FlatShift;
	
	
	//then we convert back to rgb
	
	vec3 newColor = hsv_to_rgb(hsv.x, hsv.y, hsv.z);
	COLOR = vec4(newColor, usedMultiplier);//vec4(mix(oldColor.xyz, newColor, weakenOffCenterOfObject), oldColor.a);
}