"""Print geometry stats used to tune refine_robot.py (Blender coords: +X robot left, -Y front, +Z up)."""
import bpy, sys, math
from mathutils import Vector

inp = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=inp)
objs = {o.name: o for o in bpy.data.objects if o.type == "MESH"}

Y0, Z0, H = -0.008, 0.14, 0.16  # stadium core segment guess

def seg_d(y, z):
    yy = min(max(y, Y0 - H), Y0 + H)
    return math.hypot(y - yy, z - Z0)

for name in ["Track_L", "Track_R"]:
    o = objs[name]; M = o.matrix_world
    ds = [seg_d(*(M @ p.center)[1:]) for p in o.data.polygons]
    hist = [0] * 16
    for d in ds: hist[min(15, int(d / 0.01))] += 1
    print("HIST", name, "d(cm)->faces", {i: h for i, h in enumerate(hist) if h})
    xs = [(M @ v.co).x for v in o.data.vertices]
    print("X", name, round(min(xs), 3), round(max(xs), 3))

# Body: faces outside the shoulder plane on robot right (-X), clustered by height/depth
o = objs["Body"]; M = o.matrix_world
side = [M @ p.center for p in o.data.polygons if (M @ p.center).x < -0.205]
print("BODY_RIGHT faces", len(side))
for lo, hi in [(-0.36, -0.30), (-0.30, -0.26), (-0.26, -0.23), (-0.23, -0.205)]:
    s = [c for c in side if lo <= c.x < hi]
    if s:
        print(f"  x[{lo},{hi}) n={len(s)} y[{min(c.y for c in s):.3f},{max(c.y for c in s):.3f}] z[{min(c.z for c in s):.3f},{max(c.z for c in s):.3f}]")
