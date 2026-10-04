shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
// Still, shallow water on a floor or a counter: dark and see-through, a slow ripple that catches the
// stove's light and the moonlight, more opaque at a grazing angle.

uniform vec3 deep : source_color = vec3(0.04, 0.09, 0.16);
uniform float ripple_scale = 1.2;
uniform float ripple_speed = 0.6;
uniform float ripple_strength = 0.2;

float wave(vec2 p, vec2 d, float f, float s) { return sin(dot(p, d) * f + TIME * s); }

void fragment() {
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 p = wp.xz * ripple_scale;
	float s = ripple_speed;
	// slope of a few crossing ripples -> a normal
	float dx = cos(p.x * 1.7 + TIME * s) * 0.6 + cos((p.x + p.y) * 2.9 + TIME * s * 1.3) * 0.4 + cos(p.x * 5.3 - p.y * 2.1 + TIME * s * 2.1) * 0.2;
	float dz = cos(p.y * 1.9 - TIME * s * 0.8) * 0.6 + cos((p.x + p.y) * 2.9 + TIME * s * 1.3) * 0.4 + cos(p.y * 4.7 + p.x * 1.3 + TIME * s * 1.7) * 0.2;
	vec3 n = normalize(vec3(-dx * ripple_strength * 0.1, 1.0, -dz * ripple_strength * 0.1));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = deep;
	ROUGHNESS = 0.22;
	METALLIC = 0.0;
	SPECULAR = 0.35;
	ALPHA = clamp(0.5 + fres * 0.25, 0.0, 0.85);
}
