class_name Checkpoint
extends Area3D
## Checkpoint (design doc 7.2): a little battery night-light. Entering it sets the respawn point,
## and the first visit tops the battery up a little.

@export var chapter_id := "prologue"
@export var recharge := 0.15        ## added once, on first visit
@export var respawn_charge := 0.6   ## charge after dying (running flat) and respawning here
@export var fail_below_y := -100.0  ## standing below this height = fell off the route -> respawn
@export var size := Vector3(2.0, 2.0, 2.0)
@export var show_light := true

var _used := false
var _glow: OmniLight3D

func _ready() -> void:
	if get_child_count() == 0 or not get_children().any(func(c): return c is CollisionShape3D):
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		cs.position.y = size.y / 2.0
		add_child(cs)
	if show_light:
		var bulb := MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = 0.12
		m.height = 0.24
		bulb.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0.85, 0.6)
		mat.emission_enabled = true
		mat.emission = Color(1, 0.75, 0.45)
		mat.emission_energy_multiplier = 2.0
		bulb.material_override = mat
		bulb.position = Vector3(0.6, 0.12, 0)
		add_child(bulb)
		_glow = OmniLight3D.new()
		_glow.light_color = Color(1, 0.75, 0.45)
		_glow.light_energy = 0.4
		_glow.omni_range = 2.5
		_glow.position = bulb.position + Vector3(0, 0.3, 0)
		add_child(_glow)
	body_entered.connect(_on_body_entered)

func spawn_position() -> Vector3:
	return global_position + Vector3(0, 0.05, 0)

func _on_body_entered(b: Node) -> void:
	if b != Game.player:
		return
	Game.set_checkpoint(self)
	if not _used:
		_used = true
		b.add_charge(recharge)
		if _glow:
			var tw := create_tween()
			tw.tween_property(_glow, "light_energy", 2.0, 0.15)
			tw.tween_property(_glow, "light_energy", 0.4, 0.8)
