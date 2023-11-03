shader_type canvas_item;

uniform float scrollSpeed = -4.0;
uniform vec4 sweepColor : source_color = vec4(0.3, 1.0, 0.6, 1.0);
uniform float alphaMod = 1.0;
uniform float sonarWidth = 0.8;

float when_lt(float x, float y) {
  return max(sign(y - x), 0.0);
}

float when_ge(float x, float y) {
  return 1.0 - when_lt(x, y);
}

void fragment(){
	float scrollAmount = TIME * scrollSpeed + 0.2*sin(TIME*1.8);
	vec2 centerUV = UV*2.0-vec2(1.0);
	vec2 circUV = vec2(mod(atan(centerUV.y, centerUV.x)+TAU + scrollAmount, TAU)/TAU, length(centerUV));
	COLOR = vec4(sweepColor.rgb, when_ge(1.0, circUV.y) * alphaMod * clamp((max(circUV.x, sonarWidth)-sonarWidth)/max(1.0-sonarWidth, 0.05), 0.0, 1.0));
}