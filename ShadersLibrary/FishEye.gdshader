shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 AreaShape = vec2(1,1); //shape of the affected area
uniform float FinalIntensityMultiplier = 0.3; //how strong the effect is. Default of 0.3.
uniform float DivisorIntensityReducer = 2.0; //used to make the center of the fishey not too intense. Default of 2.0.
uniform float DropoffFactor = 0.25; //how the effect weakens over distance. Default of 0.25.
uniform float LateDropoffDistance = 0.2; //how far before the effect smooths out. Default of 0.2.
uniform float LateDropoffFactor = 4; //at what intensity to smooth the effect out at the edges. Default of 4.

uniform vec2 cameraZoom = vec2(1,1); //set this to the camera's current zoom so that the effects looks the same when zooming in/out.

const float pi = 3.141592;

void fragment() {
	vec4 myColor = texture(TEXTURE, UV);
	
	vec2 screenUV = SCREEN_UV;
	
	vec2 offCenterV2 = vec2(0.5,0.5) - UV;
	float distanceFromCenterOfObject = length(offCenterV2 * AreaShape);
	float weakenOffCenterOfObject = max(1.0 - pow(distanceFromCenterOfObject, 0.5) * 1.5,0);
	
	vec2 usedUV = screenUV;
	
	vec2 newUV = usedUV + offCenterV2 / (distanceFromCenterOfObject + DivisorIntensityReducer) * SCREEN_PIXEL_SIZE * 1000.0 * FinalIntensityMultiplier / cameraZoom;
	
	float lateFalloffMultiplier = max((distanceFromCenterOfObject - LateDropoffDistance) / (0.5 - LateDropoffDistance), 0);
	lateFalloffMultiplier = clamp(lateFalloffMultiplier, 0, 1);
	lateFalloffMultiplier = (cos(lateFalloffMultiplier * pi) + 1.0) / 2.0;
	
	vec2 finalUV = mix(usedUV, newUV, pow(weakenOffCenterOfObject, DropoffFactor));
	finalUV = mix(usedUV, finalUV, pow(lateFalloffMultiplier, LateDropoffFactor));
	
	vec4 screenColor =  texture(SCREEN_TEXTURE, finalUV);
	
	COLOR = screenColor;
}