shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
// A gas flame on a quad that always turns to the camera around its own up axis: blue at the root, orange
// tongues licking upwards (scrolling noise), brightest low down. `heat` (0..1) pushes it yellow-white.

uniform float heat = 0.3;
uniform float seed = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	// cylindrical billboard: keep the quad's up axis, turn its face to the camera
	vec3 up = normalize(MODEL_MATRIX[1].xyz);
	vec3 to_cam = normalize(INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz);
	vec3 right = normalize(cross(up, to_cam));
	vec3 fwd = cross(right, up);
	mat4 bb = mat4(vec4(right * length(MODEL_MATRIX[0].xyz), 0.0), vec4(MODEL_MATRIX[1].xyz, 0.0),
		vec4(fwd * length(MODEL_MATRIX[2].xyz), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
}

void fragment() {
	vec2 uv = UV;
	float y = 1.0 - uv.y;                       // 0 at the root, 1 at the tip
	float t = TIME * 2.2 + seed * 13.0;
	float n = noise(vec2(uv.x * 5.0 + seed, y * 4.0 - t * 1.6)) * 0.6 + noise(vec2(uv.x * 11.0, y * 9.0 - t * 2.7)) * 0.4;
	float width = mix(0.42, 0.04, pow(y, 0.8)) * (0.75 + 0.5 * n);
	float body = smoothstep(width, width * 0.35, abs(uv.x - 0.5));
	body *= smoothstep(1.0, 0.55 - 0.3 * n, y) * smoothstep(0.0, 0.06, y);
	vec3 blue = vec3(0.15, 0.35, 1.0);
	vec3 orange = vec3(1.0, 0.42, 0.08);
	vec3 yellow = vec3(1.0, 0.85, 0.45);
	vec3 col = mix(blue, orange, smoothstep(0.02, 0.22, y + n * 0.1));
	col = mix(col, yellow, heat * smoothstep(0.5, 0.0, abs(uv.x - 0.5)) * smoothstep(0.7, 0.1, y));
	ALBEDO = col * body * (1.6 + heat * 1.6);
}
