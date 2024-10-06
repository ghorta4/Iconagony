shader_type canvas_item;

uniform vec3 targetColor1 : source_color = vec3(1,1,1);
uniform vec3 targetColor2 : source_color = vec3(0,0,0);
uniform vec4 replaceColor1 : source_color = vec4(0,0,0, 1);
uniform vec4 replaceColor2 : source_color = vec4(1,1,1, 1);
uniform vec4 outlineColor1 : source_color = vec4(0,0,0, 1);
uniform vec4 outlineColor2 : source_color = vec4(1,1,1, 1);

uniform float manualAlphaAdjustment = 1.0;

const vec2 searchPattern[4] = {vec2(-1, 0), vec2(1, 0), vec2(0, 1), vec2(0, -1)};
void fragment() {
	vec4 myPixel = COLOR;
	float useReplace1 = float(distance(myPixel.rgb, targetColor1) < 0.01 && myPixel.a > 0.0);
	float useReplace2 = float(distance(myPixel.rgb, targetColor2) < 0.01 && myPixel.a > 0.0);
	
	vec4 finalColor = myPixel;
	finalColor = mix(finalColor, replaceColor1, useReplace1);
	finalColor = mix(finalColor, replaceColor2, useReplace2);
	
	int nearbyColor1s = 0;
	int nearbyColor2s = 0;
	float maxNeighborAlpha = 0.0;
	for(int i = 0; i < 4; i++) {
		vec4 neighbor = texture(TEXTURE, UV + searchPattern[i] * TEXTURE_PIXEL_SIZE);
		nearbyColor1s += int(neighbor.rgb == targetColor1 && neighbor.a > 0.0);
		nearbyColor2s += int(neighbor.rgb == targetColor2 && neighbor.a > 0.0);
		maxNeighborAlpha = max(maxNeighborAlpha, neighbor.a);
	}
	int totalCounts = nearbyColor1s + nearbyColor2s;
	float outlineColorMix = float(nearbyColor1s) / max(1., float(totalCounts));
	finalColor = mix(finalColor, mix(outlineColor1, outlineColor2, outlineColorMix), float(myPixel.a == 0. && totalCounts > 0));
	COLOR.rgb = finalColor.rgb;
	COLOR.a = max(COLOR.a, maxNeighborAlpha);
	COLOR.a *= manualAlphaAdjustment;
}

