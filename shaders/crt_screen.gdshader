shader_type spatial;
render_mode unshaded, cull_back;
// The living-room CRT: shows a SubViewport (the pixel game) with a slight bulge, scanlines,
// a dark rim, static noise and a white flash for the "pulled into the screen" moment.

uniform sampler2D screen_tex : filter_nearest, source_color;
uniform vec2 res = vec2(320.0, 240.0);
uniform float glow = 1.5;
uniform float static_amt : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 4.0) = 0.0;
uniform float power : hint_range(0.0, 1.0) = 1.0;   // 0 = switched off (black, tiny dot)
uniform float desat : hint_range(0.0, 1.0) = 0.0;   // the game losing its colour at the end

void fragment() {
	vec2 c = UV - 0.5;
	vec2 uv = 0.5 + c * (1.0 + 0.09 * dot(c, c));   // tube bulge
	vec3 col = texture(screen_tex, uv).rgb;
	col = mix(col, vec3(dot(col, vec3(0.3, 0.59, 0.11))) * 0.7, desat);
	col *= 0.78 + 0.22 * sin(uv.y * res.y * 6.2831853);  // scanlines
	vec2 px = floor(uv * res);
	float n = fract(sin(dot(px + floor(TIME * 30.0) * vec2(17.0, 31.0), vec2(12.9898, 78.233))) * 43758.5453);
	col = mix(col, vec3(n * 0.9), static_amt);
	col += vec3(0.85, 0.92, 1.0) * flash;
	float rim = smoothstep(0.72, 0.5, length(c * vec2(1.0, 1.25)));
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) col = vec3(0.0);
	float dot_on = smoothstep(0.02 + power * 0.8, 0.0, length(c));
	ALBEDO = col * rim * glow * mix(dot_on, 1.0, power);
}
