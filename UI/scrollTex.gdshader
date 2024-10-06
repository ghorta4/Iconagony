shader_type canvas_item;

uniform vec2 offset = vec2(0,0);
uniform vec4 modulate : source_color = vec4(1,1,1,1);
uniform vec2 autoTimeScroll = vec2(0,0);
void fragment() {
	vec2 usedUV = UV;
	usedUV += offset + autoTimeScroll * TIME;
	vec4 oldCol = COLOR;
	COLOR = texture(TEXTURE, usedUV);
	COLOR *= modulate;
}

