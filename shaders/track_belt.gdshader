shader_type spatial;
render_mode diffuse_toon, specular_disabled;
// Moves a rigid tank-track belt around its loop. The belt mesh's local origin is the centre of
// the loop; the loop is a "stadium": straight runs along Z (from -half_len to +half_len) joined by
// half circles. Every vertex keeps its distance from the loop core and slides `offset` metres along it,
// so the lugs travel and bend round the ends. No seam: the loop is closed.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform sampler2D rm_tex : hint_default_white, filter_linear_mipmap;
uniform float offset = 0.0;      // metres travelled; top run moves towards +Z when positive
uniform float half_len = 0.16;   // half length of the straight runs
uniform float pitch_radius = 0.12; // radius used to convert cap angle <-> distance


// p = (z, y). Returns loop parameter s, sets r (distance from core) and a (outward normal angle).
float to_s(vec2 p, out float r, out float a) {
	float H = half_len, R = pitch_radius;
	if (p.x > H) {
		vec2 v = p - vec2(H, 0.0);
		r = length(v); a = atan(v.y, v.x);
		return 2.0 * H + (PI * 0.5 - a) * R;
	} else if (p.x < -H) {
		vec2 v = p - vec2(-H, 0.0);
		r = length(v);
		float phi = atan(v.y, -v.x);
		a = PI - phi;
		return 4.0 * H + PI * R + (phi + PI * 0.5) * R;
	} else if (p.y >= 0.0) {
		r = p.y; a = PI * 0.5;
		return p.x + H;
	}
	r = -p.y; a = -PI * 0.5;
	return 2.0 * H + PI * R + (H - p.x);
}

vec2 from_s(float s, float r, out float a) {
	float H = half_len, R = pitch_radius;
	if (s < 2.0 * H) { a = PI * 0.5; return vec2(s - H, r); }
	s -= 2.0 * H;
	if (s < PI * R) { a = PI * 0.5 - s / R; return vec2(H + r * cos(a), r * sin(a)); }
	s -= PI * R;
	if (s < 2.0 * H) { a = -PI * 0.5; return vec2(H - s, -r); }
	s -= 2.0 * H;
	float phi = s / R - PI * 0.5;
	a = PI - phi;
	return vec2(-half_len - r * cos(phi), r * sin(phi));
}

vec3 rot_x(vec3 v, float d) {  // rotate in the z-y plane (angle measured from +Z towards +Y)
	return vec3(v.x, v.z * sin(d) + v.y * cos(d), v.z * cos(d) - v.y * sin(d));
}

void vertex() {
	float P = 4.0 * half_len + 2.0 * PI * pitch_radius;
	float r, a0, a1;
	float s = to_s(VERTEX.zy, r, a0);
	vec2 q = from_s(mod(s + offset, P), r, a1);
	VERTEX.z = q.x;
	VERTEX.y = q.y;
	float d = a1 - a0;
	NORMAL = rot_x(NORMAL, d);
	TANGENT = rot_x(TANGENT, d);
	BINORMAL = rot_x(BINORMAL, d);
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = 0.88;
	METALLIC = 0.03;
	// Rubber tread detail comes from the mesh; avoid generated normal-map glitter.
}
