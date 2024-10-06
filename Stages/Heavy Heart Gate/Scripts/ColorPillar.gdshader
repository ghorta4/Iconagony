shader_type canvas_item;

uniform float curve = 0.0;

uniform float alphaReduction = 0.9;
uniform float alphaFalloff = 6.0;

uniform float fogDivisor = 0.25;

uniform vec2 gridSize = vec2(5,5);
uniform vec2 timeScale = vec2(1,1);

uniform float realTimeScale = 1.0;
uniform float inGameTime = 0;

uniform vec3 targetColor1 : source_color = vec3(1,1,1);
uniform vec3 targetColor2 : source_color = vec3(1,1,1);
uniform vec3 targetColor3 : source_color = vec3(1,1,1);
uniform vec3 targetColor4 : source_color = vec3(1,1,1);

float Cmod(float a, float b)
	{
		float r = mod(a,b);
		float leftOrRight = float(r >= 0.0);
		return (r+b) * (1.0 - leftOrRight) + r * leftOrRight;
	}

void fragment() {
	float uvyc = UV.y - 0.5;
	vec2 usedUV = UV + vec2(curve * uvyc * uvyc, 0);
	usedUV.y -= usedUV.x * 0.4;
	usedUV.x = abs(0.5 - usedUV.x) * -1.;
	usedUV.x += 0.6;
	
	vec2 gridUV = usedUV + (TIME * realTimeScale + inGameTime) * timeScale;
	gridUV *= gridSize;
	
	float xMelt = ((floor(gridUV.x * 2.0) - gridUV.x * 2.0 + 1.) - (1. - usedUV.x) * 2.0 * gridSize.x + gridSize.x * 2.0 ) / gridSize.x / 2.0;
	float yMelt = ((floor(gridUV.y * 2.0) - gridUV.y * 2.0 + 1.) - (1. - usedUV.y) * 2.0 * gridSize.y + gridSize.y * 2.0 ) / gridSize.y / 2.0;
	gridUV.x = Cmod(gridUV.x, 1.0);
	gridUV.y = Cmod(gridUV.y, 1.0);
	
	
	float isAltGrid = float(gridUV.x > 0.5 != gridUV.y > 0.5);
	
	
	float modX = mod(gridUV.x * 2.0, 1.0);
	float modY = mod(gridUV.y * 2.0, 1.0);
	
	float cornerDist = distance( vec2(modX, modY), vec2(1,1) );
	
	float alpha = xMelt * alphaFalloff- alphaReduction + isAltGrid * 0.25;
	alpha -= cornerDist;
	alpha = floor(alpha);
	
	COLOR.rgb = mix(targetColor1, targetColor2, isAltGrid);
	
	vec3 finalTargetColor = mix(targetColor3, targetColor4, UV.y);
	COLOR.rgb = mix(finalTargetColor, COLOR.rgb, clamp(abs(usedUV.x - 0.6) / fogDivisor, 0, 1.0));
	
	COLOR.a = alpha;
}
