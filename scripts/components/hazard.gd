class_name Hazard
extends Area3D
## Water (the robot shorts out) or fire: touching it costs a bit of charge, a flash of sparks, and sends
## the robot back to its last checkpoint. `enabled = false` turns it off (e.g. the flood draining away).

@export var size := Vector3.ONE   ## box (units); this node is its centre
@export var kind := "water"       ## "water" | "fire"
@export var cost := 0.03
@export var enabled := true

var hits := 0

func _ready() -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)

func _physics_process(_d: float) -> void:
	# also catch a robot that is already inside (e.g. landed in it while the hazard was being re-enabled)
	if enabled and Game.player and overlaps_body(Game.player):
		_on_body(Game.player)

func _on_body(b: Node) -> void:
	if not enabled or b != Game.player or Game.player.locked or Game.is_respawning():
		return
	hits += 1
	Game.player.add_charge(-cost)
	Game.player.launch_squash()
	var spark := OmniLight3D.new()
	spark.light_color = Color(0.6, 0.9, 1.0) if kind == "water" else Color(1.0, 0.55, 0.2)
	spark.light_energy = 8.0
	spark.omni_range = 2.5
	get_tree().current_scene.add_child(spark)
	spark.global_position = Game.player.global_position + Vector3(0, 0.6, 0)
	var tw := spark.create_tween()
	tw.tween_property(spark, "light_energy", 0.0, 0.5)
	tw.tween_callback(spark.queue_free)
	Game.respawn(false)
