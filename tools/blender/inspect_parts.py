"""Render close-ups of individual parts of robot_parts.glb for inspection.
blender -b -P inspect_parts.py -- --input X.glb --out DIR"""
import bpy, sys, argparse, math
from mathutils import Vector

a = argparse.ArgumentParser()
a.add_argument("--input"); a.add_argument("--out")
a = a.parse_args(sys.argv[sys.argv.index("--") + 1:])

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.input)
objs = {o.name: o for o in bpy.data.objects if o.type == "MESH"}
print("MESHES", {n: len(o.data.polygons) for n, o in objs.items()})

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = scene.render.resolution_y = 900
world = bpy.data.worlds.new("w"); scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[1].default_value = 1.2
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); scene.collection.objects.link(cam); scene.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); scene.collection.objects.link(sun)
sun.data.energy = 3; sun.rotation_euler = (0.6, 0.3, 0.8)


def bbox(o):
    ws = [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector([min(v[i] for v in ws) for i in range(3)]); hi = Vector([max(v[i] for v in ws) for i in range(3)])
    return lo, hi


def shoot(name, only, direction, dist=1.0, ortho=None):
    for n, o in objs.items():
        o.hide_render = only is not None and n not in only
    tgt = [objs[n] for n in (only or objs)]
    lo = Vector([min(bbox(o)[0][i] for o in tgt) for i in range(3)])
    hi = Vector([max(bbox(o)[1][i] for o in tgt) for i in range(3)])
    c = (lo + hi) / 2
    d = Vector(direction).normalized()
    cam.location = c + d * dist
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    if ortho:
        cam.data.type = "ORTHO"; cam.data.ortho_scale = ortho
    else:
        cam.data.type = "PERSP"
    scene.render.filepath = f"{a.out}/{name}.png"
    bpy.ops.render.render(write_still=True)


# Blender coords: +X robot left, -Y robot front (glTF +Z), +Z up
shoot("track_L_outer", ["Track_L"], (1, 0, 0), 1.0, 0.7)
shoot("track_L_inner", ["Track_L"], (-1, 0, 0), 1.0, 0.7)
shoot("body_back", ["Body"], (0, 1, 0.15), 1.2, 0.75)
shoot("body_back_right", ["Body"], (-0.7, 1, 0.2), 1.2, 0.6)
shoot("all_back", None, (0, 1, 0.2), 2.0, 1.15)
for n in ["Track_L", "Body"]:
    lo, hi = bbox(objs[n]); print("BBOX", n, [round(x, 3) for x in lo], [round(x, 3) for x in hi])
