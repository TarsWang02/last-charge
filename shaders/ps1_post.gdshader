shader_type canvas_item;
// Full-screen PS1-style post process. Tweak in the editor:
// main.tscn -> PostFX/Screen -> Material -> Shader Parameters.
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 3.0;
uniform float color_levels : hint_range(2.0, 256.0, 1.0) = 24.0;
uniform bool dither = true;
uniform float grain_amount : hint_range(0.0, 0.5) = 0.07;
uniform float chroma_offset : hint_range(0.0, 0.05) = 0.006;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.85;
uniform float vignette_radius : hint_range(0.2, 1.5) = 0.95;
uniform float vignette_softness : hint_range(0.05, 1.0) = 0.6;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 cell = pixel_size * SCREEN_PIXEL_SIZE;
	vec2 px = floor(SCREEN_UV / cell);
	vec2 uv = (px + 0.5) * cell;
	vec2 dir = uv - 0.5;
	vec3 col;
	col.r = texture(screen_tex, uv + dir * chroma_offset).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - dir * chroma_offset).b;
	float lv = color_levels - 1.0;
	float d = dither ? (BAYER[int(mod(px.x, 4.0)) + 4 * int(mod(px.y, 4.0))] / 16.0 - 0.5) : 0.0;
	col = floor(col * lv + 0.5 + d) / lv;
	col += (hash(px + fract(TIME) * 97.0) - 0.5) * grain_amount;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float r = length(dir * vec2(aspect, 1.0)) * 1.414;
	float v = 1.0 - smoothstep(vignette_radius - vignette_softness, vignette_radius, r);
	col *= mix(1.0, v, vignette_strength);
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
