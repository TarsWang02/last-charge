extends RefCounted
## The seven returned Tripo props, fitted in metres to existing gameplay proxies.
const K := 9.0
const PROPS := {
 "chair": preload("res://assets/models/props/prop_chair.glb"),
 "reading_glasses": preload("res://assets/models/props/prop_reading_glasses.glb"),
 "water_glass": preload("res://assets/models/props/prop_water_glass.glb"),
 "pill_bottle_a": preload("res://assets/models/props/prop_pill_bottle_a.glb"),
 "pill_bottle_b": preload("res://assets/models/props/prop_pill_bottle_b.glb"),
 "moving_box": preload("res://assets/models/props/prop_moving_box.glb"),
 "shoebox": preload("res://assets/models/props/prop_shoebox.glb"),
}
static func _hide(node: CSGShape3D, invisible: Material) -> void:
 node.material = invisible
 node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
static func _add(parent: Node3D, key: String, offset := Vector3.ZERO, yaw := 0.0) -> Node3D:
 var model: Node3D = PROPS[key].instantiate()
 model.name = "Art_" + key
 parent.add_child(model)
 model.position = offset * K
 model.scale = Vector3.ONE * K
 model.rotation.y = yaw
 model.set_meta("art_asset",key)
 return model
static func _glass_material(alpha: float) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 m.albedo_color = Color(0.85,0.84,0.75,alpha)
 m.roughness = 0.18
 m.metallic = 0.0
 m.cull_mode = BaseMaterial3D.CULL_DISABLED
 return m
static func _transparent(node: Node, all_glass: bool) -> void:
 if node is MeshInstance3D:
  for surface in node.mesh.get_surface_count():
   var mat: Material = node.get_active_material(surface)
   if all_glass or (mat != null and "ReadingLens" in mat.resource_name):
    node.set_surface_override_material(surface,_glass_material(0.22 if all_glass else 0.13))
  if all_glass:
   node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 for child in node.get_children(): _transparent(child,all_glass)
static func install(room: Node3D) -> void:
 if room.has_meta("tripo_structure_art_installed"): return
 var invisible := StandardMaterial3D.new()
 invisible.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 invisible.albedo_color = Color(0,0,0,0)
 var stop0 := room.get_node("Stop0")
 for entry in [["PillBottleA","pill_bottle_a",-.04],["PillBottleB","pill_bottle_b",-.0325],["ReadingGlasses","reading_glasses",-.009]]:
  var proxy: CSGShape3D = stop0.get_node(entry[0])
  _hide(proxy,invisible)
  var model := _add(proxy,entry[1],Vector3(0,entry[2],0))
  if entry[1] == "reading_glasses": _transparent(model,false)
 var glass_proxy: CSGShape3D = stop0.get_node("WaterGlass")
 _hide(glass_proxy,invisible)
 var glass := _add(glass_proxy,"water_glass",Vector3(0,-.055,0))
 _transparent(glass,true)
 var water := MeshInstance3D.new()
 water.name = "HalfGlassWater"
 var volume := CylinderMesh.new()
 volume.top_radius = .0305
 volume.bottom_radius = .0305
 volume.height = .052
 volume.radial_segments = 32
 water.mesh = volume
 water.position.y = .029
 water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var wm := _glass_material(.40)
 wm.albedo_color = Color(.69,.72,.65,.40)
 wm.roughness = .09
 water.material_override = wm
 glass.add_child(water)
 var stop2 := room.get_node("Stop2")
 var chair: CSGShape3D = stop2.get_node("DeskChair")
 _hide(chair,invisible)
 _hide(stop2.get_node("DeskChairBack"),invisible)
 _add(chair,"chair",Vector3(0,-.445,0),PI/2)
 var stop1 := room.get_node("Stop1")
 var shoebox: CSGShape3D = stop1.get_node("Shoebox")
 _hide(shoebox,invisible)
 _add(shoebox,"shoebox",Vector3(0,-.15,0))
 for key in ["BoxFloor","BoxWallW","BoxWallE","BoxWallN","BoxWallS","FlapN","FlapE","FlapWTorn"]:
  var proxy=stop1.get_node_or_null(key)
  if proxy:_hide(proxy,invisible)
 var box=_add(stop1,"moving_box",Vector3(-2.24,0,-2.20))
 # Remove the tall east lid, which obscured the head-top mechanism.
 var lid=box.find_child("FlapE",true,false)
 if lid:lid.free()
 room.set_meta("tripo_structure_art_installed",true)
