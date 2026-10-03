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
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.30, 0.20, 0.12)
	cloth.roughness = 0.98
	var cushion := MeshInstance3D.new()
	cushion.name = "LandingCushion"
	var cushion_mesh := SphereMesh.new()
	cushion_mesh.radius = 0.085 * K
	cushion_mesh.height = 0.03 * K
	cushion.mesh = cushion_mesh
	cushion.material_override = cloth
	art.add_child(cushion)
	cushion.position = Vector3(-2.70, 0.105, -2.50) * K
	cushion.scale.z = 0.75
	_attach(art, "rabbit", Vector3(-2.775, 0.018, -2.54), deg_to_rad(-25))
	_attach(art, "bear", Vector3(-2.635, 0.025, -2.49), deg_to_rad(35))

	var monkey: CSGShape3D = stop.get_node("WindUpMonkey")
	_hide_visual(monkey, invisible)
	_attach(monkey, "monkey", Vector3(0, -0.045, 0), deg_to_rad(-20))
	var clown: CSGShape3D = stop.get_node("JackHead")
	_hide_visual(clown, invisible)
	# Model origin is the spring base. Offset under the lid, then inherit the existing pop tween.
	_attach(clown, "clown", Vector3(0, -0.092, 0), deg_to_rad(-15))

	var car: CSGShape3D = stop.get_node("ElectricCar")
	_hide_visual(car, invisible)
	_attach(car, "car", Vector3(0, -0.015, 0), PI / 2)
	var drum: CSGShape3D = stop.get_node("Drum")
	_hide_visual(drum, invisible)
	_hide_visual(drum.get_node("DrumSkin"), invisible)
	_attach(drum, "drum")
	var saw: Node3D = stop.get_node("Seesaw")
	_hide_visual(saw.get_node("Plank"), invisible)
	_attach(saw, "ruler")
	for entry in [["SeesawFulcrum", "fulcrum", -0.03], ["SeesawRest", "rest", -0.015]]:
		var proxy: CSGShape3D = stop.get_node(entry[0])
		_hide_visual(proxy, invisible)
		_attach(proxy, entry[1], Vector3(0, entry[2], 0))
	STRUCTURE_ART.install(room)
	room.set_meta("room_art_installed", true)
