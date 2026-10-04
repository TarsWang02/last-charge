extends Node3D
## The farmhouse (white box), built one stop at a time. Implemented so far:
##   stop 0 - nightstand in a shaft of moonlight: move/jump among the old man's things, climb the old
##            books -> the camera turns to the desk lamp (the goal), stand the photo frame up (E), then
##            walk out on the book hanging over the edge -> it tips, the robot slides into the box.
##   stop 1 - the toy box. Its floor is "the dark" (touch it = back to the checkpoint). Plush heap ->
##            blocks -> truck -> ride the train -> jack-in-the-box springs you onto the shoebox ->
##            push two blocks into stairs -> the big toy robot's shoulder -> its head. Give the electric car on
##            its head some of your charge (hold E), drop onto the seesaw between its legs -> the car knocks the
##            drum off its head onto the other end -> launched onto the desk.
##   stop 2 - the desk: a random dark top-down maze (scripts/desk_maze.gd), no jumping. The robot's own small
##            light is always on; old lights (E, costs charge) show an area - the start one shows the END - until
##            the robot moves. Holes drop you back; push the eraser into the hole on the route; the door's
##            lever handle -> out.
##   stop 3 - the TV (white box, part 1): follow the console cable across the floor, climb the boxes /
##            magazines / speakers onto the TV cabinet, E at the screen -> the camera pushes into the glass and
##            the robot becomes a pixel robot in the game on the TV (scripts/tv_game.gd). Off the right edge
##            of the game -> spat back out onto the kitchen side of the cabinet; the camera finds the stove.
##   stop 4 - the kitchen (white box, part 1): the tap was left running, the floor is flooded (water = short
##            circuit). Reveal: the overflowing sink, then the windowsill (the way home). Climb the groceries
##            and the chair onto the counter; power the microwave (its door shoves the cutting board over the
##            gap); power the toaster, which pops you up onto the spice shelf. The stove fire burns.
##            Part 2: from the spice shelf the robot hangs under the steel hood by its electromagnet (RMB),
##            past the two burners flaring up in turn, onto the utensil rail, round the corner (the corner
##            counter is wet: a pot boiled over) and drops by the kettle.
##            Part 3: power the kettle (E): it boils and its steam leans south over the wet counter - float
##            in it to the dish rack (it only lasts a few seconds). Step down onto the lid in the sink: the
##            whole pile comes down (a cutscene, all clatter), the plug pops, the flood drains away. Tap the
##            daughter's mug by the window (E): one clear note. The windowsill starts there.
##   stop 5 - the clothesline (scripts/zipline.gd), hooked across the living room. Grab the coat hanger by
##            the mug (E) and ride it: over the room, back to the window, along it to the breaker box. A / D
##            swing to dodge things hanging from the ceiling; jump just before a peg to hop it; crash through
##            the washing hung across the line. Seen in FIRST PERSON, from the robot's eyes. Outside, the
##            town's lights go out as you pass. Behind the old man in the armchair, time slows: the robot
##            turns its head to the window (the town it lived in all its life), then to the room (all the
##            familiar things). Back to third person at the end: it lands on the sill by the breaker box's
##            wire with its last cell, red.
##   stop 6 - the finale: on the little shelf under the breaker box, hold E: the robot's last charge flows
##            into the box (cells go out one by one, the lever creeps up), then CLICK - the lights come back
##            on from the breaker outwards, the grey low-power look lifts, the old things glow, and the
##            robot's eyes go dark. The ending, one take: the robot by the box, back through the bedroom
##            door to the old man asleep, out of the bedroom window, up over the dark town - only this
##            house is lit. The title, then back to the title screen.
##   godot --path . res://scenes/room.tscn -- --autotest --shots=DIR

const PLAYER := preload("res://scenes/tps_player.tscn")
const K := 9.0
const KC_U := 0.9 * 9.0   ## kitchen counter top (units)
const BW_M := -0.4        ## the bedroom's east wall (m): the breaker box hangs on it
const ROOM_ART := preload("res://scripts/room_art.gd")

var player: CharacterBody3D
@onready var maze: DeskMaze = $Stop2/DeskMaze
var fall_armed := true
var fell := false
var revealed := false
var frame_up := false
var jack_busy := false
var machine_busy := false
var launched := false
var in_desk := false
var _walk_stalls: Array = []
var door_open := false
var note_found := false
var in_tv := false
var tv_done := false
var tv_finale := false
var kitchen_revealed := false
var board_pushed := false
var toaster_busy := false
var on_spice_shelf := false
var _fire_t := 0.0
const FLARE_PERIOD := 3.2
const METAL := ["RangeHood", "UtensilRailN", "UtensilRailE"]
const STEAM_SECONDS := 7.0
const STEAM_TOP := 1.3 * 9.0   ## units
var steam_left := 0.0
var kettle_busy := false
var sink_done := false
var mug_rung := false
var zip_done := false
var slow_look_done := false
var slow_looks := 0
var min_time_scale := 1.0
var _zip_charge0 := 0.0
var _arm_len0 := 0.0
var town: Town
var finale_started := false
var finale_done := false
var ending_stage := -1          ## which point of the ending's camera path it has reached
var ending_done := false
var _finale_c0 := 0.0
var _spark: OmniLight3D
var opening_done := false
var _jack_home := Vector3.ZERO
var _jack_t := 0.0
var seesaw_tipped := false
var _dbg_on_end := []
var _box_lines_done := false
var _box_pos := Vector3.ZERO
var _box_hint_t := 0.0
var audio: Node                  ## scripts/audio_director.gd
var _was_respawning := false
var tv_pulling := false
var _fp_desk: Camera3D
var _op_skip := false
var _op_tweens: Array[Tween] = []
var _op_cam: Camera3D
var _op_dir := ""                ## --opening-test: where its screenshots go
var _said := {}                  ## monologue lines that only play once
var _night_light: OmniLight3D
var _end_cam: Camera3D
var _end_curve: Curve3D
var _end_seg := 0
var _end_la := Vector3.ZERO
var _end_lb := Vector3.ZERO
var _fp_cam: Camera3D           ## first-person camera on the clothesline
var _fp_from := Transform3D()
var _fp_blend := 1.0            ## 0 -> 1: from _fp_from to the robot's eyes (and back at the end)
var _fp_yaw := 0.0              ## head turn, degrees (+ = left, towards the window)
var _fp_shake := 0.0
var fp_phase := ""
var _fp_fwd := Vector3.ZERO
var _speed_fx: ColorRect          ## speed lines over the first-person view
var _speed_t := 0.0
var _fp_buzz := 0.0              ## "" / "out" (looking at the town) / "in" (looking into the room)
var time_box_open := false
var _tv_cam: Camera3D
var _env_saved := []
var _block_home := {}
var _machine_home := {}

func _ready() -> void:
	ROOM_ART.install(self)
	player = PLAYER.instantiate()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.teleport($PlayerStart.global_position)
	# camera west of the robot looking east over its shoulder: the desk lamp is the first thing you see
	player.cam_pivot.rotation.y = -PI / 2
	player.spring.rotation.x = deg_to_rad(-14)
	player._face_yaw = PI / 2
	player.visual.rotation.y = PI / 2
	$PostFX.player_path = player.get_path()
	audio = preload("res://scripts/audio_director.gd").new()
	audio.name = "Audio"
	add_child(audio)
	audio.player = player
	audio.ambience("环境声/阶段混音1_童年少年_窗外_循环.ogg")
	Game.memory_restored.connect(func(_id): audio.sfx("音效/全程_回忆点亮.ogg", -8.0))
	Game.register_player(player)
	Game.set_checkpoint($Checkpoints/Opening)
	$Areas/BookTip.body_entered.connect(func(b): if b == player and fall_armed: _fall())
	$Areas/JackTop.body_entered.connect(func(b): if b == player: _jack())
	$Stop0/FrameInteract.activated.connect(_stand_frame_up)
	$Stop1/CarCharge.activated.connect(_run_machine)
	$Stop1/CarCharge.hold_progress.connect(func(_f): _car_hold_t = Time.get_ticks_msec())
	# a small cyan glow on the electric car up on the big robot's head (it's what you power: cyan = interactive)
	var car_light := OmniLight3D.new()
	car_light.light_color = Color(0.55, 1.0, 0.95)
	car_light.light_energy = 1.6
	car_light.omni_range = 0.3 * K
	car_light.position = Vector3(0, 0.1 * K, 0)
	$Stop1/ElectricCar.add_child(car_light)
	$Stop2/DoorHandleUse.activated.connect(_open_door)
	$Stop3/TvEnter.done = true   # no E prompt: walking up to the screen is enough (see _process)
	maze.visible = false         # until the lamp goes out it is just a desk
	if maze.hole_fill:
		maze.hole_fill.filled.connect(func(_b):
			_say_once("2-9")
			audio.sfx("音效/第2站_橡皮填洞.ogg", -4.0))
	$Stop3/TvScreen.game.rescued.connect(_tv_finale)
	$Stop3/TimeBoxOpen.activated.connect(_open_time_box)
	$Areas/KitchenReveal.body_entered.connect(func(b): if b == player and not kitchen_revealed and _box_lines_done: _after_tv_looks())
	$Stop4/MicrowaveUse.activated.connect(_microwave)
	$Stop4/ToasterUse.activated.connect(_toaster)
	$Stop4/KettleUse.activated.connect(_kettle)
	$Stop4/MugTap.activated.connect(_ring_mug)
	$Stop5/ZiplineGrab.activated.connect(_zipline_grab)
	$Stop5/Zipline.reached.connect(func(mu): _slow_look("out" if mu >= $Stop5/Zipline.mark_u else "in"))
	$Stop5/Zipline.finished.connect(_zipline_end)
	$Stop6/BreakerCharge.hold_time = FINALE_LAST - FINALE_FROM   # the hold lasts the finale's last phrase
	$Stop6/BreakerCharge.hold_progress.connect(_breaker_progress)
	$Stop6/BreakerCharge.activated.connect(_breaker_done)
	$Stop6/BreakerOk.visible = false
	_build_town()
	preload("res://scripts/kitchen_fx.gd").install(self)   # flames, water, steam, fill light in the kitchen
	$Areas/SinkPile.body_entered.connect(func(b): if b == player and not sink_done: _sink_collapse())
	$Stop4/SteamColumn.visible = false
	# off the rail by the kettle: turn to the dish rack beyond the wet counter (the next goal)
	$Checkpoints/Kettle.body_entered.connect(_kettle_look)
	for n in METAL:
		get_node("Stop4/" + n).add_to_group("metal")
	# the camera while hanging: from the room side (south) along the north wall, from the west along the east wall
	$Stop4/RangeHood.set_meta("cam_yaw", 0.0)
	$Stop4/UtensilRailN.set_meta("cam_yaw", 0.0)
	$Stop4/UtensilRailE.set_meta("cam_yaw", -PI / 2)
	for n in ["PushBlockLarge", "PushBlockSmall"]:
		_block_home[n] = get_node("Stop1/" + n).global_position
	for n in ["ElectricCar", "Drum", "Seesaw"]:
		_machine_home[n] = get_node("Stop1/" + n).transform
	_jack_home = $Stop1/JackHead.position
	$Stop1/JackHead.rotation_degrees.y -= 50.0   # the clown looks off to the right, towards the way in
	$Stop0/PhotoFrame.position.y += 0.004 * K   # lying flat it shared the nightstand's surface and flickered
	_print = $Stop0/PhotoFrame.find_child("FamilyPhoto", true, false)
	var stand := $Stop0/PhotoFrame.find_child("BackStand", true, false) as Node3D
	if stand:   # its face sat exactly on the back board's: the two flickered against each other as the camera moved
		stand.position.y += 0.0008
	if _print:   # the print is double-sided: face down, it showed through the frame's back. Hidden till it stands.
		_print.visible = false
	for n in ["BigBotShoulderN", "BigBotShoulderS", "BigBotTorso", "BigBotHead"]:   # up there only by the blocks
		get_node("Stop1/" + n).set_meta("no_mantle", true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if "--autotest" in OS.get_cmdline_user_args():
		_autotest()
	elif not "--f9test" in OS.get_cmdline_user_args():
		_opening()
	if "--f9test" in OS.get_cmdline_user_args():
		await _wait(1.0)
		var e := InputEventKey.new()
		e.physical_keycode = KEY_F9
		e.pressed = true
		Input.parse_input_event(e)
		await _wait(1.5)
		print("F9TEST ", JSON.stringify({"on_floor": player.is_on_floor(), "near_door": player.global_position.distance_to($OpenPlanDrop.global_position) < 0.6, "checkpoint": Game.checkpoint.name}))
		get_tree().quit()

func _process(_d: float) -> void:
	# first person on the clothesline: the robot's eyes, facing down the line; wider with speed
	if _fp_cam != null:
		if not _fp_cam.current:  # nothing else may take the view while the robot rides the line
			_fp_cam.make_current()
		$Stop5/Zipline.bar.visible = absf(_fp_yaw) < 25.0  # the bar over its head would cut across a sideways look
		var eye := _fp_eye()
		_fp_cam.global_transform = eye if _fp_blend >= 1.0 else _fp_from.interpolate_with(eye, _fp_blend)
		var zp: Zipline = $Stop5/Zipline
		var fast := clampf((zp.profile(zp.u) * zp._mult - zp.v_min) / (zp.v_max - zp.v_min), 0.0, 1.0) * (1.0 if fp_phase == "" and absf(_fp_yaw) < 10.0 else 0.0)
		_fp_cam.fov = lerpf(_fp_cam.fov, 70.0 + fast * 30.0, 1.0 - exp(-4.0 * _d))  # wide angle at speed
		if _speed_fx:
			_speed_t += _d
			var m: ShaderMaterial = _speed_fx.material
			m.set_shader_parameter("amount", lerpf(float(m.get_shader_parameter("amount")), fast, 1.0 - exp(-5.0 * _d)))
			m.set_shader_parameter("t", _speed_t)
		_fp_buzz = fast
		_fp_shake = maxf(_fp_shake - _d * 3.0, 0.0)
	# the stove fire is alive (only the people are frozen)
	_fire_t += _d
	var f := 0.75 + 0.2 * sin(_fire_t * 13.0) * sin(_fire_t * 7.3) + randf() * 0.08
	$StoveGlow.light_energy = 3.5 * f
	$Stop4/StoveFlame.scale.y = 0.6 + 0.8 * f
	# the two burners flare up in turn (warning: the flame grows; then a column right up to the hood)
	var flaring := 0.0
	for i in 2:
		var side := "W" if i == 0 else "E"
		var st: Array = flare_state(i)
		var h := 1.0 + f * 0.3
		if st[0] == "warn":
			h = 1.0 + 3.0 * st[1] / 0.6 + randf() * 0.6
		elif st[0] == "on":
			h = 16.0 * (0.85 + 0.15 * f)
			flaring += 1.0
		get_node("Stop4/FlarePivot" + side).scale.y = h
		get_node("Stop4/Flare" + side).enabled = st[0] == "on"
	$StoveGlow.light_energy += flaring * 3.0
	# hanging kitchen utensils swing as the robot passes under them
	if player and player.clinging != null:
		for u in $Stop4.get_children():
			if u.name.begins_with("HangingUtensil") and not u.has_meta("swinging") \
					and Vector2(u.global_position.x - player.global_position.x, u.global_position.z - player.global_position.z).length() < 0.7:
				u.set_meta("swinging", true)
				audio.sfx("音效/第4站_碰到餐具_0%d.ogg" % randi_range(1, 4), -10.0, 0.06)
				var tw := create_tween()
				for a in [14.0, -10.0, 6.0, -3.0, 0.0]:
					tw.tween_property(u, "rotation_degrees:x", a, 0.22).set_trans(Tween.TRANS_SINE)
				tw.tween_callback(func(): u.remove_meta("swinging"))
	if in_desk and _note_use == null and maze.note:   # E  Read on Mum's note
		_note_use = Area3D.new()
		_note_use.set_script(preload("res://scripts/components/interactable.gd"))
		_note_use.cost = 0.0
		_note_use.radius = 1.0
		_note_use.prompt_text = "E  Read"
		_note_use.prompt_offset = Vector3(0, 0.3, 1.0)   # beside it (screen right from the overhead camera), not on it
		add_child(_note_use)
		_note_use.global_position = maze.note.global_position
		_note_use.activated.connect(_read_note)
		var np := maze.note.global_position
		for n in maze.find_children("*", "VisualInstance3D", true, false):   # nothing lying on top of it
			if n == maze.note or maze.note.is_ancestor_of(n) or n is Light3D:
				continue
			var q: Vector3 = n.global_position
			if Vector2(q.x - np.x, q.z - np.z).length() < 0.075 * K and q.y > np.y - 0.005 * K:
				n.visible = false
		var nm := StandardMaterial3D.new()   # a faint warm glow until it's been read
		nm.albedo_color = Color(1, 0.93, 0.76)
		nm.emission_enabled = true
		nm.emission = Color(1, 0.72, 0.38)
		nm.emission_energy_multiplier = 0.7
		maze.note.material_override = nm
		_note_glow = OmniLight3D.new()
		_note_glow.light_color = Color(1, 0.72, 0.38)
		_note_glow.light_energy = 0.8
		_note_glow.omni_range = 0.18 * K
		add_child(_note_glow)
		_note_glow.global_position = np + Vector3(0, 0.05 * K, 0)
	if false:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 0.9, 0.7)
		m.emission_enabled = true
		m.emission = Color(1, 0.7, 0.35)
		m.emission_energy_multiplier = 0.0
		maze.note.material_override = m
		create_tween().tween_property(m, "emission_energy_multiplier", 2.5, 0.8)
		Game.restore_memory("mom_note")

var _note_use: Area3D
var _note_glow: OmniLight3D

## Mum's note, opened on screen: yellowed paper, her handwriting; the game holds still until E again.
func _read_note() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 110   # above everything, the fade and the colour grade included
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var paper := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.93, 0.78)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 48
	sb.content_margin_right = 48
	sb.content_margin_top = 40
	sb.content_margin_bottom = 40
	sb.shadow_color = Color(1.0, 0.78, 0.4, 0.35)   # a faint warm glow around the paper: a memory
	sb.shadow_size = 28
	paper.add_theme_stylebox_override("panel", sb)
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.grow_horizontal = Control.GROW_DIRECTION_BOTH
	paper.grow_vertical = Control.GROW_DIRECTION_BOTH
	paper.custom_minimum_size = Vector2(560, 0)
	paper.rotation_degrees = -1.5
	layer.add_child(paper)
	var ink := Label.new()
	ink.text = StoryText.MUM_NOTE
	ink.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hand := FontVariation.new()
	hand.base_font = ThemeDB.fallback_font
	hand.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.25, 1), Vector2.ZERO)
	ink.add_theme_font_override("font", hand)
	ink.add_theme_font_size_override("font_size", 27)
	ink.add_theme_color_override("font_color", Color(0.14, 0.16, 0.32))
	paper.add_child(ink)
	var hint := Label.new()
	hint.text = "E  close"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -50
	layer.add_child(hint)
	get_tree().paused = true
	await get_tree().process_frame
	await get_tree().process_frame
	while not Input.is_action_just_pressed("interact") and not "--autotest" in OS.get_cmdline_user_args():
		await get_tree().process_frame
	if "--autotest" in OS.get_cmdline_user_args():
		await get_tree().create_timer(1.0, true).timeout
	get_tree().paused = false
	layer.queue_free()
	note_found = true
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 0.9, 0.7)
	m.emission_enabled = true
	m.emission = Color(1, 0.7, 0.35)
	m.emission_energy_multiplier = 0.0
	maze.note.material_override = m
	create_tween().tween_property(m, "emission_energy_multiplier", 2.5, 0.8)
	Game.restore_memory("mom_note")
	audio.phrase("音乐/旋律片段2_妈妈的纸条.ogg", -8.0)
	await _wait(0.6)
	Game.captions.say_all(["2-11", "2-12"])

## Debug: F9 skips to the living room (by the bedroom door), for testing the TV stop.
func _unhandled_input(event: InputEvent) -> void:
	if _photo_cam and _photo_since > 0.6 and event is InputEventMouseMotion and event.relative.length() > 3.0:
		_photo_release()  # turning the camera ends the photo's close shot
	if not OS.is_debug_build():   # the F9-F12 skips are for us, not for players
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F9:
		_skip_to_living_room()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
		_skip_to_kitchen()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F12:
		kitchen_revealed = true  # debug: straight to the shelf under the breaker box, last cell left
		_skip_to_kitchen()
		town.set_all(false)
		zip_done = true
		player.revive(0.12)
		player.teleport($FinaleStand.global_position + Vector3(0, 0.05, 0))
		Game.set_checkpoint($Checkpoints/SillEnd)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		kitchen_revealed = true  # debug: straight to the coat hanger on the clothesline, with a normal ~35% charge
		_skip_to_kitchen()
		player.revive(0.35)
		player.teleport(Vector3(4.35 * K, 0.9 * K + 0.05, 2.33 * K))
		Game.set_checkpoint($Checkpoints/SinkSouth)

## Debug: F10 = out of the TV, on the floor by the kitchen.
func _skip_to_kitchen() -> void:
	_skip_to_living_room()
	tv_done = true
	time_box_open = true      # (the time box has been opened: the kitchen look may come)
	_box_lines_done = true
	_box_pos = Vector3(INF, 0, INF)
	player.magnet_enabled = false
	player.teleport($TvExitLanding.global_position + Vector3(0, 0.05, 0))
	Game.set_checkpoint($Checkpoints/TvExit)
	_after_tv_looks()

func _skip_to_living_room() -> void:
	if in_desk:
		in_desk = false
		var env: Environment = $WorldEnvironment.environment
		env.ambient_light_energy = _env_saved[0]
		$Moonlight.light_energy = _env_saved[1]
	player.set_top_down(false)
	for n in ["WallLampShade", "WallLampArm"]:
		get_node("Stop2/" + n).visible = true
	player.locked = false
	player.teleport($OpenPlanDrop.global_position + Vector3(0, 0.05, 0))
	Game.set_checkpoint($Checkpoints/OpenPlan)
	_look_at($TvLook.global_position, -6.0, 0.8)

func _physics_process(_d: float) -> void:
	# the clothesline ride: the battery runs down to its last cell; the town's lights go out as you pass
	var zip: Zipline = $Stop5/Zipline
	if zip.riding:
		player.charge = lerpf(_zip_charge0, 0.12, minf(zip.u / zip.mark_u, 1.0))
		player.charge_changed.emit(player.charge)
		# before the slow look only the far east goes dark (the town it turns to see is still lit); then the rest
		var edge := lerpf(19.0, 6.0, zip.u / zip.mark_u) if zip.u < zip.mark_u else lerpf(6.0, -17.0, (zip.u - zip.mark_u) / (1.0 - zip.mark_u))
		town.lights_off_east_of(edge)
	min_time_scale = minf(min_time_scale, Engine.time_scale)
	# the kettle's steam: inside the plume while it lasts = carried up
	steam_left = maxf(steam_left - _d, 0.0)
	player.updraft_top = STEAM_TOP if steam_left > 0.0 and $Areas/SteamPlume.overlaps_body(player) and not player.locked else -INF
	if steam_left > 0.0:
		var col: Node3D = $Stop4/SteamColumn
		col.visible = true
		col.scale = Vector3(1.0 + sin(_fire_t * 5.0) * 0.06, minf(1.0, steam_left) * (0.9 + sin(_fire_t * 3.3) * 0.1), 1.0)
	elif $Stop4/SteamColumn.visible:
		$Stop4/SteamColumn.visible = false
	# after the photo, a few steps on: the robot looks up and sees the desk
	if frame_up and not revealed and _photo_cam == null and not player.locked and not _photo_talking 			and Vector2(player.global_position.x - _photo_pos.x, player.global_position.z - _photo_pos.z).length() > 0.06 * K:
		_reveal_desk()
	if _photo_cam:   # the photo's close shot holds until the robot moves
		_photo_since += _d
		if _photo_since > 0.6 and (Input.get_vector("move_left", "move_right", "move_fwd", "move_back").length() > 0.2 or Input.is_action_just_pressed("jump")):
			_photo_release()
	# the TV: walk up to the screen on the cabinet and it pulls you in (after a look back at him)
	if not tv_pulling and not in_tv and not tv_done and not player.locked \
			and player.global_position.distance_to($Stop3/TvEnter.global_position) < 0.14 * K:
		_tv_approach()
	# the clothesline: the first swing past something, peg, washing, bump; the town going dark; the shelf
	if _fp_cam != null:
		var zp: Zipline = $Stop5/Zipline
		if zp.riding and zp.hang_nodes.size() > 0 and float(zp.hang_nodes[0].get_meta("u")) - zp.u < 0.04:
			_say_once("5-5")
		if zp.clacks > 0:
			_say_once("5-6")
		if zp.bumps > 0:
			_say_once("5-8")
		for g in zp._garments:
			if g.has_meta("hit"):
				_say_once("5-7")
				break
		if town.lit_count() < town.light_count() * 0.6:
			_say_once("5-11")
	if zip_done and not finale_started and player.is_on_floor() \
			and player.global_position.distance_to($FinaleStand.global_position) < 0.15 * K:
		_say_once("6-1")
	var resp := Game.is_respawning()
	if resp and not _was_respawning:
		audio.sfx("音效/机器人_掉落重来.ogg", -6.0)
	_was_respawning = resp
	# the jack-in-the-box: springs up and sinks back on its own, so it gets noticed (standing on it = launch)
	if fell and not launched and not jack_busy:
		_jack_t += _d
		var head: Node3D = $Stop1/JackHead
		var c := fmod(_jack_t, 3.2)
		var up := 0.0
		if c < 0.12:
			up = c / 0.12
		elif c < 0.9:
			up = 1.0
		elif c < 1.4:
			up = 1.0 - (c - 0.9) / 0.5
		if c < _d:
			audio.sfx("音效/第1站_玩偶匣弹出.ogg", -16.0, 0.08)
		head.position = _jack_home + Vector3(0, 0.16 * K * up, 0)
		head.scale = Vector3.ONE * lerpf(1.0, 1.4, up)
	# the seesaw: its west end starts up; the first time the robot steps on it, down it goes - it's a seesaw
	var saw_p: Vector3 = $Stop1/Seesaw.global_position
	var on_saw := absf(player.global_position.x - saw_p.x) < 0.19 * K and absf(player.global_position.z - saw_p.z) < 0.05 * K 			and player.global_position.y < saw_p.y + 0.06 * K
	if fell and not seesaw_tipped and on_saw:
		for _once in 1:
				seesaw_tipped = true
				var saw: Node3D = $Stop1/Seesaw
				var tw := create_tween()
				tw.tween_property(saw, "rotation_degrees:z", 6.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_callback(func(): _machine_home["Seesaw"] = saw.transform)
				audio.sfx("音效/第1站_积木摩擦短_01.ogg", -6.0)
				break
	# out of the TV: the time box first (it pulses, warm, until opened); a few steps after it, the kitchen
	if tv_done and not time_box_open:
		_box_hint_t += _d
		$Stop3/TimeBoxGlow.light_energy = 0.6 + 0.9 * (0.5 + 0.5 * sin(_box_hint_t * 3.0))
		if _box_hint_t > 9.0 and fmod(_box_hint_t, 9.0) < _d and not player.locked:
			_look_at($Stop3/TimeBoxGlow.global_position, -20.0, 1.0)   # nudge the camera back to it now and then
	_audio_events()
	# monologue, once each: the pixel game
	if in_tv:
		var tg: TvGame = $Stop3/TvScreen.game
		if tg.active:
			_say_once("3-6")
			if tg.bot.position.x > 200.0:
				_say_once("3-7")
			if tg.hits_taken > 0 or tg.continues > 0:
				_say_once("3-8")
			if tg.batteries > 0:
				_say_once("3-9")
			if tg.screen_reached >= 2 and tg.bot.position.x > 900.0:
				_say_once("3-10")
			if tg.boss_started:
				_say_once("3-11")
			if tg.dragon and tg.dragon.phase2:
				_say_once("3-12")
	# ...the kitchen
	if kitchen_revealed and not sink_done:
		if Game.is_respawning():
			_say_once("4-6")
		if player.clinging != null:
			_say_once("4-12")
		if player.updraft_top > -INF:
			_say_once("4-14")
		if player.is_on_floor():
			for i in player.get_slide_collision_count():
				var c := player.get_slide_collision(i).get_collider()
				if c is Node and c.name in ["CannedGoods", "RiceBag", "StepStool"]:
					_say_once("4-7")
	# monologue, once each: the desk (first old light, first crack, the eraser), the TV stop
	if in_desk:
		if Game.is_respawning():
			_say_once("2-7")
		if maze.eraser and maze.eraser.grabbed:
			_say_once("2-8")
		if not _said.has("2-4"):
			for l in maze.lights:
				if l.lit and l != maze.lights[0]:
					_said["2-4"] = true
					Game.captions.say_all(["2-4", "2-5", "2-6"])
					break
	if door_open and not tv_done and player.is_on_floor():
		for i in player.get_slide_collision_count():
			var c := player.get_slide_collision(i).get_collider()
			if c is Node and c.name in ["GameBoxes", "MagStack"]:
				_say_once("3-3")
	# monologue: the first fall into the dark of the toy box, the first ride on the train
	if fell and not launched and Game.is_respawning():
		_say_once("1-2")
	if fell and not launched and player.is_on_floor():
		for i in player.get_slide_collision_count():
			if player.get_slide_collision(i).get_collider() == $Stop1/Train:
				_say_once("1-2b")
	# a block pushed off the shoebox goes back where it started
	for n in _block_home:
		var blk: CharacterBody3D = get_node("Stop1/" + n)
		if blk.global_position.y < 0.25 * K and not blk.grabbed:
			blk.global_position = _block_home[n]
			blk.velocity = Vector3.ZERO

func _arc(a: Vector3, b: Vector3, height: float, time: float) -> void:
	await _arc_tween(a, b, height, time).finished

func _arc_tween(a: Vector3, b: Vector3, height: float, time: float) -> Tween:
	var tw := create_tween()
	tw.tween_method(func(t: float):
		player.global_position = a.lerp(b, t) + Vector3(0, sin(t * PI) * height, 0), 0.0, 1.0, time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw

# ------------------------------------------------------------------ stop 0
## Reveal shot: turn the camera towards a target, then hand control back.
func _look_at(target: Vector3, pitch_deg: float, time := 1.4) -> void:
	var d: Vector3 = target - player.global_position
	var yaw := atan2(-d.x, -d.z)
	var tw := create_tween().set_parallel()
	tw.tween_method(func(v): player.cam_pivot.rotation.y = v, player.cam_pivot.rotation.y,
		player.cam_pivot.rotation.y + wrapf(yaw - player.cam_pivot.rotation.y, -PI, PI), time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(player.spring, "rotation:x", deg_to_rad(pitch_deg), time).set_trans(Tween.TRANS_SINE)

func _reveal_desk() -> void:
	revealed = true
	_look_at($DeskLampTarget.global_position, -6.0, 0.01)  # the robot's own camera ends up facing the desk
	var p := player.global_position / K
	var lamp: Vector3 = $DeskLampTarget.global_position / K
	var d := Vector3(lamp.x - p.x, 0, lamp.z - p.z).normalized()
	var desk := Vector3(-0.8, 0.92, 0.35)   # the boy at the desk, under the lamp
	get_tree().create_timer(1.8).timeout.connect(func(): Game.captions.say("0-5"))
	await _cinematic([
		[p - d * 0.14 + Vector3(0, 0.08, 0), lamp, 1.0, 0.2],      # up behind the robot's shoulder
		[p + d * 0.75 + Vector3(0, 0.28, 0), desk, 2.6, 1.8],      # drift across the dark towards the lamp
	])

## E at the photo: the camera leaves the normal view for a close shot over the robot's right shoulder and
## stays there, the frame stands up, a warm glow, the memory. Moving (or turning the camera) brings the
## normal view back.
func _stand_frame_up() -> void:
	frame_up = true
	_photo_pos = player.global_position
	var p := player.global_position / K
	var f: Vector3 = $Stop0/PhotoFrame.global_position / K
	var d := Vector3(f.x - p.x, 0, f.z - p.z).normalized()
	var right := d.cross(Vector3.UP)
	player._face_yaw = atan2(d.x, d.z)   # turn to the photo
	var pcam := _player_cam()
	_photo_cam = Camera3D.new()
	add_child(_photo_cam)
	_photo_cam.fov = pcam.fov
	_photo_cam.global_transform = pcam.global_transform
	_photo_cam.make_current()
	_photo_since = 0.0
	var look := f + Vector3(0, 0.06, 0)
	var to := Transform3D(Basis.IDENTITY, (p - d * 0.16 + right * 0.05 + Vector3(0, 0.1, 0)) * K).looking_at(look * K)
	_photo_tw = create_tween()
	_photo_tw.set_parallel()
	_photo_tw.tween_property(_photo_cam, "global_transform", to, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_photo_tw.tween_property(_photo_cam, "fov", 40.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_photo_tw.chain().tween_property(_photo_cam, "global_transform", to.translated(-d * 0.03 * K), 7.0)  # a slow creep in
	await _wait(0.5)
	create_tween().tween_property($Stop0/PhotoFrame, "rotation_degrees:x", -102.0, 0.7) 		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	audio.sfx("音效/开场_推起相框.ogg", -6.0)
	audio.phrase("音乐/旋律片段1_童年照片.ogg", -8.0)
	var glow := OmniLight3D.new()   # warm amber: a memory
	glow.light_color = Color(1, 0.72, 0.38)
	glow.omni_range = 0.35 * K
	add_child(glow)
	glow.global_position = (f + Vector3(0, 0.1, 0.08)) * K
	create_tween().tween_property(glow, "light_energy", 1.2, 1.2)
	if _print:
		_print.visible = true
	Game.restore_memory("family_photo")
	_photo_lines()
	_shot_if(_op_dir, "op_photo.png", 2.2)
	await _wait(8.0)
	create_tween().tween_property(glow, "light_energy", 0.35, 2.0)

func _photo_lines() -> void:
	_photo_talking = true
	await _wait(0.6)
	await Game.captions.say("0-6")
	await _wait(0.4)
	await Game.captions.say("0-7")
	_photo_talking = false

var _photo_cam: Camera3D
var _photo_tw: Tween
var _photo_since := 0.0
var _photo_talking := false
var _print: Node3D
var _finale_music: AudioStreamPlayer
var _pour_t := 0
const FINALE_FROM := 29.25        ## 终章_灌电.ogg: the music-box phrase starts here...
const FINALE_LAST := 39.38        ## ...and its last note is here: the hold lasts exactly the time between
var _prev := {}                   ## counters from last frame (the pixel game's events, the magnet, hazards)
var _hazards: Array = []
var _car_hold_t := -10000
var _photo_pos := Vector3.ZERO   ## where the robot stood up the photo (the desk reveal comes a few steps on)

## Back from the photo's close shot to the robot's own camera, quickly.
func _photo_release() -> void:
	if _photo_cam == null:
		return
	var cam := _photo_cam
	_photo_cam = null
	if _photo_tw and _photo_tw.is_valid():
		_photo_tw.kill()
	var pcam := _player_cam()
	var from := cam.global_transform
	var fov0 := cam.fov
	await create_tween().tween_method(func(t: float):
		cam.global_transform = from.interpolate_with(pcam.global_transform, t)
		cam.fov = lerpf(fov0, pcam.fov, t), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	pcam.make_current()
	cam.queue_free()

func _fall() -> void:
	fall_armed = false
	player.locked = true
	Game.captions.say("0-8", 1.4)
	audio.sfx("音效/开场_书本晃动翻倒.ogg", -6.0)
	var book: Node3D = $Stop0/LooseBook
	var wob := create_tween()  # the book creaks: two small dips, then it tips over the edge
	for a in [-5.0, -1.5, -9.0]:
		wob.tween_property(book, "rotation_degrees:z", a, 0.18).set_trans(Tween.TRANS_SINE)
	player.rig.kick_arms(0.0, 320.0)
	player.rig.kick_head(-120.0, 200.0)
	await wob.finished
	var tip := create_tween().set_parallel()
	tip.tween_property(book, "rotation_degrees:z", -75.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tip.tween_property(book, "position", book.position + Vector3(0.6, -0.3, 0), 0.3)
	player.launch_squash()
	var fly := _arc_tween(player.global_position, $FallLanding.global_position, 0.8, 1.0)
	await tip.finished
	var drop := create_tween().set_parallel()
	drop.tween_property(book, "position", $BookLanding.position, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_property(book, "rotation_degrees:z", -180.0, 0.55)
	await fly.finished
	player.velocity = Vector3(0, -2.0, 0)
	player.locked = false
	fell = true
	audio.sfx("音效/第1站_掉进毛绒堆_中.ogg", -6.0)
	audio.loop("音效/第1站_玩具火车_循环.ogg", true, -20.0)
	Game.set_checkpoint($Checkpoints/ToyBox)
	_look_at($MachineLook.global_position, -14.0)  # show the goal: the big robot, the drum, the seesaw
	await Game.captions.say("1-1")
	Game.captions.say("1-4")

## Sounds for things that happen inside other scripts: read their counters each frame, play on change.
func _audio_events() -> void:
	if in_tv:
		var tg: TvGame = $Stop3/TvScreen.game
		_on_up("hits", tg.hits_taken, "音效/第3站_8bit_受伤扣电.ogg")
		_on_up("cont", tg.continues, "音效/第3站_8bit_投币续关.ogg")
		_on_up("bat", tg.batteries, "音效/第3站_8bit_拾取.ogg")
		_on_up("kills", tg.kills, "音效/第3站_8bit_打败小怪.ogg")
		_on_up("blocked", tg.blocked_hits, "音效/第3站_8bit_打在盾上.ogg")
		_on_up("gate", 1 if tg.boss_started else 0, "音效/第3站_8bit_城门关上.ogg")
		_on_up("roar", 1 if tg.dragon and tg.dragon.phase2 else 0, "音效/第3站_8bit_恶龙吼叫.ogg")
		_on_up("boss", 1 if tg.boss_beaten else 0, "音效/第3站_8bit_恶龙被打败.ogg")
		if tg.active and not tg.frozen:
			if Input.is_action_just_pressed("jump") and tg.bot.is_on_floor():
				audio.sfx("音效/第3站_8bit_跳跃.ogg", -12.0, 0.04)
			if Input.is_action_just_pressed("attack"):
				audio.sfx("音效/第3站_8bit_钳子挥击.ogg", -12.0, 0.05)
	# holding E on the car: the charging hum, only while E is held
	var charging := Time.get_ticks_msec() - _car_hold_t < 150
	if charging != bool(_prev.get("car", false)):
		audio.loop("音效/机器人_按住E分电_循环.ogg", charging, -6.0)
	_prev["car"] = charging
	# the magnet
	var cl := 1 if player.clinging != null else 0
	if cl != int(_prev.get("cling", 0)):
		audio.sfx("音效/第4站_电磁铁吸住.ogg" if cl else "音效/第4站_电磁铁松开.ogg", -6.0)
		audio.loop("音效/第4站_电磁铁嗡嗡_循环.ogg", cl == 1, -14.0)
	_prev["cling"] = cl
	if player.updraft_top > -INF and not _prev.get("lift", false):
		audio.sfx("音效/第4站_蒸汽托举.ogg", -6.0)
	_prev["lift"] = player.updraft_top > -INF
	# the burners flaring up
	if kitchen_revealed and not sink_done:
		for i in 2:
			var on := 1 if flare_state(i)[0] == "on" else 0
			if on and not int(_prev.get("flare%d" % i, 0)):
				audio.sfx("音效/第4站_灶火蹿起_0%d.ogg" % randi_range(1, 5), -8.0, 0.05)
			_prev["flare%d" % i] = on
	# hazards: water shorts it out, fire burns
	var wet := 0
	var burnt := 0
	if _hazards.is_empty():
		_hazards = find_children("*", "Area3D", true, false).filter(func(n): return n is Hazard)
	for h in _hazards:
		if h.kind == "water":
			wet += h.hits
		else:
			burnt += h.hits
	_on_up("wet", wet, "音效/第4站_碰水短路.ogg")
	_on_up("burnt", burnt, "音效/第4站_被火烫.ogg")
	# the finale's music only plays while E is held
	if _finale_music and not finale_done:
		_finale_music.stream_paused = Time.get_ticks_msec() - _pour_t > 150

func _on_up(key: String, v: int, path: String) -> void:
	if v > int(_prev.get(key, v)):
		audio.sfx(path, -8.0, 0.04)
	_prev[key] = v

## A monologue line that only plays the first time.
func _say_once(id: String) -> void:
	if not _said.has(id):
		_said[id] = true
		Game.captions.say(id)

# ------------------------------------------------------------------ the opening
## 2:14 a.m.: the old man asleep, a night light on, the living room lit. Cut to the breaker box: a spark, the
## lever drops, the lights go out. Back in the bedroom the night light dies; moonlight only. The camera
## pushes in on the tin robot on the nightstand: its eyes flicker on, its cells fill. It looks at the bed -
## at itself, asleep - then down at its own tin hands. It turns to the desk; the camera settles behind it.
## Jump or E skips it. ~30 s.
func _opening() -> void:
	player.locked = true
	player.powered_down = true
	player.charge = 0.0
	player.charge_changed.emit(0.0)
	player.pose_override = [0.0, 6.0, 34.0, -14.0, -14.0, 4.0, 4.0]   # slumped, switched off
	$PostFX.loss_cap = 0.0          # the house still has its power: no low-power look yet
	_night_light = OmniLight3D.new()
	_night_light.light_color = Color(1, 0.72, 0.42)
	_night_light.omni_range = 1.6 * K
	_night_light.omni_attenuation = 1.4
	add_child(_night_light)
	_night_light.global_position = Vector3(-3.05, 0.98, -2.5) * K
	_night_light.light_energy = 1.3
	for i in range(1, 7):           # the living room's lights, still on
		get_node("HouseLight%d" % i).light_energy = 1.1
	$Stop6/BreakerLever.rotation_degrees.z = 180.0
	$Stop6/BreakerFault.visible = false
	$Stop6/BreakerOk.visible = true
	$BreakerFaultLight.visible = false
	var pcam := _player_cam()
	_op_cam = Camera3D.new()
	add_child(_op_cam)
	_op_cam.fov = 50.0
	_op_cam.make_current()
	var robot := Vector3(-3.22, 0.795, -2.28)
	var face := Vector3(-3.93, 0.8, -2.34)   # the old man's face on the pillow
	# 1. the bedroom at night, the old man asleep
	_op_pose(Vector3(-2.2, 1.42, -0.7), Vector3(-3.5, 0.72, -2.25))
	_op_move(Vector3(-2.3, 1.38, -0.85), Vector3(-3.5, 0.72, -2.25), 6.0)
	Game.fade_in(1.2)
	Game.captions.show_line(StoryText.OPENING[0][0], StoryText.OPENING[0][1])
	await _op_wait(4.2, "op_1_bedroom.png")
	# 2. the breaker box in the living room: a spark, the lever drops, the house goes dark
	_op_pose(Vector3(0.5, 1.47, 1.62), Vector3(-0.36, 1.3, 2.2))
	_op_cam.fov = 40.0
	_op_move(Vector3(0.4, 1.45, 1.72), Vector3(-0.36, 1.3, 2.2), 2.6)
	await _op_wait(0.7, "op_2_breaker_on.png")
	var spark := OmniLight3D.new()
	spark.light_color = Color(0.85, 0.95, 1.0)
	spark.omni_range = 0.5 * K
	add_child(spark)
	spark.global_position = Vector3(-0.28, 1.36, 2.24) * K
	_op_track(create_tween()).tween_property(spark, "light_energy", 0.0, 0.35).from(7.0)
	_op_track(create_tween()).tween_property($Stop6/BreakerLever, "rotation_degrees:z", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	audio.sfx("音效/开场_配电箱跳闸.ogg", -2.0)
	await _op_wait(0.12)
	_power_cut()
	audio.sfx("音效/开场_灯灭_01.ogg", -6.0)
	await _op_wait(1.5, "op_3_breaker_tripped.png")
	# 3. back in the bedroom: the night light dies, moonlight only
	_op_cam.fov = 50.0
	_op_pose(Vector3(-2.3, 1.38, -0.85), Vector3(-3.5, 0.72, -2.25))
	await _op_wait(0.5)
	var fl := _op_track(create_tween())
	for e in [0.2, 1.1, 0.05, 0.7, 0.0]:
		fl.tween_property(_night_light, "light_energy", e, 0.07)
	audio.sfx("音效/开场_灯灭_02.ogg", -8.0)
	_op_track(create_tween()).tween_property($PostFX, "loss_cap", 1.0, 2.0)
	await _op_wait(2.0, "op_4_dark.png")
	# 4. push in on the tin robot, slumped on the nightstand
	_op_move(Vector3(-3.0, 0.84, -2.21), robot, 4.5)
	await _op_wait(4.6, "op_5_robot_off.png")
	# 5. it wakes: the eyes flicker on, the cells fill, the head comes up
	for t in [0.1, 0.25, 0.08, 0.45]:
		player.powered_down = not player.powered_down
		await _op_wait(t)
	player.powered_down = false
	audio.sfx("音效/机器人_启动.ogg", -4.0)
	_op_track(create_tween()).tween_method(_op_charge, 0.0, 1.0, 2.2)
	_op_move(Vector3(-3.04, 0.82, -2.235), robot, 3.0)
	await _op_wait(1.2)
	player.pose_override = [0.0, 0.0, -6.0, 3.0, 3.0, 0.0, 0.0]
	await _op_wait(1.2, "op_6_awake.png")
	await _op_say("0-1")
	# 6. it turns to the bed: the old man asleep. That's me.
	player._face_yaw = atan2(face.x - robot.x, face.z - robot.z)
	_op_move(Vector3(-3.05, 0.86, -2.2), face, 1.6)
	await _op_wait(1.8)
	await _op_say("0-2", "op_7_bed.png")
	_op_move(Vector3(-3.45, 0.84, -2.3), face, 3.2)
	await _op_wait(0.6)
	await _op_say("0-3", "op_8_face.png")
	# 7. ...then who's this? It looks down at its own tin hands
	_op_pose(Vector3(-3.37, 0.9, -2.25), robot + Vector3(0, -0.02, 0))
	player.pose_override = [0.0, 0.0, 30.0, 10.0, 10.0, 80.0, 80.0]
	await _op_say("0-4", "op_9_hands.png")
	# 8. it turns to the desk; the camera settles behind it, and it's yours
	player.pose_override = []
	player._face_yaw = PI / 2
	await _op_wait(0.6)
	_end_opening(pcam)

## A line of the opening: on screen for as long as it takes to read, then a short beat.
func _op_say(id: String, shot := "") -> void:
	var text: String = StoryText.MONOLOGUE[id]
	Game.captions.say(id)
	await _op_wait(0.9, shot)
	await _op_wait(preload("res://scripts/captions.gd").line_time(id) + 0.4)

func _op_charge(c: float) -> void:
	player.charge = c
	player.charge_changed.emit(c)

## Skip / end of the opening: every light and switch in its after-the-blackout state, control back.
func _end_opening(pcam: Camera3D) -> void:
	if opening_done:
		return
	opening_done = true
	for t in _op_tweens:
		if t.is_valid():
			t.kill()
	if _op_skip:
		_power_cut()
		$Stop6/BreakerLever.rotation_degrees.z = 0.0
		_night_light.light_energy = 0.0
		$PostFX.loss_cap = 1.0
		player.powered_down = false
		player.pose_override = []
		player._face_yaw = PI / 2
		Game.fade_in(0.4)
	_op_charge(1.0)
	var from := _op_cam.global_transform
	await create_tween().tween_method(func(t: float): _op_cam.global_transform = from.interpolate_with(pcam.global_transform, t), 0.0, 1.0, 0.3 if _op_skip else 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	pcam.make_current()
	_op_cam.queue_free()
	player.locked = false
	audio.music("音乐/主旋律_探索_循环.ogg", 4.0, -12.0)
	Game.captions.show_controls()

func _power_cut() -> void:
	for i in range(1, 11):
		get_node("HouseLight%d" % i).light_energy = 0.0
	$Stop6/BreakerFault.visible = true
	$Stop6/BreakerOk.visible = false
	$BreakerFaultLight.visible = true

func _op_track(t: Tween) -> Tween:
	_op_tweens.append(t)
	return t

var _op_cam_tw: Tween

func _op_pose(pos: Vector3, look: Vector3) -> void:
	if _op_cam_tw and _op_cam_tw.is_valid():
		_op_cam_tw.kill()
	_op_cam.global_transform = Transform3D(Basis.IDENTITY, pos * K).looking_at(look * K)

func _op_move(pos: Vector3, look: Vector3, time: float) -> void:
	var to := Transform3D(Basis.IDENTITY, pos * K).looking_at(look * K)
	if _op_cam_tw and _op_cam_tw.is_valid():
		_op_cam_tw.kill()
	_op_cam_tw = _op_track(create_tween())
	_op_cam_tw.tween_property(_op_cam, "global_transform", to, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## A beat of the opening; returns at once once it has been skipped (jump or E). Takes a test shot if asked.
func _op_wait(t: float, shot := "") -> void:
	var left := t
	while left > 0.0 and not _op_skip:
		await get_tree().process_frame
		left -= get_process_delta_time()
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact"):
			_op_skip = true
	if _op_skip:
		if not opening_done:
			_end_opening(_player_cam())
		while not opening_done:
			await get_tree().process_frame
		return
	if shot != "" and _op_dir != "":
		await _shot(_op_dir, shot)

func _shot_if(dir: String, n: String, after: float) -> void:
	await _wait(after)
	if dir != "":
		await _shot(dir, n)

# ------------------------------------------------------------------ stop 1
## Jack-in-the-box: the clown head bursts out (a little scare) and flings the robot onto the shoebox.
func _jack() -> void:
	if jack_busy:
		return
	jack_busy = true
	player.locked = true
	var head: Node3D = $Stop1/JackHead
	var h0 := _jack_home
	await get_tree().create_timer(0.25).timeout
	var pop := create_tween().set_parallel()
	pop.tween_property(head, "position", h0 + Vector3(0, 0.22 * K, 0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(head, "scale", Vector3.ONE * 1.6, 0.12)
	_say_once("1-3")
	audio.sfx("音效/第1站_玩偶匣弹出.ogg", -4.0)
	player.launch_squash()
	await _arc(player.global_position, $ShelfTarget.global_position, 2.2, 0.9)
	player.velocity = Vector3.ZERO
	player.locked = false
	Game.set_checkpoint($Checkpoints/BoxShelf)
	await get_tree().create_timer(1.2).timeout
	var back := create_tween().set_parallel()  # the head wobbles back into its box
	back.tween_property(head, "position", h0, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	back.tween_property(head, "scale", Vector3.ONE, 0.6)
	await back.finished
	jack_busy = false

## The exit machine. Powered with the robot's own charge (the Interactable takes it); the car drives
## to the drum, the drum drops onto the seesaw, whoever stands on the other end is thrown onto the desk.
func _run_machine() -> void:
	if machine_busy:
		return
	machine_busy = true
	_say_once("1-5")
	audio.loop("音效/第1站_电动小车_循环.ogg", true, -10.0)
	var car: Node3D = $Stop1/ElectricCar
	var drum: Node3D = $Stop1/Drum
	var saw: Node3D = $Stop1/Seesaw
	var drive := create_tween()
	var from := car.position
	var car_yaw := car.rotation.y
	for w in [$CarWay1, $CarWay2, $CarWay3, $CarWay4]:
		var to: Vector3 = w.position
		var dir := to - from
		var yaw := atan2(-dir.x, -dir.z)
		car_yaw += wrapf(yaw - car_yaw, -PI, PI)   # the short way round
		drive.tween_property(car, "rotation:y", car_yaw, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # turn at the corner
		drive.tween_property(car, "position", to, dir.length() / (0.15 * K)).set_trans(Tween.TRANS_LINEAR)
		from = to
	await drive.finished
	audio.loop("音效/第1站_电动小车_循环.ogg", false)
	var fall := create_tween().set_parallel()  # the drum tips west off the robot's head onto the raised end
	fall.tween_property(drum, "position", $DrumLanding.position, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(drum, "rotation_degrees:z", 85.0, 0.45)
	await fall.finished
	audio.sfx("音效/第1站_鼓砸跷跷板.ogg", -4.0)
	var on_end: bool = $Areas/SeesawEnd.overlaps_body(player)
	_dbg_on_end = [on_end, player.global_position / K]
	if on_end:
		player.locked = true
	create_tween().tween_property(saw, "rotation_degrees:z", -12.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if on_end:
		player.launch_squash()
		Game.captions.say("1-6", 1.4)
		audio.sfx("音效/第1站_跷跷板弹射.ogg", -4.0)
		audio.loop("音效/第1站_玩具火车_循环.ogg", false)
		await _arc(player.global_position, $DeskLanding.global_position, 5.0, 1.7)
		player.velocity = Vector3.ZERO
		player.locked = false
		launched = true
		Game.set_checkpoint($Checkpoints/Desk)
		_enter_desk()
	# reset the machine for another try (or for show if the robot made it)
	await get_tree().create_timer(1.5).timeout
	for n in _machine_home:
		var node: Node3D = get_node("Stop1/" + n)
		create_tween().tween_property(node, "transform", _machine_home[n], 0.6)
	await get_tree().create_timer(0.7).timeout
	machine_busy = false

# ------------------------------------------------------------------ stop 2
## Landing on the desk: show the goal (the door handle), the desk lamp dies, the room goes dark,
## the camera rises overhead. W walks south, towards the door.
## Landing on the desk. Through the robot's own eyes: the boy doing his homework - me, at fifteen - the
## desk, the door handle at the far end. Then the lamp dies, and in the dark the desk is a maze.
func _enter_desk() -> void:
	player.locked = true
	_look_at($DoorLook.global_position, -12.0, 0.01)   # the robot's camera, for after
	player._face_yaw = PI   # facing the boy (south)
	var eye := player.global_position + Vector3(0, 0.085 * K, 0)
	var boy := Vector3(-1.36, 1.16, 0.5) * K          # his face, bent over the homework
	var page := Vector3(-1.3, 0.78, 0.15) * K         # the homework on the desk
	var door: Vector3 = $DoorLook.global_position
	_fp_desk = Camera3D.new()
	add_child(_fp_desk)
	_fp_desk.fov = 62.0
	_fp_desk.global_transform = Transform3D(Basis.IDENTITY, eye).looking_at(page)
	_fp_desk.make_current()
	player.visual.visible = false   # we're inside its head
	audio.loop("音效/第2站_台灯嗡鸣_循环.ogg", true, -16.0)
	audio.loop("音效/第2站_笔尖写字_循环.ogg", true, -18.0)
	# it looks up from the desk to his face
	await _fp_turn(eye, boy, 1.6)
	await _wait(0.3)
	await Game.captions.say("2-1")
	_fp_turn(eye + Vector3(0, 0.01 * K, 0.03 * K), boy, 2.4)   # a little lean in
	await Game.captions.say("2-2")
	# along the desk, to the door handle at the far end
	await _fp_turn(eye, page.lerp(door, 0.5), 1.4)
	await _fp_turn(eye, door, 1.2)
	await _wait(1.0)
	var g: OmniLight3D = $DeskLampGlow
	audio.loop("音效/第2站_台灯嗡鸣_循环.ogg", false)
	audio.loop("音效/第2站_笔尖写字_循环.ogg", false)
	audio.sfx("音效/第2站_台灯开关.ogg", -4.0)
	for e in [0.3, 2.2, 0.15, 1.6, 0.05, 0.9, 0.0]:
		g.light_energy = e
		await get_tree().create_timer(0.09).timeout
	var env: Environment = $WorldEnvironment.environment
	_env_saved = [env.ambient_light_energy, $Moonlight.light_energy]
	var dark := create_tween().set_parallel()
	dark.tween_property(env, "ambient_light_energy", 0.07, 1.2)
	dark.tween_property($Moonlight, "light_energy", 0.04, 1.2)
	maze.visible = true   # in the dark, the desk becomes the maze
	if has_node("Stop2/DeskNormal"):   # (its tidy "before" dressing, if the art is in: docs/art_brief_desk_normal.md)
		$Stop2/DeskNormal.visible = false
	await Game.captions.say("2-3")
	for n in ["WallLampShade", "WallLampArm"]:  # it would sit between the overhead camera and the desk
		get_node("Stop2/" + n).visible = false
	player.set_top_down(true, -PI / 2)  # desk lies across the screen: D walks right, towards the door
	player.visual.visible = true
	await get_tree().process_frame
	var pcam := _player_cam()
	var from := _fp_desk.global_transform
	await create_tween().tween_method(func(t: float): _fp_desk.global_transform = from.interpolate_with(pcam.global_transform, t), 0.0, 1.0, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	pcam.make_current()
	_fp_desk.queue_free()
	_fp_desk = null
	player.locked = false
	in_desk = true
	audio.music("音乐/第2站_书桌迷宫_恐怖_循环.ogg", 3.0, -12.0)

## The desk's first-person look: turn the eye to `at` over `time`.
func _fp_turn(eye: Vector3, at: Vector3, time: float) -> void:
	var to := Transform3D(Basis.IDENTITY, eye).looking_at(at)
	await create_tween().tween_property(_fp_desk, "global_transform", to, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished

## The lever handle: the robot steps onto it, its weight presses it down, the door swings open,
## the robot drops onto the living-room floor; the camera comes back down and finds the breaker box.
func _open_door() -> void:
	if door_open:
		return
	door_open = true
	player.locked = true
	var handle: Node3D = $Stop2/DoorPivot/Handle
	var lever_end: Vector3 = handle.global_position + Vector3(0, 0.15, -0.12 * K)
	await _arc(player.global_position, lever_end, 0.6, 0.45)
	audio.sfx("音效/门_扭把手加开门_完整.ogg", -4.0)
	create_tween().tween_property($Stop2/DoorGapGlow, "transparency", 1.0, 0.6)   # the light under the door: gone once it's open
	audio.ambience("环境声/阶段混音2_青年_窗外_循环.ogg")
	create_tween().tween_property(handle, "rotation_degrees:x", -35.0, 0.2).set_trans(Tween.TRANS_BACK)
	player.launch_squash()
	await get_tree().create_timer(0.3).timeout
	# one shot from the living-room floor: the door swings open, the robot drops through the gap, lands,
	# looks up at the breaker box, then over at the blue light of the TV (no cut across the wall between)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 58.0
	var drop: Vector3 = $OpenPlanDrop.global_position / K
	cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(drop.x + 0.55, 0.32, drop.z - 0.25) * K).looking_at(Vector3(-0.42, 0.62, 1.32) * K)
	cam.make_current()
	in_desk = false
	player.set_top_down(false)
	audio.music("音乐/主旋律_探索_循环.ogg", 3.0, -12.0)
	for n in ["WallLampShade", "WallLampArm"]:
		get_node("Stop2/" + n).visible = true
	var env: Environment = $WorldEnvironment.environment
	var light := create_tween().set_parallel()
	light.tween_property(env, "ambient_light_energy", _env_saved[0], 1.5)
	light.tween_property($Moonlight, "light_energy", _env_saved[1], 1.5)
	await create_tween().tween_property($Stop2/DoorPivot, "rotation_degrees:y", -75.0, 0.9) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).finished
	var follow := create_tween()   # the camera tips down with the fall
	follow.tween_property(cam, "global_transform", Transform3D(Basis.IDENTITY, Vector3(drop.x + 0.5, 0.26, drop.z - 0.2) * K).looking_at((drop + Vector3(0, 0.05, 0)) * K), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _arc(player.global_position, $OpenPlanDrop.global_position, 1.0, 0.8)
	player.velocity = Vector3(0, -2.0, 0)
	audio.sfx("音效/机器人_落地_02.ogg", -6.0)
	Game.set_checkpoint($Checkpoints/OpenPlan)
	await _wait(0.5)
	# up at the breaker box on the wall: that's what's gone
	var box: Vector3 = $BreakerLook.global_position / K
	var fault: OmniLight3D = $BreakerFaultLight
	var f0 := [fault.light_energy, fault.omni_range]
	fault.omni_range = 1.4 * K
	create_tween().tween_property(fault, "light_energy", 3.0, 1.0)   # the red fault light, bright enough to read
	var box_fill := OmniLight3D.new()   # a little cold moonlight on the box so its shape reads in the dark
	box_fill.light_color = Color(0.6, 0.7, 1.0)
	box_fill.omni_range = 0.7 * K
	add_child(box_fill)
	box_fill.global_position = Vector3(BW_M + 0.4, 1.5, 2.3) * K
	create_tween().tween_property(box_fill, "light_energy", 1.4, 1.0)
	var tw := create_tween()   # across the room to the spot that frames the box (the finale's own camera)
	tw.tween_property(cam, "global_transform", Transform3D(Basis.IDENTITY, Vector3(BW_M + 0.62, 1.32, 2.62) * K).looking_at(Vector3(BW_M + 0.05, 1.25, 2.2) * K), 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _wait(1.8)
	await Game.captions.say("2-13")
	create_tween().tween_property(fault, "light_energy", f0[0], 1.5)
	fault.omni_range = f0[1]
	var fade_fill := create_tween()
	fade_fill.tween_property(box_fill, "light_energy", 0.0, 1.5)
	fade_fill.tween_callback(box_fill.queue_free)
	# ...and over to the blue light of the TV: go there first
	player._face_yaw = atan2($TvLook.global_position.x - player.global_position.x, $TvLook.global_position.z - player.global_position.z)
	var tv: Vector3 = $TvLook.global_position / K
	tw = create_tween()
	tw.tween_property(cam, "global_transform", Transform3D(Basis.IDENTITY, (drop + Vector3(-0.12, 0.14, 0.18)) * K).looking_at(tv * K), 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _wait(1.0)
	await Game.captions.say("2-14")
	_look_at($TvLook.global_position, -6.0, 0.01)   # the robot's own camera, behind it, facing the TV
	await get_tree().process_frame
	var pcam := _player_cam()
	var from := cam.global_transform
	await create_tween().tween_method(func(t: float): cam.global_transform = from.interpolate_with(pcam.global_transform, t), 0.0, 1.0, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	pcam.make_current()
	cam.queue_free()
	player.locked = false
	await _wait(0.6)
	Game.captions.say_all(["3-1", "3-2"])

# ------------------------------------------------------------------ stop 3
func _player_cam() -> Camera3D:
	return player.get_node("CamPivot/SpringArm3D/Camera3D")

## E at the screen: the camera pushes into the glass, the robot hops at it and shrinks into it,
## static + flash, and the pixel robot drops into the game.
## On the cabinet in front of the screen: it turns round and looks back at him on the sofa, twenty-two,
## controller in his hands. Then the screen crackles and pulls it in.
func _tv_approach() -> void:
	tv_pulling = true
	player.locked = true
	var tv: TvScreen = $Stop3/TvScreen
	var p := player.global_position / K
	var him := Vector3(1.3, 1.0, -1.15)   # his face, lit by the screen
	player._face_yaw = atan2(him.x - p.x, him.z - p.z)
	await _cinematic_hold([
		# from beside the screen, over the robot's shoulder, to him
		[p + Vector3(-0.1, 0.12, -0.06), him, 1.3, 0.4],
		[p + Vector3(-0.06, 0.1, 0.05), him, 2.6, 0.0],
	], ["3-4"])
	player._face_yaw = atan2(tv.global_position.x / K - p.x, tv.global_position.z / K - p.z)
	tv.zap(0.4)
	Game.captions.say("3-5")
	await _wait(0.7)
	_enter_tv()

## Like _cinematic, but holds on the last pose until the given lines have been said; leaves the camera
## on the last pose (the caller takes it from there).
func _cinematic_hold(poses: Array, lines: Array) -> void:
	var pcam := _player_cam()
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = pcam.fov
	cam.global_transform = pcam.global_transform
	cam.make_current()
	for p in poses:
		var to := Transform3D(Basis.IDENTITY, p[0] * K).looking_at(p[1] * K)
		var tw := create_tween()
		tw.tween_property(cam, "global_transform", to, p[2]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if p == poses[poses.size() - 1]:
			await _wait(0.4)
			await Game.captions.say_all(lines)
			if tw.is_valid() and tw.is_running():
				await tw.finished
		else:
			await tw.finished
			await _wait(p[3])
	var from := cam.global_transform
	await create_tween().tween_method(func(t: float): cam.global_transform = from.interpolate_with(pcam.global_transform, t), 0.0, 1.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	pcam.make_current()
	cam.queue_free()

func _enter_tv() -> void:
	audio.sfx("音效/第3站_进入电视穿梭.ogg", -4.0)
	var tv: TvScreen = $Stop3/TvScreen
	player.locked = true
	Game.set_checkpoint($Checkpoints/TvTop)
	var pcam := _player_cam()
	_tv_cam = Camera3D.new()
	add_child(_tv_cam)
	_tv_cam.fov = pcam.fov
	_tv_cam.global_transform = pcam.global_transform
	_tv_cam.make_current()
	var push := create_tween()
	push.tween_property(_tv_cam, "global_transform", tv.camera_spot(_tv_cam.fov), 1.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _wait(0.9)
	player.launch_squash()
	create_tween().tween_property(player.visual, "scale", Vector3.ONE * 0.05, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _arc(player.global_position, tv.global_position + Vector3(0, -0.4, 0), 0.5, 0.6)
	player.visual.visible = false
	tv.zap()
	$PostFX.enabled = false
	await push.finished
	tv.game.start()
	Game.captions.subtitles_top(true)   # the 2D game fills the screen: his words go up top, clear of the play
	audio.music("音乐/第3站_电视8bit_循环.ogg", 0.6, -10.0)
	in_tv = true

## The tin box at the top of the dragon's tower: the game loses its colour (and its power) and lets go
## of the robot; once it is out, the TV switches itself off.
func _tv_finale() -> void:
	var tv: TvScreen = $Stop3/TvScreen
	tv_finale = true
	audio.sfx("音效/第3站_8bit_救出公主.ogg", -6.0)
	audio.music("", 2.0)
	Game.captions.say("3-13")
	var said_by := Time.get_ticks_msec() + int(preload("res://scripts/captions.gd").line_time("3-13") * 1000.0)
	var fade := create_tween().set_parallel()
	fade.tween_method(func(v): tv.mat.set_shader_parameter("desat", v), 0.0, 1.0, 2.2)
	fade.tween_method(func(v): tv.mat.set_shader_parameter("glow", v), 1.5, 0.9, 2.2)
	await fade.finished
	await _wait(0.4)
	while Time.get_ticks_msec() < said_by + 300:   # stay in the game till he's said it
		await get_tree().process_frame
	tv.game.stop()
	await _exit_tv()
	await _wait(0.6)
	create_tween().tween_method(func(v): tv.mat.set_shader_parameter("power", v), 1.0, 0.0, 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	create_tween().tween_property($TVGlow, "light_energy", 0.0, 0.5)
	audio.sfx("音效/第3站_电视关机.ogg", -6.0)
	await Game.captions.say("3-14")
	await _wait(0.3)
	_look_at($Stop3/TimeBoxGlow.global_position, -20.0, 1.2)   # then: the old time box beside the cabinet
	_say_once("3-15")

## The childhood time box beside the cabinet: the lid lifts, a warm light; inside, his drawing.
func _open_time_box() -> void:
	time_box_open = true
	create_tween().tween_property($Stop3/TimeBoxLid, "rotation_degrees:x", -105.0, 0.8) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	create_tween().tween_property($Stop3/TimeBoxGlow, "light_energy", 2.0, 1.2)
	Game.restore_memory("time_box")
	audio.sfx("音效/第3站_时光盒打开.ogg", -6.0)
	audio.phrase("音乐/旋律片段3_答录机.ogg", -8.0)
	await _wait(0.8)
	await Game.captions.say_all(["3-16", "3-17"])
	_box_pos = player.global_position
	_box_lines_done = true   # a few steps on, the kitchen (see _process)

## Out of the game: the robot pops out of the glass and lands on the floor on the kitchen
## side; the camera pulls back out to the robot's own camera, which then turns to the stove.
func _exit_tv() -> void:
	Game.captions.subtitles_top(false)
	audio.sfx("音效/第3站_离开电视穿梭.ogg", -4.0)
	audio.music("音乐/主旋律_探索_循环.ogg", 4.0, -12.0)
	var tv: TvScreen = $Stop3/TvScreen
	in_tv = false
	tv_done = true
	tv.zap(0.6)
	player.teleport(tv.global_position + Vector3(0.5 * K * 0.48 * 0.8, -0.3, 0.15))
	player.visual.visible = true
	create_tween().tween_property(player.visual, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	player.launch_squash()
	var d: Vector3 = $StoveLook.global_position - $TvExitLanding.global_position
	player.cam_pivot.rotation.y = atan2(-d.x, -d.z)
	player.spring.rotation.x = deg_to_rad(-12.0)
	player._face_yaw = atan2(d.x, d.z)
	var pcam := _player_cam()
	var from := _tv_cam.global_transform
	var pull := create_tween()
	pull.tween_method(func(t: float): _tv_cam.global_transform = from.interpolate_with(pcam.global_transform, t), 0.0, 1.0, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _arc(player.global_position, $TvExitLanding.global_position, 1.2, 0.9)
	player.velocity = Vector3.ZERO
	await pull.finished
	pcam.make_current()
	_tv_cam.queue_free()
	_tv_cam = null
	$PostFX.enabled = true
	Game.set_checkpoint($Checkpoints/TvExit)
	player.locked = false

# ------------------------------------------------------------------ stop 4
## Burner i (0 = west, 1 = east): ["warn" | "on" | "off", seconds into that state]. They alternate.
func flare_state(i: int) -> Array:
	var t := fposmod(_fire_t + (FLARE_PERIOD / 2.0 if i == 1 else 0.0), FLARE_PERIOD)
	if t < 0.6:
		return ["warn", t]
	if t < 1.6:
		return ["on", t - 0.6]
	return ["off", t - 1.6]

## Out of the TV: the orange glow of the stove, then the kitchen reveal (from here the view is open).
func _after_tv_looks() -> void:
	audio.ambience("环境声/阶段混音3_中年_窗外_循环.ogg")
	player.locked = true
	_look_at($StoveLook.global_position, -8.0, 1.5)
	await _wait(1.0)
	await Game.captions.say("4-1")
	_look_at($FatherHead.global_position, -4.0, 1.4)
	await _wait(0.8)
	await Game.captions.say_all(["4-2", "4-3"])
	player.locked = false
	if not kitchen_revealed:
		_kitchen_reveal()

## First steps towards the kitchen: the tap left running and the water spreading over the floor, then the
## windowsill on the far side - the way home is over the counters.
func _kitchen_reveal() -> void:
	kitchen_revealed = true
	await _cinematic([
		[Vector3(2.9, 1.55, -0.9), $SinkLook.global_position / K + Vector3(0, -0.15, 0), 1.4, 0.2, "4-4"],  # the sink, the flood
		[Vector3(2.4, 1.6, -1.2), $SillLook.global_position / K, 1.3, 0.2, "4-5"],                         # the way home
	])

## A short camera move: poses = [position (m), look-at (m), move seconds, hold seconds]. Starts and ends on
## the robot's own camera; the robot can't move meanwhile.
func _cinematic(poses: Array) -> void:
	player.locked = true
	var pcam := _player_cam()
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = pcam.fov
	cam.global_transform = pcam.global_transform
	cam.make_current()
	for p in poses:
		var to := Transform3D(Basis.IDENTITY, p[0] * K).looking_at(p[1] * K)
		await create_tween().tween_property(cam, "global_transform", to, p[2]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
		if p.size() > 4:   # [.., line id]: hold for as long as the line takes
			await Game.captions.say(p[4])
		await _wait(p[3])
	var from := cam.global_transform
	await create_tween().tween_method(func(t: float): cam.global_transform = from.interpolate_with(pcam.global_transform, t), 0.0, 1.0, 1.0) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	pcam.make_current()
	cam.queue_free()
	player.locked = false

## Powered microwave: beep, the door pops open and shoves the cutting board across the gap.
func _microwave() -> void:
	audio.sfx("音效/第4站_微波炉开门推砧板.ogg", -4.0)
	get_tree().create_timer(0.9).timeout.connect(func(): audio.sfx("音效/第4站_微波炉叮.ogg", -8.0))
	Game.captions.say("4-8")
	board_pushed = true
	var door: Node3D = $Stop4/MicrowaveDoor
	await create_tween().tween_property(door, "rotation_degrees:y", 72.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).finished
	var board: Node3D = $Stop4/CuttingBoard
	create_tween().tween_property(board, "position:x", board.position.x + 0.39 * K, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Powered toaster: the robot drops into the slot, the coils glow, tick tick... ding - up onto the spice shelf.
func _toaster() -> void:
	if toaster_busy:
		return
	toaster_busy = true
	player.locked = true
	Game.captions.say("4-9")
	audio.sfx("音效/第4站_面包机压杆.ogg", -6.0)
	audio.loop("音效/第4站_面包机计时_循环.ogg", true, -10.0)
	await _arc(player.global_position, $ToasterSlot.global_position, 0.25, 0.3)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.08, 0.05)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.35, 0.1)
	m.emission_energy_multiplier = 0.0
	$Stop4/ToasterCoils.material = m
	await create_tween().tween_property(m, "emission_energy_multiplier", 4.0, 1.6).finished
	player.launch_squash()
	Game.captions.say("4-10")
	audio.loop("音效/第4站_面包机计时_循环.ogg", false)
	audio.sfx("音效/第4站_面包机弹起.ogg", -4.0)
	await _arc(player.global_position, $SpiceShelfLanding.global_position, 1.4, 0.7)
	player.velocity = Vector3.ZERO
	player.locked = false
	on_spice_shelf = true
	player.magnet_enabled = true  # the steel hood is right there: the claws can become an electromagnet
	get_tree().create_timer(2.2).timeout.connect(func(): _say_once("4-11"))
	Game.set_checkpoint($Checkpoints/SpiceShelf)
	create_tween().tween_property(m, "emission_energy_multiplier", 0.0, 2.0)
	toaster_busy = false

func _kettle_look(b: Node) -> void:
	if b == player and not has_meta("kettle_look") and not player.locked:
		set_meta("kettle_look", true)
		_look_at(Vector3(4.5, 1.15, -0.6) * K, -12.0, 1.2)

## The kettle: E powers it, the switch light comes on, it rumbles, then steam for a few seconds (whistling).
func _kettle() -> void:
	audio.sfx("音效/第4站_水壶加热震动.ogg", -6.0)
	get_tree().create_timer(1.6).timeout.connect(func():
		audio.sfx("音效/第4站_水壶鸣笛.ogg", -8.0)
		audio.loop("音效/第4站_水壶烧开_循环.ogg", true, -12.0))
	get_tree().create_timer(14.0).timeout.connect(func(): audio.loop("音效/第4站_水壶烧开_循环.ogg", false))
	Game.captions.say("4-13")
	if kettle_busy:
		return
	kettle_busy = true
	var k: Node3D = $Stop4/Kettle
	var home := k.position
	$Stop4/KettleLight.material = _glow_mat(Color(1.0, 0.45, 0.15), 3.0)
	var shake := create_tween()
	for i in 10:
		shake.tween_property(k, "position", home + Vector3(randf_range(-0.03, 0.03), 0, randf_range(-0.03, 0.03)), 0.08)
	shake.tween_property(k, "position", home, 0.08)
	await shake.finished
	steam_left = STEAM_SECONDS
	await _wait(STEAM_SECONDS)
	$Stop4/KettleLight.material = null
	kettle_busy = false

func _glow_mat(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m

## The sink: the robot steps onto the lid and the whole pile comes down - one thing after another, faster
## and faster (all clatter). The robot rides the lid off onto the counter, the plug pops, the flood
## drains away; the last lid spins in the basin, slower, and stops. Then quiet.
func _sink_collapse() -> void:
	audio.sfx("音效/第4站_水槽崩塌.ogg", -2.0)
	get_tree().create_timer(2.5).timeout.connect(func(): Game.captions.say("4-15"))
	sink_done = true
	player.locked = true
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = _player_cam().fov
	cam.global_transform = _player_cam().global_transform
	cam.make_current()
	create_tween().tween_property(cam, "global_transform",
		Transform3D(Basis.IDENTITY, $SinkCam.global_position).looking_at(Vector3(4.45, 0.85, 0.15) * K), 0.8).set_trans(Tween.TRANS_SINE)
	var fall := [  # piece, tilt (x, z degrees), drop (m), beat (s)
		["DishLid", Vector3(-14, 0, 6), 0.0, 0.0],
		["DishBowlB", Vector3(0, 0, -70), 0.1, 0.45],
		["DishBowlA", Vector3(60, 0, 20), 0.1, 0.32],
		["DishLadle", Vector3(0, 40, 80), 0.18, 0.26],
		["DishPlates", Vector3(-35, 0, -25), 0.05, 0.22],
		["DishPot", Vector3(-75, 0, 0), 0.08, 0.18]]
	for i in fall.size():
		var f: Array = fall[i]
		await _wait(f[3])
		var n: Node3D = get_node("Stop4/" + f[0])
		var tw := create_tween().set_parallel()
		tw.tween_property(n, "rotation_degrees", f[1], 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(n, "position:y", n.position.y - f[2] * K, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if i == 1:  # the lid tips the robot off, onto the counter south of the sink
			player.launch_squash()
			_arc_tween(player.global_position, $SinkLanding.global_position, 1.2, 0.8)
	# the lid drops into the basin and spins
	var lid: Node3D = $Stop4/DishLid
	create_tween().tween_property(lid, "position", Vector3(4.45, 0.75, 0.2) * K, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	create_tween().tween_property(lid, "rotation_degrees", Vector3(0, 0, 0), 0.3)
	var spin := create_tween()
	spin.tween_method(func(a: float): lid.rotation.y = a, 0.0, TAU * 6.0, 3.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	spin.parallel().tween_method(func(w: float): lid.rotation.x = sin(lid.rotation.y * 2.0) * w, 0.12, 0.0, 3.2)
	# the plug pops out; the water drains away
	await _wait(0.4)
	var plug: Node3D = $Stop4/SinkPlug
	var pop := create_tween()
	pop.tween_property(plug, "position:y", plug.position.y + 0.12 * K, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop.tween_property(plug, "position:y", plug.position.y + 0.01 * K, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_drain_flood()
	await spin.finished
	await _wait(0.6)
	var from := cam.global_transform
	await create_tween().tween_method(func(t: float): cam.global_transform = from.interpolate_with(_player_cam().global_transform, t), 0.0, 1.0, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	_player_cam().make_current()
	cam.queue_free()
	player.velocity = Vector3.ZERO
	player.locked = false
	Game.set_checkpoint($Checkpoints/SinkSouth)

## The flood goes: the water on the floor, in the gap, on the counter and in the basin sinks away.
func _drain_flood() -> void:
	audio.sfx("音效/第4站_塞子弹开.ogg", -4.0)
	get_tree().create_timer(0.4).timeout.connect(func(): audio.sfx("音效/第4站_积水流走.ogg", -6.0))
	Game.captions.say("4-16")
	for n in ["WaterFloor", "WaterGap", "WaterCounter"]:
		get_node("Stop4/" + n).enabled = false
	for n in ["FloodFloor", "FloodGap", "CounterWater", "SinkWater"]:
		var w: Node3D = get_node("Stop4/" + n)
		var tw := create_tween()
		tw.tween_property(w, "position:y", w.position.y - (0.17 if n == "SinkWater" else 0.02) * K, 2.6).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): w.visible = false)
	var spill: Node3D = $Stop4/SinkSpill
	create_tween().tween_property(spill, "scale:y", 0.01, 1.2)

## The daughter's mug by the window: one tap - a single clear note and a warm glow - and the camera finds
## the frozen father at the stove for a moment.
func _ring_mug() -> void:
	audio.sfx("音效/第4站_敲杯子一声.ogg", -2.0)
	audio.phrase("音乐/旋律片段4_八音盒.ogg", -8.0)
	mug_rung = true
	player.rig.kick_arms(-250.0, 0.0)
	var g: OmniLight3D = $Stop4/MugGlow
	var tw := create_tween()
	tw.tween_property(g, "light_energy", 3.0, 0.08)
	tw.tween_property(g, "light_energy", 0.8, 2.5)
	Game.restore_memory("daughter_mug")
	player.locked = true
	await Game.captions.say("4-17")
	_look_at($FatherHead.global_position, -2.0, 1.6)
	await _wait(0.6)
	await Game.captions.say("4-18")
	await _zipline_reveal()
	player.locked = false

## Up at the window: the clothesline. The camera runs along it - across the room, back to the window,
## along the window - to the breaker box at the far end. That's the way.
func _zipline_reveal() -> void:
	var zp: Zipline = $Stop5/Zipline
	var box: Vector3 = $Stop6/BreakerBox.global_position / K
	await _cinematic([
		[Vector3(4.0, 1.75, 1.6), zp.point(0.0) / K, 1.4, 0.2],                       # the coat hanger on the line
		[Vector3(3.2, 2.2, 1.4), zp.point(0.3) / K, 1.8, 0.2, "5-1"],                 # the line, across the room
		[Vector3(1.6, 2.1, 0.6), zp.point(0.75) / K, 2.0, 0.2],                       # back to the window
		[Vector3(0.8, 1.75, 1.7), box, 2.0, 0.4, "5-2"],                              # the breaker box at the end
	])

# ------------------------------------------------------------------ stop 5
## The town outside (scripts/town.gd): cheap MultiMeshes; its lights go out as the robot rides past.
func _build_town() -> void:
	town = Town.new()
	add_child(town)
	town.build()

## E at the coat hanger by the mug: up onto it, then the ride, seen through the robot's eyes.
func _zipline_grab() -> void:
	if not has_node("RadioVoice"):
		var radio := AudioStreamPlayer3D.new()
		radio.name = "RadioVoice"
		radio.stream = load("res://assets/audio/广播/第5站_广播连播.ogg")
		radio.bus = "SFX"
		radio.volume_db = -6.0
		radio.unit_size = 1.2 * K
		add_child(radio)
		radio.global_position = $Stop5/Radio.global_position
		radio.play()
		audio.sfx("音效/第5站_收音机调频.ogg", -12.0)
	var zip: Zipline = $Stop5/Zipline
	player.locked = true
	player.hanging = true
	player._face_yaw = -PI / 2  # facing west, down the line
	_zip_charge0 = player.charge
	player.launch_squash()
	await _arc(player.global_position, zip.rider_pos(), 0.5, 0.45)
	_fp_cam = Camera3D.new()
	add_child(_fp_cam)
	_fp_cam.fov = _player_cam().fov
	_fp_from = _player_cam().global_transform
	_fp_cam.global_transform = _fp_from
	_fp_cam.make_current()
	_fp_blend = 0.0
	_fp_yaw = 0.0
	await create_tween().tween_property(self, "_fp_blend", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	player.visual.visible = false  # we are inside its head now
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_speed_fx = ColorRect.new()
	_speed_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speed_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/speed_lines.gdshader")
	sm.set_shader_parameter("amount", 0.0)
	_speed_fx.material = sm
	layer.add_child(_speed_fx)
	for w in zip.wires:
		w.visible = false
	zip.clacked.connect(func(): _fp_shake = 1.0)
	zip.ride(player)
	audio.ambience("环境声/阶段混音4_老年_窗外_循环.ogg")
	Game.captions.say_all(["5-3", "5-4"])

## The robot's eyes on the line: facing the way it travels, a touch down; head turn, sway, shake.
func _fp_eye() -> Transform3D:
	var zip: Zipline = $Stop5/Zipline
	var fwd := zip.direction(zip.u)
	_fp_fwd = _fp_fwd.slerp(fwd, 0.08) if _fp_fwd != Vector3.ZERO else fwd  # turn smoothly at the corner hooks
	var yaw := atan2(-_fp_fwd.x, -_fp_fwd.z) + deg_to_rad(_fp_yaw)
	var pitch := deg_to_rad(-7.0 + sin(_fire_t * 2.3) * 1.0)
	var level := clampf(1.0 - absf(_fp_yaw) / 60.0, 0.0, 1.0)  # the frame levels out while it turns to look around
	var roll := (-zip.swing * 0.55 + deg_to_rad(sin(_fire_t * 1.7) * 1.5)) * level + randf_range(-1.0, 1.0) * 0.03 * _fp_shake
	var eye := player.global_position + Vector3(0, 0.8, 0) + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * (0.04 * _fp_shake + 0.012 * _fp_buzz * _fp_buzz)
	return Transform3D(Basis.from_euler(Vector3(pitch, yaw, roll), EULER_ORDER_YXZ), eye)

## Two slow looks. Crossing the room: time slows and the robot turns its head to the room - the kitchen,
## the stove, all the familiar things. On the last stretch along the window: it turns to the town outside,
## where it has lived all its life. Then time runs on.
func _slow_look(kind: String) -> void:
	slow_looks += 1
	Game.captions.say_all(["5-9", "5-10"] if kind == "in" else ["5-12", "5-13"])
	slow_look_done = slow_looks >= 2
	create_tween().set_ignore_time_scale(true).tween_property(Engine, "time_scale", 0.2, 0.6).set_trans(Tween.TRANS_SINE)
	# one last clear look: the grey low-power veil lifts while it looks around, and comes back after
	create_tween().set_ignore_time_scale(true).tween_property($PostFX, "loss_cap", 0.12, 1.2)
	var steps := [["in", -70.0, 1.6, 2.4]] if kind == "in" else [["out", 80.0, 1.6, 2.6]]
	var env: Environment = $WorldEnvironment.environment
	var fog0 := [env.fog_density, env.volumetric_fog_density]
	if kind == "out":  # the room's haze thins so the town's roofs read against the sky
		create_tween().set_ignore_time_scale(true).tween_property(env, "fog_density", 0.0008, 1.4)
		create_tween().set_ignore_time_scale(true).tween_property(env, "volumetric_fog_density", 0.0006, 1.4)
	for step in steps:  # what, head turn (deg; + = left), turn s, hold s (real time)
		await create_tween().set_ignore_time_scale(true).tween_property(self, "_fp_yaw", step[1], step[2]) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
		fp_phase = step[0]
		await get_tree().create_timer(step[3], true, false, true).timeout
		fp_phase = ""
	create_tween().set_ignore_time_scale(true).tween_property(Engine, "time_scale", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	create_tween().set_ignore_time_scale(true).tween_property($PostFX, "loss_cap", 1.0, 2.5)
	if kind == "out":
		create_tween().set_ignore_time_scale(true).tween_property(env, "fog_density", fog0[0], 2.5)
		create_tween().set_ignore_time_scale(true).tween_property(env, "volumetric_fog_density", fog0[1], 2.5)
	await create_tween().set_ignore_time_scale(true).tween_property(self, "_fp_yaw", 0.0, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	Engine.time_scale = 1.0

## The end of the line, by the bedroom door: back to third person, let go onto the sill, last cell left.
func _zipline_end() -> void:
	player.visual.visible = true
	get_tree().create_timer(1.6).timeout.connect(func(): Game.captions.say_all(["5-14", "5-15", "5-16"]))
	if _speed_fx:
		_speed_fx.get_parent().queue_free()
		_speed_fx = null
	for w in $Stop5/Zipline.wires:
		w.visible = true
	player.hanging = false
	var d: Vector3 = $BreakerLook.global_position - player.global_position
	player.cam_pivot.rotation.y = atan2(-d.x, -d.z)  # the robot's own camera, facing the breaker box
	player.spring.rotation.x = deg_to_rad(-8.0)
	await get_tree().process_frame
	_fp_from = _fp_cam.global_transform
	var cam := _fp_cam
	_fp_cam = null
	var pcam := _player_cam()
	await create_tween().tween_method(func(t: float): cam.global_transform = _fp_from.interpolate_with(pcam.global_transform, t), 0.0, 1.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	pcam.make_current()
	cam.queue_free()
	player.velocity = Vector3.ZERO
	player.locked = false
	zip_done = true
	await _wait(0.6)
	Game.set_checkpoint($Checkpoints/SillEnd)

# ------------------------------------------------------------------ stop 6: the finale and the ending
## Holding E at the breaker: the last charge flows out of the robot into the box; the lever creeps up.
func _breaker_progress(f: float) -> void:
	_pour_t = Time.get_ticks_msec()
	if _finale_music == null:
		_finale_music = AudioStreamPlayer.new()
		_finale_music.stream = load("res://assets/audio/音乐/终章_灌电.ogg")
		_finale_music.bus = "Music"
		_finale_music.volume_db = -6.0
		add_child(_finale_music)
		_finale_music.play(FINALE_FROM)   # the last phrase (the music box): its last note lands on the CLICK
		audio.music("", 2.0)
		audio.loop("音效/给机关充电_循环.ogg", true, -10.0)
	_finale_music.stream_paused = false
	if f >= 0.02:
		_say_once("6-2")
	if f >= 0.5:
		_say_once("6-3")
	if f >= 0.85:
		_say_once("6-4")
	if not finale_started:
		finale_started = true
		player.locked = true  # no way back now
		_finale_c0 = player.charge
		player._face_yaw = -PI / 2  # facing the box on the wall
		$Stop5/Zipline.hanger.visible = false
		var fc := Camera3D.new()  # from the room side: the robot, the box, the wire running up the wall
		fc.name = "FinaleCam"
		add_child(fc)
		fc.fov = 55.0
		var from_t := _player_cam().global_transform
		var to_t := Transform3D(Basis.IDENTITY, Vector3(BW_M + 0.62, 1.32, 2.62) * K).looking_at(Vector3(BW_M + 0.05, 1.2, 2.24) * K)
		fc.global_transform = from_t
		fc.make_current()
		create_tween().tween_method(func(t: float): fc.global_transform = from_t.interpolate_with(to_t, t), 0.0, 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_spark = OmniLight3D.new()
		_spark.light_color = Color(0.5, 1.0, 0.95)
		_spark.omni_range = 0.4 * K
		add_child(_spark)
		_spark.global_position = (player.global_position + $BreakerLook.global_position) / 2.0 + Vector3(0, 0.3, 0)
	player.charge = lerpf(_finale_c0, 0.0, f)
	player.charge_changed.emit(player.charge)
	$Stop6/BreakerLever.rotation_degrees.z = lerpf(0.0, 120.0, f * f)
	_spark.light_energy = (1.0 + 2.5 * f) * randf_range(0.6, 1.0)

## CLICK. The power is back: lights on from the breaker outwards, the grey veil lifts, the old things glow,
## the robot's eyes go dark. Then the ending.
func _breaker_done() -> void:
	finale_done = true
	audio.loop("音效/给机关充电_循环.ogg", false)
	audio.sfx("音效/终章_空气开关合上.ogg", 0.0)
	get_tree().create_timer(0.7).timeout.connect(func():
		audio.sfx("音效/终章_全屋亮灯.ogg", -2.0)
		audio.music("音乐/结局_亮灯之后.ogg", 2.5, -6.0))
	get_tree().create_timer(0.8).timeout.connect(func(): Game.captions.say("6-5"))
	var lever := create_tween()
	lever.tween_property($Stop6/BreakerLever, "rotation_degrees:z", 180.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	$Stop6/BreakerFault.visible = false
	$BreakerFaultLight.light_energy = 0.0
	$Stop6/BreakerOk.visible = true
	if _spark:
		_spark.light_color = Color(1, 1, 1)
		var flash := create_tween()
		flash.tween_property(_spark, "light_energy", 8.0, 0.05)
		flash.tween_property(_spark, "light_energy", 0.0, 0.5)
	player.charge = 0.0
	player.charge_changed.emit(0.0)
	player.powered_down = true
	player.alive = false  # slumps against the box (no "died": nothing respawns any more)
	create_tween().tween_property($PostFX, "loss_cap", 0.0, 2.5)
	town.set_all(false)
	_lights_on()
	await _wait(5.0)
	_ending_camera()

func _lights_on() -> void:
	await _wait(0.6)
	var bp: Vector3 = $BreakerLook.global_position
	var lamps := []
	for i in range(1, 11):
		lamps.append(get_node("HouseLight%d" % i))
	lamps.sort_custom(func(x, y): return x.global_position.distance_to(bp) < y.global_position.distance_to(bp))
	var env: Environment = $WorldEnvironment.environment
	create_tween().tween_property(env, "ambient_light_energy", 0.5, 3.0)
	for l in lamps:  # one by one, outwards: each flickers on
		var tw := create_tween()
		tw.tween_property(l, "light_energy", 1.6, 0.06)
		tw.tween_property(l, "light_energy", 0.3, 0.06)
		tw.tween_property(l, "light_energy", 1.3, 0.25)
		await _wait(0.28)
	for n in ["WindowSpill1", "WindowSpill2", "WindowSpill3"]:
		create_tween().tween_property(get_node(n), "light_energy", 4.0, 1.5)
	# the old things the robot found on its way glow warm
	get_tree().create_timer(1.0).timeout.connect(func(): Game.captions.say("6-6"))
	create_tween().tween_property($Stop3/TimeBoxGlow, "light_energy", 1.6, 1.5)
	create_tween().tween_property($Stop4/MugGlow, "light_energy", 1.4, 1.5)
	create_tween().tween_property($DeskLampGlow, "light_energy", 1.8, 1.5)
	for pos in [$Stop0/PhotoFrame.global_position + Vector3(0, 0.6, 0), maze.note.global_position + Vector3(0, 0.6, 0)]:
		var g := OmniLight3D.new()
		g.light_color = Color(1, 0.72, 0.38)
		g.omni_range = 0.6 * K
		add_child(g)
		g.global_position = pos
		create_tween().tween_property(g, "light_energy", 1.4, 1.5)

## The ending, one take: the robot by the box; back through the bedroom door; the old man asleep; out of
## the bedroom window; up over the town, all dark - only this house is lit. Fade, title.
func _ending_camera() -> void:
	var pc: Camera3D = get_node_or_null("FinaleCam") if has_node("FinaleCam") else _player_cam()
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 62.0
	cam.global_transform = pc.global_transform
	cam.make_current()
	var start := pc.global_position / K
	var pts := [start, Vector3(-0.02, 1.2, 2.45), Vector3(0.5, 1.35, 1.55), Vector3(-0.6, 1.25, 1.35),
		Vector3(-3.0, 1.15, -1.0), Vector3(-3.2, 1.45, 1.7), Vector3(-3.2, 1.55, 3.5), Vector3(-2.0, 6.0, 12.0), Vector3(6.0, 11.0, 34.0), Vector3(11.0, 16.0, 62.0)]
	var looks := [start - pc.global_basis.z, Vector3(-0.32, 1.12, 2.22), Vector3(-0.4, 1.0, 1.35), Vector3(-2.6, 0.9, -0.8),
		Vector3(-4.05, 0.72, -2.35), Vector3(-3.2, 1.55, 2.65), Vector3(-3.2, 2.2, 14.0), Vector3(0.3, 0.9, 0.0), Vector3(0.2, 3.0, 0.0), Vector3(0.0, 13.0, 0.0)]
	var secs := [2.5, 3.0, 2.6, 3.6, 3.6, 2.6, 4.5, 5.0, 6.5]
	var holds := [0.0, 1.6, 0.0, 0.0, 2.4, 0.0, 0.0, 0.0, 0.0, 3.5]
	var curve := Curve3D.new()
	for i in pts.size():
		var prev: Vector3 = pts[maxi(i - 1, 0)]
		var next: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var tan := (next - prev) * 0.22 * K
		curve.add_point(pts[i] * K, -tan, tan)
	var roof := _roof()
	for i in secs.size():
		if i == 4:
			get_tree().create_timer(secs[i] + 0.2).timeout.connect(func(): Game.captions.say("6-7"))   # at the bedside
		if i == 8:
			get_tree().create_timer(1.5).timeout.connect(func(): Game.captions.say("6-8"))   # over the dark town
		if i == 5:
			roof.visible = true  # from here on we see the house from outside
			var env: Environment = $WorldEnvironment.environment
			create_tween().tween_property(env, "fog_density", 0.0004, 3.0)
			create_tween().tween_property(env, "volumetric_fog_density", 0.0004, 3.0)
		_end_cam = cam
		_end_curve = curve
		_end_seg = i
		_end_la = looks[i] * K
		_end_lb = looks[i + 1] * K
		await create_tween().tween_method(_ending_frame, 0.0, 1.0, secs[i]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
		ending_stage = i + 1
		if holds[i + 1] > 0.0:
			await _wait(holds[i + 1] if i + 1 < pts.size() - 1 else 0.3)
	# the title over the lit house in the dark town
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var title := Label.new()
	title.text = "Last Charge"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.65))
	title.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)  # under the lit house, not over it
	title.offset_top = -190.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.grow_vertical = Control.GROW_DIRECTION_BOTH
	title.modulate.a = 0.0
	layer.add_child(title)
	await create_tween().tween_property(title, "modulate:a", 1.0, 2.0).finished
	ending_stage = 99
	await _wait(3.5)
	ending_done = true
	if not "--autotest" in OS.get_cmdline_user_args():
		Game.to_title()

func _ending_frame(t: float) -> void:
	var pos := _end_curve.sample(_end_seg, t)
	_end_cam.global_transform = Transform3D(Basis.IDENTITY, pos).looking_at(_end_la.lerp(_end_lb, smoothstep(0.0, 1.0, t)))

## A plain pitched roof over the whole house, only for the ending's shots from outside (the bedroom has no
## ceiling, and the overhead debug shots look into it).
func _roof() -> Node3D:
	var art := "res://assets/models/props/prop_farmhouse_roof.glb"   # docs/art_brief_livingroom_finale.md
	if ResourceLoader.exists(art):  # origin: the middle of the house at eave height
		var model: Node3D = load(art).instantiate()
		add_child(model)
		model.scale = Vector3.ONE * K
		model.global_position = Vector3(0, 2.76, 0) * K
		model.visible = false
		return model
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(5.75, 1.1, 9.75) * K   # across x after the turn below: the ridge runs east-west
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.34, 0.24, 0.2)
	m.roughness = 0.9
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = Vector3(0, 2.76 + 0.55, 0) * K
	mi.rotation.y = PI / 2
	mi.visible = false
	return mi

# ------------------------------------------------------------------ self test
func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _act(action: String, down: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = down
	Input.parse_input_event(e)

func _shot(dir: String, n: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(n))

## Shots of the outside with the game's own lighting, fog and post effects (no debug brightening).
func _views(dir: String) -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 62.0
	var views := [
		["view_north_nightstand.png", Vector3(-3.0, 0.8, -2.15), Vector3(-2.95, 1.75, -4.0), Vector3(-3.0, 0.75, -2.0)],
		["view_north_bed.png", Vector3(-2.1, 1.25, -0.6), Vector3(-3.1, 1.45, -2.7), Vector3(-2.1, 0.6, -0.6)],
		["view_south_sill.png", Vector3(1.4, 1.45, 2.3), Vector3(2.2, 1.1, 12.0), Vector3(1.5, 0.95, 2.4)],
		["view_south_wide.png", Vector3(-0.6, 1.4, 2.4), Vector3(4.0, 1.3, 9.0), Vector3(-0.6, 0.95, 2.4)],
		["view_house_outside.png", Vector3(9.0, 2.2, 15.0), Vector3(0, 1.5, 0), Vector3(1.5, 0.95, 2.4)],
		["view_aerial_lit.png", Vector3(11, 16, 62), Vector3(0, 13, 0), Vector3(1.5, 0.95, 2.4)],
		["view_moon_window.png", Vector3(-3.0, 0.85, -1.2), Vector3(-3.3, 1.6, -2.7), Vector3(-2.1, 0.6, -0.6)],
	]
	for v in views:
		player.global_position = v[3] * K
		cam.position = v[1] * K
		cam.look_at(v[2] * K)
		cam.make_current()
		await _wait(0.6)
		await _shot(dir, v[0])
		print("VIEW %s fps=%d draws=%d prims=%d" % [v[0], Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	_roof().visible = true
	town.set_all(false)
	await _wait(1.5)
	cam.position = Vector3(11, 16, 62) * K
	cam.look_at(Vector3(0, 13, 0) * K)
	await _wait(0.3)
	await _shot(dir, "view_aerial_dark.png")
	print("VIEWS lights=", town.light_count())

func _cam_shot(dir: String, n: String, pos: Vector3, look: Vector3, ortho := 0.0) -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = pos
	if ortho > 0.0:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = ortho
		cam.rotation_degrees = Vector3(-90, 0, 0)
	else:
		cam.look_at(look)
	cam.make_current()
	var env: Environment = $WorldEnvironment.environment
	var keep := [env.fog_enabled, env.volumetric_fog_enabled, env.ambient_light_energy]
	$PostFX.enabled = false
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.ambient_light_energy = 2.5
	await _wait(0.25)
	await _shot(dir, n)
	$PostFX.enabled = true
	env.fog_enabled = keep[0]
	env.volumetric_fog_enabled = keep[1]
	env.ambient_light_energy = keep[2]
	player.get_node("CamPivot/SpringArm3D/Camera3D").make_current()
	cam.queue_free()

func _set_axis(x: float, y: float) -> void:
	for pair in [["move_right", x], ["move_left", -x], ["move_back", y], ["move_fwd", -y]]:
		if pair[1] > 0.05:
			Input.action_press(pair[0], clampf(pair[1], 0.0, 1.0))
		else:
			Input.action_release(pair[0])

## Walk through waypoints (x, z in metres) with real movement input; returns the number of respawns seen.
func _walk_path(points: Array) -> int:
	var respawns := 0
	for pt in points:
		var target: Vector3 = pt if pt is Vector3 else Vector3(pt.x * K, 0, pt.y * K)
		var t := 0.0
		var last := player.global_position
		while t < 4.0:
			var d := target - player.global_position
			d.y = 0.0
			if d.length() < 0.12:
				break
			var v := Basis(Vector3.UP, -player.cam_pivot.rotation.y) * d.normalized()
			var s := clampf(d.length() / 0.6, 0.35, 1.0)
			_set_axis(v.x * s, v.z * s)
			await get_tree().physics_frame
			if player.global_position.distance_to(last) > 2.0:
				respawns += 1
			last = player.global_position
			t += 1.0 / 60.0
		if t >= 4.0:
			_walk_stalls.append(str(target.snapped(Vector3.ONE * 0.01)) + " at " + str(player.global_position.snapped(Vector3.ONE * 0.01)))
	_set_axis(0, 0)
	await _wait(0.3)
	return respawns

## Teleport (metres), face camera yaw (forward = (-sin, 0, -cos)), run + jump; returns landing y in units.
func _hop(from_m: Vector3, y_units: float, yaw: float, hold := 0.35, run_after := 0.05) -> float:
	player.teleport(Vector3(from_m.x * K, y_units, from_m.z * K))
	player.cam_pivot.rotation.y = yaw
	await _wait(0.4)
	_act("move_fwd", true)
	_act("jump", true)
	await _wait(hold)
	_act("jump", false)
	await _wait(run_after)
	_act("move_fwd", false)
	await _wait(0.8)
	return snappedf(player.global_position.y, 0.01) if player.is_on_floor() else -1.0

## Plays the TV game with real input until the robot passes x_goal (or the finale starts / time runs out):
## jumps at the known spots, hops plank to plank, waits for the moving platform, baits the knight's thrust
## and hits it while it recovers, claws whatever is in front; in the boss fight it dodges the lunge
## marker, hops fireballs and the tail, and claws the dazed head.
var _tv_debug := "--tv-debug" in OS.get_cmdline_user_args()
var _prev_tail_d := 9999.0
const PILOT_JUMPS := [104.0, 556.0, 682.0, 1026.0, 1062.0, 1108.0, 1164.0]

func _tv_pilot(g: TvGame, x_goal: float, timeout: float) -> void:
	if timeout > 2.0:
		print("TVPILOT to %s from x=%.0f charge=%.2f hits=%d cont=%d" % [x_goal, g.bot.position.x, player.charge, g.hits_taken, g.continues])
	var t := 0.0
	var hold := 0.0
	var atk := false
	var dt := 1.0 / 60.0
	while t < timeout and not tv_finale and g.bot.position.x < x_goal:
		var b: TvGame.PixelBot = g.bot
		var bx: float = b.position.x
		var on_floor := b.is_on_floor()
		var ax := 1.0
		var jump := false
		var swing := false
		var live: Array = g.enemies.filter(func(e): return is_instance_valid(e) and not e.dead)
		if g.frozen:
			ax = 0.0
		elif g.boss_started and not g.boss_beaten:
			var dr: TvGame.Dragon = g.dragon
			var target := 1336.0
			if dr.state == TvGame.Dragon.DAZED:
				target = dr.head.x - 15.0
			elif dr.state == TvGame.Dragon.LUNGE_WARN or dr.state == TvGame.Dragon.LUNGE:
				target = dr._to.x - 46.0 if dr._to.x > 1340.0 else dr._to.x + 46.0
			ax = signf(target - bx) if absf(target - bx) > 3.0 else 0.0
			for e in live:
				if e is TvGame.Fireball and e.position.y >= 207.0 and e.position.x - bx > 4.0 and e.position.x - bx < 30.0:
					jump = true
			var tail_d := absf(dr.tail_tip.x - bx)
			if dr.state == TvGame.Dragon.TAIL and tail_d < 34.0 and tail_d < _prev_tail_d:
				jump = true  # it is coming at us
			_prev_tail_d = tail_d
			if dr.head_hittable() and absf(dr.head.x - bx) < 24.0 and dr.head.x > bx:
				swing = true
				ax = 0.0
		elif g.boss_beaten:
			jump = on_floor and bx > 1505.0
		else:
			for spot in PILOT_JUMPS:
				if bx > spot and bx < spot + 6.0:
					jump = true
			if on_floor and bx > 596.0 and bx < 606.0 and b.position.y > 205.0:
				jump = true  # onto the turret's block
			if on_floor and bx > 700.0 and bx < 884.0 and b.position.y < 205.0:
				jump = true  # plank to plank, no waiting
			if on_floor and bx > 1190.0 and bx < 1226.0 and b.position.y < 152.0:
				jump = true  # off the last tower, over the spikes
			if bx > 384.0 and bx < 400.0 and on_floor and b.position.y > 205.0:
				if g._platform.position.x > 407.0:
					ax = 0.0  # wait for the platform to come close
				else:
					jump = true
			if on_floor and b.position.y < 200.0 and bx > 400.0 and bx < 470.0:
				ax = 1.0 if g._platform.position.x > 440.0 else 0.0  # ride it across
			for e in live:  # the knight: bait the thrust, back off, hit it while it recovers
				if e is TvGame.Knight and e.position.x - bx < 80.0 and e.position.x - bx > -10.0:
					var d: float = e.position.x - bx
					if e.state == TvGame.Knight.WINDUP or e.state == TvGame.Knight.THRUST:
						ax = -1.0 if d < 50.0 and bx > 892.0 else 0.0
					elif e.state == TvGame.Knight.RECOVER:
						ax = 1.0 if d > 17.0 else 0.0
						if d < 24.0 and b.facing > 0:
							swing = true
					else:
						ax = 1.0 if d > 27.0 else 0.0
		for e in live:  # claw anything right in front
			if e is TvGame.Knight or not e.hittable():
				continue
			var d: float = (e.position.x - bx) * b.facing
			if d > -2.0 and d < 22.0 and absf(e.position.y - b.position.y) < 16.0:
				swing = true
		_set_axis(ax, 0)
		if jump and hold <= 0.0 and on_floor:
			_act("jump", true)
			hold = 0.34
		elif hold > 0.0:
			hold -= dt
			if hold <= 0.0:
				_act("jump", false)
		if atk:
			_act("attack", false)
			atk = false
		elif swing:
			_act("attack", true)
			atk = true
		var was_floor := on_floor
		await get_tree().physics_frame
		t += dt
		if _tv_debug and b.is_on_floor() != was_floor:
			print("  %s at x=%.1f y=%.1f t=%.2f" % ["LAND" if b.is_on_floor() else "AIR ", b.position.x, b.position.y, t])
	_act("jump", false)
	_act("attack", false)
	_set_axis(0, 0)

## The TV stop's self test: climb, into the screen, all five screens of the game, out, the time box.
func _autotest_tv(dir: String) -> Dictionary:
	# ---- stop 3: the TV, part 1 (climb, into the screen, out again)
	var s3 := {}
	await _wait(1.0)
	while player.locked:
		await get_tree().process_frame
	await _wait(0.3)
	var to_tv: Vector3 = ($TvLook.global_position - _player_cam().global_position).normalized()
	s3["reveal_looks_at_tv"] = -_player_cam().global_basis.z.dot(to_tv) > 0.9
	await _shot(dir, "room_s3_reveal_tv.png")
	s3["floor_to_boxes(0.81)"] = await _hop(Vector3(0.35, 0, -1.70), 0.05, 0.0)
	s3["boxes_to_mags(1.71)"] = await _hop(Vector3(0.36, 0, -1.86), 0.86, 0.0)
	s3["mags_to_sub(2.61)"] = await _hop(Vector3(0.37, 0, -2.02), 1.76, 0.0)
	s3["sub_to_speaker(3.51)"] = await _hop(Vector3(0.38, 0, -2.20), 2.66, 0.0)
	s3["speaker_to_cabinet(4.5)"] = await _hop(Vector3(0.40, 0, -2.45), 3.56, -PI / 2)
	s3["walk_respawns"] = await _walk_path([Vector2(0.6, -2.09), Vector2(1.0, -2.09)])
	s3["at_screen"] = tv_pulling
	await _shot(dir, "room_s3_cabinet.png")
	s3["pulled_in_passively"] = tv_pulling
	await _wait(2.4)
	await _shot(dir, "room_s3_look_back.png")
	while _tv_cam == null:
		await get_tree().process_frame
	await _wait(1.2)
	await _shot(dir, "room_s3_push_in.png")
	await _wait(1.6)
	var tvg: TvGame = $Stop3/TvScreen.game
	s3["in_tv"] = in_tv and tvg.active
	s3["tv_camera"] = get_viewport().get_camera_3d() == _tv_cam
	await _wait(1.0)
	s3["pixel_bot_landed"] = tvg.bot.is_on_floor()
	await _shot(dir, "room_s3_in_tv.png")
	var by: float = tvg.bot.position.y
	_act("jump", true)
	await _wait(0.2)
	s3["pixel_jump"] = tvg.bot.position.y < by - 10.0
	_act("jump", false)
	await _wait(0.6)
	for a in OS.get_cmdline_user_args():  # debug: --tv-start=X drops the robot at x and plays from there
		if a.begins_with("--tv-start="):
			tvg.bot.position = Vector2(float(a.substr(11)), 190)
			tvg.screen_reached = clampi(int(tvg.bot.position.x / 320.0), 0, 4)
			var t0 := Time.get_ticks_msec()
			while not tv_finale and Time.get_ticks_msec() - t0 < 150000:
				await _tv_pilot(tvg, 99999.0, 1.0)
			s3["debug_seconds"] = (Time.get_ticks_msec() - t0) / 1000.0
			s3["debug_end_x"] = tvg.bot.position.x
			s3["boss_hp"] = tvg.dragon.hp
			s3["hits_taken"] = tvg.hits_taken
			s3["finale"] = tv_finale
			s3["continues"] = tvg.continues
			return s3
	# screen 1 (pit, the slime in the tunnel), played by an autopilot with real input
	await _tv_pilot(tvg, 330.0, 20.0)
	s3["screen1_cleared"] = tvg.bot.position.x >= 330.0
	s3["tunnel_slime_killed"] = tvg.kills >= 1
	# a pit = insert coin: 5% charge, back at the start of this screen
	var c3: float = player.charge
	tvg.bot.position = Vector2(436, 236)
	tvg.bot.velocity = Vector2.ZERO
	await _wait(0.8)
	await _shot(dir, "room_s3_continue.png")
	await _wait(1.2)
	s3["continue_cost"] = snappedf(c3 - player.charge, 0.001)
	s3["continue_respawn"] = tvg.bot.position.distance_to(TvGame.STARTS[1]) < 12.0 and not tvg.frozen
	# screens 2 + 3 (moving platform, turret, crumbling planks, the shield knight)
	await _tv_pilot(tvg, 1004.0, 60.0)
	s3["screens2_3_cleared"] = tvg.bot.position.x >= 1004.0
	s3["knight_beaten"] = not tvg.enemies.any(func(e): return e is TvGame.Knight)
	s3["shield_blocks"] = tvg.blocked_hits
	# screen 4 (towers over spikes, turret on top) up to the roof
	await _tv_pilot(tvg, 1306.0, 40.0)
	s3["screen4_cleared"] = tvg.bot.position.x >= 1306.0
	s3["boss_started"] = tvg.boss_started
	s3["continues_before_boss"] = tvg.continues
	s3["hits_before_boss"] = tvg.hits_taken
	await _wait(1.2)
	await _shot(dir, "room_s3_boss.png")
	# the dragon (two phases), then up the steps to the princess
	var tb := Time.get_ticks_msec()
	var hits0: int = tvg.hits_taken
	var shot2 := false
	while tvg.dragon.state != TvGame.Dragon.GONE and Time.get_ticks_msec() - tb < 150000:
		await _tv_pilot(tvg, 99999.0, 1.0)
		if tvg.dragon.phase2 and not shot2:
			shot2 = true
			await _shot(dir, "room_s3_boss_phase2.png")
	s3["boss_seconds"] = snappedf((Time.get_ticks_msec() - tb) / 1000.0, 0.1)
	s3["boss_hits_taken"] = tvg.hits_taken - hits0
	s3["boss_phase2_seen"] = shot2
	s3["boss_beaten"] = tvg.boss_beaten
	await _tv_pilot(tvg, 99999.0, 12.0)
	s3["princess_reached"] = tv_finale
	s3["kills"] = tvg.kills
	s3["hits_taken"] = tvg.hits_taken
	s3["continues"] = tvg.continues
	s3["batteries"] = tvg.batteries
	await _wait(1.2)
	await _shot(dir, "room_s3_colour_drains.png")
	for i in 60:
		if tv_done:
			break
		await _wait(0.1)
	s3["left_tv"] = tv_done
	await _wait(0.8)
	await _shot(dir, "room_s3_pop_out.png")
	await _wait(1.6)
	s3["landed_kitchen_side"] = player.is_on_floor() and player.global_position.distance_to($TvExitLanding.global_position) < 0.8
	s3["camera_back"] = get_viewport().get_camera_3d() == _player_cam()
	s3["checkpoint"] = Game.checkpoint.name
	s3["charge"] = snappedf(player.charge, 0.01)
	await _wait(1.0)
	await _shot(dir, "room_s3_stove_look.png")
	var pw = $Stop3/TvScreen.mat.get_shader_parameter("power")
	s3["tv_switched_off"] = pw != null and pw < 0.05
	# the real time box, by the cabinet
	player.teleport(Vector3(1.6 * K, 0.05, -1.98 * K))
	player.cam_pivot.rotation.y = 0.0
	await _wait(0.5)
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(1.2)
	s3["time_box_open"] = time_box_open and "time_box" in Game.memories
	await _shot(dir, "room_s3_time_box.png")
	return s3

## Rides the toy train for 3 s: per-physics-frame steps of the carriage (should be even) and of the rider.
func _train_smoothness() -> Dictionary:
	var train: Node3D = $Stop1/Train
	var out := {}
	for mode in ["empty", "riding", "in_path"]:
		var riding: bool = mode == "riding"
		var pos := Vector3(-2.7 * K, 2.0, -2.5 * K)
		if riding:
			pos = train.global_position + Vector3(0, 0.6, 0)
		elif mode == "in_path":  # standing on the track just ahead of the carriage
			var a: float = train._a + 0.45
			pos = train.center + Vector3(cos(a), 0, sin(a)) * train.radius + Vector3(0, 0.1, 0)
		player.teleport(pos)
		await _wait(0.6)
		var steps := []
		var rsteps := []
		var last := train.global_position
		var rlast := player.global_position
		var f0 := Engine.get_physics_frames()
		while steps.size() < 180:
			await get_tree().physics_frame
			if Engine.get_physics_frames() == f0:
				continue
			f0 = Engine.get_physics_frames()
			steps.append((train.global_position - last).length())
			rsteps.append((player.global_position - rlast).length())
			last = train.global_position
			rlast = player.global_position
		var key: String = mode
		out[key + "_train_step_min"] = snappedf(steps.min(), 0.0001)
		out[key + "_train_step_max"] = snappedf(steps.max(), 0.0001)
		out[key + "_rider_step_min"] = snappedf(rsteps.min(), 0.0001)
		out[key + "_rider_step_max"] = snappedf(rsteps.max(), 0.0001)
		out[key + "_on_train"] = player.is_on_floor() and player.global_position.y > 0.4
		var mean: float = steps.reduce(func(acc, v): return acc + v, 0.0) / steps.size()
		out[key + "_train_jitter"] = snappedf(steps.reduce(func(acc, v): return acc + absf(v - mean), 0.0) / steps.size(), 0.00001)
	return out

## The kitchen's self test (part 1): reveal, climb, the gap, the microwave bridge, the toaster lift, hazards.
func _autotest_kitchen(dir: String) -> Dictionary:
	var s4 := {}
	_skip_to_kitchen()
	var t0 := Time.get_ticks_msec()   # the stove, him at forty, the tap, the way home: with their lines (~25 s)
	while not kitchen_revealed and Time.get_ticks_msec() - t0 < 40000:
		await get_tree().process_frame
	s4["reveal"] = kitchen_revealed
	await _wait(2.0)
	await _shot(dir, "room_s4_reveal_sink.png")
	s4["yaw_sink"] = snappedf(rad_to_deg(player.cam_pivot.rotation.y), 1.0)
	while player.locked and Time.get_ticks_msec() - t0 < 70000:
		await get_tree().process_frame
	await _shot(dir, "room_s4_reveal_sill.png")
	await _wait(0.5)
	s4["control_back_after_reveal"] = not player.locked and get_viewport().get_camera_3d() == _player_cam()
	s4["yaw_sill"] = snappedf(rad_to_deg(player.cam_pivot.rotation.y), 1.0)
	s4["robot_at"] = str((player.global_position / K).snapped(Vector3.ONE * 0.01))
	s4["floor_to_cans(0.99)"] = await _hop(Vector3(1.62, 0, -2.47), 0.05, -PI / 2)
	s4["cans_to_rice(1.98)"] = await _hop(Vector3(1.77, 0, -2.47), 1.04, -PI / 2)
	s4["rice_to_stool(2.97)"] = await _hop(Vector3(1.90, 0, -2.47), 2.03, -PI / 2)
	s4["stool_to_seat(3.96)"] = await _hop(Vector3(2.04, 0, -2.47), 3.02, -PI / 2)
	s4["seat_to_lunchbox(4.95)"] = await _hop(Vector3(2.22, 0, -2.48), 4.01, PI)
	s4["lunchbox_to_cereal(6.03)"] = await _hop(Vector3(2.22, 0, -2.37), 5.0, PI)
	s4["cereal_to_chairback(7.2)"] = await _hop(Vector3(2.22, 0, -2.27), 6.08, PI)
	s4["chairback_to_counter(8.1)"] = await _hop(Vector3(2.22, 0, -2.18), 7.25, -PI / 2)
	s4["checkpoint_kitchen"] = Game.checkpoint.name == "Kitchen"
	await _shot(dir, "room_s4_counter.png")
	# the gap is too wide to jump; falling in = water = short circuit, back to the checkpoint
	var c0: float = player.charge
	var y_gap: float = await _hop(Vector3(2.80, 0, -2.17), KC_U + 0.05, -PI / 2, 0.35, 0.4)
	await _wait(1.2)
	s4["gap_too_wide"] = y_gap < 0.0 or y_gap < KC_U - 0.5
	s4["water_shorts_out"] = $Stop4/WaterGap.hits >= 1 and player.charge < c0 and player.global_position.distance_to($Checkpoints/Kitchen.global_position) < 1.0
	# the microwave: the door shoves the cutting board over the gap
	player.teleport(Vector3(2.80 * K, KC_U + 0.25, -2.17 * K))   # the far end of the board, clear of the door
	await _wait(0.5)
	c0 = player.charge
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(1.0)
	s4["microwave_cost"] = snappedf(c0 - player.charge, 0.001)
	s4["board_bridges_gap"] = board_pushed and absf($Stop4/CuttingBoard.global_position.x - 2.99 * K) < 0.1
	await _shot(dir, "room_s4_board.png")
	s4["walk_board_respawns"] = await _walk_path([Vector2(2.7, -2.17), Vector2(3.17, -2.17)])
	s4["crossed_gap"] = player.global_position.x > 3.1 * K and player.global_position.y > KC_U - 0.1
	s4["board_to_breadbag(8.91)"] = await _hop(Vector3(3.17, 0, -2.2), player.global_position.y + 0.05, -PI / 2)
	s4["breadbag_to_toaster(9.72)"] = await _hop(Vector3(3.32, 0, -2.18), 8.96, 0.0)
	s4["shelf_not_jumpable"] = (await _hop(Vector3(3.30, 0, -2.36), 9.77, 0.0)) < 11.5
	# the toaster: in, glow, ding, up onto the spice shelf
	player.teleport(Vector3(3.30 * K, 9.8, -2.40 * K))
	await _wait(0.5)
	c0 = player.charge
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(1.2)
	await _shot(dir, "room_s4_toaster.png")
	await _wait(2.0)
	s4["toaster_cost"] = snappedf(c0 - player.charge, 0.001)
	s4["popped_to_shelf"] = on_spice_shelf and player.is_on_floor() and absf(player.global_position.y - 1.33 * K) < 0.15
	s4["checkpoint_shelf"] = Game.checkpoint.name == "SpiceShelf"
	await _shot(dir, "room_s4_shelf.png")
	# the stove fire burns
	player.teleport(Vector3(3.7 * K, 9.1, -2.35 * K))
	await _wait(1.6)
	s4["fire_burns"] = $Stop4/StoveFire.hits >= 1 and player.global_position.distance_to($Checkpoints/SpiceShelf.global_position) < 1.0
	# ---- the electromagnet: hang under the hood, past the flares, the rail round the corner, drop by the kettle
	var hood: Node3D = $Stop4/RangeHood
	player.teleport(Vector3(3.32 * K, 1.335 * K, -2.6 * K))
	await _wait(0.5)
	s4["magnet_hint_shown"] = player._magnet_hint.visible
	_act("magnet", true)
	await _wait(0.4)
	s4["clings_to_hood"] = player.clinging == hood and not player.is_on_floor()
	await _shot(dir, "room_s4_hang.png")
	# a flare while hanging under it burns
	await _cling_to(Vector3(3.40, 0, -2.5), -1)
	while flare_state(0)[0] != "warn":
		await get_tree().physics_frame
	await _cling_to(Vector3(3.55, 0, -2.5), -1)
	await _wait(1.6)
	_act("magnet", false)
	s4["flare_burns"] = $Stop4/FlareW.hits >= 1 and Game.checkpoint.name == "SpiceShelf" \
		and player.global_position.distance_to($Checkpoints/SpiceShelf.global_position) < 1.0
	# letting go over the stove = the fire
	await _wait(0.6)
	player.teleport(Vector3(3.32 * K, 1.335 * K, -2.6 * K))
	await _wait(0.4)
	_act("magnet", true)
	await _wait(0.3)
	await _cling_to(Vector3(3.40, 0, -2.5), 0)
	await _cling_to(Vector3(3.70, 0, -2.5), -1)
	var fire0: int = $Stop4/StoveFire.hits + $Stop4/FlareW.hits + $Stop4/FlareE.hits
	var at_release := str((player.global_position / K).snapped(Vector3.ONE * 0.01))
	_act("magnet", false)
	await _wait(1.4)
	s4["drop_on_stove_burns"] = $Stop4/StoveFire.hits + $Stop4/FlareW.hits + $Stop4/FlareE.hits > fire0
	if not s4["drop_on_stove_burns"]:
		s4["drop_debug"] = "released at %s, now at %s, cp %s" % [at_release, str((player.global_position / K).snapped(Vector3.ONE * 0.01)), Game.checkpoint.name]
	# the full crossing, waiting for each burner to die down
	await _wait(0.6)
	player.teleport(Vector3(3.32 * K, 1.335 * K, -2.6 * K))
	await _wait(0.4)
	var c1: float = player.charge
	var t1: float = player.magnet_seconds
	var burns: int = $Stop4/FlareW.hits + $Stop4/FlareE.hits
	_act("magnet", true)
	await _wait(0.3)
	await _cling_to(Vector3(3.40, 0, -2.5), -1)
	await _cling_to(Vector3(3.70, 0, -2.5), 0)
	await _cling_to(Vector3(3.99, 0, -2.6), 1)
	await _shot(dir, "room_s4_past_flares.png")
	await _cling_to(Vector3(4.3, 0, -2.62), -1)
	s4["on_rail_n"] = player.clinging == $Stop4/UtensilRailN
	await _shot(dir, "room_s4_rail.png")
	await _cling_to(Vector3(4.69, 0, -2.6), -1)
	await _cling_to(Vector3(4.69, 0, -1.5), -1)
	s4["on_rail_e"] = player.clinging == $Stop4/UtensilRailE
	_act("magnet", false)
	await _wait(1.0)
	s4["flare_burns_on_crossing"] = $Stop4/FlareW.hits + $Stop4/FlareE.hits - burns
	s4["dropped_by_kettle"] = player.is_on_floor() and absf(player.global_position.y - KC_U) < 0.15 \
		and absf(player.global_position.z - (-1.5 * K)) < 0.5
	s4["checkpoint_kettle"] = Game.checkpoint.name == "Kettle"
	s4["magnet_cost"] = snappedf(c1 - player.charge, 0.001)
	s4["magnet_seconds"] = snappedf(player.magnet_seconds - t1, 0.1)
	await _shot(dir, "room_s4_kettle.png")
	# the corner counter is wet: dropping off the rail too early shorts out
	player.teleport(Vector3(4.4 * K, KC_U + 0.3, -2.0 * K))
	await _wait(1.2)
	s4["corner_is_wet"] = $Stop4/WaterCorner.hits >= 1
	# ---- the kettle's steam to the dish rack (the hazard tests above drained a lot: back to a normal ~50%)
	s4["charge_before_kettle_reset"] = snappedf(player.charge, 0.01)
	player.revive(0.5)
	player.teleport(Vector3(4.68 * K, KC_U + 0.05, -1.5 * K))
	await _wait(0.5)
	var ck: float = player.charge
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(1.3)
	s4["kettle_cost"] = snappedf(ck - player.charge, 0.001)
	s4["steam_on"] = steam_left > 0.0
	await _wait(1.2)
	s4["steam_lifts"] = player.global_position.y > 1.2 * K
	await _shot(dir, "room_s4_steam.png")
	await _float_to(Vector3(4.5, 0, -0.62))
	await _wait(1.0)
	s4["on_dish_rack"] = player.is_on_floor() and absf(player.global_position.y - 1.15 * K) < 0.2
	s4["wet_counter_hits_during_float"] = $Stop4/WaterCounter.hits
	# ---- the sink comes down
	await _walk_path([Vector2(4.47, -0.45), Vector2(4.47, -0.15)])
	s4["collapse_started"] = sink_done
	await _wait(1.6)
	await _shot(dir, "room_s4_collapse.png")
	await _wait(4.6)
	s4["flood_drained"] = not $Stop4/WaterFloor.enabled and not $Stop4/FloodFloor.visible
	s4["landed_south_of_sink"] = player.is_on_floor() and player.global_position.distance_to($SinkLanding.global_position) < 0.6
	s4["control_back_after_sink"] = not player.locked and get_viewport().get_camera_3d() == _player_cam()
	s4["checkpoint_sink"] = Game.checkpoint.name == "SinkSouth"
	await _shot(dir, "room_s4_after_sink.png")
	# ---- the mug, then onto the windowsill
	await _walk_path([Vector2(4.45, 1.55), Vector2(4.45, 2.28)])
	s4["mug_robot_at"] = str((player.global_position / K).snapped(Vector3.ONE * 0.01))
	s4["mug_in_range"] = $Stop4/MugTap.player_in_range()
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(1.8)
	s4["mug_rung"] = mug_rung and "daughter_mug" in Game.memories
	await _shot(dir, "room_s4_mug.png")
	var tm := Time.get_ticks_msec()   # his lines, then the clothesline reveal
	while player.locked and Time.get_ticks_msec() - tm < 40000:
		await get_tree().process_frame
	await _wait(0.3)
	s4["to_sill_respawns"] = await _walk_path([Vector2(4.28, 2.3), Vector2(4.22, 2.52), Vector2(3.9, 2.52)])
	s4["on_windowsill"] = player.is_on_floor() and player.global_position.x < 4.15 * K and absf(player.global_position.y - 0.9 * K) < 0.15
	s4["charge"] = snappedf(player.charge, 0.01)
	await _cam_shot(dir, "room_s4_overview.png", Vector3(1.6 * K, 2.2 * K, 0.6 * K), Vector3(3.6 * K, 0.8 * K, -1.6 * K))
	return s4

## While hanging: steer (real input) to a point (x, z in units); if `wait_flare` >= 0, first wait for that
## burner to have just died down.
func _cling_to(target: Vector3, wait_flare: int) -> void:
	if wait_flare >= 0:
		while not (flare_state(wait_flare)[0] == "off" and flare_state(wait_flare)[1] < 0.2):
			await get_tree().physics_frame
	var tgt := Vector3(target.x * K, 0, target.z * K)
	var t := 0.0
	while t < 6.0 and player.clinging != null:
		var d := tgt - player.global_position
		d.y = 0.0
		if d.length() < 0.1:
			break
		var v := Basis(Vector3.UP, -player.cam_pivot.rotation.y) * d.normalized()
		var sp := clampf(d.length() / 0.4, 0.4, 1.0)
		_set_axis(v.x * sp, v.z * sp)
		await get_tree().physics_frame
		t += 1.0 / 60.0
	_set_axis(0, 0)
	await get_tree().physics_frame

## Floating in the kettle's steam: steer (real input) towards a point (x, z in m) until the robot lands.
func _float_to(target: Vector3) -> void:
	var tgt := Vector3(target.x * K, 0, target.z * K)
	var t := 0.0
	while t < 6.0:
		var d := tgt - player.global_position
		d.y = 0.0
		if d.length() < 0.15 or (t > 0.5 and player.is_on_floor()):
			break
		var v := Basis(Vector3.UP, -player.cam_pivot.rotation.y) * d.normalized()
		_set_axis(v.x, v.z)
		await get_tree().physics_frame
		t += 1.0 / 60.0
	_set_axis(0, 0)

## The clothesline's self test: grab, ride (hop two pegs, miss one), the slow look, land by the breaker box.
func _autotest_sill(dir: String) -> Dictionary:
	var s5 := {}
	kitchen_revealed = true  # (no kitchen intro cutscene running into the ride)
	_skip_to_kitchen()
	await _wait(0.6)
	player.revive(0.35)
	player.teleport(Vector3(4.35 * K, 0.9 * K + 0.05, 2.33 * K))
	Game.set_checkpoint($Checkpoints/SinkSouth)
	await _wait(0.6)
	var zip: Zipline = $Stop5/Zipline
	s5["grab_in_range"] = $Stop5/ZiplineGrab.player_in_range()
	await _cam_shot(dir, "room_s5_overview.png", Vector3(1.8 * K, 1.9 * K, 0.4 * K), Vector3(2.0 * K, 1.1 * K, 2.6 * K))
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(1.4)
	s5["on_line"] = zip.riding and player.hanging
	s5["first_person"] = _fp_cam != null and get_viewport().get_camera_3d() == _fp_cam and not player.visual.visible
	await _shot(dir, "room_s5_ride_start.png")
	var lights0 := town.lit_count()
	var t0 := Time.get_ticks_msec()
	var peg := 0
	var shots := 0
	var ax := 0.0
	var got_in := false
	var got_out := false
	while not zip_done and Time.get_ticks_msec() - t0 < 90000:
		# swing away from whatever hangs ahead (about 0.8 s ahead), otherwise let the pendulum settle
		ax = 0.0
		for hn in zip.hang_nodes:
			var hu: float = hn.get_meta("u")
			var secs_to: float = (hu - zip.u) * zip._len / maxf(zip.profile(zip.u), 0.1)
			if secs_to > -0.05 and secs_to < 0.8:
				ax = -float(hn.get_meta("side"))
		_set_axis(ax, 0)
		if peg < zip.pegs.size():
			var secs_left: float = (zip.pegs[peg] - zip.u) * zip._len / maxf(zip.profile(zip.u) * zip._mult, 0.1)
			if secs_left < 0.2:
				if peg != 1:  # hop pegs 1 and 3, miss the middle one
					_act("jump", true)
					await get_tree().physics_frame
					_act("jump", false)
				peg += 1
		if zip.u > 0.35 and shots == 0:
			shots = 1
			await _shot(dir, "room_s5_ride_fast.png")
		if fp_phase == "out" and not got_out:
			got_out = true
			await _shot(dir, "room_s5_look_out.png")
			s5["look_out_dir"] = str((-get_viewport().get_camera_3d().global_basis.z).snapped(Vector3.ONE * 0.01))
			s5["look_out_at"] = str((get_viewport().get_camera_3d().global_position / K).snapped(Vector3.ONE * 0.01))
		if fp_phase == "in" and not got_in:
			got_in = true
			await _shot(dir, "room_s5_look_in.png")
			s5["look_in_dir"] = str((-get_viewport().get_camera_3d().global_basis.z).snapped(Vector3.ONE * 0.01))
		await get_tree().process_frame
	_set_axis(0, 0)
	s5["ride_real_seconds"] = snappedf((Time.get_ticks_msec() - t0) / 1000.0, 0.1)
	s5["ride_game_seconds"] = snappedf(zip.ride_seconds, 0.1)
	s5["hops"] = zip.hops
	s5["bumps"] = zip.bumps
	s5["dodged"] = zip.hang_nodes.size() - zip.bumps
	s5["clacks"] = zip.clacks
	s5["slow_looks"] = slow_looks
	s5["slow_look"] = slow_look_done and min_time_scale < 0.3 and got_in and got_out
	s5["time_scale_back"] = is_equal_approx(Engine.time_scale, 1.0)
	s5["town_lights_went_out"] = "%d of %d" % [lights0 - town.lit_count(), lights0]
	await _wait(1.5)
	s5["landed_on_shelf"] = zip_done and player.is_on_floor() and absf(player.global_position.y - 1.06 * K) < 0.15
	s5["walk_to_box_respawns"] = await _walk_path([Vector2(-0.27, 2.28)])
	s5["by_the_breaker_box"] = player.is_on_floor() and player.global_position.distance_to(Vector3(-0.27, 1.06, 2.28) * K) < 0.3
	s5["checkpoint"] = Game.checkpoint.name
	s5["charge_end"] = snappedf(player.charge, 0.01)
	s5["control_back"] = not player.locked and get_viewport().get_camera_3d() == _player_cam() and player.visual.visible
	await _shot(dir, "room_s5_landed.png")
	return s5

## The finale's self test: hold E at the breaker (charge -> 0, lever up), the lights, the ending's one take.
func _autotest_finale(dir: String) -> Dictionary:
	var s6 := {}
	kitchen_revealed = true
	_skip_to_kitchen()
	await _wait(0.4)
	town.set_all(false)  # (they went out while it rode the clothesline)
	zip_done = true
	player.revive(0.12)
	player.teleport($FinaleStand.global_position + Vector3(0, 0.05, 0))
	Game.set_checkpoint($Checkpoints/SillEnd)
	await _wait(1.0)
	s6["prompt_in_range"] = $Stop6/BreakerCharge.player_in_range()
	await _shot(dir, "room_s6_before.png")
	_act("interact", true)
	await _wait(5.0)
	s6["charge_mid"] = snappedf(player.charge, 0.01)
	await _shot(dir, "room_s6_pouring.png")
	await _wait(5.6)
	_act("interact", false)
	s6["breaker_on"] = finale_done
	s6["charge_zero"] = player.charge <= 0.001
	s6["robot_dark"] = player.powered_down
	await _wait(3.4)
	var lit := 0
	for i in range(1, 11):
		if get_node("HouseLight%d" % i).light_energy > 0.5:
			lit += 1
	s6["house_lights_on"] = "%d of 10" % lit
	s6["grey_lifted"] = $PostFX.loss_cap < 0.05
	await _shot(dir, "room_s6_lights_on.png")
	var shots := {1: "room_s6_end_robot.png", 4: "room_s6_end_bedside.png", 6: "room_s6_end_window.png", 9: "room_s6_end_town.png", 99: "room_s6_end_title.png"}
	var t0 := Time.get_ticks_msec()
	var seen := {}
	while not ending_done and Time.get_ticks_msec() - t0 < 60000:
		if shots.has(ending_stage) and not seen.has(ending_stage):
			seen[ending_stage] = true
			await _wait(0.3 if ending_stage != 99 else 1.0)
			await _shot(dir, shots[ending_stage])
		await get_tree().process_frame
	s6["ending_seconds"] = snappedf((Time.get_ticks_msec() - t0) / 1000.0, 0.1)
	s6["ending_done"] = ending_done
	s6["town_dark"] = town.lit_count() == 0
	s6["town_lights"] = town.light_count()
	await _cam_shot(dir, "room_s6_town_debug.png", Vector3(1.0, 9.0, 16.0) * K, Vector3(0.5, 0.5, 4.0) * K)
	return s6

func _autotest() -> void:
	var dir := OS.get_user_data_dir()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			dir = a.substr(8)
	var r := {}
	if "--train-test" in OS.get_cmdline_user_args():  # debug: is the toy train smooth with the robot riding it?
		r["train"] = await _train_smoothness()
		print("ROOMTEST ", JSON.stringify(r))
		get_tree().quit()
		return
	if "--shortcut-test" in OS.get_cmdline_user_args():  # debug: shoebox -> big robot's shoulder without the blocks?
		var off: float = get_meta("toybox_offset_m", 0.0)
		var best := 0.0
		for zz in [-2.42, -2.45, -2.5]:
			player.teleport(Vector3((-1.97 + off) * K, 0.31 * K, zz * K))
			player.cam_pivot.rotation.y = -PI / 2
			await _wait(0.5)
			_act("move_fwd", true)
			for k in 3:
				_act("jump", true)
				await _wait(0.35)
				_act("jump", false)
				await _wait(0.6)
				best = maxf(best, player.global_position.y / K)
			_act("move_fwd", false)
		print("ROOMTEST ", JSON.stringify({"highest_m": best, "reached_shoulder": best > 0.49}))
		get_tree().quit()
		return
	if "--note-view" in OS.get_cmdline_user_args():  # debug: Mum's note as the player sees it in the maze
		player.teleport($DeskLanding.global_position)
		await _enter_desk()
		player.teleport(maze.note.global_position + Vector3(0.9, 0.3, 0.0))
		await _wait(1.5)
		await _shot(dir, "note_view.png")
		var near := []
		for n in maze.find_children("*", "Node3D", true, false):
			if n != maze.note and n is VisualInstance3D and n.is_visible_in_tree() and n.global_position.distance_to(maze.note.global_position) < 0.6:
				near.append("%s %.2f" % [n.name, (n.global_position.y - maze.note.global_position.y) / K])
		print("ROOMTEST ", JSON.stringify({"note_at": str(maze.note.global_position / K), "note_class": maze.note.get_class(), "near": near}))
		get_tree().quit()
		return
	if "--kitchen-views" in OS.get_cmdline_user_args():  # debug: the kitchen as the player sees it
		_skip_to_kitchen()
		await _wait(2.0)
		var cam := Camera3D.new()
		add_child(cam)
		cam.fov = 62.0
		for v in [["k_overview.png", Vector3(2.3, 1.5, 0.3), Vector3(3.6, 0.9, -2.2)],
				["k_stove.png", Vector3(3.2, 1.25, -1.4), Vector3(3.7, 1.0, -2.4)],
				["k_sink.png", Vector3(3.6, 1.3, 0.2), Vector3(4.4, 0.9, -0.6)],
				["k_floor.png", Vector3(2.6, 0.35, 0.4), Vector3(4.0, 0.2, -1.2)],
				["k_counter_low.png", Vector3(2.45, 1.0, -1.85), Vector3(3.6, 1.0, -2.3)]]:
			cam.global_transform = Transform3D(Basis.IDENTITY, v[1] * K).looking_at(v[2] * K)
			cam.make_current()
			await _wait(0.6)
			await _shot(dir, v[0])
		get_tree().quit()
		return
	if "--photo-view" in OS.get_cmdline_user_args():  # debug: the photo frame lying on the nightstand, close
		var cam := Camera3D.new()
		add_child(cam)
		cam.fov = 40.0
		var f: Vector3 = $Stop0/PhotoFrame.global_position
		for i in 3:
			cam.global_transform = Transform3D(Basis.IDENTITY, f + Vector3(0.6 - i * 0.6, 0.35, 0.9)).looking_at(f)
			cam.make_current()
			await _wait(0.4)
			await _shot(dir, "photo_%d.png" % i)
		print("ROOMTEST ", JSON.stringify({"frame": str($Stop0/PhotoFrame.global_transform)}))
		get_tree().quit()
		return
	if "--door-view" in OS.get_cmdline_user_args():  # debug: where the robot lands from the bedroom door
		$Stop2/DoorPivot.rotation_degrees.y = -75.0
		var cam := Camera3D.new()
		add_child(cam)
		cam.fov = 58.0
		var drop: Vector3 = $OpenPlanDrop.global_position / K
		var bl: Vector3 = $BreakerLook.global_position / K
		_power_cut()
		$BreakerFaultLight.light_energy = 2.6
		$BreakerFaultLight.omni_range = 1.4 * K
		var fill := OmniLight3D.new()
		fill.light_color = Color(0.6, 0.7, 1.0)
		fill.omni_range = 0.7 * K
		fill.light_energy = 1.4
		add_child(fill)
		fill.global_position = Vector3(BW_M + 0.4, 1.5, 2.3) * K
		var views := [[Vector3(BW_M + 0.62, 1.32, 2.62), Vector3(BW_M + 0.05, 1.25, 2.2)], [Vector3(0.2, 0.7, 1.85), bl], [Vector3(0.3, 0.45, 1.75), bl],
			[Vector3(drop.x + 0.5, 0.26, drop.z - 0.2), drop + Vector3(0, 0.05, 0)],
			[Vector3(drop.x + 0.2, 0.08, drop.z + 0.3), Vector3(-0.42, 0.02, 1.2)]]
		for i in views.size():
			cam.global_transform = Transform3D(Basis.IDENTITY, views[i][0] * K).looking_at(views[i][1] * K)
			cam.make_current()
			await _wait(0.5)
			await _shot(dir, "door_%d.png" % i)
		get_tree().quit()
		return
	if "--note-test" in OS.get_cmdline_user_args():  # debug: Mum's note, opened
		_read_note()
		await get_tree().create_timer(0.6, true).timeout
		await _shot(dir, "note.png")
		await get_tree().create_timer(1.0, true).timeout
		print("ROOMTEST ", JSON.stringify({"note_found": note_found, "unpaused": not get_tree().paused}))
		get_tree().quit()
		return
	if "--opening-test" in OS.get_cmdline_user_args():  # the opening cutscene, the desk reveal, the photo
		_op_dir = dir
		var t0 := Time.get_ticks_msec()
		await _opening()
		while not opening_done or player.locked:
			await get_tree().process_frame
		r["opening_seconds"] = (Time.get_ticks_msec() - t0) / 1000.0
		r["charge_full"] = player.charge > 0.98
		r["lights_out"] = $HouseLight1.light_energy == 0.0 and $Stop6/BreakerFault.visible
		r["control_back"] = not player.locked
		await _wait(1.0)
		await _shot(dir, "op_10_control.png")
		player.teleport($Stop0/FrameInteract.global_position + Vector3(0.05, 0, 0.1) * K)
		await _wait(0.5)
		await _stand_frame_up()
		r["photo_cam_holds"] = _photo_cam != null and _photo_cam.current
		_act("move_fwd", true)
		await _wait(0.9)
		_act("move_fwd", false)
		r["photo_cam_released"] = _photo_cam == null and _player_cam().current
		while _photo_talking:
			await get_tree().process_frame
		_act("move_fwd", true)
		await _wait(0.6)
		_act("move_fwd", false)
		await _wait(0.5)
		r["desk_reveal_after_photo"] = revealed
		await _wait(6.0)
		r["frame_up"] = frame_up
		r["memory"] = Game.memories.has("family_photo")
		print("ROOMTEST ", JSON.stringify(r))
		get_tree().quit()
		return
	if "--from=views" in OS.get_cmdline_user_args():  # debug: the outside, as seen from the windows and the ending
		await _wait(1.5)
		await _views(dir)
		get_tree().quit()
		return
	if "--from=finale" in OS.get_cmdline_user_args():  # only the breaker box and the ending
		await _wait(1.0)
		r["stop6"] = await _autotest_finale(dir)
		print("ROOMTEST ", JSON.stringify(r))
		get_tree().quit()
		return
	if "--from=sill" in OS.get_cmdline_user_args():  # only the clothesline
		await _wait(1.0)
		r["stop5"] = await _autotest_sill(dir)
		print("ROOMTEST ", JSON.stringify(r))
		get_tree().quit()
		return
	if "--from=kitchen" in OS.get_cmdline_user_args():  # only the kitchen
		await _wait(1.0)
		r["stop4"] = await _autotest_kitchen(dir)
		print("ROOMTEST ", JSON.stringify(r))
		get_tree().quit()
		return
	if "--from=tv" in OS.get_cmdline_user_args():  # only the TV stop (starts by the bedroom door)
		await _wait(1.0)
		_skip_to_living_room()
		r["stop3"] = await _autotest_tv(dir)
		print("ROOMTEST ", JSON.stringify(r))
		get_tree().quit()
		return
	var top := 0.72 * K
	await _wait(1.5)
	r["start_on_nightstand"] = player.is_on_floor() and absf(player.global_position.y - top) < 0.1
	await _shot(dir, "room_s0_start.png")
	await _cam_shot(dir, "room_box_topdown.png", Vector3(-2.24 * K, 30, -2.2 * K), Vector3.ZERO, 13.0)
	await _cam_shot(dir, "room_box_view.png", Vector3(-2.24 * K, 11, -1.2 * K), Vector3(-2.24 * K, 1.0, -2.25 * K))
	await _cam_shot(dir, "room_bedroom_view.png", Vector3(-16, 13, -6), Vector3(-24, 3, -20))
	# ---- stop 0
	var s0 := {}
	s0["table_to_pill(7.2)"] = await _hop(Vector3(-3.07, 0, -2.445), top + 0.05, 0.0, 0.3, 0.0)
	s0["pill_to_books(7.74)"] = await _hop(Vector3(-3.07, 0, -2.55), top + 0.8, PI / 2)
	await _wait(1.6)
	player.teleport($Stop0/FrameInteract.global_position + Vector3(0, .04, .45))
	await _wait(0.4)
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(1.0)
	s0["frame_up"] = frame_up
	_act("move_right", true)   # a few steps away from the photo: the desk reveal
	await _wait(1.2)
	_act("move_right", false)
	await _wait(6.5)
	s0["reveal"] = revealed
	player.teleport($Stop0/LooseBook.global_position + Vector3(-.14 * K, .05, 0))
	player.cam_pivot.rotation.y = -PI / 2
	await _wait(0.4)
	_act("move_fwd", true)
	for i in 30:
		await _wait(0.1)
		if not fall_armed:
			break
	_act("move_fwd", false)
	await _wait(2.2)
	s0["fell_into_box"] = fell and player.is_on_floor() and Game.checkpoint.name == "ToyBox"
	await _wait(1.0)
	await _shot(dir, "room_s1_machine_reveal.png")
	r["stop0"] = s0
	await _shot(dir, "room_s1_landed.png")
	# ---- stop 1
	var s1 := {}
	var box_offset_m: float = float(get_meta("toybox_offset_m", 0.0))
	s1["plush_to_blockstack(1.8)"] = await _hop(Vector3(-2.72 + box_offset_m, 0, -2.40), 0.9, PI)
	s1["blockstack_to_truck(1.26)"] = await _hop(Vector3(-2.71 + box_offset_m, 0, -2.27), 1.85, PI)
	# box floor = the dark -> respawn
	player.teleport(Vector3((-2.4 + box_offset_m) * K, 0.2, -2.4 * K))
	await _wait(1.6)
	s1["dark_floor_respawns"] = player.global_position.distance_to($Checkpoints/ToyBox.global_position) < 1.0
	# ride the train
	var train: Node3D = $Stop1/Train
	player.teleport(train.global_position + Vector3(0, 0.6, 0))
	await _wait(0.2)
	var p0 := player.global_position
	await _wait(1.5)
	s1["train_carries"] = player.is_on_floor() and player.global_position.distance_to(p0) > 0.4 and player.global_position.y > 0.4
	await _shot(dir, "room_s1_train.png")
	# jack-in-the-box
	player.teleport(Vector3((-2.28 + box_offset_m) * K, 0.95, -1.95 * K))
	await _wait(0.6)
	await _shot(dir, "room_s1_jack.png")
	await _wait(1.2)
	s1["jack_to_shelf(2.7)"] = snappedf(player.global_position.y, 0.01) if player.is_on_floor() else -1.0
	# push the big block east to the shoebox's east edge (the top step of the stairs)
	var big: Node3D = $Stop1/PushBlockLarge
	var bx0 := big.global_position.x
	player.teleport(Vector3(big.global_position.x - big.size.x * 0.5 - 0.36, 2.75, big.global_position.z))
	player.cam_pivot.rotation.y = -PI / 2
	await _wait(0.4)
	_act("interact", true)
	await _wait(0.1)
	_act("move_fwd", true)
	await _wait(1.2)
	_act("move_fwd", false)
	_act("interact", false)
	await _wait(0.3)
	s1["big_block_pushed_m"] = snappedf((big.global_position.x - bx0) / K, 0.001)
	# stairs (blocks set in their final places) -> the big robot's shoulder -> its head
	big.global_position = Vector3((-1.995 + box_offset_m) * K, 0.301 * K, -2.47 * K)
	$Stop1/PushBlockSmall.global_position = Vector3((-2.09 + box_offset_m) * K, 0.301 * K, -2.47 * K)
	await _wait(0.3)
	s1["shelf_to_small(3.31)"] = await _hop(Vector3(-2.20 + box_offset_m, 0, -2.47), 2.75, -PI / 2, 0.3, 0.0)
	s1["small_to_big(4.06)"] = await _hop(Vector3(-2.09 + box_offset_m, 0, -2.47), 3.4, -PI / 2, 0.3, 0.0)
	s1["big_to_shoulder(4.5)"] = await _hop(Vector3(-1.995 + box_offset_m, 0, -2.42), 4.12, -PI / 2, 0.3, 0.05)
	s1["shoulder_to_head(5.22)"] = await _hop(Vector3(-1.80 + box_offset_m, 0, -2.40), 4.55, PI, 0.3, 0.05)
	await _shot(dir, "room_s1_head.png")
	# the exit machine: charge the car on the head, drop onto the seesaw's cyan end, get launched
	player.teleport(Vector3((-1.76 + box_offset_m) * K, 5.3, -2.15 * K))
	await _wait(0.4)
	var c0: float = player.charge
	_act("interact", true)
	await _wait(1.7)
	_act("interact", false)
	s1["car_charge_cost"] = snappedf(c0 - player.charge, 0.01)
	s1["machine_running"] = machine_busy
	player.teleport(Vector3((-2.26 + box_offset_m) * K, 0.75, -2.20 * K))
	await _wait(2.6)
	await _shot(dir, "room_s1_launch.png")
	await _wait(4.5)   # (the car turns its corners more gently now)
	s1["seesaw_tipped"] = seesaw_tipped
	s1["on_end_at_drop"] = str(_dbg_on_end) + " launched=" + str(launched) + " at " + str(player.global_position / K)
	s1["launched_onto_desk"] = launched and player.is_on_floor() and absf(player.global_position.y - 0.75 * K) < 0.2
	s1["checkpoint"] = Game.checkpoint.name
	await _shot(dir, "room_s1_on_desk.png")
	r["stop1"] = s1
	# ---- stop 2: the random desk maze
	var s2 := {"seed": maze.used_seed, "route_cells": maze.path.size(), "holes": maze.holes.size(), "lights": maze.lights.size()}
	await _wait(3.0)
	s2["desk_first_person"] = _fp_desk != null and _fp_desk.current and not maze.visible
	await _shot(dir, "room_s2_pov_boy.png")
	var t0 := Time.get_ticks_msec()
	while not in_desk and Time.get_ticks_msec() - t0 < 30000:
		await get_tree().process_frame
	s2["desk_intro_seconds"] = 3.0 + (Time.get_ticks_msec() - t0) / 1000.0
	await _wait(0.3)
	s2["top_down"] = player.top_down
	s2["room_dark"] = $WorldEnvironment.environment.ambient_light_energy < 0.12
	await _shot(dir, "room_s2_dark.png")
	var y0 := player.global_position.y
	_act("jump", true)
	await _wait(0.3)
	_act("jump", false)
	s2["no_jump"] = absf(player.global_position.y - y0) < 0.05
	# the start flashlight shows the END of the maze, and the camera widens to show it
	var pts: Array = maze.route_points()
	player.teleport(pts[0] + Vector3(0, 0.05, 0))
	await _wait(0.5)
	var c2: float = player.charge
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(1.2)
	var fl: Node3D = maze.lights[0]
	s2["start_light_on"] = fl.lit
	s2["start_light_shows_goal"] = fl.lit_center().distance_to(pts.back()) < 0.1
	s2["camera_widened"] = player.spring.spring_length > player.top_down_dist + 1.0
	s2["light_cost"] = snappedf(c2 - player.charge, 0.01)
	await _shot(dir, "room_s2_flashlight.png")
	# walk the generated route with real input; push the eraser into its hole on the way
	var e: int = maze.eraser_index
	var respawns := 0
	if e > 0:
		respawns += await _walk_path(pts.slice(1, e - 1))
		var fwd: Vector3 = (pts[e - 1] - pts[e - 2]).normalized()
		respawns += await _walk_path([pts[e - 2] + fwd * 0.25])
		_act("interact", true)
		await _wait(0.1)
		var v := Basis(Vector3.UP, -player.cam_pivot.rotation.y) * fwd
		_set_axis(v.x, v.z)
		for i in 120:  # push until it drops into the hole, then let go
			await get_tree().physics_frame
			if maze.hole_fill.bridge != null:
				break
		_set_axis(0, 0)
		_act("interact", false)
		await _wait(0.6)
		s2["eraser_bridged"] = maze.hole_fill.bridge != null
		respawns += await _walk_path(pts.slice(e - 1))
	else:
		respawns += await _walk_path(pts.slice(1))
	s2["start_light_went_out"] = not fl.lit
	s2["route_respawns"] = respawns
	s2["reached_goal_cell"] = player.global_position.distance_to(pts.back()) < 0.5
	s2["walk_stalls"] = _walk_stalls
	await _shot(dir, "room_s2_goal.png")
	# a hole off the route drops you back to the last checkpoint
	var hole_c: Vector2i = maze.holes.back()
	var before := player.global_position
	player.teleport(maze.cell_world(hole_c) + Vector3(0, 0.3, 0))
	await _wait(1.8)
	s2["hole_respawns"] = player.global_position.y > 6.6 and player.global_position.distance_to(maze.cell_world(hole_c)) > 0.4
	# mom's note
	player.teleport(maze.note.global_position + Vector3(0.3, 0.05, 0))
	await _wait(0.5)
	s2["note_found"] = note_found
	# the door handle
	player.teleport(pts.back() + Vector3(0, 0.05, 0))
	await _wait(0.4)
	_act("interact", true)
	await _wait(0.1)
	_act("interact", false)
	await _wait(3.6)
	s2["door_opened"] = door_open and absf($Stop2/DoorPivot.rotation_degrees.y + 75.0) < 2.0
	s2["out_on_floor"] = player.is_on_floor() and player.global_position.y < 0.3 and player.global_position.x > -0.4 * K
	s2["back_to_third_person"] = not player.top_down
	s2["checkpoint"] = Game.checkpoint.name
	s2["developer_fps"] = Performance.get_monitor(Performance.TIME_FPS)
	r["stop2"] = s2
	# Desk art acceptance stops before the independently developed TV station.
	if "--desk-autotest" in OS.get_cmdline_user_args():
		print("ROOMTEST ", JSON.stringify(r))
		get_tree().quit()
		return
	r["stop3"] = await _autotest_tv(dir)

	print("ROOMTEST ", JSON.stringify(r))
	get_tree().quit()
