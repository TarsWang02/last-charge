extends SceneTree
var room: Node3D
var game
const SIZES={"bot": [12, 13], "bot_idle_0": [12, 13], "bot_idle_1": [12, 13], "bot_walk_0": [12, 13], "bot_walk_1": [12, 13], "bot_walk_2": [12, 13], "bot_walk_3": [12, 13], "bot_jump_0": [12, 13], "bot_fall_0": [12, 13], "bot_hurt_0": [12, 13], "bot_claw": [20, 6], "bot_claw_attack_0": [20, 6], "bot_claw_attack_1": [20, 6], "bot_claw_attack_2": [20, 6], "slime": [12, 8], "slime_crawl_0": [12, 8], "slime_crawl_1": [12, 8], "bat": [12, 6], "bat_flap_0": [12, 6], "bat_flap_1": [12, 6], "turret": [12, 10], "turret_idle_0": [12, 10], "turret_charge_0": [12, 10], "orb": [6, 6], "orb_pulse_0": [6, 6], "orb_pulse_1": [6, 6], "knight": [14, 17], "knight_walk_0": [14, 17], "knight_walk_1": [14, 17], "knight_windup_0": [14, 17], "knight_thrust_0": [14, 17], "knight_recover_0": [14, 17], "knight_sword": [16, 3], "princess": [13, 19], "princess_wait_0": [13, 19], "princess_wait_1": [13, 19], "princess_wave_0": [13, 19], "princess_wave_1": [13, 19], "princess_rescued_0": [13, 19], "princess_rescued_1": [13, 19], "battery": [6, 9], "battery_shine_0": [6, 9], "battery_shine_1": [6, 9], "heart": [5, 4], "dragon_head": [24, 14], "dragon_head_open": [24, 15], "dragon_head_dazed": [24, 14], "dragon_wing": [30, 13], "dragon_wing_down": [30, 13], "dragon_neck": [10, 10], "dragon_tail": [12, 12], "dragon_tail_tip": [10, 8], "fireball": [8, 8], "fireball_roll_0": [8, 8], "fireball_roll_1": [8, 8], "tile_grass": [16, 16], "tile_dirt": [16, 16], "tile_rock": [16, 16], "tile_stone": [16, 16], "tile_tower_top": [8, 8], "tile_gate": [8, 96], "plank": [24, 6], "plank_shake_0": [24, 6], "plank_shake_1": [24, 6], "plank_shake": [24, 6], "platform": [26, 8], "spikes": [6, 6], "bg_sky": [320, 240], "bg_stars": [320, 240], "bg_hills": [320, 40], "bg_castle_far": [320, 240], "bg_princess_tower": [44, 140], "hud_battery": [36, 12], "hud_cell_on": [4, 6], "hud_cell_off": [4, 6], "hud_boss_pip_on": [6, 6], "hud_boss_pip_off": [6, 6], "key_A": [13, 10], "key_D": [13, 10], "key_J": [13, 10], "key_SPACE": [25, 10], "key_mouse": [9, 13], "coin_cell": [8, 10], "coin_slot": [40, 30], "dragon_body": [48, 31]}
const OUT="res://shots/pixel_art_review"
func _initialize():call_deferred("run")
func shot(name: String):
    game.cam.process_mode=Node.PROCESS_MODE_ALWAYS
    game.cam.force_update_scroll()
    await create_timer(.1).timeout
    game.queue_redraw();game._hud.queue_redraw();game.bot.queue_redraw();game.dragon.queue_redraw()
    for enemy in game.enemies:
        if is_instance_valid(enemy):enemy.queue_redraw()
    await process_frame;await RenderingServer.frame_post_draw
    room.get_node("Stop3/TvScreen").viewport.get_texture().get_image().save_png(OUT.path_join(name+".png"))
func run():
    DirAccess.make_dir_recursive_absolute(OUT)
    room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
    await create_timer(.3).timeout
    game=room.get_node("Stop3/TvScreen").game
    game.process_mode=Node.PROCESS_MODE_DISABLED
    game.active=true;game.frozen=false;game._game_t=1;game._t=.2
    game.bot.visible=true;game.bot.invuln=0;game.bot.position=Vector2(40,208)
    var dimensions_ok:=true
    for name in SIZES:
        var expected: Array=SIZES[name]
        var texture=load("res://assets/pixel/"+name+".png")
        if not texture or texture.get_size()!=Vector2(expected[0],expected[1]):dimensions_ok=false
    await shot("opening")
    game.cam.position.x=800;game.bot.position=Vector2(770,177)
    await shot("bridge_and_knight")
    game.boss_started=true;game.cam.position.x=1440;game.bot.position=Vector2(1360,208)
    game.dragon.state=game.dragon.FIRE_WARN;game.dragon._st=.3;game.dragon._t=.2
    await shot("fire_warning")
    game.dragon.state=game.dragon.LUNGE_WARN;game.dragon._to=Vector2(1410,201)
    await shot("lunge_warning")
    game.dragon.state=game.dragon.DAZED;game.dragon.head=Vector2(1420,200)
    await shot("dazed_head")
    game.dragon.state=game.dragon.TAIL_WARN;game.dragon.phase2=true;game.dragon.hp=3
    await shot("phase2_tail_warning")
    game.dragon.state=game.dragon.GONE;game.boss_beaten=true;game._rescue_t=.3
    await shot("princess_rescued")
    game._cont_t=.6
    await shot("continue_coin")
    print("PIXELARTTEST ",JSON.stringify({"native_resolution":game.get_parent().size==Vector2i(320,240),"all_dimensions_match":dimensions_ok,"png_count":SIZES.size(),"nearest_filter":game.get_parent().canvas_item_default_texture_filter==Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST,"frame_sequences_loaded":game._frame_cache.size()>0}))
    quit(0 if dimensions_ok else 1)


