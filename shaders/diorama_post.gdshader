shader_type canvas_item;
render_mode unshaded;
// Full-screen post process for the "miniature diorama / toy photography" look (design doc 11.3).
// Order: tilt-shift blur -> chromatic aberration -> colour grade -> power-loss -> vignette -> grain.
// All parameters are editable in the inspector: scenes/post_fx.tscn -> Screen -> Material.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;

group_uniforms tilt_shift;
uniform bool tilt_shift_enabled = true;
uniform float focus_center : hint_range(0.0, 1.0) = 0.58; // screen height of the sharp band (0 = top)
uniform float focus_width : hint_range(0.0, 0.5) = 0.16;  // half height of the fully sharp band
uniform float focus_falloff : hint_range(0.01, 1.0) = 0.38;
uniform float max_blur : hint_range(0.0, 6.0) = 3.2;      // in mip levels (Godot's screen mips are gaussian-blurred)

group_uniforms grade;
uniform float exposure : hint_range(0.2, 3.0) = 1.05;
uniform float contrast : hint_range(0.5, 1.6) = 1.08;
uniform float saturation : hint_range(0.0, 2.0) = 1.18;
uniform vec3 shadow_tint : source_color = vec3(0.42, 0.52, 0.85);   // moonlight
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.8, 0.55);  // tungsten
uniform float split_tone : hint_range(0.0, 1.0) = 0.3;

group_uniforms lens;
uniform float chroma_offset : hint_range(0.0, 0.01) = 0.0018;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float vignette_radius : hint_range(0.2, 1.5) = 0.85;
uniform float vignette_softness : hint_range(0.05, 1.0) = 0.55;
uniform float grain_amount : hint_range(0.0, 0.3) = 0.035;

group_uniforms power;
uniform float power_loss : hint_range(0.0, 1.0) = 0.0; // 0 = healthy, 1 = battery empty (driven by post_fx.gd)
uniform float power_desaturate : hint_range(0.0, 1.0) = 0.65;
uniform float power_vignette : hint_range(0.0, 1.0) = 0.35;
uniform float power_flicker : hint_range(0.0, 0.5) = 0.12;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

vec3 sample_blur(vec2 uv, float lod, vec2 pixel) {
	if (lod < 0.01) return textureLod(screen_tex, uv, 0.0).rgb;
	// 5 taps at the blurred mip hide the mip's blockiness
	vec2 px = pixel * exp2(lod) * 0.75;
	vec3 c = textureLod(screen_tex, uv, lod).rgb * 0.4;
	c += textureLod(screen_tex, uv + vec2(px.x, 0.0), lod).rgb * 0.15;
	c += textureLod(screen_tex, uv - vec2(px.x, 0.0), lod).rgb * 0.15;
	c += textureLod(screen_tex, uv + vec2(0.0, px.y), lod).rgb * 0.15;
	c += textureLod(screen_tex, uv - vec2(0.0, px.y), lod).rgb * 0.15;
	return c;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - 0.5;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

	// tilt-shift: blur grows with distance from a horizontal focus band
	float lod = 0.0;
	if (tilt_shift_enabled) {
		float d = abs(uv.y - focus_center);
		lod = smoothstep(focus_width, focus_width + focus_falloff, d) * max_blur;
	}

	// chromatic aberration, stronger towards the edges
	vec2 ca = dir * chroma_offset * (1.0 + 4.0 * dot(dir, dir));
	vec3 col;
	col.r = sample_blur(uv + ca, lod, SCREEN_PIXEL_SIZE).r;
	col.g = sample_blur(uv, lod, SCREEN_PIXEL_SIZE).g;
	col.b = sample_blur(uv - ca, lod, SCREEN_PIXEL_SIZE).b;

	// grade
	col *= exposure;
	float l = luma(col);
	vec3 tint = mix(shadow_tint, highlight_tint, smoothstep(0.05, 0.6, l));
	col = mix(col, col * tint / max(luma(tint), 1e-3), split_tone);
	float sat = saturation * (1.0 - power_desaturate * power_loss);
	col = mix(vec3(luma(col)), col, sat);
	col = (col - 0.5) * contrast + 0.5;

	// power loss: low-frequency brown-out flicker once the battery is nearly empty
	float brown = power_loss * power_loss;
	float flick = 1.0 - power_flicker * brown * (0.5 + 0.5 * sin(TIME * 7.0) * sin(TIME * 2.3 + 1.0));
	col *= flick;

	// vignette (oval, follows aspect) - tightens as power drops
	float r = length(dir * vec2(aspect, 1.0)) * 1.414;
	float vs = clamp(vignette_strength + power_vignette * power_loss, 0.0, 1.0);
	float v = 1.0 - smoothstep(vignette_radius - vignette_softness, vignette_radius, r);
	col *= mix(1.0, v, vs);

	// film grain, stronger in the shadows
	float g = hash(floor(uv / SCREEN_PIXEL_SIZE) + fract(TIME) * 113.0) - 0.5;
	col += g * grain_amount * (1.2 - luma(clamp(col, 0.0, 1.0)));

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
