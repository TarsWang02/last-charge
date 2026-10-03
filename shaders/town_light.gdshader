shader_type spatial;
render_mode unshaded, cull_disabled;
// The town's lit windows and street lamps: unshaded, brighter than 1 so they bloom, and only
// half as hazy as everything else (light carries through the night air).

uniform vec3 haze_color : source_color = vec3(0.07, 0.095, 0.17);
uniform float haze_start = 80.0;
uniform float haze_density = 0.0004;
uniform float boost = 1.8;

void fragment() {
	ALBEDO = COLOR.rgb * boost;
	float d = max(length(VERTEX) - haze_start, 0.0);
	FOG = vec4(haze_color, 1.0 - exp(-d * haze_density));
}
