shader_type spatial;
// The town outside: flat colours per instance (MultiMesh colours), lit by the moon, with its own
// distance haze into the sky's horizon colour (the room's fog is far too thick for a whole town).

uniform vec3 haze_color : source_color = vec3(0.07, 0.095, 0.17);
uniform float haze_start = 80.0;
uniform float haze_density = 0.0008;
uniform float lift = 0.035;   // a touch of cold night light of its own, so the dark town still reads in the ending

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
	EMISSION = COLOR.rgb * vec3(0.55, 0.65, 1.0) * lift;
	float d = max(length(VERTEX) - haze_start, 0.0);
	FOG = vec4(haze_color, 1.0 - exp(-d * haze_density));
}
