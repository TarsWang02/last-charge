class_name Interactable
extends Area3D
## Anything the robot powers with E. Shows a small key prompt when in range.
## hold_time = 0 -> tap; > 0 -> hold E, battery drains while holding (e.g. the breaker finale).
## Connect `activated` to drive the object's behaviour.

signal activated
signal hold_progress(fraction: float)

@export var cost := 0.05            ## battery used (spread over the hold for hold interactions)
@export var hold_time := 0.0
@export var once := true
@export var radius := 1.5
@export var prompt_offset := Vector3(0, 1.2, 0)
@export var prompt_text := "E"

var done := false
var _held := 0.0
var _prompt: Label3D

func _ready() -> void:
	if not get_children().any(func(c): return c is CollisionShape3D):
		var cs := CollisionShape3D.new()
		var sh := SphereShape3D.new()
		sh.radius = radius
		cs.shape = sh
		add_child(cs)
	_prompt = Label3D.new()
	_prompt.text = prompt_text
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.fixed_size = true
	_prompt.pixel_size = 0.0012
	_prompt.font_size = 36
	_prompt.outline_size = 10
	_prompt.modulate = Color(1, 0.88, 0.6)
	_prompt.position = prompt_offset
	_prompt.visible = false
	add_child(_prompt)

func player_in_range() -> bool:
	return Game.player != null and overlaps_body(Game.player) and Game.player.alive

func _process(delta: float) -> void:
	var can := player_in_range() and not (once and done)
	_prompt.visible = can
	if not can:
		_held = 0.0
		return
	if hold_time <= 0.0:
		if Input.is_action_just_pressed("interact"):
			Game.player.add_charge(-cost)
			_activate()
	elif Input.is_action_pressed("interact"):
		_held += delta
		Game.player.add_charge(-cost * delta / hold_time)
		hold_progress.emit(clampf(_held / hold_time, 0.0, 1.0))
		_prompt.text = "%s  %d%%" % [prompt_text, int(clampf(_held / hold_time, 0.0, 1.0) * 100)]
		if _held >= hold_time:
			_activate()
	else:
		_prompt.text = prompt_text

func _activate() -> void:
	done = true
	_held = 0.0
	_prompt.text = prompt_text
	activated.emit()
