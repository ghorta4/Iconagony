shader_type canvas_item;

uniform vec3 targetColor1 : source_color = vec3(1,1,1);
uniform vec3 targetColor2 : source_color = vec3(0,0,0);
uniform vec3 newColor1 : source_color;
uniform vec3 newColor2 : source_color;

void fragment() {
	vec3 originalColor = COLOR.rgb;
	
	COLOR.rgb = mix(COLOR.rgb, newColor1, float(originalColor == targetColor1));
	
	COLOR.rgb = mix(COLOR.rgb, newColor2, float(originalColor == targetColor2));
}
