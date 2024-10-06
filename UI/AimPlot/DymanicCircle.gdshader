shader_type canvas_item;

uniform vec4 color : source_color;
uniform vec4 secondaryColor : source_color;
uniform vec2 circleCenter;
uniform float radius = 0.5;
uniform float radiusMin = 0.1;
uniform float outlineSize = 0.03;
uniform float startAngle = -1;
uniform float endAngle = 1;
uniform float rotateOffset = 0;

float fwrap(float a, float start, float end)
	{
		float f = a;
		
		f -= start;
		f = mod(f, end - start);
		f += start;
		
		return f;
	}

void fragment() {
	
	
	float dist = distance(circleCenter, UV);
	
	vec2 transform = UV - circleCenter;
	float angle =  fwrap(atan(transform.y, transform.x) + rotateOffset, -PI, PI);
	
	bool inRange = dist < radius && dist > radiusMin;
	bool inAngle = angle > startAngle && angle < endAngle;
	
	bool validOne = inRange && inAngle;
	
	COLOR = mix(vec4(0,0,0,0), color, float(validOne));
	
	bool inRange2 = (dist < radiusMin && dist > radiusMin - outlineSize) || (dist > radius && dist < radius + outlineSize);
	bool inAngle2 = angle > startAngle && angle < endAngle;
	
	bool edgeCaseDist = (dist > radiusMin - outlineSize) && (dist < radius + outlineSize);
	bool edgeCaseAngle = ((angle - endAngle) * dist < outlineSize) && ((startAngle - angle) * dist < outlineSize);
	edgeCaseAngle = edgeCaseAngle || !(((angle - endAngle + PI * 2.0) * dist > outlineSize) && ((startAngle - angle + PI * 2.0) * dist > outlineSize));
	
	bool validTwo = (inRange2 && inAngle2) || (edgeCaseDist && edgeCaseAngle);
	
	COLOR = mix(COLOR, secondaryColor, float(validTwo && !validOne));
}
