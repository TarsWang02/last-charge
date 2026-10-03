class_name RevealLight
extends Interactable
## An old light (flashlight, night light, lamp). Hold the robot still and press E to spend some charge:
## it lights an area - its own surroundings, or a spot elsewhere (target_offset) - and the camera widens
## to show it. The moment the robot moves, it goes out.

@export var light_range := 4.5   ## units
@export var light_energy := 3.0
@export var light_color := Color(1.0, 0.78, 0.5)
@export var light_height := 1.6  ## units above the lit spot
@export var target_offset := Vector3.ZERO  ## world offset from this node to the centre of the lit area
var kind := "local"

var lit := false
var _light: OmniLight3D

func _ready() -> void:
	once = false
	super._ready()
	_light = OmniLight3D.new()
	_light.light_color = light_color
	_light.light_energy = 0.0
	_light.omni_range = light_range
	_light.omni_attenuation = 0.4
	_light.shadow_enabled = true
	_light.position = target_offset + Vector3(0, light_height, 0)
	add_child(_light)
	activated.connect(_on_activated)

func lit_center() -> Vector3:
	return global_position + target_offset

func _on_activated() -> void:
	lit = true
	create_tween().tween_property(_light, "light_energy", light_energy, 0.25).set_trans(Tween.TRANS_EXPO)
	if Game.player and Game.player.has_method("set_view_focus"):
		Game.player.set_view_focus(lit_center(), light_range)

func _process(delta: float) -> void:
	if not lit:
		super._process(delta)
		return
	_prompt.visible = false  # already on: no paying twice
	if Game.player == null:
		return
	var p: CharacterBody3D = Game.player
	var moving := Input.get_vector("move_left", "move_right", "move_fwd", "move_back").length() > 0.2 \
		or Vector2(p.velocity.x, p.velocity.z).length() > 0.3
	if moving:
		lit = false
		create_tween().tween_property(_light, "light_energy", 0.0, 0.35)
		if p.has_method("clear_view_focus"):
			p.clear_view_focus()
