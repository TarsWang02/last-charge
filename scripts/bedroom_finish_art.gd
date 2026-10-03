extends RefCounted
## Visuals in real metres follow the existing gameplay nodes and visibility rules.
const K := 9.0
const PROPS := {
    "mattress": preload("res://assets/models/props/prop_mattress.glb"),
    "toy_truck": preload("res://assets/models/props/prop_toy_truck.glb"),
    "wall_lamp": preload("res://assets/models/props/prop_wall_lamp.glb"),
    "window_south": preload("res://assets/models/props/prop_window_south.glb"),
    "bedroom_door": preload("res://assets/models/props/prop_bedroom_door.glb"),
    "door_lever": preload("res://assets/models/props/prop_door_lever.glb"),
    "car_head_tracks": preload("res://assets/models/props/prop_car_head_tracks.glb"),
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
    model.set_meta("art_asset", key)
    return model
static func install(room: Node3D) -> void:
    if room.has_meta("bedroom_finish_art_installed"): return
    var invisible := StandardMaterial3D.new()
    invisible.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    invisible.albedo_color = Color(0,0,0,0)
    var mattress: CSGShape3D = room.get_node("Bedroom/Mattress")
    _hide(mattress, invisible)
    _add(mattress, "mattress", Vector3(0,-.10,0))
    var stop1 := room.get_node("Stop1")
    var truck: CSGShape3D = stop1.get_node("ToyTruck")
    _hide(truck, invisible)
    _hide(stop1.get_node("TruckCab"), invisible)
    _add(truck, "toy_truck", Vector3(0,-.07,0))
    for key in ["CarTrack1","CarTrack2","CarTrack3"]: _hide(stop1.get_node(key), invisible)
    _add(stop1, "car_head_tracks", Vector3(-1.81,.58,-2.20))
    var stop2 := room.get_node("Stop2")
    var shade: CSGShape3D = stop2.get_node("WallLampShade")
    _hide(shade, invisible)
    _hide(stop2.get_node("WallLampArm"), invisible)
    # The full lamp inherits the shade's visibility during the overhead desk sequence.
    var lamp := _add(shade, "wall_lamp")
    var bulb := lamp.find_child("LampBulb", true, false) as MeshInstance3D
    var glow := StandardMaterial3D.new()
    glow.albedo_color = Color(.88,.76,.51)
    glow.emission_enabled = true
    glow.emission = Color(1,.70,.35)
    glow.emission_energy_multiplier = 1.5
    glow.roughness = .65
    bulb.material_override = glow
    _add(room.get_node("Shell/WindowBedroomS"), "window_south", Vector3(0,-.45,-.036), PI)
    var pivot := stop2.get_node("DoorPivot")
    _hide(pivot.get_node("Door"), invisible)
    _hide(pivot.get_node("Handle/Lever"), invisible)
    _add(pivot, "bedroom_door")
    _add(pivot.get_node("Handle"), "door_lever", Vector3(0,0,-.07))
    room.set_meta("bedroom_finish_art_installed", true)
