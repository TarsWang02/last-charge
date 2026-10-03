"""Find the modelled battery cells on Body: faces whose base-colour texture is teal, clustered into 5 cells.
Prints each cell's centre/size in Godot coords relative to Body's pivot (for RobotRig.cell_*).
blender -b -P measure_cells.py -- robot_parts_v2.glb"""
import bpy, sys, json, colorsys
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=sys.argv[sys.argv.index("--") + 1])
body = bpy.data.objects["Body"]
me = body.data
mat = me.materials[0]
img = next(n.image for n in mat.node_tree.nodes if n.type == "TEX_IMAGE" and "basecolor" in n.image.name.lower()) \
    if any(n.type == "TEX_IMAGE" and "basecolor" in n.image.name.lower() for n in mat.node_tree.nodes) \
    else next(n.image for n in mat.node_tree.nodes if n.type == "TEX_IMAGE")
W, H = img.size
px = img.pixels[:]
uv = me.uv_layers.active.data
M = body.matrix_world

def sample(u, v):
    x = min(W - 1, max(0, int(u % 1.0 * W))); y = min(H - 1, max(0, int(v % 1.0 * H)))
    i = (y * W + x) * 4
    return px[i], px[i + 1], px[i + 2]

pts = []
for p in me.polygons:
    u = sum(uv[l].uv.x for l in p.loop_indices) / p.loop_total
    v = sum(uv[l].uv.y for l in p.loop_indices) / p.loop_total
    r, g, b = sample(u, v)
    h, s, val = colorsys.rgb_to_hsv(r, g, b)
    if 0.42 < h < 0.58 and s > 0.4 and val > 0.15:  # teal / cyan
        c = M @ p.center
        n = (M.to_3x3() @ p.normal).normalized()
        if c.y > 0.1 and n.y > 0.5 and 0.40 < c.z < 0.56:  # back-facing cell fronts only
            pts.append(c)
print("teal faces on back:", len(pts))
# 1-D k-means on x with 5 clusters
xs = sorted(c.x for c in pts)
cent = [xs[int((i + 0.5) * len(xs) / 5)] for i in range(5)]
for _ in range(30):
    groups = [[] for _ in cent]
    for c in pts:
        groups[min(range(5), key=lambda k: abs(c.x - cent[k]))].append(c)
    cent = [sum(c.x for c in g) / len(g) if g else cent[i] for i, g in enumerate(groups)]
clusters = [g for g in groups if g]
pivot = Vector((0.0, 0.0, 0.049))  # Body pivot (Blender coords)
out = []
for cl in clusters:
    lo = Vector([min(c[i] for c in cl) for i in range(3)]); hi = Vector([max(c[i] for c in cl) for i in range(3)])
    ctr = (lo + hi) / 2 - pivot
    # Godot: (x, z_blender, -y_blender)
    out.append({"n": len(cl), "godot_center": [round(ctr.x, 4), round(ctr.z, 4), round(-ctr.y, 4)],
                "width": round(hi.x - lo.x, 4), "height": round(hi.z - lo.z, 4),
                "surface_godot_z": round(-(hi.y - pivot.y), 4)})
print("CELLS", json.dumps(out))
