shader_type spatial;
render_mode cull_back;
// The robot's paint: the model's colour atlas read soft (a higher mip, so the generated texture's speckle
// and blotches melt away), its colours cleaned up a touch, under a smooth satin enamel - a tin toy, not a
// rough sculpt. `charge_light` lifts it a little in the dark so it always reads.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float softness = 2.2;        // mip level the colour is read at
uniform float saturation = 1.18;
uniform float roughness = 0.34;
uniform float metallic = 0.12;
uniform vec3 rim_color : source_color = vec3(0.55, 0.8, 1.0);
uniform float rim = 0.12;

void fragment() {
	vec3 c = textureLod(albedo_tex, UV, softness).rgb;
	vec3 fine = texture(albedo_tex, UV).rgb;
	c = mix(c, fine, 0.18);                        // keep a hint of the printed detail (bolts, edges)
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = clamp(mix(vec3(l), c, saturation), 0.0, 1.0);
	c = pow(c, vec3(0.95));
	ALBEDO = c;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = 0.35;
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = rim_color * f * rim;
}
