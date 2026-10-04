class_name TvGame
extends Node2D
## The pixel game on the living-room TV (320 x 240 view inside a SubViewport - see tv_screen.gd).
## The young man's game is his childhood daydream: a knight's road to a castle, a dragon, a princess.
## Five screens, scrolling (level 1600 x 240 px):
##   1 - walk, jump a pit, a slime in a low tunnel (can't jump over it: the claw - J / left click)
##   2 - a moving platform over a wide pit, a slime + a bat, a turret on a block spitting aimed orbs
##   3 - a bridge of crumbling planks over a long pit (they shake, then drop), a bat; a shield knight:
##       hits on its shield bounce off - wait for its thrust, dodge, hit it while it recovers (2 hits)
##   4 - the battlements: tower tops to hop between, spikes below (= a pit), a turret on the highest tower
##   5 - the castle roof: the gate shuts, the dragon (6 hits, two phases). Phase 1: a rolling fireball;
##       a head lunge at a marked spot, after which the head lies dazed = the only time it can be hit.
##       At 3 hits it roars -> phase 2: three fireballs, double lunges, a tail sweep along the floor.
##       Then steps appear up to the tower ledge where the princess waits.
## Getting hit costs 2.5% of the robot's real charge (the idle drain is only 30% of the usual rate in here).
## Falling into a pit = "insert coin": 4% of your charge buys a continue at the start of the screen.
## Three pixel batteries (+5% each) sit in slightly risky spots.
## The HUD battery IS the robot's battery. Key prompts (pixel keycaps) appear when they are first needed.
## Sprites are baked from the ASCII art below; a PNG at res://assets/pixel/<name>.png replaces one.

signal rescued

const W := 320
const H := 240
const LEVEL_W := 1600
const ARENA_X := 1280
const HIT_COST := 0.025
const CONTINUE_COST := 0.04
const BATTERY_GAIN := 0.05
const STARTS := [Vector2(40, -8), Vector2(336, 200), Vector2(660, 200), Vector2(970, 200), Vector2(1300, 200)]
const PRINCESS := Rect2(1574, 138, 12, 22)
const SPIKES := Rect2(1070, 202, 166, 6)

# ---------------------------------------------------------------- pixel art (facing right unless noted)
const PAL := {
	"k": Color(0.06, 0.03, 0.06), "R": Color(0.66, 0.16, 0.16), "r": Color(0.42, 0.08, 0.12),
	"Y": Color(0.92, 0.82, 0.55), "E": Color(1.0, 0.85, 0.2), "W": Color(0.95, 0.95, 0.9),
	"O": Color(1.0, 0.55, 0.15), "M": Color(0.86, 0.65, 0.2), "m": Color(0.6, 0.42, 0.12),
	"C": Color(0.3, 1.0, 0.95), "G": Color(0.32, 0.32, 0.36), "T": Color(0.18, 0.18, 0.2),
	"S": Color(1.0, 0.82, 0.7), "H": Color(0.98, 0.78, 0.3), "P": Color(0.9, 0.45, 0.62),
	"p": Color(0.7, 0.3, 0.48), "B": Color(0.25, 0.32, 0.6), "b": Color(0.16, 0.2, 0.42),
	"A": Color(0.62, 0.64, 0.72), "a": Color(0.42, 0.44, 0.52), "V": Color(0.55, 0.25, 0.62),
	"v": Color(0.38, 0.14, 0.45), "D": Color(0.5, 0.2, 0.32),
}
const BOT := [  # the tin robot, 12 x 13
	"...kkkkkk...",
	"..kMMMMMMk..",
	"..kMMMkCkCk.",
	"..kMMMMMMk..",
	"...kkkkkk...",
	".kkMMMMMMkk.",
	"kGkMCCCCMkGk",
	".kkMCCCCMkk.",
	"..kmMMMMmk..",
	".kkkkkkkkkk.",
	"kTTTTTTTTTTk",
	"kTkTkTkTkTTk",
	".kkkkkkkkkk.",
]
const SLIME := [
	"....kkkk....",
	"..kkVVVVkk..",
	".kVVVVVVVVk.",
	"kVVWkVVWkVVk",
	"kVVVVVVVVVVk",
	"kvVVVVVVVVvk",
	".kvvvvvvvvk.",
	"..kkkkkkkk..",
]
const BATTERY := [  # 6 x 9, cyan = it powers the robot
	".kkkk.",
	"kkCCkk",
	"kCCCCk",
	"kCWCCk",
	"kCCCCk",
	"kCCCCk",
	"kCCCCk",
	"kCCCCk",
	"kkkkkk",
]
const BAT := [
	"k..........k",
	"kk...kk...kk",
	"kDk.kDDk.kDk",
	"kDDkDODDkDDk",
	".kDDDDDDDDk.",
	"..kk.kk.kk..",
]
const TURRET := [
	"...kkkkkk...",
	"..kRRRRRRk..",
	".kRRRRRRRRk.",
	"kkkkRREERRk.",
	"kGGkRRRRRRk.",
	"kkkkRRRRRRk.",
	".kRRRRRRRRk.",
	"kkkkkkkkkkkk",
	"kGGGGGGGGGGk",
	"kkkkkkkkkkkk",
]
const KNIGHT := [  # facing LEFT (shield in front), 14 x 18
	"....kkkkk.....",
	"...kAAAAAk....",
	"...kAkkkAk....",
	"...kAAAAAk....",
	"....kkkkk.....",
	".kkkkAAAAkk...",
	"kBBBkAAAAAAk..",
	"kBEBkAAAAAAk..",
	"kBBBkAaAAAAk..",
	"kBBBkAAAAAk...",
	"kbBBkAAAAAk...",
	".kbkAAAAAk....",
	"..kkAAkAAk....",
	"...kAak.kAk...",
	"...kAak.kAk...",
	"...kAk..kAk...",
	"..kkkk.kkkk...",
]
const PRINCESS_ART := [  # facing LEFT, 12 x 22
	"....kEkEk...",
	"....kEEEk...",
	"...kHHHHHk..",
	"..kHSSSSHHk.",
	"..kHkSkSSHk.",
	"..kHSSSSSHk.",
	"..kHHSSSHHHk",
	"..kHHkkkHHHk",
	"...kPPPPPkHk",
	"..kSPPPPPSk.",
	"..kkPPpPPkk.",
	"...kPPPPPk..",
	"..kPPpPPpPk.",
	"..kPPPPPPPk.",
	".kPPpPPPpPPk",
	".kPPPPPPPPPk",
	"kPPpPPPPPpPPk",
	"kPPPPPPPPPPPk",
	"kkkkkkkkkkkkk",
]
const DRAGON_HEAD := [  # facing LEFT, 24 x 14
	"..........kkk...........",
	".........kYYk..kkk......",
	"........kYYk..kYYk......",
	".....kkkkRRkkkkRk.......",
	"...kkRRRRRRRRRRRRkk.....",
	"..kRRRRRRRRRkEEkRRRk....",
	".kRRRRRRRRRRkEkkRRRRk...",
	"kRRRRRRRRRRRRRRRRRRRRk..",
	"kRrrRRRRRRRRRRRRRRRRRRk.",
	"kRRRRRRRRRRRRRRRRRRRRRRk",
	".kWkWkWkRRRRRRRRRRRRRRRk",
	".kYYYYYYYYYYYRRRRRRRRRk.",
	"..kkkkkkkkkkkkRRRRRRkk..",
	".............kkkkkk.....",
]
const DRAGON_HEAD_OPEN := [
	"..........kkk...........",
	".........kYYk..kkk......",
	"........kYYk..kYYk......",
	".....kkkkRRkkkkRk.......",
	"...kkRRRRRRRRRRRRkk.....",
	"..kRRRRRRRRRkEEkRRRk....",
	".kRRRRRRRRRRkEkkRRRRk...",
	"kRRRRRRRRRRRRRRRRRRRRk..",
	"kRrrRRRRRRRRRRRRRRRRRRk.",
	"kkWkWkWkkRRRRRRRRRRRRRRk",
	".kOOOOOOOkRRRRRRRRRRRRRk",
	".kOOOOOOOkRRRRRRRRRRRRk.",
	".kWkWkWkkRRRRRRRRRRRkk..",
	".kYYYYYYYYYYRRRRRRRRk...",
	"..kkkkkkkkkkkkkkkkkk....",
]
const DRAGON_BODY := [  # facing LEFT, 48 x 31
	"..............kkkkkkkkkk........................",
	"...........kkkRRRRRRRRRRkkk.....................",
	".........kkRRRRRRRRRRRRRRRRkk...................",
	"........kRRRRRRRRRRRRRRRRRRRRkk.................",
	".......kRRRRRRRRRRRRRRRRRRRRRRRkk...............",
	"......kRRRRRRRRRRRRRRRRRRRRRRRRRRk..............",
	".....kYYRRRRRRRRRRRRRRRRRRRRRRRRRRk.............",
	".....kYYYRRRRRRRRRRRRRRRRRRRRRRRRRRk............",
	"....kYYYYRRRRRRrrRRRRRRRRRRRRRRRRRRRk...........",
	"....kYYYYYRRRRRRrrRRRRRRRRRRRRRRRRRRRk..........",
	"....kYYYYYRRRRRRRrrRRRRRRRRRRRRRRRRRRRk.........",
	"...kYYYYYYYRRRRRRRrrRRRRRRRRRRRRRRRRRRRk........",
	"...kYYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk.......",
	"...kYYYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk......",
	"...kYYYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk.....",
	"...kYYYYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk....",
	"...kYYYYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk...",
	"....kYYYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk...",
	"....kYYYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk..",
	".....kYYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk..",
	"......kYYYYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk..",
	".......kkYYYRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk...",
	".........kkRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRk....",
	"..........kRRRRrrRRRRRRRRRRRRRRRRRrrRRRRRkk.....",
	"..........kRRRrrrrRRRRRRRRRRRRRRRrrrrRRRk.......",
	"..........kRRrrkkrrRkkkkkkkkkkkkRrrkkrrRk.......",
	"..........kRRrk..krRk..........kRrk..krRk.......",
	".........kRRrk...krRk.........kRRrk..krRk.......",
	".........kRrk....kkRk.........kRrk....kRk.......",
	"........kWkWk...kWkWk........kWkWk...kWkWk......",
	"........kkkkk...kkkkk........kkkkk...kkkkk......",
]
const DRAGON_WING := [  # 30 x 13 (flipped vertically for the down beat)
	"......................k.......",
	"....................kkrk......",
	"..................kkrrrk......",
	"...............kkkrrrrrk......",
	"............kkkrrrrRrrrk......",
	".........kkkrrrrrrRRrrrk......",
	"......kkkrrrrrrrRRRrrrrk......",
	"....kkrrrrrrrrRRRRrrrrk.......",
	"..kkrrrrrrrrRRRRRrrrrrk.......",
	".krrrrrrrrRRRRRRrrrrrk........",
	"krrrrrrRRRRRRRRrrrrrk.........",
	"kkkrrrRRRRRRrrrrrrkk..........",
	"...kkkkkkkkkkkkkkk............",
]
const GLYPHS := {  # 3 x 5 pixel font for the key prompts
	"A": [".k.", "k.k", "kkk", "k.k", "k.k"], "D": ["kk.", "k.k", "k.k", "k.k", "kk."],
	"J": ["..k", "..k", "..k", "k.k", ".k."], "S": [".kk", "k..", ".k.", "..k", "kk."],
	"P": ["kk.", "k.k", "kk.", "k..", "k.."], "C": [".kk", "k..", "k..", "k..", ".kk"],
	"E": ["kkk", "k..", "kk.", "k..", "kkk"],
}
static var _px_cache := {}

## A sprite texture: res://assets/pixel/<name>.png if the artists have made one, else baked from ASCII.
static func px(name: String, rows: Array) -> Texture2D:
	if _px_cache.has(name):
		return _px_cache[name]
	var path := "res://assets/pixel/%s.png" % name
	var t: Texture2D
	if ResourceLoader.exists(path):
		t = load(path)
	else:
		var w := 0
		for r in rows:
			w = maxi(w, r.length())
		var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
		for y in rows.size():
			for x in rows[y].length():
				var ch: String = rows[y][x]
				if PAL.has(ch):
					img.set_pixel(x, y, PAL[ch])
		t = ImageTexture.create_from_image(img)
	_px_cache[name] = t
	return t

## Draw a sprite with its bottom-centre at `foot`; flip = mirror horizontally.
static func blit(ci: CanvasItem, tex: Texture2D, foot: Vector2, flip := false, tint := Color.WHITE, vflip := false) -> void:
	var s := tex.get_size()
	ci.draw_set_transform(foot, 0.0, Vector2(-1.0 if flip else 1.0, -1.0 if vflip else 1.0))
	ci.draw_texture(tex, Vector2(-floorf(s.x / 2.0), 0.0 if vflip else -s.y), tint)
	ci.draw_set_transform(Vector2.ZERO)


## Art frames only: all timing and state transitions remain owned by gameplay.
static var _frame_cache := {}
static func frame(name: String, action: String, clock: float, fps: float, rows: Array = []) -> Texture2D:
	var key := name + "_" + action
	if not _frame_cache.has(key):
		var sequence: Array[Texture2D] = []
		var index := 0
		while ResourceLoader.exists("res://assets/pixel/%s_%s_%d.png" % [name, action, index]):
			sequence.append(load("res://assets/pixel/%s_%s_%d.png" % [name, action, index]))
			index += 1
		_frame_cache[key] = sequence
	var frames: Array = _frame_cache[key]
	return px(name, rows) if frames.is_empty() else frames[int(maxf(clock, 0.0) * fps) % frames.size()]

static func stamp(ci: CanvasItem, name: String, position: Vector2, tint := Color.WHITE) -> void:
	ci.draw_texture(px(name, []), position.round(), tint)

## Crop partial edge tiles instead of stretching them. Collision rectangles are untouched.
static func tiles(ci: CanvasItem, rect: Rect2, name: String) -> void:
	var texture := px(name, [])
	var size := texture.get_size()
	for y in range(0, ceili(rect.size.y), int(size.y)):
		for x in range(0, ceili(rect.size.x), int(size.x)):
			var extent := Vector2(minf(size.x, rect.size.x-x), minf(size.y, rect.size.y-y))
			ci.draw_texture_rect_region(texture, Rect2(rect.position+Vector2(x,y), extent), Rect2(Vector2.ZERO, extent))

static func parallax(ci: CanvasItem, name: String, left: float, speed: float, y: float) -> void:
	var offset := floorf(fposmod(left * speed, W))
	stamp(ci, name, Vector2(left-offset, y))
	stamp(ci, name, Vector2(left-offset+W, y))

# ---------------------------------------------------------------- state
var active := false        ## the robot is in the game
var frozen := false        ## continue screen / the ending: nothing moves
var bot: PixelBot
var dragon: Dragon
var boss_started := false
var boss_beaten := false
var continues := 0
var hits_taken := 0
var kills := 0
var blocked_hits := 0
var batteries := 0
var screen_reached := 0
var cam: Camera2D
var enemies: Array = []    ## PixelThing nodes
var crumbles: Array = []   ## Crumble nodes
var _solids: Array = []    ## [Rect2, style]
var _platform: AnimatableBody2D
var _plat_t := 0.0
var _puffs: Array = []     ## [pos, t, colour]
var _t := 0.0
var _game_t := 0.0
var _cont_t := -1.0
var _shake := 0.0
var _hud: Node2D
var _jumped_pit := false
var _rescue_t := -1.0

func _ready() -> void:
	# ---- screen 1
	_add_solid(Rect2(0, 208, 120, 32), "grass")
	_add_solid(Rect2(152, 208, 248, 32), "grass")
	_add_solid(Rect2(232, 0, 88, 186), "rock")          # a cliff with a low tunnel under it
	# ---- screen 2
	_add_solid(Rect2(472, 208, 96, 32), "grass")
	_add_solid(Rect2(598, 208, 102, 32), "grass")
	_add_solid(Rect2(606, 184, 20, 24), "stone")        # the turret's block
	# ---- screen 3: crumbling planks over a long pit, then the knight's ground
	for p in [Vector2(712, 196), Vector2(756, 188), Vector2(800, 192), Vector2(844, 198)]:
		var c := Crumble.new()
		c.home = p
		add_child(c)
		crumbles.append(c)
	_add_solid(Rect2(884, 208, 116, 32), "grass")
	# ---- screen 4 + 5: castle stone; towers over a spike floor; the roof arena; the princess's ledge
	_add_solid(Rect2(1000, 208, 600, 32), "stone")
	for r in [Rect2(1040, 176, 30, 32), Rect2(1088, 148, 30, 60), Rect2(1136, 124, 36, 84), Rect2(1190, 150, 36, 58)]:
		_add_solid(r, "tower")
	_add_solid(Rect2(1560, 160, 32, 48), "stone")
	_add_solid(Rect2(1592, 0, 8, 208), "stone")
	_add_solid(Rect2(-8, 0, 8, 240), "rock")
	_platform = AnimatableBody2D.new()
	_platform.sync_to_physics = false
	var pcs := CollisionShape2D.new()
	var psh := RectangleShape2D.new()
	psh.size = Vector2(26, 8)
	pcs.shape = psh
	pcs.position = Vector2(13, 4)
	_platform.add_child(pcs)
	_platform.position = Vector2(404, 196)
	add_child(_platform)
	# ---- enemies
	_spawn(Slime.new(), Vector2(290, 208), {"a": 262.0, "b": 314.0})
	_spawn(Slime.new(), Vector2(520, 208), {"a": 480.0, "b": 560.0})
	_spawn(Bat.new(), Vector2(525, 150), {"a": 490.0, "b": 565.0})
	_spawn(Shooter.new(), Vector2(616, 184), {})
	_spawn(Bat.new(), Vector2(790, 140), {"a": 720.0, "b": 860.0})
	_spawn(Knight.new(), Vector2(990, 208), {"a": 944.0, "b": 1030.0})  # clear of the pit edge
	_spawn(Shooter.new(), Vector2(1162, 124), {})
	_spawn(Bat.new(), Vector2(1110, 110), {"a": 1060.0, "b": 1230.0})
	_spawn(Spikes.new(), Vector2(SPIKES.get_center().x, SPIKES.end.y), {"size": SPIKES.size})
	for p in [Vector2(436, 168), Vector2(778, 156), Vector2(1150, 104)]:  # over the platform, the bridge, the top tower
		_spawn(Battery.new(), p, {})
	dragon = Dragon.new()
	dragon.game = self
	add_child(dragon)
	# ---- robot, camera, HUD
	bot = PixelBot.new()
	bot.visible = false
	add_child(bot)
	cam = Camera2D.new()
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	cam.position = Vector2(W / 2.0, H / 2.0)
	add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Hud.new()
	_hud.game = self
	layer.add_child(_hud)

func _add_solid(r: Rect2, style: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = r.position + r.size / 2.0
	body.add_child(cs)
	add_child(body)
	_solids.append([r, style])
	return body

func _spawn(e: PixelThing, pos: Vector2, props: Dictionary) -> PixelThing:
	e.position = pos
	e.game = self
	for k in props:
		e.set(k, props[k])
	add_child(e)
	enemies.append(e)
	return e

## The robot arrives: drops in from the top-left.
func start() -> void:
	_respawn(0)
	active = true

func stop() -> void:
	active = false
	bot.visible = false

func _respawn(screen: int) -> void:
	bot.position = STARTS[screen]
	bot.velocity = Vector2.ZERO
	bot.facing = 1
	bot.visible = true
	bot.invuln = 0.6

func screen_pos(p: Vector2) -> Vector2:
	return p - cam.position + Vector2(W / 2.0, H / 2.0)

func _physics_process(delta: float) -> void:
	_t += delta
	bot.enabled = active and not frozen
	_plat_t += delta  # the moving platform (move_and_collide so the robot rides it)
	var px_ := 404.0 + (0.5 - 0.5 * cos(_plat_t * TAU / 2.6)) * 42.0
	_platform.move_and_collide(Vector2(px_ - _platform.position.x, 0))
	if active:
		_play(delta)
	for p in _puffs:
		p[1] += delta
	_puffs = _puffs.filter(func(p): return p[1] < 0.35)
	_shake = maxf(_shake - delta, 0.0)
	cam.offset = Vector2(randf_range(-2, 2), randf_range(-2, 2)) if _shake > 0.0 else Vector2.ZERO
	queue_redraw()
	_hud.queue_redraw()

func _play(delta: float) -> void:
	if _cont_t >= 0.0:  # continue screen: the coin drops, then back to the start of this screen
		_cont_t += delta
		if _cont_t > 1.4:
			_cont_t = -1.0
			frozen = false
			_respawn(screen_reached)
		return
	if _rescue_t >= 0.0:
		_rescue_t += delta
		return
	if frozen:
		return
	_game_t += delta
	screen_reached = maxi(screen_reached, clampi(int(bot.position.x / W), 0, 4))
	if bot.position.x > 152.0:
		_jumped_pit = true
	if Game.player:  # idle drain is gentle in here: hits and continues are what cost you
		_pay(Game.player.drain_per_sec * 0.3 * delta)
	var want := clampf(bot.position.x, W / 2.0, LEVEL_W - W / 2.0)
	if boss_started:
		want = ARENA_X + W / 2.0
	cam.position.x = lerpf(cam.position.x, want, 1.0 - exp(-8.0 * delta))
	if not boss_started and bot.position.x > ARENA_X + 24:  # the gate shuts behind you
		boss_started = true
		_add_solid(Rect2(ARENA_X, 112, 8, 96), "gate")
		puff(Vector2(ARENA_X + 4, 200))
		dragon.wake()
	if bot.position.y > H + 24 or (bot.hurt_rect().intersects(SPIKES) and bot.position.y > 200.0):
		_fall_out()  # a pit or the spike floor -> insert coin
		return
	var hurt := bot.hurt_rect()
	var claw := bot.claw_rect()
	for e in enemies.duplicate():
		if not is_instance_valid(e) or e.dead:
			continue
		if e is Battery:
			if hurt.intersects(e.rect()):
				e.dead = true
				e.queue_free()
				batteries += 1
				if Game.player:
					Game.player.add_charge(BATTERY_GAIN)
				puff(e.rect().get_center(), Color(0.3, 1.0, 0.95))
			continue
		if claw.has_area() and e.hittable() and claw.intersects(e.rect()) and bot.can_hit(e):
			bot.mark_hit(e)
			if e.blocks(bot.position):
				blocked_hits += 1
				puff(e.rect().get_center() + Vector2(-6 * signf(e.position.x - bot.position.x), -4), Color(0.8, 0.85, 1.0))
				bot.knock(signf(bot.position.x - e.position.x), 0.4)
				continue
			e.hit()
			if e.dead:
				kills += 1
				puff(e.rect().get_center())
		if not e.dead:
			for r in e.harm_rects():
				if hurt.intersects(r):
					_hurt(r.get_center())
					break
	if dragon.active:
		if claw.has_area() and dragon.head_hittable() and claw.intersects(dragon.head_rect()) and bot.can_hit(dragon):
			bot.mark_hit(dragon)
			dragon.hit()
			puff(dragon.head_rect().get_center())
		for r in dragon.harm_rects():
			if hurt.intersects(r):
				_hurt(r.get_center())
				break
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.dead)
	if boss_beaten and bot.is_on_floor() and hurt.intersects(PRINCESS.grow(2)):  # the princess: the end of the daydream
		frozen = true
		_rescue_t = 0.0
		rescued.emit()

func _fall_out() -> void:
	continues += 1
	_pay(CONTINUE_COST)
	frozen = true
	_cont_t = 0.0
	bot.visible = false

func _hurt(from: Vector2, upward := false) -> void:
	if bot.invuln > 0.0:
		return
	hits_taken += 1
	if "--tv-debug" in OS.get_cmdline_user_args():
		print("  HURT by %s at x=%.0f (dragon state %d, bot x=%.0f y=%.0f)" % [from, from.x, dragon.state, bot.position.x, bot.position.y])
	_pay(HIT_COST)
	bot.knock(signf(bot.position.x - from.x), 1.0, upward)

func _pay(c: float) -> void:
	if Game.player:
		Game.player.add_charge(-minf(c, maxf(Game.player.charge - 0.05, 0.0)))  # the game never kills you

func puff(p: Vector2, col := Color(1, 1, 0.9)) -> void:
	_puffs.append([p, 0.0, col])

func shake(t: float) -> void:
	_shake = t

func on_boss_beaten() -> void:
	boss_beaten = true
	for r in [Rect2(1520, 192, 16, 16), Rect2(1540, 176, 16, 32)]:  # steps up to the princess's ledge
		_add_solid(r, "stone")
		puff(r.get_center())

## Which key prompts to show right now (drawn by the HUD above the robot).
func hints() -> Array:
	var out := []
	if _game_t < 6.0 and absf(bot.position.x - STARTS[0].x) < 24.0:
		out.append("move")
	if not _jumped_pit and bot.position.x > 60.0 and bot.position.x < 152.0 and screen_reached == 0:
		out.append("jump")
	if kills == 0:
		for e in enemies:
			if is_instance_valid(e) and e.hittable() and absf(e.position.x - bot.position.x) < 70.0:
				out.append("attack")
				break
	if dragon.head_hittable() and dragon.hp == 6:
		out.append("attack")
	return out

func _draw() -> void:
	var cl := floorf(cam.position.x - W / 2.0)
	stamp(self, "bg_sky", Vector2(cl, 0))
	parallax(self, "bg_stars", cl, .10, 0)
	parallax(self, "bg_castle_far", cl, .12, 0)
	parallax(self, "bg_hills", cl, .50, 168)
	stamp(self, "bg_princess_tower", Vector2(1556,20))
	for solid in _solids:
		var rect: Rect2 = solid[0]
		match solid[1]:
			"grass":
				tiles(self, rect, "tile_dirt")
				tiles(self, Rect2(rect.position,Vector2(rect.size.x,minf(16,rect.size.y))), "tile_grass")
			"rock": tiles(self, rect, "tile_rock")
			"stone", "tower":
				tiles(self, rect, "tile_stone")
				if solid[1]=="tower":tiles(self,Rect2(rect.position-Vector2(0,8),Vector2(rect.size.x,8)),"tile_tower_top")
			"gate":stamp(self,"tile_gate",rect.position)
	stamp(self,"platform",_platform.position)
	var pf := PRINCESS.position + Vector2(PRINCESS.size.x / 2.0, PRINCESS.size.y)
	if boss_beaten:
		draw_rect(PRINCESS.grow(4), Color(1.0,.75,.35,.12+.08*sin(_t*4.0)))
	var action := "rescued" if _rescue_t>=0 else ("wave" if boss_beaten else "wait")
	blit(self,frame("princess",action,_t,3.0,PRINCESS_ART),pf)
	if _rescue_t >= 0:
		for i in 3:
			var hp_ := pf + Vector2(-6+i*6,-26-fmod(_rescue_t*14+i*5,18))
			stamp(self,"heart",hp_)
	for puff in _puffs:
		var k: float = puff[1] / .35
		for i in 6:
			var a := i * TAU / 6.0
			var col: Color = puff[2]
			col.a = 1.0-k
			draw_rect(Rect2(puff[0]+Vector2(cos(a),sin(a))*(3.0+10.0*k),Vector2(2,2)),col)

# ======================================================================= the robot
class PixelBot extends CharacterBody2D:
	## The tin robot, 12 x 13 pixels. A/D, Space (variable jump), J / left click = claw.
	const SPEED := 72.0
	const ACCEL := 900.0
	const GRAVITY := 720.0
	const JUMP := 235.0
	var enabled := false
	var facing := 1
	var invuln := 0.0
	var _coyote := 0.0
	var _buffer := 0.0
	var _walk := 0.0
	var _swing := 0.0      ## > 0 while the claw is out
	var _cool := 0.0
	var _knock := 0.0
	var _hit_this_swing := []

	func _ready() -> void:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(10, 13)
		cs.shape = sh
		cs.position = Vector2(0, -6.5)
		add_child(cs)

	func hurt_rect() -> Rect2:
		return Rect2(position + Vector2(-5, -13), Vector2(10, 13))

	## The claw's reach while it is out (early part of a swing), else empty.
	func claw_rect() -> Rect2:
		if _swing < 0.08:
			return Rect2()
		return Rect2(position + Vector2(2 if facing > 0 else -20, -14), Vector2(18, 14))

	func can_hit(e: Object) -> bool:
		return not _hit_this_swing.has(e)

	func mark_hit(e: Object) -> void:
		_hit_this_swing.append(e)

	func knock(dir: float, strength := 1.0, upward := false) -> void:
		var d := dir if dir != 0.0 else -float(facing)
		velocity = Vector2(d * 130.0 * strength, -220.0 if upward else -150.0 * strength)
		_knock = 0.3 * strength
		if strength >= 1.0:
			invuln = 1.0

	func _physics_process(delta: float) -> void:
		invuln = maxf(invuln - delta, 0.0)
		_swing = maxf(_swing - delta, 0.0)
		_cool = maxf(_cool - delta, 0.0)
		_knock = maxf(_knock - delta, 0.0)
		if not enabled:
			queue_redraw()
			return
		var on_floor := is_on_floor()
		velocity.y += GRAVITY * delta
		_coyote = 0.1 if on_floor else _coyote - delta
		_buffer = 0.12 if Input.is_action_just_pressed("jump") else _buffer - delta
		var x := Input.get_axis("move_left", "move_right")
		if _knock <= 0.0:
			velocity.x = move_toward(velocity.x, x * SPEED, ACCEL * delta)
			if absf(x) > 0.1:
				facing = 1 if x > 0 else -1
		if _buffer > 0.0 and _coyote > 0.0:
			velocity.y = -JUMP
			_buffer = 0.0
			_coyote = 0.0
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= 0.5
		if Input.is_action_just_pressed("attack") and _cool <= 0.0:
			_swing = 0.2
			_cool = 0.3
			_hit_this_swing.clear()
		move_and_slide()
		_walk += absf(velocity.x) * delta
		queue_redraw()

	func _draw() -> void:
		if invuln>0 and int(invuln*20.0)%2==0:return
		var f := float(facing)
		var action := "idle"
		if invuln>0:action="hurt"
		elif not is_on_floor():action="jump" if velocity.y<0 else "fall"
		elif absf(velocity.x)>5:action="walk"
		var bob := -1.0 if is_on_floor() and absf(velocity.x)>5 and int(_walk/4.0)%2==0 else 0.0
		var clock := _walk/32.0 if action=="walk" else Time.get_ticks_msec()/1000.0
		TvGame.blit(self,TvGame.frame("bot",action,clock,8.0 if action=="walk" else 3.0,BOT),Vector2(0,bob),f<0)
		if _swing>0:
			draw_set_transform(Vector2(2*f,-9+bob),0,Vector2(f,1))
			draw_texture(TvGame.frame("bot_claw","attack",.2-_swing,15),Vector2.ZERO)
			draw_set_transform(Vector2.ZERO)
			if _swing>.08:
				var reach := 4.0+10.0*sin(clampf(1.0-_swing/.2,0,1)*PI)
				var tip := Vector2((5+reach)*f,-6+bob)
				for i in 5:
					var a := -1.0+i*.5
					draw_rect(Rect2(tip+Vector2(cos(a)*7*f,sin(a)*7),Vector2.ONE),Color(1,1,.85))

# ======================================================================= level pieces
class Crumble extends StaticBody2D:
	## A rotten plank: stand on it and it shakes for a moment, then drops; it comes back a bit later.
	const SIZE := Vector2(24, 6)
	var home := Vector2.ZERO
	var state := 0          ## 0 solid, 1 shaking, 2 gone
	var _t := 0.0
	var _cs: CollisionShape2D
	func _ready() -> void:
		position = home
		_cs = CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = SIZE
		_cs.shape = sh
		_cs.position = SIZE / 2.0
		add_child(_cs)
	func _physics_process(delta: float) -> void:
		var g: TvGame = get_parent()
		if g.frozen:
			return
		_t += delta
		var b: PixelBot = g.bot
		match state:
			0:
				if b.is_on_floor() and absf(b.position.y - home.y) < 2.0 and b.position.x > home.x - 5.0 and b.position.x < home.x + SIZE.x + 5.0:
					state = 1
					_t = 0.0
			1:
				if _t > 0.45:
					state = 2
					_t = 0.0
					_cs.set_deferred("disabled", true)
			2:
				if _t > 2.5:
					state = 0
					_cs.set_deferred("disabled", false)
		queue_redraw()
	func _draw() -> void:
		var o := Vector2.ZERO
		if state==1:o.x=1.0 if int(_t*30.0)%2==0 else -1.0
		elif state==2:
			if _t>.6:return
			o.y=_t*_t*300.0
		TvGame.stamp(self,"plank_shake" if state==1 else "plank",o)

# ======================================================================= enemies
class PixelThing extends Node2D:
	var game: TvGame
	var dead := false
	var size := Vector2(10, 10)
	func rect() -> Rect2:
		return Rect2(position + Vector2(-size.x / 2.0, -size.y), size)
	func harm_rects() -> Array:
		return [rect()]
	func hittable() -> bool:
		return true
	func blocks(_from: Vector2) -> bool:
		return false
	func hit() -> void:
		dead = true
		queue_free()

class Slime extends PixelThing:
	## Crawls back and forth between a and b.
	var a := 0.0
	var b := 0.0
	var _dir := 1.0
	var _t := 0.0
	func _ready() -> void:
		size = Vector2(12, 8)
	func _physics_process(delta: float) -> void:
		if game.frozen:
			return
		_t += delta
		position.x += _dir * 18.0 * delta
		if position.x > b or position.x < a:
			_dir = -_dir
			position.x = clampf(position.x, a, b)
		queue_redraw()
	func _draw() -> void:
		TvGame.blit(self,TvGame.frame("slime","crawl",_t,6.0,SLIME),Vector2.ZERO,_dir<0)


class Bat extends PixelThing:
	## Flaps between a and b, bobbing up and down.
	var a := 0.0
	var b := 0.0
	var _dir := 1.0
	var _t := 0.0
	var _y0 := 0.0
	func _ready() -> void:
		size = Vector2(12, 6)
		_y0 = position.y
	func _physics_process(delta: float) -> void:
		if game.frozen:
			return
		_t += delta
		position.x += _dir * 30.0 * delta
		if position.x > b or position.x < a:
			_dir = -_dir
			position.x = clampf(position.x, a, b)
		position.y = _y0 + sin(_t * 2.4) * 22.0
		queue_redraw()
	func _draw() -> void:
		TvGame.blit(self,TvGame.frame("bat","flap",_t,10.0,BAT),Vector2.ZERO,_dir<0)


class Shooter extends PixelThing:
	## A little cannon: spits a slow orb at the robot every couple of seconds (its eye glows first).
	var _cd := 1.0
	func _ready() -> void:
		size = Vector2(12, 10)
	func _physics_process(delta: float) -> void:
		if game.frozen:
			return
		_cd -= delta
		if _cd <= 0.0 and game.active and absf(game.bot.position.x - position.x) < 200.0:
			_cd = 2.2
			var from := position + Vector2(-8, -5)
			var aim := (game.bot.position + Vector2(0, -6) - from).normalized()
			if aim.x > 0.2:
				aim = Vector2(-1, 0)  # only fires forward (left)
			game._spawn(Orb.new(), from, {"vel": aim * 62.0})
		queue_redraw()
	func _draw() -> void:
		var charge := _cd<.45
		TvGame.blit(self,TvGame.frame("turret","charge" if charge else "idle",0,1,TURRET),Vector2.ZERO,false,
			Color(1.6,1.3,1.0) if charge and int(_cd*20.0)%2==0 else Color.WHITE)


class Battery extends PixelThing:
	## A pixel battery: touch it for +5% real charge. Bobs gently.
	var _t := 0.0
	func _ready() -> void:
		size = Vector2(6, 9)
	func hittable() -> bool:
		return false
	func harm_rects() -> Array:
		return []
	func _physics_process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		TvGame.blit(self,TvGame.frame("battery","shine",_t,3.0,BATTERY),Vector2(0,roundf(sin(_t*3.0)*1.5)))


class Orb extends PixelThing:
	var vel := Vector2(-62, 0)
	var _life := 3.5
	func _ready() -> void:
		size = Vector2(6, 6)
	func hittable() -> bool:
		return false
	func _physics_process(delta: float) -> void:
		if game.frozen:
			return
		position += vel * delta
		_life -= delta
		if _life <= 0.0:
			dead = true
			queue_free()
		queue_redraw()
	func _draw() -> void:
		TvGame.blit(self,TvGame.frame("orb","pulse",Time.get_ticks_msec()/1000.0,8),Vector2.ZERO)


class Spikes extends PixelThing:
	## The floor under the battlements. Touch = like falling into a pit (handled by the game).
	func hittable() -> bool:
		return false
	func harm_rects() -> Array:
		return []
	func _draw() -> void:
		for x in range(int(-size.x/2),int(size.x/2),6):TvGame.stamp(self,"spikes",Vector2(x,-size.y))


class Knight extends PixelThing:
	## A shield knight. Walks its patch facing the robot; claw hits on the shield bounce off. When the
	## robot comes close it raises its sword (flashing), thrusts forward, then stands open for a moment
	## (shield lowered) - that's when to hit it. Hits from behind always land. 2 hits.
	enum { WALK, WINDUP, THRUST, RECOVER }
	var a := 0.0
	var b := 0.0
	var hp := 2
	var state := WALK
	var face := -1.0           ## -1 = facing left
	var _st := 0.0
	var _cool := 0.0
	var _flash := 0.0
	func _ready() -> void:
		size = Vector2(12, 17)
	func blocks(from: Vector2) -> bool:
		var in_front := signf(from.x - position.x) == face
		return in_front and state != RECOVER
	func harm_rects() -> Array:
		var out := [rect()]
		if state == THRUST:
			out.append(Rect2(position + Vector2(face * 6.0 if face > 0 else -22.0, -11), Vector2(16, 4)))
		return out
	func hit() -> void:
		hp -= 1
		_flash = 0.2
		if hp <= 0:
			dead = true
			queue_free()
		else:
			state = WALK
			_cool = 0.8
	func _physics_process(delta: float) -> void:
		if game.frozen:
			return
		_st += delta
		_cool = maxf(_cool - delta, 0.0)
		_flash = maxf(_flash - delta, 0.0)
		var bot: PixelBot = game.bot
		var dx := bot.position.x - position.x
		match state:
			WALK:
				if absf(dx) < 90.0:
					face = signf(dx) if dx != 0.0 else face
					if absf(dx) > 30.0:
						position.x = clampf(position.x + face * 14.0 * delta, a, b)
					elif _cool <= 0.0 and absf(bot.position.y - position.y) < 20.0:
						state = WINDUP
						_st = 0.0
			WINDUP:
				if _st > 0.55:
					state = THRUST
					_st = 0.0
			THRUST:
				position.x = clampf(position.x + face * 60.0 * delta, a, b)
				if _st > 0.18:
					state = RECOVER
					_st = 0.0
			RECOVER:
				if _st > 0.85:
					state = WALK
					_st = 0.0
					_cool = 0.6
		queue_redraw()
	func _draw() -> void:
		var tint := Color(3,3,3) if _flash>0 else Color.WHITE
		var action: String = ["walk","windup","thrust","recover"][state]
		TvGame.blit(self,TvGame.frame("knight",action,_st,8.0,KNIGHT),Vector2.ZERO,face>0,tint)
		match state:
			WINDUP:
				var c := Color(1,1,1) if int(_st*14.0)%2==0 else Color.WHITE
				draw_set_transform(Vector2(-face*2,-26),PI/2)
				draw_texture(TvGame.px("knight_sword",[]),Vector2.ZERO,c)
				draw_set_transform(Vector2.ZERO)
			THRUST:
				TvGame.blit(self,TvGame.px("knight_sword",[]),Vector2(face*14,-8),face>0)


class Fireball extends PixelThing:
	## Drops from the dragon's mouth to the floor, then rolls left along it.
	var vel := Vector2(-60, 40)
	var roll := 105.0
	var _life := 6.0
	func _ready() -> void:
		size = Vector2(8, 8)
	func hittable() -> bool:
		return false
	func _physics_process(delta: float) -> void:
		if game.frozen:
			return
		position += vel * delta
		if position.y >= 208.0:
			position.y = 208.0
			vel = Vector2(-roll, 0)
		_life -= delta
		if _life <= 0.0 or position.x < ARENA_X + 8:
			dead = true
			queue_free()
		queue_redraw()
	func _draw() -> void:
		TvGame.blit(self,TvGame.frame("fireball","roll",Time.get_ticks_msec()/1000.0,12),Vector2.ZERO)

# ======================================================================= the dragon
class Dragon extends Node2D:
	## Sits on the right of the castle roof. 6 hits; it can only be hit while its head lies dazed.
	## Phase 1: FIRE (rears, mouth glows, one rolling fireball) / LUNGE (marker on the floor, head slams
	## down there, then lies dazed). At 3 hits left it ROARS (screen shakes) -> phase 2: faster warnings,
	## three fireballs in a row, double lunges (dazed only after the second), a TAIL sweep along the floor.
	enum { SLEEP, IDLE, FIRE_WARN, FIRE, LUNGE_WARN, LUNGE, LIFT, DAZED, RETRACT, TAIL_WARN, TAIL, ROAR, DYING, GONE }
	const FOOT := Vector2(1552, 208)               ## the body sprite's bottom-centre
	const BODY := Rect2(1532, 182, 40, 26)         ## what hurts to touch
	const HEAD_IDLE := Vector2(1500, 140)
	const SHOULDER := Vector2(1538, 186)
	const TAIL_BASE := Vector2(1574, 196)
	var game: TvGame
	var state := SLEEP
	var hp := 6
	var phase2 := false
	var active := false
	var head := HEAD_IDLE
	var tail_tip := Vector2(1588, 176)
	var _to := Vector2.ZERO
	var _t := 0.0
	var _st := 0.0
	var _from := Vector2.ZERO
	var _flash := 0.0
	var _queue: Array = []
	var _shots := 0
	var _lunges := 0

	func wake() -> void:
		active = true
		_go(IDLE)

	func _go(s: int) -> void:
		state = s
		_st = 0.0
		_from = head

	func head_rect() -> Rect2:
		return Rect2(head + Vector2(-11, -7), Vector2(22, 14))

	func head_hittable() -> bool:
		return state == DAZED

	func harm_rects() -> Array:
		var out := [BODY]
		if state == LUNGE and _st >= 0.14:  # only the straight drop onto the marker hurts
			out.append(head_rect())
		if state == TAIL:
			out.append(Rect2(tail_tip + Vector2(-8, -6), Vector2(16, 10)))
		return out

	func hit() -> void:
		hp -= 1
		_flash = 0.25
		if hp <= 0:
			_go(DYING)
		elif hp == 3 and not phase2:
			_go(ROAR)
		else:
			_go(RETRACT)

	func _warn(base: float) -> float:
		return base * (0.72 if phase2 else 1.0)

	func _next() -> void:
		if _queue.is_empty():
			_queue = ["fire3", "lunge2", "tail", "lunge2"] if phase2 else ["fire", "lunge"]
		match _queue.pop_front():
			"fire":
				_shots = 1
				_go(FIRE_WARN)
			"fire3":
				_shots = 3
				_go(FIRE_WARN)
			"lunge":
				_lunges = 1
				_lunge_warn()
			"lunge2":
				_lunges = 2
				_lunge_warn()
			"tail":
				_go(TAIL_WARN)

	func _lunge_warn() -> void:
		_go(LUNGE_WARN)
		_to = Vector2(clampf(game.bot.position.x, ARENA_X + 36.0, 1486.0), 201.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		_flash = maxf(_flash - delta, 0.0)
		if not active or game.frozen:
			queue_redraw()
			return
		_st += delta
		var bob := Vector2(0, sin(_t * 2.0) * 3.0)
		var k := 1.0 - exp(-7.0 * delta)
		if state != TAIL:
			tail_tip = tail_tip.lerp(Vector2(1590, 172) + Vector2(0, sin(_t * 1.5) * 4.0) if state != TAIL_WARN else Vector2(1596, 150), k)
		match state:
			IDLE:
				head = head.lerp(HEAD_IDLE + bob, k)
				if _st > (0.7 if phase2 else 1.0):
					_next()
			FIRE_WARN:
				head = head.lerp(HEAD_IDLE + Vector2(6, -12), k)
				if _st > _warn(0.6):
					_go(FIRE)
			FIRE:
				if _shots > 0 and _st > 0.0:
					game._spawn(Fireball.new(), head + Vector2(-12, 4), {"roll": 120.0 if phase2 else 105.0})
					_shots -= 1
					_st = -0.42
				elif _shots <= 0 and _st > 0.2:
					_go(IDLE)
			LUNGE_WARN:
				head = head.lerp(HEAD_IDLE + Vector2(22, -14), k)
				if _st > _warn(0.75 if _lunges == 2 or not phase2 else 0.6):
					_go(LUNGE)
			LUNGE:  # across overhead, then straight down onto the marked spot
				var over := Vector2(_to.x, 150.0)
				if _st < 0.14:
					head = _from.lerp(over, _st / 0.14)
				else:
					head = over.lerp(_to, clampf((_st - 0.14) / 0.1, 0.0, 1.0))
				if _st > 0.24:
					game.shake(0.15)
					_lunges -= 1
					_go(LIFT if _lunges > 0 else DAZED)
			LIFT:  # between the two lunges of a double: up a little, pick a new spot
				head = _from.lerp(HEAD_IDLE + Vector2(14, -6), clampf(_st / 0.3, 0.0, 1.0))
				if _st > 0.3:
					_go(LUNGE_WARN)
					_to = Vector2(clampf(game.bot.position.x, ARENA_X + 36.0, 1486.0), 201.0)
					_st = 0.25  # the second warning is shorter
			DAZED:
				if _st > (1.15 if phase2 else 1.5):
					_go(RETRACT)
			RETRACT:
				head = _from.lerp(HEAD_IDLE, clampf(_st / 0.45, 0.0, 1.0))
				if _st > 0.45:
					_go(IDLE)
			TAIL_WARN:
				head = head.lerp(HEAD_IDLE + Vector2(10, -4), k)
				if _st > _warn(0.8):
					_go(TAIL)
			TAIL:  # the tail tip sweeps along the floor to the gate and back at a steady speed: jump it twice
				var span := 1590.0 - (ARENA_X + 16.0)
				var u := _st / (span / 170.0)
				tail_tip = Vector2(1590.0 - span * (u if u <= 1.0 else 2.0 - u), 202.0)
				if u >= 2.0:
					_go(IDLE)
			ROAR:
				head = head.lerp(HEAD_IDLE + Vector2(8, -22), k)
				if _st < 0.1:
					game.shake(1.1)
				if _st > 1.3:
					phase2 = true
					_queue.clear()
					_go(IDLE)
			DYING:
				if _st > 1.4:
					state = GONE
					active = false
					game.puff(BODY.get_center())
					game.puff(head)
					game.on_boss_beaten()
		queue_redraw()

	func _draw() -> void:
		if state==GONE or (state==DYING and int(_st*14.0)%2==0):return
		var tint := Color(3,3,3) if _flash>0 else Color.WHITE
		if phase2 and _flash<=0:tint=Color(1.15,.95,.95)
		var tail_tint := tint
		if state==TAIL_WARN and int(_st*12.0)%2==0:tail_tint=Color(1,.9,.9)
		for i in 9:
			var u := i/8.0
			var mid := TAIL_BASE.lerp(tail_tip,u)+Vector2(0,-sin(u*PI)*(10.0 if state!=TAIL else 2.0))
			var diameter := roundf(lerpf(12,4,u))
			# Tail segments intentionally shrink, as required by the articulated boss design.
			draw_texture_rect(TvGame.px("dragon_tail",[]),Rect2(mid-Vector2.ONE*diameter/2,Vector2.ONE*diameter),false,tail_tint)
		TvGame.stamp(self,"dragon_tail_tip",tail_tip-Vector2(2,4),tail_tint)
		var up := int(_t*(6.0 if phase2 else 4.0))%2==0
		TvGame.blit(self,TvGame.px("dragon_wing" if up else "dragon_wing_down",DRAGON_WING),FOOT+Vector2(12,-20 if up else -8),false,tint)
		var open := state in [FIRE_WARN,FIRE,ROAR]
		var name := "dragon_head_dazed" if state==DAZED else ("dragon_head_open" if open else "dragon_head")
		TvGame.blit(self,TvGame.px(name,DRAGON_HEAD_OPEN if open else DRAGON_HEAD),head+Vector2(0,7),false,tint)
		# Visual sockets follow the PNG artwork; collision and animated head remain unchanged.
		var neck_base := FOOT+Vector2(-10,-27)
		var neck_top := head+Vector2(9,3)
		var neck_steps := maxi(2,ceili(neck_base.distance_to(neck_top)/6.0)+1)
		for i in neck_steps:
			var p := neck_base.lerp(neck_top,float(i)/(neck_steps-1)).round()
			TvGame.blit(self,TvGame.px("dragon_neck",[]),p+Vector2(0,5),false,tint)
		TvGame.blit(self,TvGame.px("dragon_body",DRAGON_BODY),FOOT,false,tint)
		if state==LUNGE_WARN:
			draw_rect(Rect2(_to.x-11,205,22,3),Color(.95,.2,.15,.45+.45*sin(_st*30.0)))
		var hr := head_rect()
		if state==FIRE_WARN and int(_st*12.0)%2==0:
			draw_rect(Rect2(hr.position+Vector2(1,10),Vector2(7,2)),Color(1,.95,.5))
		if state==LUNGE_WARN and int(_st*12.0)%2==0:
			draw_rect(Rect2(hr.position+Vector2(13,5),Vector2(3,2)),Color(1,1,1))
		if state==DAZED:
			for i in 3:
				var a := _t*5+i*TAU/3
				draw_rect(Rect2(hr.get_center()+Vector2(cos(a)*10,-12+sin(a)*3),Vector2(2,2)),Color(1,1,.6))

# ======================================================================= HUD (screen space)
class Hud extends Node2D:
	## The robot's battery (top-left), the dragon's life (top-right), key prompts over the robot,
	## and the "insert coin" continue screen. All drawn in pixels, no text.
	var game: TvGame
	func _draw() -> void:
		var ch := 1.0
		if Game.player:
			ch = Game.player.charge
		TvGame.stamp(self,"hud_battery",Vector2(18,16))
		var cells := ceili(ch*5.0-.001)
		for i in 5:TvGame.stamp(self,"hud_cell_on" if i<cells else "hud_cell_off",Vector2(21+i*6,19))
		if game.boss_started and not game.boss_beaten:
			for i in 6:
				TvGame.stamp(self,"hud_boss_pip_on" if i<game.dragon.hp else "hud_boss_pip_off",Vector2(W-28-i*9,18))
		# key prompts above the robot
		var hs: Array = game.hints() if game.active and not game.frozen else []
		if not hs.is_empty():
			var p := game.screen_pos(game.bot.position) + Vector2(0, -24)
			var blink := int(game._t * 3.0) % 2 == 0
			var x := p.x
			var items := []
			for h in hs:
				match h:
					"move": items += ["A", "D"]
					"jump": items.append("SPACE")
					"attack": items += ["J", "mouse"]
			var w := 0.0
			for it in items:
				w += _cap_w(it) + 3.0
			x -= w / 2.0
			for it in items:
				if it == "mouse":
					_mouse(Vector2(x, p.y - 2), blink)
				else:
					_cap(it, Vector2(x, p.y), blink)
				x += _cap_w(it) + 3.0
		if game._cont_t >= 0.0:  # insert coin: a cyan cell drops out of the robot's battery into the slot
			var k := clampf(game._cont_t / 1.0, 0.0, 1.0)
			draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.75))
			TvGame.stamp(self,"coin_slot",Vector2(140,150))
			if k < 1.0:
				TvGame.stamp(self,"coin_cell",Vector2(156,lerpf(70,150,k*k)))
			elif int(game._cont_t * 10.0) % 2 == 0:
				draw_rect(Rect2(150, 140, 20, 6), Color(1.0, 0.85, 0.4))

	func _cap_w(label: String) -> float:
		return 9.0 if label=="mouse" else (25.0 if label=="SPACE" else 13.0)

	func _cap(label: String, pos: Vector2, lit: bool) -> void:
		TvGame.stamp(self,"key_"+label,pos,Color.WHITE if lit else Color(.78,.78,.78))

	func _mouse(pos: Vector2, lit: bool) -> void:
		TvGame.stamp(self,"key_mouse",pos,Color.WHITE if lit else Color(.78,.78,.78))
