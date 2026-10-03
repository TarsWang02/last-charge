shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
// A soft pool of lamplight on the ground under a street lamp (an additive quad), faded by the
// instance colour together with its lamp.

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float f = pow(clamp(1.0 - r, 0.0, 1.0), 2.2);
	ALBEDO = COLOR.rgb * f * 0.55;
}
