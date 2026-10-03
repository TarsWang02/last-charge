class_name ToyTrain
extends AnimatableBody3D
## A toy train carriage running round a circular track: a moving platform the robot can ride
## (AnimatableBody3D carries a CharacterBody3D standing on it).

@export var center := Vector3.ZERO   ## track centre (world units)
@export var radius := 1.0
@export var speed := 0.35            ## radians per second
@export var size := Vector3(0.9, 0.54, 0.45)
@export var color := Color(0.6, 0.15, 0.12)
@export var phase := 0.0

var _a := 0.0

func _ready() -> void:
	# Moved by setting its transform each physics frame (not move_and_collide: that sweep would bump into
	# the robot riding on top and make the train stutter). The physics server derives the carriage's
	# velocity from the transform change, so a robot standing on it is still carried along.
	sync_to_physics = false
	_a = phase
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position.y = size.y / 2.0
	add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mi.material_override = mat
	mi.position.y = size.y / 2.0
	add_child(mi)
	global_position = _target()
	rotation.y = -_a - PI / 2.0

func _physics_process(delta: float) -> void:
	_a = fmod(_a + speed * delta, TAU)
	global_transform = Transform3D(Basis(Vector3.UP, -_a - PI / 2.0), _target())  # faces along the track

func _target() -> Vector3:
	return center + Vector3(cos(_a), 0, sin(_a)) * radius
