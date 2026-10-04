extends Node
## The game's sound (docs/audio/音频说明.md): one music track at a time (cross-faded), the window ambience,
## one-shot effects, named loops, and the robot's own sounds (tracks, jumps, landings), read off the
## player every frame so nothing in the player has to call in. Owned by room.gd ($Audio).

const A := "res://assets/audio/"
var player: CharacterBody3D
var _music: Array[AudioStreamPlayer] = []
var _cur := 0
var _amb: Array[AudioStreamPlayer] = []
var _amb_cur := 0
var _loops := {}
var _tracks: AudioStreamPlayer
var _moving := false
var _was_floor := true
var _fall_v := 0.0
var _creak_t := 25.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		add_child(m)
		_music.append(m)
		var a := AudioStreamPlayer.new()
		a.bus = "SFX"
		add_child(a)
		_amb.append(a)
	_tracks = AudioStreamPlayer.new()
	_tracks.bus = "SFX"
	_tracks.stream = load(A + "音效/机器人_履带行进_小号_循环.ogg")
	_tracks.volume_db = -14.0
	add_child(_tracks)

func _s(path: String) -> AudioStream:
	return load(A + path) if ResourceLoader.exists(A + path) else null

## A one-shot. `vary` randomises the pitch a little (repeated sounds don't machine-gun).
func sfx(path: String, db := 0.0, vary := 0.0) -> void:
	var s := _s(path)
	if s == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = s
	p.volume_db = db
	p.pitch_scale = 1.0 + randf_range(-vary, vary)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

## Start / stop a named loop.
func loop(path: String, on: bool, db := 0.0) -> void:
	if on and not _loops.has(path):
		var s := _s(path)
		if s == null:
			return
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.stream = s
		p.volume_db = db
		add_child(p)
		p.play()
		_loops[path] = p
	elif not on and _loops.has(path):
		var p: AudioStreamPlayer = _loops[path]
		_loops.erase(path)
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -40.0, 0.4)
		tw.tween_callback(p.queue_free)

## Cross-fade to a music track ("" = fade out).
func music(path: String, fade := 2.5, db := -8.0) -> void:
	var old := _music[_cur]
	if path != "" and old.playing and old.stream == _s(path):
		return
	create_tween().tween_property(old, "volume_db", -60.0, fade)
	get_tree().create_timer(fade).timeout.connect(func(): if old != _music[_cur]: old.stop())
	if path == "":
		return
	_cur = 1 - _cur
	var m := _music[_cur]
	m.stream = _s(path)
	m.volume_db = -60.0
	m.pitch_scale = 1.0
	m.play()
	create_tween().tween_property(m, "volume_db", db, fade)

## A one-off musical phrase over the exploration loop (a memory): the loop dips while it plays.
func phrase(path: String, db := -6.0) -> void:
	var m := _music[_cur]
	var base := m.volume_db
	create_tween().tween_property(m, "volume_db", base - 14.0, 1.0)
	var s := _s(path)
	if s == null:
		return
	sfx(path, db)
	get_tree().create_timer(s.get_length()).timeout.connect(func(): create_tween().tween_property(m, "volume_db", base, 3.0))

## Cross-fade the window ambience (the night outside, by stage of life).
func ambience(path: String, db := -14.0) -> void:
	var old := _amb[_amb_cur]
	create_tween().tween_property(old, "volume_db", -60.0, 3.0)
	_amb_cur = 1 - _amb_cur
	var a := _amb[_amb_cur]
	a.stream = _s(path)
	a.volume_db = -60.0
	a.play()
	create_tween().tween_property(a, "volume_db", db, 3.0)

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player) or get_tree().paused:
		_tracks.stream_paused = true
		return
	_tracks.stream_paused = false
	# the tracks: start / run / stop
	var hv := Vector2(player.velocity.x, player.velocity.z).length()
	var on_floor: bool = player.is_on_floor()
	var moving: bool = hv > 0.6 and on_floor and not player.locked and player.alive
	if moving and not _moving:
		sfx("音效/机器人_履带启动_小号.ogg", -14.0)
		_tracks.play()
	elif not moving and _moving:
		_tracks.stop()
		sfx("音效/机器人_履带停下_小号.ogg", -14.0)
	_moving = moving
	if _moving:
		_tracks.pitch_scale = lerpf(0.85, 1.1, clampf(hv / 6.0, 0.0, 1.0))
	# jumps and landings
	if _was_floor and not on_floor and player.velocity.y > 2.0 and not player.locked:
		sfx("音效/机器人_弹簧起跳_0%d.ogg" % randi_range(1, 2), -10.0, 0.05)
	if not on_floor:
		_fall_v = minf(_fall_v, player.velocity.y)
	elif not _was_floor:
		if _fall_v < -4.0:
			sfx("音效/机器人_落地_0%d.ogg" % randi_range(1, 3), lerpf(-16.0, -6.0, clampf(-_fall_v / 20.0, 0.0, 1.0)), 0.06)
		_fall_v = 0.0
	_was_floor = on_floor
	# the old house creaks now and then
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = randf_range(25.0, 60.0)
		sfx("环境声/全程_老房子吱呀_0%d.ogg" % randi_range(1, 3), -20.0, 0.05)
	# low charge: the music slows and quietens (below half, slowest at 15 %)
	var k := clampf((0.5 - float(player.charge)) / 0.35, 0.0, 1.0)
	_music[_cur].pitch_scale = lerpf(1.0, 0.88, k)
