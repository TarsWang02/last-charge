"""Overlap check for the white box: flags colliding solids that intersect each other (in plan + height)
and anything inside the toy train's sweep circle. Run after editing tools/gen_room.py.
  python tools/check_layout.py [group]   (default group: Stop1)"""
import importlib.util, math, sys
from pathlib import Path

group = sys.argv[1] if len(sys.argv) > 1 else "Stop1"
spec = importlib.util.spec_from_file_location("gen", Path(__file__).parent / "gen_room.py")
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)  # also regenerates room.tscn

# intended contacts (touching/embedded on purpose)
ALLOW = {("BoxFloor", "*"), ("PlushHeap", "BoxWallW"), ("PlushHeap", "BoxWallN"), ("BigBotSeat", "BigBotTorso"),
         ("BigBotTorso", "BigBotHead"), ("BigBotTorso", "BigBotShoulderN"), ("BigBotTorso", "BigBotShoulderS"),
         ("BigBotShoulderN", "BigBotArmN"), ("BigBotShoulderS", "BigBotArmS"), ("BigBotSeat", "BigBotLegN"),
         ("BigBotSeat", "BigBotLegS"), ("BigBotLegN", "BigBotFootN"), ("BigBotLegS", "BigBotFootS"),
         ("ToyTruck", "TruckCab"), ("BigBotHead", "BigBotShoulderN"), ("BigBotHead", "BigBotShoulderS"),
         ("BigBotArmN", "BigBotSeat"), ("BigBotArmS", "BigBotSeat"), ("BigBotTorso", "BigBotArmN"), ("BigBotTorso", "BigBotArmS")}
WALLS = {"BoxWallW", "BoxWallE", "BoxWallN", "BoxWallS", "FlapN", "FlapE"}


def aabb(sh):
    kind, grp, name, dims, c, mat, col, rot = sh
    if kind == "box":
        h = [d / 2 for d in dims]
    elif kind == "cyl":
        r, hh = dims
        h = [r, hh / 2, r] if rot == (0, 0, 0) else [r, r, hh / 2]
    else:
        h = [dims[0]] * 3
    return [c[i] - h[i] for i in range(3)], [c[i] + h[i] for i in range(3)]


solids = [s for s in gen.S if s[1] == group and s[6]]
problems = []
for i, a in enumerate(solids):
    for b in solids[i + 1:]:
        na, nb = a[2], b[2]
        if (na, nb) in ALLOW or (nb, na) in ALLOW or (na, "*") in ALLOW or (nb, "*") in ALLOW:
            continue
        if na in WALLS and nb in WALLS:
            continue
        (al, ah), (bl, bh) = aabb(a), aabb(b)
        ov = [min(ah[k], bh[k]) - max(al[k], bl[k]) for k in range(3)]
        if all(o > 0.002 for o in ov):
            problems.append(f"OVERLAP {na} x {nb}: {[round(o, 3) for o in ov]} m")
if hasattr(gen, "TRAIN_C"):
    sweep = gen.TRAIN_R + 0.056
    for sh in solids:
        lo, hi = aabb(sh)
        if lo[1] > 0.07:
            continue  # above the carriage
        dx = max(lo[0] - gen.TRAIN_C[0], 0, gen.TRAIN_C[0] - hi[0])
        dz = max(lo[2] - gen.TRAIN_C[2], 0, gen.TRAIN_C[2] - hi[2])
        if math.hypot(dx, dz) < sweep and sh[2] not in ("BoxFloor",):
            problems.append(f"TRAIN HITS {sh[2]} (gap {math.hypot(dx, dz) - sweep:+.3f} m)")
print("\n".join(problems) if problems else "layout OK")
