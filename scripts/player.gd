extends CharacterBody3D
## First-person controller + flashlight with battery.

signal battery_changed(value: float, on: bool)

@export var speed := 3.0
@export var sprint_speed := 5.5
@export var mouse_sensitivity := 0.0025
@export var battery_drain_per_sec := 1.5 ## percent per second while on
@export var flicker_below := 20.0

@onready var head: Node3D = $Head
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

var battery := 100.0
var light_on := true
var _base_energy := 1.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	_base_energy = flashlight.light_energy
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -1.4, 1.4)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		elif event.physical_keycode == KEY_F:
			toggle_light()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_light() -> void:
	light_on = (not light_on) and battery > 0.0
	flashlight.visible = light_on
	battery_changed.emit(battery, light_on)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var input := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input.x = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		input.y = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var s := sprint_speed if Input.is_physical_key_pressed(KEY_SHIFT) else speed
	velocity.x = dir.x * s
	velocity.z = dir.z * s
	move_and_slide()
	_update_battery(delta)

func _update_battery(delta: float) -> void:
	if not light_on:
		return
	battery = max(0.0, battery - battery_drain_per_sec * delta)
	if battery <= 0.0:
		light_on = false
		flashlight.visible = false
	elif battery < flicker_below:
		flashlight.light_energy = _base_energy * (0.4 if randf() < 0.08 else 1.0)
	battery_changed.emit(battery, light_on)
