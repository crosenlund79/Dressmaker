shader_type canvas_item;
// Tints a fabric pattern while preserving its texture.
// Pattern channels: R = shading detail (0.8 neutral), G = secondary mask, B = sheen, A = coverage.

uniform sampler2D pattern : repeat_enable, filter_linear_mipmap;
uniform vec4 primary : source_color = vec4(0.7, 0.2, 0.3, 1.0);
uniform vec4 secondary : source_color = vec4(0.95, 0.9, 0.8, 1.0);
uniform float pattern_scale = 1.0;
uniform float pattern_rotation = 0.0; // radians
uniform float opacity = 1.0;
uniform float highlight = 0.0;

void fragment() {
	float c = cos(pattern_rotation);
	float s = sin(pattern_rotation);
	vec2 uv = mat2(vec2(c, s), vec2(-s, c)) * UV / max(pattern_scale, 0.05);
	vec4 p = texture(pattern, uv);
	vec3 base = mix(primary.rgb, secondary.rgb, p.g);
	vec3 col = base * (p.r * 1.25) * COLOR.rgb + vec3(p.b) * 0.8;
	col = mix(col, vec3(1.0, 0.93, 0.7), highlight * 0.12);
	COLOR = vec4(col, p.a * opacity);
}
