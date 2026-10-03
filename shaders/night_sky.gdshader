shader_type sky;
// The night sky outside the farmhouse: a deep-blue gradient with a pale band of haze at the horizon,
// a field of small stars, and the moon (with a soft halo), low in the north. Nothing
// here depends on TIME, so the radiance map is only rendered once.

uniform vec3 zenith : source_color = vec3(0.006, 0.01, 0.03);
uniform vec3 horizon : source_color = vec3(0.07, 0.095, 0.17);
uniform vec3 glow : source_color = vec3(0.16, 0.14, 0.17);   // a faint warm band right at the horizon
uniform vec3 ground : source_color = vec3(0.02, 0.025, 0.035);
uniform vec3 moon_color : source_color = vec3(1.0, 0.97, 0.88);
uniform vec3 moon_dir = vec3(-0.303, 0.454, -0.838);   // low in the north-north-west: in the bedroom's north
                                                       // window, and above the house in the ending's last shot
uniform float moon_size = 0.03;        // radius in radians
uniform float star_density = 0.06;     // share of cells that hold a star

float hash(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	// gradient: ground below, a hazy band at the horizon, deep blue overhead
	vec3 col = mix(horizon, zenith, pow(clamp(h, 0.0, 1.0), 0.45));
	if (h >= 0.0) {
		col += glow * exp(-h * 22.0);
	} else {   // below the horizon (past the end of the ground): the town's haze colour, darkening downwards
		col = mix(horizon, ground, clamp(-h * 12.0, 0.0, 1.0));
	}
	if (!AT_CUBEMAP_PASS) {
		// stars: one candidate per cell of a cube grid on the sphere, fading towards the horizon
		vec3 p = d * 160.0;
		vec3 cell = floor(p);
		float r = hash(cell);
		if (r < star_density) {
			vec3 c = cell + 0.5 + (vec3(hash(cell + 3.1), hash(cell + 7.7), hash(cell + 1.3)) - 0.5) * 0.6;
			float dist = length(p - c);
			float size = 0.09 + 0.16 * hash(cell + 11.0);
			float s = smoothstep(size, 0.0, dist) * smoothstep(0.02, 0.3, h);
			vec3 tint = mix(vec3(0.75, 0.82, 1.0), vec3(1.0, 0.9, 0.75), hash(cell + 5.0));
			col += tint * s * (0.6 + 2.2 * pow(hash(cell + 9.0), 4.0));
		}
	}
	// the moon
	{
		vec3 m = normalize(moon_dir);
		float a = acos(clamp(dot(d, m), -1.0, 1.0));
		float disc = smoothstep(moon_size, moon_size * 0.85, a);
		// a few darker "seas" on the disc
		vec3 q = d - m;
		float seas = 0.82 + 0.18 * smoothstep(0.4, 0.6, hash(floor(q * 220.0)));
		col = mix(col, moon_color * 2.4 * seas, disc);
		col += moon_color * (0.10 * exp(-a * 14.0) + 0.05 * exp(-a * 3.0));
	}
	COLOR = col;
}
