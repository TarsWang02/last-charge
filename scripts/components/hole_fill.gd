class_name HoleFill
extends Area3D
## A gap that a pushed block can drop into: once a Pushable's centre is over the gap, it sinks in until
## its top is flush with the surface and stays there as a bridge (it can no longer be pushed).

signal filled(block: Node3D)

@export var size := Vector3(1, 1, 1)     ## gap footprint (units); this node sits at the gap's centre
@export var surface_y := 0.0             ## world height of the surface the gap is cut into (units)

var bridge: Node3D = null

func _ready() -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(size.x, 2.0, size.z)
	cs.shape = sh
	add_child(cs)

func _physics_process(_d: float) -> void:
	if bridge:
		return
	for b in get_overlapping_bodies():
		if not b.is_in_group("pushable"):
			continue
		var off: Vector3 = b.global_position - global_position
		if absf(off.x) <= size.x / 2.0 and absf(off.z) <= size.z / 2.0:
			_capture(b)
			return

func _capture(b: Node3D) -> void:
	bridge = b
	b.remove_from_group("pushable")
	b.grabbed = false
	b.set_physics_process(false)
	if Game.player and Game.player.grabbing == b:
		Game.player._release_grab()
	b.show_prompt(false)
	var bh: float = b.size.y
	var to := Vector3(global_position.x, surface_y - bh, global_position.z)  # centred: no gap on either side
	create_tween().tween_property(b, "global_position", to, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	filled.emit(b)
