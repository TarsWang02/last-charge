extends SceneTree
var out := "res://shots/maze_seeds"
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--seed-output="): out = arg.trim_prefix("--seed-output=")
    DirAccess.make_dir_recursive_absolute(out)
    var rows := []
    var candidates := []
    var file := FileAccess.open(out.path_join("stats.csv"), FileAccess.WRITE)
    file.store_line("seed,path_len,holes,dead_ends,turns_on_path,has_eraser,has_lamp,note_on_path")
    for i in range(500):
        var maze: DeskMaze = load("res://scripts/desk_maze.gd").new()
        maze.used_seed = i
        maze.rng.seed = i
        maze.goal = Vector2i(maze.cols - 1, maze.rows - 1)
        maze._carve()
        maze.path = maze._solve()
        maze._place_eraser_hole()
        maze._choose_item_cells()
        maze._place_holes()
        var turns := 0
        for j in range(2, maze.path.size()):
            if maze.path[j] - maze.path[j-1] != maze.path[j-1] - maze.path[j-2]: turns += 1
        var row := {"seed":i,"path_len":maze.path.size(),"holes":maze.holes.size(),"dead_ends":maze.open.keys().filter(func(c):return maze.open[c].size()==1).size(),"turns_on_path":turns,"has_eraser":maze.eraser_index>0,"has_lamp":maze.light_specs.any(func(sp):return sp[4]=="lamp"),"note_on_path":maze.path.has(maze.note_cell)}
        rows.append(row)
        file.store_line("%d,%d,%d,%d,%d,%s,%s,%s" % [i,row.path_len,row.holes,row.dead_ends,turns,row.has_eraser,row.has_lamp,row.note_on_path])
        if row.path_len>=22 and row.path_len<=30 and row.holes>=10 and row.holes<=18 and turns>=10 and row.has_eraser and row.has_lamp and not row.note_on_path:
            candidates.append(row)
        maze.free()
    file.close()
    var json := FileAccess.open(out.path_join("candidates.json"),FileAccess.WRITE)
    json.store_string(JSON.stringify(candidates.slice(0,24),"\t"))
    print("SEED_CANDIDATES ",JSON.stringify(candidates.slice(0,24)))
    if "--render" in OS.get_cmdline_user_args():
        var renderer = load("res://tools/maze_seed_render.gd")
        # Rendering is a separate graphical run; the stats-only mode stays headless.
        var args := ["--path", ProjectSettings.globalize_path("res://"), "--resolution", "1024x640", "--script", "res://tools/maze_seed_render.gd", "--", "--seed-output=" + ProjectSettings.globalize_path(out)]
        OS.execute(OS.get_executable_path(), args)
        var python := ProjectSettings.globalize_path("res://tools/.venv/Scripts/python.exe")
        if FileAccess.file_exists(python):
            OS.execute(python, [ProjectSettings.globalize_path("res://tools/maze_contact_sheet.py"), ProjectSettings.globalize_path(out)])
    quit()

