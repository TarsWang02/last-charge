extends PathFollow3D
## "The moving thing". Follows its Path3D, alternates walk / idle.
## To swap the placeholder: set `model_scene` to a .glb in the inspector, or just
## put a file at res://assets/models/creature.glb (auto-loaded if present).

@export var model_scene: PackedScene
@export var auto_model_path := "res://assets/models/creature.glb"
@export var target_height := 1.8 ## auto-scale model to this height (m); 0 = keep original
@export var model_yaw_offset_deg := 0.0 ## fix models that face the wrong way
@export var speed := 1.2 ## m/s along path; tune against the walk anim to avoid foot sliding
@export var anim_idle := "idle"
@export var anim_move := "walk"
@export var walk_time := 6.0
@export var idle_time := 2.5

@onready var model_root: Node3D = $ModelRoot

var moving := true
var anim_player: AnimationPlayer
var _t := 0.0

func _ready() -> void:
	if model_scene == null and ResourceLoader.exists(auto_model_path):
		model_scene = load(auto_model_path)
	if model_scene:
		set_model(model_scene)

func set_model(scene: PackedScene) -> void:
	for c in model_root.get_children():
		c.free()
	var inst: Node3D = scene.instantiate()
	model_root.add_child(inst)
	ModelUtil.fit(inst, target_height)
	inst.rotation_degrees.y += model_yaw_offset_deg
	var players := inst.find_children("*", "AnimationPlayer", true, false)
	anim_player = players[0] if players.size() > 0 else null
	if anim_player:
		print("[stalker] animations: ", anim_player.get_animation_list())
		for n in [anim_idle, anim_move]:
			if anim_player.has_animation(n):
				anim_player.get_animation(n).loop_mode = Animation.LOOP_LINEAR
			else:
				push_warning("[stalker] missing animation '%s'" % n)
	_apply_anim()

func set_moving(v: bool) -> void:
	moving = v
	_t = 0.0
	_apply_anim()

func current_anim() -> String:
	return String(anim_player.current_animation) if anim_player else ""

func _apply_anim() -> void:
	if anim_player == null:
		return
	var n := anim_move if moving else anim_idle
	if anim_player.has_animation(n):
		anim_player.play(n, 0.25)

func _process(delta: float) -> void:
	_t += delta
	if _t > (walk_time if moving else idle_time):
		set_moving(not moving)
	if moving:
		progress += speed * delta
