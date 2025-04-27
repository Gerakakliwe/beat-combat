shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 beam_color : source_color = vec4(1.0, 0.2, 0.6, 0.5); // Pink-ish
uniform float glow_strength = 1.5;

void fragment() {
	vec2 uv_centered = (UV - vec2(0.5)) * 2.0;
	float radial_dist = length(uv_centered);
	float alpha = smoothstep(1.0, 0.2, radial_dist);
	ALBEDO = beam_color.rgb;
	ALPHA = beam_color.a * alpha;
	EMISSION = ALBEDO * glow_strength * alpha;
}