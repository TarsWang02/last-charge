class_name BatteryPickup
extends Area3D
## Collectable battery (design doc 7.2): limited, placed along the route.

@export var amount := 0.2

var _mesh: MeshInstance3D
var _t := 0.0

func _ready() -> void:
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.45
	cs.shape = sh
	add_child(cs)
	_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.09
	cyl.height = 0.3
	_mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.9)
	mat.emission_energy_multiplier = 2.5
	_mesh.material_override = mat
	add_child(_mesh)
	var l := OmniLight3D.new()
	l.light_color = Color(0.2, 1.0, 0.9)
	l.light_energy = 0.4
	l.omni_range = 1.4
	add_child(l)
	body_entered.connect(func(b):
		if b == Game.player:
			b.add_charge(amount)
			queue_free())

func _process(delta: float) -> void:
	_t += delta
	_mesh.position.y = 0.25 + sin(_t * 2.0) * 0.06
	_mesh.rotation = Vector3(0.35, _t * 1.5, 0)
