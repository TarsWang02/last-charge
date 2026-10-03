"""Second pass on robot_parts.glb:
  1. delete the decorative "8" wind-up key on the robot's right side of the back (part of Body);
  2. split each track into Wheel_<S>1..3 (spin about X) + Belt_<S> (runs around the loop) + Track_<S> (static frame).
blender -b -P refine_robot.py -- --input robot_parts.glb --output robot_parts_v2.glb [--debug-render DIR]
Coordinates below are Blender world coords: +X robot left, -Y robot front, +Z up."""
import bpy, bmesh, sys, argparse, math, json
from mathutils import Vector, Matrix

ap = argparse.ArgumentParser()
ap.add_argument("--input", required=True); ap.add_argument("--output", required=True)
ap.add_argument("--debug-render", default=None)
a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])

# track loop ("stadium") core segment: y in [Y0-H, Y0+H] at height Z0; belt = faces farther than BELT_D from it
Y0, Z0, H, BELT_D = -0.008, 0.14, 0.16, 0.086
# wheel centres (y, z) and radii, front to back (measured from the outer side render)
WHEELS = [(-0.185, 0.117, 0.074), (-0.0065, 0.124, 0.085), (0.171, 0.113, 0.074)]
KEY_X, KEY_Y = -0.228, 0.09  # Body faces with x < KEY_X and y > KEY_Y = the "8" key

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.input)
objs = {o.name: o for o in bpy.data.objects if o.type == "MESH"}
report = {}


def seg_d(y, z):
    yy = min(max(y, Y0 - H), Y0 + H)
    return math.hypot(y - yy, z - Z0)


def edit(o):
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(o.data)
    bm.faces.ensure_lookup_table()
    return bm


def weld(o):
    bm = edit(o)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-6)
    bmesh.update_edit_mesh(o.data)
    bpy.ops.object.mode_set(mode="OBJECT")


def separate(o, pick, name, pivot_world):
    """Move faces where pick(world_centroid) is true into a new object `name` whose origin is pivot_world."""
    bm = edit(o)
    M = o.matrix_world
    n = 0
    for f in bm.faces:
        f.select = pick(M @ f.calc_center_median())
        n += f.select
    bmesh.update_edit_mesh(o.data)
    if n == 0:
        bpy.ops.object.mode_set(mode="OBJECT"); return None
    before = set(bpy.data.objects)
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    new = (set(bpy.data.objects) - before).pop()
    new.name = new.data.name = name
    # set origin to pivot, keep world placement; parent to the part it came from
    local = new.matrix_world.inverted() @ Vector(pivot_world)
    new.data.transform(Matrix.Translation(-local))
    mw = new.matrix_world @ Matrix.Translation(local)
    new.parent = o
    new.matrix_world = mw
    report[name] = {"faces": n, "pivot_blender": [round(c, 4) for c in pivot_world]}
    return new


# 1. remove the decorative key
body = objs["Body"]
weld(body)
bm = edit(body)
M = body.matrix_world
kill = [f for f in bm.faces if (lambda c: c.x < KEY_X and c.y > KEY_Y)(M @ f.calc_center_median())]
border = {v for f in kill for v in f.verts}
bmesh.ops.delete(bm, geom=kill, context="FACES")
open_edges = [e for e in bm.edges if e.is_boundary and all(v in border for v in e.verts)]
filled = bmesh.ops.holes_fill(bm, edges=open_edges, sides=0)["faces"] if open_edges else []
bmesh.update_edit_mesh(body.data)
bpy.ops.object.mode_set(mode="OBJECT")
report["Body_key_removed"] = {"faces_deleted": len(kill), "cap_faces": len(filled)}

# 2. tracks -> wheels + belt + frame
for side, sx in (("L", 1), ("R", -1)):
    tr = objs["Track_" + side]
    weld(tr)
    xs = [(tr.matrix_world @ v.co).x for v in tr.data.vertices]
    xmid = (min(xs) + max(xs)) / 2
    for i, (wy, wz, wr) in enumerate(WHEELS, 1):
        separate(tr, lambda c, wy=wy, wz=wz, wr=wr: math.hypot(c.y - wy, c.z - wz) < wr,
                 f"Wheel_{side}{i}", (xmid, wy, wz))
    separate(tr, lambda c: seg_d(c.y, c.z) > BELT_D, f"Belt_{side}", (xmid, Y0, Z0))
    report["Track_" + side + "_frame_faces"] = len(tr.data.polygons)

# export
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=a.output, export_format="GLB", use_selection=True, export_yup=True,
                          export_animations=False, export_cameras=False, export_lights=False,
                          export_materials="EXPORT", export_image_format="AUTO")
# glTF/Godot coords of the belt loop for the crawl shader (Y up, Z = -Blender Y)
report["belt_loop_godot"] = {"center_y": Z0, "center_z": -Y0, "half_len": H}
print("REFINE", json.dumps(report))

if a.debug_render:
    cols = {"Belt": (0.9, 0.2, 0.2, 1), "Wheel": (0.2, 0.5, 1, 1), "Track": (0.3, 0.9, 0.3, 1)}
    for o in bpy.data.objects:
        if o.type != "MESH": continue
        key = next((k for k in cols if o.name.startswith(k)), None)
        m = bpy.data.materials.new(o.name + "_dbg"); m.diffuse_color = cols.get(key, (0.6, 0.6, 0.6, 1))
        o.data.materials.clear(); o.data.materials.append(m)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"; sc.display.shading.color_type = "MATERIAL"
    sc.render.resolution_x = sc.render.resolution_y = 900
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"
    for nm, loc, sc_ in [("dbg_side_L", (1.2, -0.008, 0.14), 0.75), ("dbg_back", (0, 1.5, 0.45), 1.15)]:
        cam.location = loc; cam.data.ortho_scale = sc_
        d = (Vector((0, -0.008, 0.14 if "side" in nm else 0.4)) - Vector(loc)).normalized()
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = f"{a.debug_render}/{nm}.png"
        bpy.ops.render.render(write_still=True)
