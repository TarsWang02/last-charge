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
var _sub: Label             ## the old man's inner voice (on _sub_plate)
var _sub_plate: PanelContainer
var _controls_plate: PanelContainer
var _sub_token := 0
var _vo: AudioStreamPlayer

## "2-11" -> res://assets/audio/vo/vo_s2_11.ogg ("1-2b" -> vo_s1_02b.ogg)
static func vo_path(id: String) -> String:
	var p := id.split("-")
	if p.size() != 2:
		return ""
	var b := "b" if p[1].ends_with("b") else ""
	return "res://assets/audio/vo/vo_s%s_%02d%s.ogg" % [p[0], int(p[1].trim_suffix("b")), b]
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

	# the controls card: a small dark pill at the bottom (UiKit look)
	_controls_plate = _plate(UiKit.card(0.6, 12), -28)
	_controls = _label(17, Color(UiKit.CREAM, 0.85))
	_controls.autowrap_mode = TextServer.AUTOWRAP_OFF
	_controls.add_theme_constant_override("outline_size", 0)
	_controls_plate.add_child(_controls)

	# the old man's inner voice: Nunito on a soft rounded plate, bottom centre (It Takes Two-style subtitles)
	_sub_plate = _plate(UiKit.card(0.55, 0), -110)
	var sb: StyleBoxFlat = _sub_plate.get_theme_stylebox("panel")
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	sb.shadow_size = 12
	_sub = _label(28, UiKit.CREAM)
	_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	_sub.add_theme_font_override("font", UiKit.body(700))
	_sub.add_theme_constant_override("outline_size", 0)
	_sub_plate.add_child(_sub)

	_vo = AudioStreamPlayer.new()
	_vo.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(_vo)
	for c in get_children():   # a CanvasLayer stops the window's theme: hand it to each top Control
		if c is Control:
			c.theme = UiKit.theme()
	Game.memory_restored.connect(show_memory)


## A rounded plate anchored bottom-centre that grows to fit its text; `y` = its bottom edge from the
## screen bottom. Starts hidden (faded out).
func _plate(style: StyleBoxFlat, y: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_bottom = y
	p.offset_top = y
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.modulate.a = 0.0
	add_child(p)
	return p


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
	return   # the memories are voiced now (the monologue subtitles); no second, written card
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


## A line of the old man's inner monologue (StoryText.MONOLOGUE id or plain text). A newer line replaces
## an older one. Await it to know when it has faded out.
func say(id_or_text: String, seconds := -1.0) -> void:
	var text: String = StoryText.MONOLOGUE.get(id_or_text, id_or_text)
	if seconds < 0.0:
		seconds = line_time(id_or_text)
	voice(id_or_text)
	_sub_token += 1
	var token := _sub_token
	_sub.text = text
	await _fade(_sub_plate, 1.0, 0.35)
	await _hold(seconds)
	if token == _sub_token:
		await _fade(_sub_plate, 0.0, 0.6)


## How long a line stays up: a calm reading pace (~2.6 words a second) plus a beat, a little longer for
## every pause written into it ("...", a dash, a full stop mid-line). Cutscenes await say() to follow it.
static func read_time(text: String) -> float:
	var words := text.split(" ", false).size()
	var pauses := text.count("...") + text.count("—") + text.count(". ") + text.count("? ") + text.count("! ")
	return maxf(1.8, 0.9 + words / 2.6 + pauses * 0.35)


## Seconds a line stays up: its voice-over's length (+ a beat), never shorter than its reading time.
static func line_time(id: String) -> float:
	var text: String = StoryText.MONOLOGUE.get(id, id)
	var t := read_time(text)
	var vo := vo_path(id)
	if vo != "" and ResourceLoader.exists(vo):
		t = (load(vo) as AudioStream).get_length() + 0.3   # on screen exactly as long as it's spoken
	return t


## Just the voice of a line (for lines shown another way, e.g. a memory card).
func voice(id: String) -> void:
	var vo := vo_path(id)
	if vo != "" and ResourceLoader.exists(vo):
		_vo.stream = load(vo)
		_vo.play()


## Several lines one after another (each waits for the last to fade).
func say_all(ids: Array) -> void:
	for id in ids:
		await say(id)


## The controls card, once, when the player first gets control.
func show_controls() -> void:
	_controls.text = StoryText.CONTROLS
	await _fade(_controls_plate, 1.0, 0.8)
	await _hold(8.0)
	await _fade(_controls_plate, 0.0, 1.5)


## Opening of a new game: the two lines, then the controls card for a while.
func play_opening() -> void:
	await play_lines(StoryText.OPENING)
	_controls.text = StoryText.CONTROLS
	await _fade(_controls_plate, 1.0, 0.8)
	await _hold(8.0)
	await _fade(_controls_plate, 0.0, 1.5)


func _fade(c: CanvasItem, to: float, t: float) -> void:
	await create_tween().set_ignore_time_scale(true).tween_property(c, "modulate:a", to, t).finished


func _hold(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout
