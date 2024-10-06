shader_type canvas_item;


void fragment() {
	vec4 color = COLOR;
	
	vec4 originalColor = texture(TEXTURE, UV);
	
	float centerDist = pow(distance(SCREEN_UV, vec2(0.5, 0.5)), 2 ) + 0.2;
	
	float alphaReduction = clamp((centerDist - 0.3) * 10., 0.0, 1.0);
	color.a = 1.0 - alphaReduction;
	COLOR = color * originalColor;
}