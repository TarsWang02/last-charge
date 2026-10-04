extends RefCounted
## Imported art follows existing gameplay nodes. Greybox collision geometry stays intact.
const K := 9.0
const STRUCTURE_ART := preload("res://scripts/room_structure_art.gd")
const PROPS := {
	"bigbot": preload("res://assets/models/props/prop_bigbot.glb"),
	"rabbit": preload("res://assets/models/props/prop_plush_rabbit.glb"),
	"bear": preload("res://assets/models/props/prop_plush_bear.glb"),
	"clown": preload("res://assets/models/props/prop_jackbox_head.glb"),
	"monkey": preload("res://assets/models/props/prop_clockwork_monkey.glb"),
	"car": preload("res://assets/models/props/prop_electric_car.glb"),
	"drum": preload("res://assets/models/props/prop_drum.glb"),
	"ruler": preload("res://assets/models/props/prop_seesaw_ruler.glb"),
	"fulcrum": preload("res://assets/models/props/prop_seesaw_fulcrum.glb"),
	"rest": preload("res://assets/models/props/prop_seesaw_rest.glb"),
}

static func _invisible_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 0, 0, 0)
	return mat

static func _hide_visual(shape: CSGShape3D, mat: Material) -> void:
	# Visibility and use_collision are deliberately unchanged, including moving CSG bodies.
	shape.set("material", mat)
	shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shape.set_meta("art_collision_proxy", true)

static func _attach(parent: Node3D, key: String, offset := Vector3.ZERO, yaw := 0.0) -> Node3D:
	var model: Node3D = PROPS[key].instantiate()
	model.name = "Art_" + key
	parent.add_child(model)
	model.position = offset * K
	model.rotation.y = yaw
	model.scale = Vector3.ONE * K
	model.set_meta("art_asset", key)
	return model

static func install(room: Node3D) -> void:
	if room.has_meta("room_art_installed") or "--whitebox" in OS.get_cmdline_user_args():
		return
	var stop: Node3D = room.get_node("Stop1")
	var invisible := _invisible_material()
	for child in stop.get_children():
		if child is CSGShape3D and child.name.begins_with("BigBot"):
			_hide_visual(child, invisible)
	var art := Node3D.new()
	art.name = "ImportedArt"
	stop.add_child(art)
	var bot := _attach(art, "bigbot", Vector3(-1.81, 0, -2.20), -PI / 2)
	for label in ["Eye_L", "Eye_R"]:
		var eye := bot.find_child(label, true, false) as MeshInstance3D
		if eye:
			var lens := StandardMaterial3D.new()
			lens.albedo_color = Color(0.9, 0.37, 0.04)
			lens.roughness = 0.45
			lens.emission_enabled = true
			lens.emission = Color(1, 0.58, 0.14)
			lens.emission_energy_multiplier = 1.8
			eye.material_override = lens

	# Keep the tested landing collider; replace its bulky visual with a soft cushion.
	_hide_visual(stop.get_node("PlushHeap"), invisible)
	_hide_visual(stop.get_node("PlushBunnyHead"), invisible)
	# The larger bear supplies the landing visual; retain the tested invisible landing collider.
	_attach(art, "rabbit", Vector3(-2.74, 0.0, -1.88), 0.0)
	var bear := _attach(art, "bear", Vector3(-2.70, 0.0, -2.50))
	bear.scale *= Vector3(1.65, 1.19343, 1.65)

	var monkey: CSGShape3D = stop.get_node("WindUpMonkey")
	_hide_visual(monkey, invisible)
	_attach(monkey, "drum")
	var clown: CSGShape3D = stop.get_node("JackHead")
	_hide_visual(clown, invisible)
	# Model origin is the spring base. Offset under the lid, then inherit the existing pop tween.
	_attach(clown, "clown", Vector3(0, -0.092, 0), deg_to_rad(-15))

	var car: CSGShape3D = stop.get_node("ElectricCar")
	_hide_visual(car, invisible)
	_attach(car, "car", Vector3(0, -0.015, 0), PI)
	var drum: CSGShape3D = stop.get_node("Drum")
	_hide_visual(drum, invisible)
	_hide_visual(drum.get_node("DrumSkin"), invisible)
	var head_monkey := _attach(drum, "monkey", Vector3(0, -.081, 0), -PI / 2)
	head_monkey.scale *= 1.8
	var saw: Node3D = stop.get_node("Seesaw")
	_hide_visual(saw.get_node("Plank"), invisible)
	_attach(saw, "ruler")
	for entry in [["SeesawFulcrum", "fulcrum", -0.03], ["SeesawRest", "rest", -0.015]]:
		var proxy: CSGShape3D = stop.get_node(entry[0])
		_hide_visual(proxy, invisible)
		_attach(proxy, entry[1], Vector3(0, entry[2], 0))
	STRUCTURE_ART.install(room)
	load("res://scripts/tv_livingroom_art.gd").install(room)
	load("res://scripts/kitchen_art.gd").install(room)
	load("res://scripts/bedroom_layout_art.gd").install(room)
	load("res://scripts/livingroom_finale_art.gd").install(room)
	room.set_meta("room_art_installed", true)
	if not "--bedroom-look-before" in OS.get_cmdline_user_args():
		var look := Node.new()
		look.name = "BedroomLook"
		look.set_script(load("res://scripts/bedroom_look.gd"))
		room.add_child(look)


	var whole_look := Node.new()
	whole_look.name = "WholeGameLook"
	whole_look.set_script(load("res://scripts/whole_game_look.gd"))
	room.add_child(whole_look)
