shader_type canvas_item;
// Speed lines for the clothesline ride: thin radial streaks flying outward from the edges of the screen,
// more and brighter with `amount` (0..1); the centre stays clear.

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float t = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV - 0.5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;  // square up the aspect ratio
	float r = length(uv);
	float a = atan(uv.y, uv.x) / 6.2831853 + 0.5;
	float lines = 140.0;
	float id = floor(a * lines);
	float h = fract(sin(id * 12.9898 + 4.1) * 43758.5453);
	float on = step(1.0 - amount * 0.55, h);                              // more lines as it speeds up
	float cell = abs(fract(a * lines) - 0.5) * 2.0;
	float thin = smoothstep(0.35, 0.0, cell);                             // each line is a thin wedge
	float band = fract(r * 1.6 - t * (1.2 + h * 1.6) + h * 7.0);           // a streak running outwards
	float streak = smoothstep(0.0, 0.08, band) * smoothstep(0.55, 0.1, band);
	float edge = smoothstep(0.2, 0.55, r);                                // keep the middle clear
	COLOR = vec4(0.88, 0.92, 1.0, amount * 0.4 * on * thin * streak * edge);
}
