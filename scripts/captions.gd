extends CanvasLayer
## Quiet story captions (child of the Game autoload, reach it as Game.captions):
##   - memory cards: title + one or two lines, bottom centre, when Game.memory_restored fires
##   - centred lines over the scene for the opening (play_lines; reusable for any later lines)
## Non-blocking: never pauses the game or takes input. Text lives in scripts/story_text.gd.

var _memory_box: VBoxContainer
var _memory_title: Label
var _memory_body: Label
var _center: Label
var _controls: Label
var _queue: Array = []
var _busy := false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS

	_memory_box = VBoxContainer.new()
	_memory_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_memory_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_memory_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_memory_box.offset_bottom = -70
	_memory_box.custom_minimum_size = Vector2(900, 0)
	_memory_box.offset_left = -450
	_memory_box.offset_right = 450
	_memory_box.alignment = BoxContainer.ALIGNMENT_END
	_memory_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_memory_box.modulate.a = 0.0
	add_child(_memory_box)
	_memory_title = _label(20, Color(1.0, 0.75, 0.35))   # warm amber = memory (see art brief)
	_memory_body = _label(26, Color(1, 0.96, 0.9))
	_memory_box.add_child(_memory_title)
	_memory_box.add_child(_memory_body)

	_center = _label(30, Color(1, 0.96, 0.9))
	_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)  # upper third: clear of the robot
	_center.anchor_top = 0.14
	_center.anchor_bottom = 0.34
	_center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center.modulate.a = 0.0
	add_child(_center)

	_controls = _label(16, Color(1, 1, 1, 0.55))
	_controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_controls.offset_bottom = -24
	_controls.offset_left = -640  # autowrap needs a width, or it wraps every letter
	_controls.offset_right = 640
	_controls.modulate.a = 0.0
	add_child(_controls)

	Game.memory_restored.connect(show_memory)


func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return l


## Memory card for Game.restore_memory(id). Queued if one is already showing.
func show_memory(id: String) -> void:
	if not StoryText.MEMORIES.has(id):
		return
	_queue.append(StoryText.MEMORIES[id])
	if not _busy:
		_drain_queue()


func _drain_queue() -> void:
	_busy = true
	while not _queue.is_empty():
		var m: Dictionary = _queue.pop_front()
		_memory_title.text = m.title
		_memory_body.text = m.body
		await _hold(0.6)  # let the object's own reaction (the frame standing up, the glow) land first
		await _fade(_memory_box, 1.0, 0.8)
		await _hold(4.0 + m.body.length() * 0.03)
		await _fade(_memory_box, 0.0, 1.2)
	_busy = false


## Centred lines one after another: [[text, seconds], ...]. Await it to know when it's done.
func play_lines(lines: Array) -> void:
	for entry in lines:
		await show_line(entry[0], entry[1])


func show_line(text: String, seconds: float) -> void:
	_center.text = text
	await _fade(_center, 1.0, 0.9)
	await _hold(seconds)
	await _fade(_center, 0.0, 0.9)


## Opening of a new game: the two lines, then the controls card for a while.
func play_opening() -> void:
	await play_lines(StoryText.OPENING)
	_controls.text = StoryText.CONTROLS
	await _fade(_controls, 1.0, 0.8)
	await _hold(8.0)
	await _fade(_controls, 0.0, 1.5)


func _fade(c: CanvasItem, to: float, t: float) -> void:
	await create_tween().tween_property(c, "modulate:a", to, t).finished


func _hold(s: float) -> void:
	await get_tree().create_timer(s, true).timeout
