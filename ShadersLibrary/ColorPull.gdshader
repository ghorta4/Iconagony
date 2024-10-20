shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 AreaShape = vec2(1,1); //shape of the affected area
uniform float IntensityCap = 0.5; //so it looks nicer near the center. Default of 0.25.
uniform float FinalIntensityMultiplier = 1; //how strong the effect is. Default of 1.
uniform vec4 MixedColor = vec4(1,1,1,1); //what color to mix our background elements with. Default of white (1,1,1,1).

void fragment() {
	vec4 myColor = texture(TEXTURE, UV);
	
	vec2 screenUV = SCREEN_UV;
	
	float distanceFromCenterOfObject = length((vec2(0.5,0.5) - UV) * AreaShape);
	float weakenOffCenterOfObject = min(IntensityCap, max(1.0 - pow(distanceFromCenterOfObject, 0.5) * 1.5,0));
	
	vec4 screenColor = texture(SCREEN_TEXTURE, screenUV);
	
	float oldLum = (0.2126*screenColor.r + 0.7152*screenColor.g + 0.0722*screenColor.b);
	
	vec4 finalColor = mix(screenColor, MixedColor, clamp(FinalIntensityMultiplier * weakenOffCenterOfObject, 0, 1));
	float newLum = (0.2126*finalColor.r + 0.7152*finalColor.g + 0.0722*finalColor.b);
	float intensityMult = oldLum / newLum;
	finalColor *= intensityMult;
	finalColor.a = 1.0;
	COLOR = finalColor;
}