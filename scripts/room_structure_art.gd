extends RefCounted
const K := 9.0
const PROPS := {
    "nightstand": preload("res://assets/models/props/prop_nightstand.glb"),
    "old_books": preload("res://assets/models/props/prop_old_books.glb"),
    "loose_book": preload("res://assets/models/props/prop_loose_book.glb"),
    "photo_frame": preload("res://assets/models/props/prop_photo_frame.glb"),
    "coin": preload("res://assets/models/props/prop_coin.glb"),
    "window_north": preload("res://assets/models/props/prop_window_north.glb"),
    "bed_frame": preload("res://assets/models/props/prop_bed_frame.glb"),
    "desk_frame": preload("res://assets/models/props/prop_desk_frame.glb"),
    "block_stack": preload("res://assets/models/props/prop_block_stack.glb"),
    "train_track": preload("res://assets/models/props/prop_train_track.glb"),
    "train_carriage": preload("res://assets/models/props/prop_train_carriage.glb"),
    "jackbox_body": preload("res://assets/models/props/prop_jackbox_body.glb"),
    "jackbox_lid": preload("res://assets/models/props/prop_jackbox_lid.glb"),
    "jackbox_crank": preload("res://assets/models/props/prop_jackbox_crank.glb"),
    "clown_spring": preload("res://assets/models/props/prop_clown_spring.glb"),
    "letter_block_a": preload("res://assets/models/props/prop_letter_block_a.glb"),
    "letter_block_b": preload("res://assets/models/props/prop_letter_block_b.glb"),
    "battery": preload("res://assets/models/props/prop_battery.glb"),
}
const LID_SCRIPT := preload("res://scripts/jack_lid_art.gd")
const FLOOR_TEX := preload("res://assets/textures/tex_floor_boards.png")
const WALL_TEX := preload("res://assets/textures/tex_wall_boards.png")

static func _invisible() -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = Color(0, 0, 0, 0)
    return m

static func _hide(node: CSGShape3D, mat: Material) -> void:
    node.material = mat
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _add(parent: Node3D, key: String, offset := Vector3.ZERO) -> Node3D:
    var model: Node3D = PROPS[key].instantiate()
    model.name = "Art_" + key
    parent.add_child(model)
    model.position = offset * K
    model.scale = Vector3.ONE * K
    model.set_meta("art_asset", key)
    return model

static func _surface(texture: Texture2D, period_m: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_texture = texture
    m.roughness = 0.91
    m.uv1_triplanar = true
    m.uv1_world_triplanar = true
    m.uv1_scale = Vector3.ONE / (period_m * K)
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    return m

static func install(room: Node3D) -> void:
    if room.has_meta("structure_art_installed"):
        return
    var invisible := _invisible()
    var stop0 := room.get_node("Stop0")
    var stand: CSGShape3D = stop0.get_node("Nightstand")
    _hide(stand, invisible)
    _hide(stop0.get_node("NightstandDrawer"), invisible)
    _add(stand, "nightstand", Vector3(0, -0.36, 0))
    var books: CSGShape3D = stop0.get_node("OldBooks")
    _hide(books, invisible)
    _add(books, "old_books", Vector3(0, -0.07, 0))
    var loose: CSGShape3D = stop0.get_node("LooseBook/Book")
    _hide(loose, invisible)
    _hide(loose.get_node("Pages"), invisible)
    _add(loose, "loose_book")
    var frame := stop0.get_node("PhotoFrame")
    _hide(frame.get_node("Frame"), invisible)
    _hide(frame.get_node("Frame/Photo"), invisible)
    _add(frame, "photo_frame")
    for key in ["CoinA", "CoinB"]:
        var coin: CSGShape3D = stop0.get_node(key)
        _hide(coin, invisible)
        _add(coin, "coin", Vector3(0, -0.0015, 0))
    var shell := room.get_node("Shell")
    shell.get_node("Floor").material = _surface(FLOOR_TEX, 0.8)
    for key in ["WallN", "WallS", "WallW", "WallE", "BedroomWallN", "BedroomWallS", "DoorLintel"]:
        shell.get_node(key).material = _surface(WALL_TEX, 0.8)
    # Retain the old blue emissive panel as the night sky behind the wood frame.
    _add(shell.get_node("WindowBedroomN"), "window_north", Vector3(0, -0.5, 0.036))
    var bed := room.get_node("Bedroom")
    _hide(bed.get_node("BedFrame"), invisible)
    _hide(bed.get_node("Headboard"), invisible)
    var bedroom_art := Node3D.new()
    bedroom_art.name = "ImportedStructureArt"
    bed.add_child(bedroom_art)
    _add(bedroom_art, "bed_frame", Vector3(-4.05, 0, -1.65))
    var desk := room.get_node("Stop2")
    for key in ["DeskLegNW", "DeskLegSW", "DeskLegSE", "DeskApron", "DeskDrawerUnit"]:
        _hide(desk.get_node(key), invisible)
    var desk_art := Node3D.new()
    desk_art.name = "ImportedStructureArt"
    desk.add_child(desk_art)
    _add(desk_art, "desk_frame", Vector3(-0.81, 0, 0.15))
    # The generated maze floor stays perforated; update only its shared surface material.
    var maze := desk.get_node("DeskMaze")
    var maze_mat: StandardMaterial3D = maze.get("_floor_mat")
    if maze_mat:
        maze_mat.albedo_color = Color.WHITE
        maze_mat.albedo_texture = FLOOR_TEX
        maze_mat.roughness = 0.9
        maze_mat.uv1_triplanar = true
        maze_mat.uv1_world_triplanar = true
        maze_mat.uv1_scale = Vector3.ONE / (0.8 * K)
    var stop1 := room.get_node("Stop1")
    var blocks: CSGShape3D = stop1.get_node("BlockStack")
    _hide(blocks, invisible)
    _add(blocks, "block_stack", Vector3(0, -0.10, 0))
    var ring: CSGShape3D = stop1.get_node("TrackRing")
    _hide(ring, invisible)
    _add(ring, "train_track")
    var train: Node3D = stop1.get_node("Train")
    for child in train.get_children():
        if child is MeshInstance3D:
            child.visible = false
    _add(train, "train_carriage")
    var jack: CSGShape3D = stop1.get_node("JackBox")
    _hide(jack, invisible)
    _add(jack, "jackbox_body", Vector3(0, -0.05, 0))
    var lid := _add(jack, "jackbox_lid", Vector3(0, 0.04, -0.05))
    lid.set_script(LID_SCRIPT)
    lid.set_process(true)
    _add(jack, "jackbox_crank", Vector3(0.052, 0.005, 0))
    _add(stop1.get_node("JackHead"), "clown_spring", Vector3(0, -0.092, 0))
    for entry in [["PushBlockLarge", "letter_block_a"], ["PushBlockSmall", "letter_block_b"]]:
        var block: Node3D = stop1.get_node(entry[0])
        for child in block.get_children():
            if child is MeshInstance3D:
                child.visible = false
            elif child is Label3D and child.text == block.letter:
                child.visible = false
        _add(block, entry[1])
    for key in ["Battery1", "Battery2"]:
        var pickup := stop1.get_node(key)
        var mesh: MeshInstance3D = pickup.get("_mesh")
        mesh.material_override = invisible
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        var battery := _add(mesh, "battery")
        # Engine owns the interactive glow; it is not baked into the texture.
        var stripe := battery.find_child("EnergyIndicator", true, false) as MeshInstance3D
        if not stripe:
            stripe = MeshInstance3D.new()
            stripe.name = "EngineEnergyStripe"
            var stripe_mesh := BoxMesh.new()
            stripe_mesh.size = Vector3(0.003, 0.010, 0.0003)
            stripe.mesh = stripe_mesh
            battery.add_child(stripe)
            stripe.position = Vector3(0, 0, 0.0062)
        if stripe:
            var glow := StandardMaterial3D.new()
            glow.albedo_color = Color(0.2, 1, 0.9)
            glow.emission_enabled = true
            glow.emission = Color(0.2, 1, 0.9)
            glow.emission_energy_multiplier = 1.4
            stripe.material_override = glow
    load("res://scripts/tripo_structure_art.gd").install(room)
    load("res://scripts/bedroom_finish_art.gd").install(room)
    load("res://scripts/bedroom_soft_art.gd").install(room)
    room.set_meta("structure_art_installed", true)
