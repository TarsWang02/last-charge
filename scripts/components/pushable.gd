class_name Pushable
extends CharacterBody3D
## A block the robot can grab (hold E) and push / pull to build a path. Falls with gravity,
## can be stood on. The player drives it through push(); the block reports how far it really
## moved so the robot stops when the block is stuck.

@export var size := Vector3(1.0, 1.0, 1.0)
@export var color := Color(0.75, 0.3, 0.2)
@export var letter := ""  ## painted on the sides, like a toy alphabet block

var grabbed := false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _prompt: Node3D

func _ready() -> void:
	add_to_group("pushable")
	if not get_children().any(func(c): return c is CollisionShape3D):
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size - Vector3(0.02, 0.0, 0.02)
		cs.shape = sh
		cs.position.y = size.y / 2.0
		add_child(cs)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.7
		mi.material_override = mat
		mi.position.y = size.y / 2.0
		add_child(mi)
		if letter != "":
			for rot in [0.0, 90.0, 180.0, 270.0]:
				var l := Label3D.new()
				l.text = letter
				l.font_size = 160
				l.pixel_size = 0.004
				l.modulate = Color(1, 0.95, 0.85)
				var dir := Basis(Vector3.UP, deg_to_rad(rot))
				l.position = Vector3(0, size.y / 2.0, 0) + dir * Vector3(0, 0, size.z / 2.0 + 0.01)
				l.rotation.y = deg_to_rad(rot)
				add_child(l)
	_prompt = UiKit.make_prompt("E", "Hold to push")
	_prompt.position = Vector3(0, size.y + 0.4, 0)
	_prompt.visible = false
	add_child(_prompt)

func show_prompt(v: bool) -> void:
	_prompt.visible = v and not grabbed

## Move horizontally with the robot; returns the velocity actually achieved (zero if stuck).
func push(vel: Vector3, delta: float) -> Vector3:
	var before := global_position
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	velocity = Vector3(vel.x, velocity.y, vel.z)
	move_and_slide()
	var moved := (global_position - before) / maxf(delta, 1e-4)
	return Vector3(moved.x, 0, moved.z)

func _physics_process(delta: float) -> void:
	if grabbed:
		return  # moved by push() from the player
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()
