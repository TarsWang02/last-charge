extends RefCounted
const K := 9.0
const PROPS := {
    "soft_pillow": preload("res://assets/models/props/prop_soft_pillow.glb"),
    "soft_quilt": preload("res://assets/models/props/prop_soft_quilt.glb"),
    "sleeping_grandfather": preload("res://assets/models/props/prop_sleeping_grandfather.glb"),
    "seated_teen": preload("res://assets/models/props/prop_seated_teen.glb"),
    "porcelain_doll_head": preload("res://assets/models/props/prop_porcelain_doll_head.glb"),
    "soft_landing_cushion": preload("res://assets/models/props/prop_soft_landing_cushion.glb"),
}
const FIGURE_SCRIPT := preload("res://scripts/background_figure.gd")
static func _hide(node: CSGShape3D, invisible: Material) -> void:
    node.material = invisible
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
static func _add(parent: Node3D, key: String, offset := Vector3.ZERO, yaw := 0.0, factor := 1.0) -> Node3D:
    var model: Node3D = PROPS[key].instantiate()
    model.name = "Art_" + key
    parent.add_child(model)
    model.position = offset * K
    model.scale = Vector3.ONE * K * factor
    model.rotation.y = yaw
    model.set_meta("art_asset", key)
    return model
static func install(room: Node3D) -> void:
    if room.has_meta("bedroom_soft_art_installed"): return
    var invisible := StandardMaterial3D.new()
    invisible.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    invisible.albedo_color = Color(0,0,0,0)
    var bedroom := room.get_node("Bedroom")
    _hide(bedroom.get_node("Pillow"), invisible)
    _hide(bedroom.get_node("Blanket"), invisible)
    _add(bedroom,"soft_pillow",Vector3(-4.05,.55,-2.375))
    _add(bedroom,"soft_quilt",Vector3(-4.05,.55,-1.45))
    var people := room.get_node("People")
    for key in ["OldManInBed","OldManHead","BoyAtDesk","BoyHead"]:
        _hide(people.get_node(key), invisible)
    _add(people,"sleeping_grandfather",Vector3(-4.05,.74,-1.667))
    var boy := _add(people,"seated_teen",Vector3(-1.38,0,.50),PI/2)
    boy.set_script(FIGURE_SCRIPT)
    boy.set_process(true)
    var stop1 := room.get_node("Stop1")
    for entry in [["DollHeadA",.04,1.0,-.15],["DollHeadB",.03,.75,1.20]]:
        var proxy: CSGShape3D = stop1.get_node(entry[0])
        _hide(proxy,invisible)
        _add(proxy,"porcelain_doll_head",Vector3(0,-entry[1],0),entry[3],entry[2])
    stop1.get_node("ImportedArt/LandingCushion").visible = false
    _add(stop1.get_node("ImportedArt"),"soft_landing_cushion",Vector3(-2.70,.09,-2.50))
    room.set_meta("bedroom_soft_art_installed",true)
