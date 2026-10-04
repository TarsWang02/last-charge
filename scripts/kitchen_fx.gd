extends Node
## The kitchen's moving light and water (installed by room.gd; the art itself is kitchen_art.gd's):
##   - gas flames: shader flames on the two burners that grow with the flare (FlarePivotW/E's scale),
##     blue at the root, licking orange, yellow-white when they roar; sparks when they flare
##   - the flood, the wet counters and the sink: a dark, slow-rippling water that catches the stove light
##   - steam off the stock pot, a warm bounce off the stove, a cool fill from the window
const K := 9.0
var room: Node3D
var _flames := []   # [pivot, [materials], sparks]

static func install(r: Node3D) -> Node:
	var fx := new()
	fx.name = "KitchenFX"
	fx.room = r
	r.add_child(fx)
	fx._build()
	return fx

func _build() -> void:
	var stop: Node3D = room.get_node("Stop4")
	stop.get_node("StoveFlame").visible = false   # the flat pilot slab: the burners' own small flames do this now
	var flame_shader := preload("res://shaders/flame.gdshader")
	for side in ["W", "E"]:
		var pivot: Node3D = stop.get_node("FlarePivot" + side)
		for m in pivot.find_children("*", "MeshInstance3D", true, false):   # the modelled flame (it stretches badly)
			m.visible = false
		var mats := []
		for k in 2:
			var q := QuadMesh.new()
			q.size = Vector2(0.12 - k * 0.03, 0.034) * K
			var mi := MeshInstance3D.new()
			mi.mesh = q
			var mat := ShaderMaterial.new()
			mat.shader = flame_shader
			mat.set_shader_parameter("seed", randf() * 10.0)
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position = Vector3(0.01 * K * k, 0.017 * K, 0.0)
			pivot.add_child(mi)
			mats.append(mat)
		var sparks := _sparks()
		stop.add_child(sparks)
		sparks.global_position = pivot.global_position + Vector3(0, 0.05 * K, 0)
		_flames.append([pivot, mats, sparks])
	# the water
	var water := ShaderMaterial.new()
	water.shader = preload("res://shaders/water.gdshader")
	for n in ["FloodFloor", "FloodGap", "SinkSpill", "CounterWater", "SinkWater", "CornerWater"]:
		var w := stop.get_node_or_null(n) as CSGShape3D
		if w:
			w.material = water
	# steam off the pot that boiled over
	var pot := stop.get_node_or_null("StockPot") as Node3D
	if pot:
		var steam := _steam()
		stop.add_child(steam)
		steam.global_position = pot.global_position + Vector3(0, 0.11 * K, 0)
	# light: warm bounce off the stove onto the counters and the floor; cool moonlight fill from the window side
	_light(Vector3(3.3, 0.95, -1.5), Color(1.0, 0.58, 0.3), 0.55, 1.7)
	_light(Vector3(4.2, 1.7, 0.7), Color(0.5, 0.62, 1.0), 0.45, 2.4)
	_light(Vector3(3.0, 0.6, -0.4), Color(1.0, 0.55, 0.28), 0.3, 1.5)   # the stove's glow on the wet floor

func _light(p: Vector3, c: Color, e: float, r: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = r * K
	l.omni_attenuation = 1.4
	l.light_specular = 0.6
	room.add_child(l)
	l.global_position = p * K

func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 32
	t.height = 32
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

func _particles(amount: int, life: float, quad: float, color: Color, additive: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_dot()
	m.albedo_color = color
	var q := QuadMesh.new()
	q.size = Vector2.ONE * quad * K
	q.material = m
	p.draw_pass_1 = q
	return p

func _sparks() -> GPUParticles3D:
	var p := _particles(40, 0.9, 0.006, Color(1.0, 0.6, 0.2), true)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.25 * K
	pm.initial_velocity_max = 0.6 * K
	pm.gravity = Vector3(0, -0.1 * K, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.05, 0.01, 0.1) * K
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 0.9, 0.6, 1))
	fade.set_color(1, Color(1, 0.3, 0.05, 0))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	p.process_material = pm
	p.emitting = false
	return p

func _steam() -> GPUParticles3D:
	var p := _particles(26, 4.0, 0.07, Color(0.85, 0.87, 0.9, 0.16), false)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.03 * K
	pm.initial_velocity_max = 0.06 * K
	pm.gravity = Vector3(0.004, 0.01, 0) * K
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.04 * K
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.4))
	grow.add_point(Vector2(1, 1.6))
	var gt := CurveTexture.new()
	gt.curve = grow
	pm.scale_curve = gt
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	p.process_material = pm
	return p

func _process(_d: float) -> void:
	for f in _flames:
		var h: float = (f[0] as Node3D).scale.y
		var heat := clampf((h - 1.2) / 10.0, 0.0, 1.0)
		for m in f[1]:
			(m as ShaderMaterial).set_shader_parameter("heat", 0.25 + heat * 0.75)
		(f[2] as GPUParticles3D).emitting = h > 3.0
