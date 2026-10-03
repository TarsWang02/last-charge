"""Generate scenes/room.tscn: the white-box farmhouse from the level design doc.

Everything below is written in REAL METRES and multiplied by K. The robot is 0.9 units tall, so
K = 9 makes it a ~10 cm toy. Axes: x west(-) -> east(+), z north(-) -> south(+), y up.
House 9.5 x 5.3 m. North wall of the bedroom, west to east: bed | nightstand | cardboard toy box | desk.
The robot wakes on an alarm clock on the nightstand looking at the desk, wobbles, and falls into the box.
Toy box climb (robot units, max jump 1.32): plush 1.0 -> pushed block 1.0 -> books 1.8 ->
folded flap ledge 2.7 -> pulled-out drawer 3.85 -> pencil case 4.12 -> desk top 5.06.
Detail level: stop 0 (nightstand) and stop 1 (toy box) are built in detail; the rest is rough.
Re-running overwrites editor changes to room.tscn.
"""
from pathlib import Path
import math

K = 9.0
OUT = Path(__file__).resolve().parent.parent / "scenes" / "room.tscn"
# Update the selected pool without regenerating other stations currently under development.
# A full regeneration below writes the identical pool as well.
import sys, re
if "--desk-seed-pool-only" in sys.argv:
    text = OUT.read_text(encoding="utf-8")
    pattern = r'(\[node name="DeskMaze"[^\n]*\]\n)(.*?)(?=\n\[node|\Z)'
    def update_pool(match):
        body = re.sub(r'^seed_pool = .*\n?', '', match.group(2), flags=re.M).rstrip()
        return match.group(1) + body + '\nseed_pool = PackedInt32Array(0, 7, 22, 49)\n'
    text, count = re.subn(pattern, update_pool, text, flags=re.S)
    if count != 1:
        raise RuntimeError("Expected exactly one DeskMaze node")
    OUT.write_text(text, encoding="utf-8")
    print("Updated DeskMaze seed pool in", OUT)
    sys.exit(0)


MATS = {  # name: (albedo rgb, roughness, emission rgb or None, transparent)
    "floor": ((0.28, 0.2, 0.14), 0.75, None, False),
    "wall": ((0.32, 0.31, 0.28), 0.9, None, False),
    "wood": ((0.38, 0.24, 0.13), 0.6, None, False),
    "darkwood": ((0.22, 0.14, 0.08), 0.6, None, False),
    "fabric": ((0.3, 0.33, 0.42), 0.95, None, False),
    "cardboard": ((0.55, 0.4, 0.24), 0.95, None, False),
    "cardboard_dark": ((0.36, 0.25, 0.14), 0.95, None, False),
    "plush": ((0.6, 0.45, 0.32), 1.0, None, False),
    "toy_red": ((0.6, 0.15, 0.12), 0.7, None, False),
    "toy_blue": ((0.15, 0.3, 0.6), 0.7, None, False),
    "toy_yellow": ((0.7, 0.55, 0.15), 0.7, None, False),
    "toy_green": ((0.2, 0.45, 0.25), 0.7, None, False),
    "metal": ((0.45, 0.47, 0.5), 0.4, None, False),
    "brass": ((0.6, 0.45, 0.2), 0.35, None, False),
    "paper": ((0.7, 0.66, 0.55), 0.9, None, False),
    "glass": ((0.7, 0.8, 0.9), 0.1, None, True),
    "abyss": ((0.02, 0.02, 0.03), 1.0, None, False),
    "ruler": ((0.85, 0.72, 0.35), 0.5, None, False),
    "cyanmark": ((0.2, 1.0, 0.9), 0.4, (0.2, 1.0, 0.9), False),
    "amber_eye": ((1.0, 0.7, 0.3), 0.3, (1.0, 0.65, 0.25), False),
    "person": ((0.12, 0.12, 0.14), 1.0, None, False),
    "window": ((0.2, 0.25, 0.4), 1.0, (0.35, 0.45, 0.8), False),
    "outside": ((0.09, 0.1, 0.13), 1.0, None, False),
    "sky": ((0.02, 0.03, 0.07), 1.0, (0.03, 0.05, 0.12), False),
    "moon": ((0.9, 0.92, 1.0), 1.0, (0.85, 0.9, 1.0), False),
    "tvscreen": ((0.1, 0.15, 0.3), 0.3, (0.25, 0.4, 0.9), False),
    "kitchen": ((0.55, 0.52, 0.45), 0.5, None, False),
    "fault": ((0.5, 0.05, 0.05), 0.5, (1.0, 0.1, 0.05), False),
    "lampshade": ((0.8, 0.7, 0.5), 0.8, (1.0, 0.7, 0.4), False),
    "cable": ((0.05, 0.07, 0.12), 0.6, (0.15, 0.25, 0.6), False),
    "water": ((0.3, 0.55, 0.9), 0.05, (0.18, 0.4, 0.8), True),
    "steam": ((0.92, 0.93, 0.97), 1.0, (0.25, 0.27, 0.3), True),
}

ALPHA = {"steam": 0.12, "glass": 0.08}   # transparent materials that need to be fainter than the default 0.35
S = []  # shapes, all in metres

def box(name, x0, x1, y0, y1, z0, z1, mat, col=True, group="Greybox"):
    S.append(("box", group, name, (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), mat, col, (0, 0, 0)))

def cyl(name, r, h, c, mat, col=True, rot=(0, 0, 0), group="Greybox"):
    S.append(("cyl", group, name, (r, h), c, mat, col, rot))

def sph(name, r, c, mat, col=True, group="Greybox"):
    S.append(("sph", group, name, (r,), c, mat, col, (0, 0, 0)))

# ---------------- shell (house x -4.75..4.75, z -2.65..2.65, walls 2.7 m)
X0, X1, Z0, Z1, H = -4.75, 4.75, -2.65, 2.65, 2.7
BW = -0.4                       # bedroom east wall
DOOR = (0.95, 1.8)              # door gap on the bedroom wall (z)
box("Floor", X0, X1, -0.06, 0, Z0, Z1, "floor", group="Shell")
NWIN = (-3.45, -2.65, 1.0, 2.0)      # the bedroom's north window: x0 x1 y0 y1
box("WallN", X0 - .06, X1 + .06, 0, NWIN[2], Z0 - .06, Z0, "wall", group="Shell")
box("WallNHigh", X0 - .06, X1 + .06, NWIN[3], H, Z0 - .06, Z0, "wall", group="Shell")
box("WallNWest", X0 - .06, NWIN[0], NWIN[2], NWIN[3], Z0 - .06, Z0, "wall", group="Shell")
box("WallNEast", NWIN[1], X1 + .06, NWIN[2], NWIN[3], Z0 - .06, Z0, "wall", group="Shell")
WIN = (-1.2, 4.0, 1.0, 2.2)          # the long window in the south wall: x0 x1 y0 y1
box("WallS", X0 - .06, X1 + .06, 0, WIN[2], Z1, Z1 + .06, "wall", group="Shell")
box("WallSHigh", X0 - .06, X1 + .06, WIN[3], H, Z1, Z1 + .06, "wall", group="Shell")
BWIN = (-3.8, -2.6, 1.1, 2.0)        # the bedroom's south window: x0 x1 y0 y1
box("WallSWest", X0 - .06, BWIN[0], WIN[2], WIN[3], Z1, Z1 + .06, "wall", group="Shell")
box("WallSBedLow", BWIN[0], BWIN[1], WIN[2], BWIN[2], Z1, Z1 + .06, "wall", group="Shell")
box("WallSBedHigh", BWIN[0], BWIN[1], BWIN[3], WIN[3], Z1, Z1 + .06, "wall", group="Shell")
box("WallSMid", BWIN[1], WIN[0], WIN[2], WIN[3], Z1, Z1 + .06, "wall", group="Shell")
box("WallSEast", WIN[1], X1 + .06, WIN[2], WIN[3], Z1, Z1 + .06, "wall", group="Shell")
box("WallW", X0 - .06, X0, 0, H, Z0, Z1, "wall", group="Shell")
box("WallE", X1, X1 + .06, 0, H, Z0, Z1, "wall", group="Shell")
box("BedroomWallN", BW - .06, BW, 0, H, Z0, DOOR[0], "wall", group="Shell")
box("BedroomWallS", BW - .06, BW, 0, H, DOOR[1], Z1, "wall", group="Shell")
box("DoorLintel", BW - .06, BW, 2.05, H, DOOR[0], DOOR[1], "wall", group="Shell")
box("WindowBedroomN", -3.45, -2.65, 1.0, 2.0, Z0 + .005, Z0 + .01, "glass", col=False, group="Shell")
box("WindowBedroomS", -3.8, -2.6, 1.1, 2.0, Z1 - .01, Z1 - .005, "glass", col=False, group="Shell")
box("WindowLongS", WIN[0], WIN[1], WIN[2], WIN[3], Z1 + .02, Z1 + .025, "glass", col=False, group="Shell")
for i, x in enumerate([-1.2, -0.13, 0.93, 2.0, 3.07, 4.0]):   # window frame: mullions + a transom
    box(f"WindowMullion{i + 1}", x - 0.025, x + 0.025, WIN[2], WIN[3], Z1, Z1 + 0.06, "darkwood", col=False, group="Shell")
box("WindowTransom", WIN[0], WIN[1], 1.72, 1.75, Z1, Z1 + 0.06, "darkwood", col=False, group="Shell")
# outside: the ground, the town, the sky and the moon are all built at runtime (scripts/town.gd, shaders/night_sky.gdshader)

# ---------------- stop 0: bed + nightstand (head at the north wall) - lit by a shaft of moonlight
box("BedFrame", -4.75, -3.35, 0, 0.35, -2.65, -0.65, "darkwood", group="Bedroom")
box("Mattress", -4.7, -3.4, 0.35, 0.55, -2.6, -0.7, "fabric", group="Bedroom")
box("Headboard", -4.75, -3.35, 0, 1.0, -2.65, -2.58, "darkwood", group="Bedroom")
box("Pillow", -4.6, -3.5, 0.55, 0.67, -2.55, -2.2, "paper", col=False, group="Bedroom")
box("Blanket", -4.68, -3.42, 0.55, 0.62, -2.15, -0.75, "fabric", col=False, group="Bedroom")
NT = 0.72                               # nightstand top (m)
NS = (-3.3, -2.86, -2.65, -2.21, NT)    # nightstand x0 x1 z0 z1 top (44 x 44 cm = 4 x 4 robot units)
box("Nightstand", NS[0], NS[1], 0, NT, NS[2], NS[3], "wood", group="Stop0")
box("NightstandDrawer", NS[0] + .02, NS[1] - .02, NT - 0.22, NT - 0.08, NS[3] - .005, NS[3] + .005, "darkwood", col=False, group="Stop0")
# tabletop. Heights above it in robot units: pill 0.72, books 1.26, glass 1.0
box("OldBooks", -3.27, -3.1, NT, NT + 0.14, -2.62, -2.47, "darkwood", group="Stop0")
cyl("PillBottleA", 0.02, 0.08, (-3.07, NT + 0.04, -2.55), "toy_yellow", group="Stop0")
cyl("PillBottleB", 0.018, 0.065, (-2.97, NT + 0.0325, -2.45), "paper", group="Stop0")
cyl("WaterGlass", 0.035, 0.11, (-2.92, NT + 0.055, -2.58), "glass", group="Stop0")
box("ReadingGlasses", -3.06, -2.94, NT, NT + 0.018, -2.255, -2.225, "metal", group="Stop0")
cyl("CoinA", 0.012, 0.003, (-3.2, NT + 0.0015, -2.42), "brass", col=False, group="Stop0")
cyl("CoinB", 0.012, 0.003, (-3.17, NT + 0.0015, -2.4), "brass", col=False, group="Stop0")
# the unstable thing: a hardback book lying across the east edge, 9 cm hanging over the box -
# it reads as a bridge towards the desk lamp. Pivot = the table edge (built in the emit section).
BOOK_EDGE = (NS[1], NT, -2.33)
BOOK = (0.24, 0.035, 0.16)             # length (x), thickness, width (z)
BOOK_OVER = 0.09

# ---------------- stop 1: the old moving box (120 x 90 x 60 cm). Its floor is "the dark": touch it = respawn.
# Inner x -2.828..-1.652 (W->E), z -2.638..-1.762 (N->S). Route: NW plush -> W blocks -> SW train loop ->
# jack -> shoebox along the north wall (push puzzle) -> the big toy robot's shoulder -> its head (the car
# platform). The robot sits against the east wall facing west, legs spread; the seesaw lies between its legs.
BX = (-2.84, -1.64, -2.65, -1.75)   # outer x0 x1 z0 z1
T = 0.012
BH = 0.6
box("BoxFloor", BX[0], BX[1], 0, 0.008, BX[2], BX[3], "abyss", group="Stop1")
box("BoxWallW", BX[0], BX[0] + T, 0, BH, BX[2], BX[3], "cardboard", group="Stop1")
box("BoxWallE", BX[1] - T, BX[1], 0, BH, BX[2], BX[3], "cardboard", group="Stop1")
box("BoxWallN", BX[0], BX[1], 0, BH, BX[2], BX[2] + T, "cardboard", group="Stop1")
box("BoxWallS", BX[0], BX[1], 0, BH - 0.05, BX[3] - T, BX[3], "cardboard", group="Stop1")
box("FlapN", BX[0], BX[1], BH, BH + 0.28, BX[2] - 0.01, BX[2] + 0.002, "cardboard", group="Stop1")
box("FlapE", BX[1] - T, BX[1], BH, BH + 0.4, BX[2], BX[3], "cardboard", group="Stop1")   # no shortcut from the robot's head to the desk
box("FlapWTorn", BX[0] - 0.22, BX[0], BH - 0.09, BH - 0.08, BX[2] + 0.08, BX[3] - 0.2, "cardboard_dark", col=False, group="Stop1")
# A - landing (top 0.12 m)
sph("PlushHeap", 0.15, (-2.70, -0.03, -2.50), "plush", group="Stop1")
sph("PlushBunnyHead", 0.045, (-2.78, 0.11, -2.58), "plush", col=False, group="Stop1")
# B - blocks down the west side
box("BlockStack", -2.76, -2.68, 0, 0.20, -2.32, -2.24, "toy_blue", group="Stop1")      # 1.8 u
box("ToyTruck", -2.80, -2.68, 0, 0.14, -2.14, -2.02, "toy_green", group="Stop1")      # 1.26 u, battery on top
box("TruckCab", -2.80, -2.74, 0.14, 0.19, -2.14, -2.08, "toy_green", group="Stop1")
# train loop in the south-west; the carriage sweeps TRAIN_R + 0.056 from the centre
TRAIN_C = (-2.52, 0.008, -1.94)
TRAIN_R = 0.10
# C - the shadow corner: dolls, wind-up monkey, jack-in-the-box
box("JackBox", -2.33, -2.23, 0, 0.10, -2.00, -1.90, "toy_red", group="Stop1")         # 0.9 u; springs you onto the shoebox
sph("DollHeadA", 0.04, (-2.77, 0.04, -1.90), "paper", group="Stop1")
sph("DollHeadB", 0.03, (-2.68, 0.03, -1.82), "paper", group="Stop1")
cyl("WindUpMonkey", 0.03, 0.09, (-2.15, 0.045, -1.82), "toy_yellow", group="Stop1")
# D - shoebox (2.7 u) along the north wall with two push blocks -> stairs up to the big robot's north shoulder
box("Shoebox", -2.48, -1.92, 0, 0.30, -2.62, -2.40, "cardboard_dark", group="Stop1")
# E - the big toy robot (an old tin robot, sitting, back to the east wall, facing west)
box("BigBotSeat", -1.92, -1.664, 0, 0.12, -2.36, -2.04, "metal", group="Stop1")
box("BigBotTorso", -1.90, -1.664, 0.12, 0.44, -2.34, -2.06, "toy_yellow", group="Stop1")
box("BigBotHead", -1.95, -1.67, 0.44, 0.58, -2.34, -2.06, "toy_yellow", group="Stop1")      # 5.22 u: the car platform
box("BigBotShoulderN", -1.90, -1.70, 0.36, 0.50, -2.44, -2.36, "metal", group="Stop1")      # 4.5 u
box("BigBotShoulderS", -1.90, -1.70, 0.36, 0.50, -2.04, -1.96, "metal", group="Stop1")
box("BigBotArmN", -1.88, -1.78, 0, 0.36, -2.46, -2.38, "metal", group="Stop1")
box("BigBotArmS", -1.88, -1.78, 0, 0.36, -2.02, -1.94, "metal", group="Stop1")
box("BigBotLegN", -2.30, -1.92, 0, 0.09, -2.36, -2.28, "toy_yellow", group="Stop1")         # legs spread west
box("BigBotLegS", -2.30, -1.92, 0, 0.09, -2.12, -2.04, "toy_yellow", group="Stop1")
box("BigBotFootN", -2.36, -2.30, 0, 0.15, -2.37, -2.27, "metal", group="Stop1")
box("BigBotFootS", -2.36, -2.30, 0, 0.15, -2.13, -2.03, "metal", group="Stop1")
for i, (x0, x1, z0, z1) in enumerate([(-1.73, -1.71, -2.31, -2.09), (-1.81, -1.71, -2.32, -2.30), (-1.81, -1.79, -2.31, -2.20)]):
    box(f"CarTrack{i + 1}", x0, x1, 0.58, 0.583, z0, z1, "metal", col=False, group="Stop1")  # the car's U route on the head
# the seesaw between the legs (along x): fulcrum + a rest under the west (robot) end
box("SeesawFulcrum", -2.15, -2.09, 0, 0.06, -2.25, -2.15, "wood", group="Stop1")
box("SeesawRest", -2.29, -2.25, 0, 0.03, -2.23, -2.17, "wood", group="Stop1")

# ---------------- stop 2: an old wooden school desk (70 x 140 cm) against the bedroom's east wall, its south
# end right by the bedroom door. The top is a random top-down maze built at runtime (scripts/desk_maze.gd):
# no jumping, holes in dead ends, an open edge, lights that show an area until you move, an eraser to push
# into a hole on the route. Goal: the door's lever handle at the south-east corner. Desk top 0.75 m = 6.75 u.
DK = (BW - 0.76, BW - 0.06, -0.55, 0.85, 0.75)   # x0 x1 z0 z1 top (east edge = the wall's inner face)
box("DeskLegNW", DK[0], DK[0] + 0.04, 0, DK[4] - 0.03, DK[2], DK[2] + 0.04, "wood", group="Stop2")
box("DeskLegSW", DK[0], DK[0] + 0.04, 0, DK[4] - 0.03, DK[3] - 0.04, DK[3], "wood", group="Stop2")
box("DeskLegSE", DK[1] - 0.04, DK[1], 0, DK[4] - 0.03, DK[3] - 0.04, DK[3], "wood", group="Stop2")
box("DeskApron", DK[0], DK[1], DK[4] - 0.09, DK[4] - 0.05, DK[2], DK[3], "darkwood", group="Stop2")  # frame under the top
box("DeskDrawerUnit", DK[1] - 0.35, DK[1], 0.44, DK[4] - 0.09, -0.53, -0.08, "wood", group="Stop2")
box("DeskChair", DK[0] - 0.4, DK[0] - 0.02, 0.43, 0.46, 0.3, 0.7, "wood", group="Stop2")
box("DeskChairBack", DK[0] - 0.42, DK[0] - 0.38, 0.46, 0.95, 0.3, 0.7, "wood", group="Stop2")
# the brass lamp that glows over the desk at the start (seen from the nightstand) - a wall lamp now
box("WallLampArm", BW - 0.12, BW, 1.12, 1.135, 0.54, 0.56, "brass", col=False, group="Stop2")
cyl("WallLampShade", 0.07, 0.09, (BW - 0.14, 1.1, 0.55), "lampshade", col=False, group="Stop2")

# ---------------- stop 3: TV + sofa (rough)
# Climb (robot units, max jump 1.32): floor -> game boxes 0.81 -> magazines 1.71 -> subwoofer 2.61 ->
# tall speaker 3.51 -> cabinet top 4.5. The console's cable runs from a power strip by the bedroom door
# across the floor to the stack and up to the console: "follow the cable". The screen (E) pulls you in.
TVC = (0.5, 1.5, -2.65, -2.0, 0.5)    # cabinet x0 x1 z0 z1 top
box("TVCabinet", TVC[0], TVC[1], 0, TVC[4], TVC[2], TVC[3], "darkwood", group="Stop3")
box("CRT", 0.7, 1.3, TVC[4], 1.0, -2.6, -2.18, "metal", group="Stop3")
box("CRTScreen", 0.76, 1.24, 0.56, 0.94, -2.182, -2.178, "tvscreen", col=False, group="Stop3")
box("GameConsole", 1.32, 1.48, TVC[4], TVC[4] + 0.06, -2.2, -2.05, "metal", group="Stop3")
box("GameBoxes", 0.26, 0.44, 0, 0.09, -1.95, -1.80, "toy_red", group="Stop3")
box("MagStack", 0.28, 0.46, 0, 0.19, -2.13, -1.96, "paper", group="Stop3")
box("Subwoofer", 0.28, 0.48, 0, 0.29, -2.33, -2.14, "person", group="Stop3")
box("SpeakerTall", 0.30, 0.48, 0, 0.39, -2.62, -2.34, "person", group="Stop3")
box("TimeBoxBody", 1.54, 1.66, 0, 0.05, -2.195, -2.105, "metal", group="Stop3")  # dusty, beside the cabinet
box("PowerStrip", BW, BW + 0.05, 0, 0.03, 0.70, 0.95, "paper", group="Stop3")
for i, (x0, x1, y0, y1, z0, z1) in enumerate([
        (BW + 0.02, BW + 0.032, 0, 0.006, -1.87, 0.70),        # along the bedroom wall, north
        (BW + 0.02, 0.26, 0, 0.006, -1.882, -1.87),            # east to the game boxes
        (0.44, 1.40, 0, 0.006, -1.882, -1.87),                 # past the stack to under the console
        (1.394, 1.406, 0, TVC[4], -1.998, -1.99),              # up the cabinet front
        (1.394, 1.406, TVC[4], TVC[4] + 0.006, -2.05, -1.99)]):  # into the console
    box(f"ConsoleCable{i + 1}", x0, x1, y0, y1, z0, z1, "cable", col=False, group="Stop3")
box("SofaSeat", 0.65, 2.25, 0, 0.42, -1.3, -0.6, "fabric", group="Stop3")  # east of the door->TV sight line
box("SofaBack", 0.65, 2.25, 0, 0.85, -0.6, -0.45, "fabric", group="Stop3")

# ---------------- stop 4: kitchen (middle age). The sink tap was left running: the floor in front of the
# counters is flooded (water = the robot shorts out). The way home (the long windowsill) is across the
# kitchen, so the robot goes over the counters along the L: north counter west -> east, round the corner,
# east counter north -> south, where it meets the windowsill. The cook at the stove is a frozen silhouette;
# fire and water move. Climb (units, max jump 1.32): cans 0.99 -> rice bag 1.98 -> stool 2.97 -> chair seat
# 3.96 -> lunchbox 4.95 -> cereal box 6.03 -> chair back 7.2 -> counter 8.1.
KC = 0.9                                                    # counter top (m)
box("CounterA", 2.35, 2.85, 0, KC, -2.65, -2.05, "kitchen", group="Stop4")    # microwave
box("CounterB", 3.2, 3.4, 0, KC, -2.65, -2.05, "kitchen", group="Stop4")      # toaster; gap A|B = 35 cm
box("StoveBody", 3.4, 4.0, 0, KC + 0.03, -2.65, -2.05, "metal", group="Stop4")
box("StoveFlame", 3.5, 3.9, KC + 0.03, KC + 0.045, -2.55, -2.25, "fault", col=False, group="Stop4")   # low pilot glow
# a big pot on the corner boiled over: the corner counter is wet -> hang on the rail round the corner instead
cyl("StockPot", 0.1, 0.2, (4.35, KC + 0.1, -2.35), "metal", group="Stop4")
box("CornerWater", 4.0, 4.75, KC, KC + 0.004, -2.65, -1.75, "water", col=False, group="Stop4")
box("CounterC", 4.0, 4.15, 0, KC, -2.65, -2.05, "kitchen", group="Stop4")
box("CounterE_N", 4.15, 4.75, 0, KC, -2.65, -0.25, "kitchen", group="Stop4")
box("SinkBase", 4.25, 4.65, 0, 0.72, -0.25, 0.65, "kitchen", group="Stop4")      # basin floor at 0.72
box("SinkRimW", 4.15, 4.25, 0, KC, -0.25, 0.65, "kitchen", group="Stop4")
box("SinkRimE", 4.65, 4.75, 0, KC, -0.25, 0.65, "kitchen", group="Stop4")
box("CounterE_S", 4.15, 4.75, 0, KC, 0.65, 2.65, "kitchen", group="Stop4")
box("UpperCabW", 2.35, 3.35, 1.5, 2.2, -2.65, -2.3, "kitchen", group="Stop4")
box("RangeHood", 3.35, 4.05, 1.46, 1.62, -2.65, -2.25, "metal", group="Stop4")    # steel: magnet route (next step)
box("HoodChimney", 3.55, 3.85, 1.62, 2.7, -2.65, -2.4, "metal", group="Stop4")
box("UpperCabE", 4.05, 4.75, 1.55, 2.2, -2.65, -2.3, "kitchen", group="Stop4")
box("UpperCabEast", 4.4, 4.75, 1.55, 2.2, -2.3, -1.0, "kitchen", group="Stop4")
box("SpiceShelf", 3.04, 3.34, 1.31, 1.33, -2.65, -2.52, "wood", group="Stop4")    # the toaster pops you up here
box("UtensilRailN", 4.05, 4.72, 1.3, 1.315, -2.63, -2.615, "metal", col=False, group="Stop4")   # grabbed by magnet, not stood on
box("UtensilRailE", 4.705, 4.72, 1.3, 1.315, -2.63, -1.45, "metal", col=False, group="Stop4")
for i, x in enumerate([4.15, 4.3, 4.45, 4.6]):
    box(f"HangingUtensil{i + 1}", x - 0.012, x + 0.012, 1.1, 1.3, -2.63, -2.61, "metal", col=False, group="Stop4")
# the climb (west of counter A, on the dry part of the floor)
box("CannedGoods", 1.72, 1.84, 0, 0.11, -2.54, -2.40, "toy_red", group="Stop4")
box("RiceBag", 1.84, 1.97, 0, 0.22, -2.55, -2.39, "paper", group="Stop4")
box("StepStool", 1.97, 2.10, 0, 0.33, -2.56, -2.38, "wood", group="Stop4")
box("ChairSeat", 2.10, 2.34, 0.40, 0.44, -2.52, -2.14, "wood", group="Stop4")
for i, (x, z) in enumerate([(2.11, -2.51), (2.33, -2.51), (2.11, -2.15), (2.33, -2.15)]):
    box(f"ChairLeg{i + 1}", x - 0.01, x + 0.01, 0, 0.40, z - 0.01, z + 0.01, "wood", group="Stop4")
box("ChairBack", 2.10, 2.34, 0.44, 0.80, -2.22, -2.14, "wood", group="Stop4")    # faces the counter's free strip
box("Lunchbox", 2.13, 2.31, 0.44, 0.55, -2.42, -2.32, "toy_blue", group="Stop4")
box("CerealBox", 2.13, 2.31, 0.44, 0.67, -2.32, -2.22, "toy_yellow", group="Stop4")
# counter A: the microwave and the cutting board it shoves over the gap
box("Microwave", 2.40, 2.72, KC, KC + 0.27, -2.62, -2.30, "metal", group="Stop4")
box("BreadBag", 3.245, 3.395, KC, KC + 0.09, -2.28, -2.12, "paper", group="Stop4")
box("Toaster", 3.22, 3.38, KC, KC + 0.18, -2.52, -2.30, "metal", group="Stop4")
# east counter: kettle, dish rack, the overflowing sink, the mug by the window (later steps)
box("Kettle", 4.36, 4.56, KC, KC + 0.22, -1.65, -1.45, "metal", group="Stop4")
box("DishRack", 4.3, 4.7, KC, KC + 0.25, -0.85, -0.35, "metal", group="Stop4")
# the pile of unwashed things in the sink (step on the lid -> it all comes down; the plug pops, the flood drains)
box("DishPot", 4.29, 4.61, 0.72, 0.96, -0.22, 0.18, "metal", group="Stop4")
box("DishLid", 4.27, 4.63, 0.96, 0.99, -0.345, 0.2, "metal", group="Stop4")      # reaches back to the dish rack
box("DishBowlA", 4.29, 4.45, 0.72, 0.92, 0.2, 0.4, "paper", group="Stop4")
box("DishBowlB", 4.47, 4.62, 0.72, 0.9, 0.2, 0.4, "paper", group="Stop4")
box("DishPlates", 4.29, 4.62, 0.72, 0.94, 0.4, 0.62, "paper", group="Stop4")
box("DishLadle", 4.3, 4.6, 0.92, 0.945, 0.3, 0.33, "metal", group="Stop4")
cyl("SinkPlug", 0.025, 0.015, (4.45, 0.728, 0.5), "person", col=False, group="Stop4")
box("KettleLight", 4.4, 4.43, KC + 0.02, KC + 0.035, -1.445, -1.44, "lampshade", col=False, group="Stop4")
box("SteamColumn", 4.36, 4.62, 1.12, 1.36, -1.6, -0.72, "steam", col=False, group="Stop4")
cyl("Faucet", 0.015, 0.25, (4.7, 1.025, 0.2), "metal", col=False, group="Stop4")
cyl("Mug", 0.04, 0.1, (4.45, KC + 0.05, 2.45), "toy_yellow", group="Stop4")
box("DiningTable", 2.2, 3.2, 0.72, 0.75, -0.6, 0.2, "wood", group="Stop4")
# the flood: water over the floor in front of the counters, the sink overflow running down the cabinet
box("FloodFloor", 2.35, 4.15, 0, 0.006, -2.05, 2.4, "water", col=False, group="Stop4")
box("FloodGap", 2.85, 3.2, 0, 0.006, -2.65, -2.05, "water", col=False, group="Stop4")
box("SinkSpill", 4.144, 4.15, 0, KC, 0.05, 0.45, "water", col=False, group="Stop4")
box("CounterWater", 4.15, 4.75, KC, KC + 0.004, -1.3, -0.25, "water", col=False, group="Stop4")
box("SinkWater", 4.25, 4.65, KC - 0.01, KC - 0.005, -0.25, 0.65, "water", col=False, group="Stop4")

# ---------------- stop 5: the long windowsill (rough)
box("Windowsill", -1.45, 4.15, 0.87, 0.9, 2.4, 2.65, "wood", group="Stop5")
box("Armchair", 1.2, 2.0, 0, 0.42, 1.4, 2.15, "fabric", group="Stop5")
box("ArmchairBack", 1.2, 2.0, 0, 0.95, 2.15, 2.3, "fabric", group="Stop5")
box("RadioTable", 2.15, 2.5, 0, 0.55, 1.9, 2.25, "wood", group="Stop5")
box("Radio", 2.18, 2.47, 0.55, 0.72, 1.95, 2.2, "darkwood", group="Stop5")

# the clothesline (scripts/zipline.gd), hooked across the living room: from the kitchen end of the window,
# over the room to a hook behind the sofa, back to the window by the armchair, then along the window to the
# breaker box. Each span sags a little.
ZIP_POINTS = [(4.35, 1.62, 2.5), (2.0, 1.56, -0.4), (0.9, 1.48, 2.45), (-0.3, 1.38, 2.45)]
ZIP_SAGS = [0.14, 0.12, 0.05]
# ---------------- stop 6: breaker box south of the bedroom door + wire clips up from the sill (rough)
# The clothesline ends right above a little wall shelf under the breaker box: drop onto it, walk to the box.
box("BreakerBox", BW, BW + 0.08, 1.11, 1.56, 2.0, 2.35, "metal", group="Stop6")
box("BreakerFault", BW + 0.08, BW + 0.085, 1.47, 1.50, 2.12, 2.15, "fault", col=False, group="Stop6")
box("BreakerShelf", BW, BW + 0.2, 1.03, 1.06, 1.95, 2.62, "wood", group="Stop6")
for i, z in enumerate([2.0, 2.55]):
    box(f"ShelfBracket{i + 1}", BW, BW + 0.12, 0.95, 1.03, z - 0.01, z + 0.01, "darkwood", col=False, group="Stop6")
box("WireDrop", BW, BW + 0.012, 1.56, 1.915, 2.16, 2.175, "person", col=False, group="Stop6")
box("BreakerOk", BW + 0.08, BW + 0.085, 1.42, 1.45, 2.12, 2.15, "cyanmark", col=False, group="Stop6")
box("WireAlongWall", BW, BW + 0.012, 1.9, 1.915, -2.6, 2.0, "person", col=False, group="Stop6")

PEOPLE = [  # name, kind, radius(m), height(m), centre(m), rotation(deg)
    ("OldManInBed", "cyl", 0.17, 1.15, (-4.05, 0.68, -1.5), (90, 0, 0)),
    ("OldManHead", "sph", 0.11, 0, (-4.05, 0.72, -2.35), None),
    ("BoyAtDesk", "cyl", 0.16, 0.6, (-1.3, 0.76, 0.5), (0, 0, 0)),
    ("BoyHead", "sph", 0.1, 0, (-1.26, 1.16, 0.5), None),
    ("YoungManOnSofa", "cyl", 0.2, 0.75, (1.3, 0.8, -0.95), (0, 0, 0)),
    ("CookAtStove", "cyl", 0.22, 1.5, (3.7, 0.75, -1.78), (0, 0, 0)),
    ("OldManInArmchair", "cyl", 0.2, 0.7, (1.6, 0.77, 1.75), (0, 0, 0)),
]
SPAWN = (-3.22, NT, -2.28)
FAIL = 0.3 / K   # box floor = the dark: standing below 0.3 robot units -> respawn
CHECKPOINTS = [  # name, position(m), chapter, recharge, respawn_charge, fail_below_y(units)
    ("Opening", SPAWN, "opening", 0.0, 1.0, -100),
    ("ToyBox", (-2.70, 0.12, -2.50), "childhood", 0.0, 0.9, 0.3),
    ("BoxShelf", (-2.25, 0.3, -2.58), "childhood", 0.05, 0.8, 0.3),
    ("Desk", (-1.0983, 0.75, -0.4917), "teen", 0.1, 0.8, 6.7),
    ("OpenPlan", (BW + 0.3, 0.0, 1.3), "young", 0.1, 0.7, -100),
    ("TvTop", (0.6, TVC[4], -2.45), "young", 0.0, 0.7, -100),
    ("TvExit", (1.68, 0.0, -1.80), "young", 0.05, 0.6, -100),
    ("Kitchen", (2.42, KC, -2.17), "middle", 0.0, 0.5, -100),
    ("SpiceShelf", (3.2, 1.33, -2.585), "middle", 0.0, 0.5, -100),
    ("Kettle", (4.66, KC, -1.52), "middle", 0.0, 0.45, -100),
    ("SinkSouth", (4.45, KC, 0.85), "middle", 0.0, 0.4, -100),
    ("SillEnd", (-0.27, 1.06, 2.42), "old", 0.0, 0.2, -100),
]
MARKERS = {
    "PlayerStart": SPAWN,
    "FallLanding": (-2.70, 0.122, -2.50),
    "MachineLook": (-1.95, 0.35, -2.2),
    "BookLanding": (-2.5, 0.02, -2.3),
    "DeskLampTarget": (BW - 0.14, 1.1, 0.55),
    "DoorLook": (-0.45, 0.85, 0.95),
    "OpenPlanDrop": (BW + 0.3, 0.002, 1.3),
    "BreakerLook": (BW + 0.04, 1.33, 2.17),
    "FinaleStand": (BW + 0.13, 1.062, 2.27),
    "TvLook": (1.0, 0.75, -2.18),
    "TvExitLanding": (1.68, 0.002, -1.80),
    "StoveLook": (3.7, 1.0, -2.3),
    "SinkLook": (4.3, 0.95, 0.2),
    "SillLook": (3.9, 0.95, 2.5),
    "ToasterSlot": (3.3, KC + 0.11, -2.41),
    "SpiceShelfLanding": (3.2, 1.332, -2.585),
    "SinkLanding": (4.45, KC + 0.002, 0.85),
    "SinkCam": (3.55, 1.35, 0.35),
    "FatherHead": (3.7, 1.42, -1.78),
    "ShelfTarget": (-2.25, 0.302, -2.58),
    "DeskLanding": (-1.0983, 0.752, -0.4917),
    "DrumLanding": (-2.0, 0.12, -2.20),
    "CarWay1": (-1.72, 0.595, -2.31),
    "CarWay2": (-1.80, 0.595, -2.31),
    "CarWay3": (-1.80, 0.595, -2.20),
    "CarWay4": (-1.81, 0.595, -2.20),
}
AREAS = {  # trigger boxes: name -> (centre m, size m)
    "BookTip": ((NS[1] + BOOK_OVER / 2, NT + BOOK[1] + 0.03, BOOK_EDGE[2]), (BOOK_OVER, 0.05, BOOK[2])),
    "BooksTop": ((-3.185, NT + 0.16, -2.545), (0.15, 0.04, 0.13)),
    "JackTop": ((-2.28, 0.13, -1.95), (0.09, 0.05, 0.09)),
    "SeesawEnd": ((-2.26, 0.08, -2.20), (0.08, 0.08, 0.08)),
    "KitchenReveal": ((1.7, 0.05, -2.12), (0.36, 0.1, 0.4)),
    "SinkPile": ((4.45, 1.03, -0.1), (0.3, 0.07, 0.3)),
    "SteamPlume": ((4.51, 1.155, -1.16), (0.42, 0.41, 0.9)),
}
LIGHTS = [  # name, kind, pos(m), colour, energy, range(m)
    ("DeskLampGlow", "omni", (BW - 0.16, 1.02, 0.55), (1.0, 0.7, 0.4), 1.8, 1.4),
    ("TVGlow", "omni", (1.0, 0.75, -1.9), (0.35, 0.5, 1.0), 2.0, 2.2),
    ("StoveGlow", "omni", (3.7, 1.1, -2.3), (1.0, 0.5, 0.2), 3.5, 2.8),
    ("FloodSheen", "omni", (3.4, 0.35, 0.3), (0.45, 0.65, 1.0), 1.2, 2.6),   # makes the flood water glint
    ("BreakerFaultLight", "omni", (BW + 0.1, 1.48, 2.13), (1.0, 0.1, 0.05), 1.8, 0.9),
]


def tr(c, rot=(0, 0, 0), scale=True):
    k = K if scale else 1.0
    rx, ry, rz = (math.radians(a) for a in rot)
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    m = [[cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx],
         [cx * sz, cx * cz, -sx],
         [-sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx]]
    rows = [m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2]]  # tscn stores basis rows
    return "Transform3D(" + ", ".join(f"{v:.6g}" for v in rows) + f", {c[0] * k:.4g}, {c[1] * k:.4g}, {c[2] * k:.4g})"


L = ['[gd_scene format=3]', '',
     '[ext_resource type="Script" path="res://scripts/room.gd" id="room"]',
     '[ext_resource type="Script" path="res://scripts/components/checkpoint.gd" id="cp"]',
     '[ext_resource type="Script" path="res://scripts/components/pushable.gd" id="push"]',
     '[ext_resource type="Script" path="res://scripts/components/interactable.gd" id="ia"]',
     '[ext_resource type="Script" path="res://scripts/components/toy_train.gd" id="train"]',
     '[ext_resource type="Script" path="res://scripts/components/battery_pickup.gd" id="bat"]',
     '[ext_resource type="Script" path="res://scripts/components/reveal_light.gd" id="reveal"]',
     '[ext_resource type="Script" path="res://scripts/components/hole_fill.gd" id="holefill"]',
     '[ext_resource type="Script" path="res://scripts/desk_maze.gd" id="maze"]',
     '[ext_resource type="Script" path="res://scripts/tv_screen.gd" id="tv"]',
     '[ext_resource type="Script" path="res://scripts/components/hazard.gd" id="hazard"]',
     '[ext_resource type="Script" path="res://scripts/zipline.gd" id="zip"]',
     '[ext_resource type="PackedScene" path="res://scenes/post_fx.tscn" id="post"]',
     '[ext_resource type="Shader" path="res://shaders/night_sky.gdshader" id="nightsky"]', '']
for name, (rgb, rough, em, transp) in MATS.items():
    L.append(f'[sub_resource type="StandardMaterial3D" id="m_{name}"]')
    L += (['transparency = 1', f'albedo_color = Color({rgb[0]}, {rgb[1]}, {rgb[2]}, {ALPHA.get(name, 0.35)})'] if transp
          else [f'albedo_color = Color({rgb[0]}, {rgb[1]}, {rgb[2]}, 1)'])
    L.append(f'roughness = {rough}')
    if em:
        L += ['emission_enabled = true', f'emission = Color({em[0]}, {em[1]}, {em[2]}, 1)', 'emission_energy_multiplier = 1.5']
    L.append('')
for name, (c, sz) in AREAS.items():
    L += [f'[sub_resource type="BoxShape3D" id="area_{name}"]', f'size = Vector3({sz[0] * K:.4g}, {sz[1] * K:.4g}, {sz[2] * K:.4g})', '']
L += ['[sub_resource type="PlaneMesh" id="bed_ceiling"]', f'size = Vector2({(BW - X0) * K:.4g}, {(Z1 - Z0) * K:.4g})', 'flip_faces = true', '']
L += ['[sub_resource type="ShaderMaterial" id="sky_mat"]', 'shader = ExtResource("nightsky")', '',
      '[sub_resource type="Sky" id="sky"]', 'sky_material = SubResource("sky_mat")', 'radiance_size = 1', '']
L += ['[sub_resource type="Environment" id="env"]', 'background_mode = 2', 'background_color = Color(0.025, 0.035, 0.08, 1)',
      'sky = SubResource("sky")', 'fog_sky_affect = 0.0',
      'ambient_light_source = 2', 'ambient_light_color = Color(0.35, 0.42, 0.65, 1)', 'ambient_light_energy = 0.45',
      'tonemap_mode = 3', 'ssao_enabled = true', 'glow_enabled = true', 'glow_hdr_threshold = 0.9',
      'fog_enabled = true', 'fog_light_color = Color(0.03, 0.04, 0.07, 1)', 'fog_density = 0.006',
      'volumetric_fog_enabled = true', 'volumetric_fog_density = 0.004', '']
L += ['[node name="Room" type="Node3D"]', 'script = ExtResource("room")', '',
      '[node name="WorldEnvironment" type="WorldEnvironment" parent="."]', 'environment = SubResource("env")', '',
      '[node name="Moonlight" type="DirectionalLight3D" parent="."]', f'transform = {tr((0, 4, 0), (-35, 200, 0))}',
      'light_color = Color(0.55, 0.65, 1, 1)', 'light_energy = 0.8', 'light_volumetric_fog_energy = 2.0', 'shadow_enabled = true', '']
groups = []
for s in S:
    if s[1] not in groups:
        groups.append(s[1])
        L += [f'[node name="{s[1]}" type="Node3D" parent="."]', '']
for kind, group, name, dims, c, mat, col, rot in S:
    t = {"box": "CSGBox3D", "cyl": "CSGCylinder3D", "sph": "CSGSphere3D"}[kind]
    L += [f'[node name="{name}" type="{t}" parent="{group}"]', f'transform = {tr(c, rot)}']
    if col:
        L.append('use_collision = true')
    if kind == "box":
        L.append(f'size = Vector3({dims[0] * K:.4g}, {dims[1] * K:.4g}, {dims[2] * K:.4g})')
    elif kind == "cyl":
        L += [f'radius = {dims[0] * K:.4g}', f'height = {dims[1] * K:.4g}', 'sides = 24']
    else:
        L += [f'radius = {dims[0] * K:.4g}', 'radial_segments = 16', 'rings = 10']
    L += [f'material = SubResource("m_{mat}")', '']
L += ['[node name="People" type="Node3D" parent="."]', '']
for name, kind, r, h, c, rot in PEOPLE:
    if kind == "sph":
        L += [f'[node name="{name}" type="CSGSphere3D" parent="People"]', f'transform = {tr(c)}', f'radius = {r * K:.4g}']
    else:
        L += [f'[node name="{name}" type="CSGCylinder3D" parent="People"]', f'transform = {tr(c, rot)}',
              f'radius = {r * K:.4g}', f'height = {h * K:.4g}']
    L += ['material = SubResource("m_person")', '']
L += ['[node name="Checkpoints" type="Node3D" parent="."]', '']
for name, p, ch, rc, rsp, fb in CHECKPOINTS:
    L += [f'[node name="{name}" type="Area3D" parent="Checkpoints"]', f'transform = {tr(p)}', 'script = ExtResource("cp")',
          f'chapter_id = "{ch}"', f'recharge = {rc}', f'respawn_charge = {rsp}', f'fail_below_y = {fb}',
          'size = Vector3(1.5, 1.5, 1.5)', 'show_light = false', '']
for name, kind, p, col, e, rng in LIGHTS:
    L += [f'[node name="{name}" type="OmniLight3D" parent="."]', f'transform = {tr(p)}',
          f'light_color = Color({col[0]}, {col[1]}, {col[2]}, 1)', f'light_energy = {e}', f'omni_range = {rng * K:.4g}',
          'shadow_enabled = true', '']
# a shaft of moonlight through the north window onto the nightstand top
L += ['[node name="MoonShaft" type="SpotLight3D" parent="."]', f'transform = {tr((-3.06, 2.3, -2.6), (-96, 0, 0))}',
      'light_color = Color(0.75, 0.82, 1, 1)', 'light_energy = 40.0', 'light_volumetric_fog_energy = 1.5',
      'shadow_enabled = true', f'spot_range = {3.5 * K:.4g}', 'spot_angle = 17.0', 'spot_attenuation = 0.15', '']
L += ['[node name="MoonFill" type="OmniLight3D" parent="."]', f'transform = {tr((-3.0, 1.4, -2.2))}',
      'light_color = Color(0.5, 0.6, 1, 1)', 'light_energy = 1.2', f'omni_range = {2.2 * K:.4g}', 'omni_attenuation = 0.6', '']
# the loose book: Node3D pivot on the table edge, the book offset so 9 cm hangs over
L += ['[node name="LooseBook" type="Node3D" parent="Stop0"]', f'transform = {tr(BOOK_EDGE)}', '',
      '[node name="Book" type="CSGBox3D" parent="Stop0/LooseBook"]',
      f'transform = {tr((BOOK_OVER - BOOK[0] / 2, BOOK[1] / 2, 0))}', 'use_collision = true',
      f'size = Vector3({BOOK[0] * K:.4g}, {BOOK[1] * K:.4g}, {BOOK[2] * K:.4g})', 'material = SubResource("m_toy_red")', '',
      '[node name="Pages" type="CSGBox3D" parent="Stop0/LooseBook/Book"]',
      f'transform = {tr((0.004, 0, 0))}', f'size = Vector3({(BOOK[0] - 0.01) * K:.4g}, {(BOOK[1] - 0.008) * K:.4g}, {(BOOK[2] + 0.002) * K:.4g})',
      'material = SubResource("m_paper")', '']
# the face-down photo frame: E stands it up
L += ['[node name="PhotoFrame" type="Node3D" parent="Stop0"]', f'transform = {tr((-3.12, NT, -2.49))}', '',
      '[node name="Frame" type="CSGBox3D" parent="Stop0/PhotoFrame"]', f'transform = {tr((0.065, 0.006, 0.09))}',
      'use_collision = true', f'size = Vector3({0.13 * K:.4g}, {0.012 * K:.4g}, {0.18 * K:.4g})', 'material = SubResource("m_darkwood")', '',
      '[node name="Photo" type="CSGBox3D" parent="Stop0/PhotoFrame/Frame"]', f'transform = {tr((0, -0.0065, 0))}',
      f'size = Vector3({0.11 * K:.4g}, {0.001 * K:.4g}, {0.16 * K:.4g})', 'material = SubResource("m_lampshade")', '',
      '[node name="FrameInteract" type="Area3D" parent="Stop0"]', f'transform = {tr((-3.055, NT + 0.02, -2.4))}',
      'script = ExtResource("ia")', 'cost = 0.0', 'radius = 1.3', 'prompt_offset = Vector3(0, 1.2, 0)', '']
# ---- stop 1 dynamic pieces
L += ['[node name="TrackRing" type="CSGTorus3D" parent="Stop1"]', f'transform = {tr((TRAIN_C[0], 0.009, TRAIN_C[2]))}',
      f'inner_radius = {(TRAIN_R - 0.012) * K:.4g}', f'outer_radius = {(TRAIN_R + 0.012) * K:.4g}', 'sides = 48', 'ring_sides = 4',
      'material = SubResource("m_metal")', '',
      '[node name="Train" type="AnimatableBody3D" parent="Stop1"]', 'script = ExtResource("train")',
      f'center = Vector3({TRAIN_C[0] * K:.4g}, {0.008 * K:.4g}, {TRAIN_C[2] * K:.4g})', f'radius = {TRAIN_R * K:.4g}',
      'speed = 0.5', f'size = Vector3({0.1 * K:.4g}, {0.06 * K:.4g}, {0.05 * K:.4g})', '']
L += ['[node name="JackHead" type="CSGSphere3D" parent="Stop1"]', f'transform = {tr((-2.28, 0.07, -1.95))}',
      f'radius = {0.04 * K:.4g}', 'material = SubResource("m_paper")', '']
# the big robot's eyes: two amber discs on the west face of its head + a light shining down on the seesaw
for i, z in enumerate([-2.25, -2.15]):
    L += [f'[node name="BigBotEye{i + 1}" type="CSGCylinder3D" parent="Stop1"]', f'transform = {tr((-1.952, 0.52, z), (0, 0, 90))}',
          f'radius = {0.022 * K:.4g}', f'height = {0.004 * K:.4g}', 'sides = 20', 'material = SubResource("m_amber_eye")', '']
L += ['[node name="BigBotEyeLight" type="SpotLight3D" parent="Stop1"]', f'transform = {tr((-1.97, 0.52, -2.20), (-38, 90, 0))}',
      'light_color = Color(1, 0.72, 0.35, 1)', 'light_energy = 6.0', 'shadow_enabled = true',
      f'spot_range = {0.8 * K:.4g}', 'spot_angle = 32.0', 'spot_attenuation = 0.5', '']
# the seesaw: a 34 cm ruler between the legs, pivot at the fulcrum; west end (cyan, "stand here") rests low
L += ['[node name="Seesaw" type="Node3D" parent="Stop1"]', f'transform = {tr((-2.12, 0.06, -2.20), (0, 0, 6))}', '',
      '[node name="Plank" type="CSGBox3D" parent="Stop1/Seesaw"]', f'transform = {tr((0, 0.007, 0))}', 'use_collision = true',
      f'size = Vector3({0.36 * K:.4g}, {0.014 * K:.4g}, {0.08 * K:.4g})', 'material = SubResource("m_ruler")', '',
      '[node name="StandHere" type="CSGBox3D" parent="Stop1/Seesaw/Plank"]', f'transform = {tr((-0.14, 0.0075, 0))}',
      f'size = Vector3({0.075 * K:.4g}, {0.002 * K:.4g}, {0.078 * K:.4g})', 'material = SubResource("m_cyanmark")', '']
# a big toy drum on the west edge of the robot's head, right above the seesaw's raised east end
L += ['[node name="Drum" type="CSGCylinder3D" parent="Stop1"]', f'transform = {tr((-1.89, 0.625, -2.20))}', 'use_collision = true',
      f'radius = {0.06 * K:.4g}', f'height = {0.09 * K:.4g}', 'sides = 24', 'material = SubResource("m_toy_red")', '',
      '[node name="DrumSkin" type="CSGCylinder3D" parent="Stop1/Drum"]', f'transform = {tr((0, 0.046, 0))}',
      f'radius = {0.058 * K:.4g}', f'height = {0.003 * K:.4g}', 'sides = 24', 'material = SubResource("m_paper")', '',
      '[node name="ElectricCar" type="CSGBox3D" parent="Stop1"]', f'transform = {tr((-1.72, 0.595, -2.09))}', 'use_collision = true',
      f'size = Vector3({0.05 * K:.4g}, {0.03 * K:.4g}, {0.08 * K:.4g})', 'material = SubResource("m_toy_green")', '',
      '[node name="CarCharge" type="Area3D" parent="Stop1"]', f'transform = {tr((-1.72, 0.60, -2.09))}', 'script = ExtResource("ia")',
      'cost = 0.08', 'hold_time = 1.5', 'once = false', 'radius = 1.4', 'prompt_offset = Vector3(0, 1.0, 0)', '']
for name, sz, pos, col in [("PushBlockLarge", 0.15, (-2.18, 0.301, -2.47), "Color(0.75, 0.3, 0.2, 1)"),
                           ("PushBlockSmall", 0.067, (-2.38, 0.301, -2.47), "Color(0.2, 0.45, 0.7, 1)")]:
    L += [f'[node name="{name}" type="CharacterBody3D" parent="Stop1"]', f'transform = {tr(pos)}', 'script = ExtResource("push")',
          f'size = Vector3({sz * K:.4g}, {sz * K:.4g}, {sz * K:.4g})', f'color = {col}', f'letter = "{"A" if "Large" in name else "B"}"', '']
for i, pos in enumerate([(-2.74, 0.15, -2.06), (-2.40, 0.31, -2.58)]):
    L += [f'[node name="Battery{i + 1}" type="Area3D" parent="Stop1"]', f'transform = {tr(pos)}', 'script = ExtResource("bat")', '']
# ---- stop 2 dynamic pieces
# the random maze on the desk top
L += ['[node name="DeskMaze" type="Node3D" parent="Stop2"]', 'script = ExtResource("maze")',
      f'x0 = {DK[0]}', f'x1 = {DK[1]}', f'z0 = {DK[2]}', f'z1 = {DK[3]}', f'top = {DK[4]}', 'seed_pool = PackedInt32Array(0, 7, 22, 49)', '']
# the bedroom door, closed, hinged on its south edge; its lever handle reaches back towards the desk
L += ['[node name="DoorPivot" type="Node3D" parent="Stop2"]', f'transform = {tr((BW + 0.02, 0, DOOR[1]))}', '',
      '[node name="Door" type="CSGBox3D" parent="Stop2/DoorPivot"]', f'transform = {tr((0, 1.025, -(DOOR[1] - DOOR[0]) / 2))}',
      'use_collision = true', f'size = Vector3({0.04 * K:.4g}, {2.05 * K:.4g}, {(DOOR[1] - DOOR[0]) * K:.4g})', 'material = SubResource("m_wood")', '',
      '[node name="Handle" type="Node3D" parent="Stop2/DoorPivot"]', f'transform = {tr((-0.11, 0.80, -(DOOR[1] - DOOR[0]) + 0.08))}', '',
      '[node name="Lever" type="CSGBox3D" parent="Stop2/DoorPivot/Handle"]', f'transform = {tr((0, 0, -0.07))}',
      f'size = Vector3({0.025 * K:.4g}, {0.02 * K:.4g}, {0.14 * K:.4g})', 'material = SubResource("m_brass")', '',
      '[node name="DoorGapGlow" type="CSGBox3D" parent="Stop2"]', f'transform = {tr((BW - 0.002, 0.004, (DOOR[0] + DOOR[1]) / 2))}',
      f'size = Vector3({0.004 * K:.4g}, {0.008 * K:.4g}, {(DOOR[1] - DOOR[0]) * K:.4g})', 'material = SubResource("m_tvscreen")', '',
      '[node name="DoorHandleUse" type="Area3D" parent="Stop2"]', f'transform = {tr((DK[1] - 0.06, 0.77, 0.79))}', 'script = ExtResource("ia")',
      'cost = 0.0', 'radius = 1.0', 'prompt_offset = Vector3(0, 1.2, 0)', '']
# ---- stop 3: the live screen (a 2D game in a SubViewport) and the spot in front of it
L += ['[node name="TvScreen" type="Node3D" parent="Stop3"]', f'transform = {tr((1.0, 0.75, -2.177))}', 'script = ExtResource("tv")',
      f'size = Vector2({0.48 * K:.4g}, {0.38 * K:.4g})', '',
      '[node name="TvEnter" type="Area3D" parent="Stop3"]', f'transform = {tr((1.0, TVC[4] + 0.02, -2.09))}', 'script = ExtResource("ia")',
      'cost = 0.0', 'radius = 0.8', 'prompt_offset = Vector3(0, 1.3, 0)', '']
# the childhood time box: a painted tin with its lid hinged at the back (north) edge
L += ['[node name="TimeBoxLid" type="Node3D" parent="Stop3"]', f'transform = {tr((1.6, 0.05, -2.195))}', '',
      '[node name="Lid" type="CSGBox3D" parent="Stop3/TimeBoxLid"]', f'transform = {tr((0, 0.006, 0.045))}',
      f'size = Vector3({0.124 * K:.4g}, {0.012 * K:.4g}, {0.094 * K:.4g})', 'material = SubResource("m_toy_yellow")', '',
      '[node name="Drawing" type="CSGBox3D" parent="Stop3"]', f'transform = {tr((1.6, 0.046, -2.15), (0, 12, 0))}',
      f'size = Vector3({0.09 * K:.4g}, {0.003 * K:.4g}, {0.065 * K:.4g})', 'material = SubResource("m_paper")', '',
      '[node name="TimeBoxGlow" type="OmniLight3D" parent="Stop3"]', f'transform = {tr((1.6, 0.14, -2.12))}',
      'light_color = Color(1, 0.72, 0.38, 1)', 'light_energy = 0.0', f'omni_range = {0.6 * K:.4g}', '',
      '[node name="TimeBoxOpen" type="Area3D" parent="Stop3"]', f'transform = {tr((1.6, 0.03, -2.1))}', 'script = ExtResource("ia")',
      'cost = 0.0', 'radius = 0.9', 'prompt_offset = Vector3(0, 1.0, 0)', '']
# ---- stop 4 dynamic pieces: the microwave door + cutting board, the toaster's glowing coils, hazards
L += ['[node name="MicrowaveDoor" type="Node3D" parent="Stop4"]', f'transform = {tr((2.72, KC, -2.30))}', '',
      '[node name="Door" type="CSGBox3D" parent="Stop4/MicrowaveDoor"]', f'transform = {tr((-0.16, 0.135, 0.008))}',
      f'size = Vector3({0.32 * K:.4g}, {0.27 * K:.4g}, {0.016 * K:.4g})', 'material = SubResource("m_glass")', '',
      '[node name="CuttingBoard" type="CSGBox3D" parent="Stop4"]', f'transform = {tr((2.6, KC + 0.005, -2.17))}', 'use_collision = true',
      f'size = Vector3({0.5 * K:.4g}, {0.01 * K:.4g}, {0.14 * K:.4g})', 'material = SubResource("m_wood")', '',
      '[node name="MicrowaveUse" type="Area3D" parent="Stop4"]', f'transform = {tr((2.56, KC + 0.02, -2.2))}', 'script = ExtResource("ia")',
      'cost = 0.04', 'radius = 0.9', 'prompt_offset = Vector3(0, 1.2, 0)', '',
      '[node name="ToasterCoils" type="CSGBox3D" parent="Stop4"]', f'transform = {tr((3.3, KC + 0.17, -2.41))}',
      f'size = Vector3({0.12 * K:.4g}, {0.012 * K:.4g}, {0.16 * K:.4g})', 'material = SubResource("m_person")', '',
      '[node name="ToasterUse" type="Area3D" parent="Stop4"]', f'transform = {tr((3.3, KC + 0.19, -2.41))}', 'script = ExtResource("ia")',
      'cost = 0.06', 'radius = 0.75', 'prompt_offset = Vector3(0, 1.1, 0)', '']
for name, kind, (x0, x1, y0, y1, z0, z1) in [
        ("WaterFloor", "water", (2.35, 4.15, -0.2, 0.03, -2.05, 2.4)),
        ("WaterGap", "water", (2.85, 3.2, -0.2, 0.03, -2.65, -2.05)),
        ("WaterCounter", "water", (4.15, 4.75, KC - 0.02, KC + 0.02, -1.3, -0.25)),
        ("StoveFire", "fire", (3.42, 3.98, KC + 0.03, KC + 0.12, -2.63, -2.08)),
        ("WaterCorner", "water", (4.0, 4.75, KC - 0.02, KC + 0.02, -2.65, -1.75))]:
    L += [f'[node name="{name}" type="Area3D" parent="Stop4"]', f'transform = {tr(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))}',
          'script = ExtResource("hazard")', f'kind = "{kind}"',
          f'size = Vector3({(x1 - x0) * K:.4g}, {(y1 - y0) * K:.4g}, {(z1 - z0) * K:.4g})', '']
# the kettle (E: boils, steam) and the daughter's mug by the window (E: tap it)
L += ['[node name="KettleUse" type="Area3D" parent="Stop4"]', f'transform = {tr((4.6, KC + 0.02, -1.5))}', 'script = ExtResource("ia")',
      'cost = 0.05', 'once = false', 'radius = 0.9', 'prompt_offset = Vector3(0, 1.3, 0)', '',
      '[node name="MugTap" type="Area3D" parent="Stop4"]', f'transform = {tr((4.45, KC + 0.02, 2.36))}', 'script = ExtResource("ia")',
      'cost = 0.0', 'radius = 0.9', 'prompt_offset = Vector3(0, 1.1, 0)', '',
      '[node name="MugGlow" type="OmniLight3D" parent="Stop4"]', f'transform = {tr((4.45, KC + 0.12, 2.42))}',
      'light_color = Color(1, 0.72, 0.38, 1)', 'light_energy = 0.0', f'omni_range = {0.7 * K:.4g}', '']
# the two burners flare up in turn, right up to the hood: wait for a gap, hanging underneath
for side, x in [("W", 3.55), ("E", 3.85)]:
    L += [f'[node name="FlarePivot{side}" type="Node3D" parent="Stop4"]', f'transform = {tr((x, KC + 0.03, -2.4))}', '',
          f'[node name="Flame" type="CSGBox3D" parent="Stop4/FlarePivot{side}"]', f'transform = {tr((0, 0.015, 0))}',
          f'size = Vector3({0.14 * K:.4g}, {0.03 * K:.4g}, {0.3 * K:.4g})', 'material = SubResource("m_fault")', '',
          f'[node name="Flare{side}" type="Area3D" parent="Stop4"]', f'transform = {tr((x, (KC + 0.12 + 1.46) / 2, -2.4))}',
          'script = ExtResource("hazard")', 'kind = "fire"', 'enabled = false',
          f'size = Vector3({0.2 * K:.4g}, {(1.46 - KC - 0.12) * K:.4g}, {0.4 * K:.4g})', '']
# ---- stop 5: the clothesline and the hanger you grab (E) at the kitchen end
L += ['[node name="Zipline" type="Node3D" parent="Stop5"]', 'script = ExtResource("zip")',
      'points = PackedVector3Array(' + ', '.join(f'{c * K:.4g}' for p in ZIP_POINTS for c in p) + ')',
      'sags = PackedFloat32Array(' + ', '.join(f'{v * K:.4g}' for v in ZIP_SAGS) + ')', f'ceiling = {H * K:.4g}', '',
      '[node name="ZiplineGrab" type="Area3D" parent="Stop5"]', f'transform = {tr((ZIP_POINTS[0][0], 0.92, ZIP_POINTS[0][2] - 0.05))}',
      'script = ExtResource("ia")', 'cost = 0.0', 'radius = 1.1', 'prompt_offset = Vector3(0, 1.0, 0)', '']
# ---- the finale: the breaker's lever, holding E to pour the last charge in, the house's own lights
L += ['[node name="BreakerLever" type="Node3D" parent="Stop6"]', f'transform = {tr((BW + 0.085, 1.30, 2.24))}', '',
      '[node name="Handle" type="CSGBox3D" parent="Stop6/BreakerLever"]', f'transform = {tr((0.02, -0.04, 0))}',
      f'size = Vector3({0.03 * K:.4g}, {0.09 * K:.4g}, {0.03 * K:.4g})', 'material = SubResource("m_toy_red")', '',
      '[node name="BreakerCharge" type="Area3D" parent="Stop6"]', f'transform = {tr((BW + 0.13, 1.08, 2.25))}', 'script = ExtResource("ia")',
      'cost = 0.0', 'hold_time = 4.0', 'radius = 0.9', 'prompt_offset = Vector3(0, 1.2, 0)', '']
HOUSE_LIGHTS = [(-0.1, 2.4, 2.0), (0.9, 2.4, 1.2), (1.0, 2.4, -1.3), (2.8, 2.4, 0.0), (3.8, 2.4, -1.6), (4.3, 2.4, 1.0),
                (-1.4, 2.4, 1.6), (-1.8, 2.4, -0.6), (-3.4, 2.4, -1.6), (-3.2, 2.4, 1.6)]
for i, p in enumerate(HOUSE_LIGHTS):  # off until the power comes back
    L += [f'[node name="HouseLight{i + 1}" type="OmniLight3D" parent="."]', f'transform = {tr(p)}',
          'light_color = Color(1, 0.78, 0.5, 1)', 'light_energy = 0.0', f'omni_range = {3.2 * K:.4g}', 'omni_attenuation = 1.2', '']
for i, p in enumerate([(1.5, 1.6, 3.4), (-3.2, 1.6, 3.2), (-3.05, 1.5, -3.2)]):  # warm light spilling out of the windows
    L += [f'[node name="WindowSpill{i + 1}" type="OmniLight3D" parent="."]', f'transform = {tr(p)}',
          'light_color = Color(1, 0.75, 0.45, 1)', 'light_energy = 0.0', f'omni_range = {2.6 * K:.4g}', '']
L += ['[node name="Areas" type="Node3D" parent="."]', '']
for name, (c, sz) in AREAS.items():
    L += [f'[node name="{name}" type="Area3D" parent="Areas"]', f'transform = {tr(c)}', '',
          f'[node name="Shape" type="CollisionShape3D" parent="Areas/{name}"]', f'shape = SubResource("area_{name}")', '']
for name, p in MARKERS.items():
    L += [f'[node name="{name}" type="Marker3D" parent="."]', f'transform = {tr(p)}', '']
# a ceiling over the open-plan room (the clothesline's hanging things hang from it); casts no shadow so the
# room keeps its moonlight. The bedroom's ceiling is one-sided (seen only from below), so the overhead shots and
# the desk maze's top-down camera still look straight down into the room - but the sky no longer shows through it.
L += ['[node name="Ceiling" type="CSGBox3D" parent="Shell"]', f'transform = {tr(((BW + X1) / 2, H + 0.03, (Z0 + Z1) / 2))}',
      f'size = Vector3({(X1 - BW) * K:.4g}, {0.06 * K:.4g}, {(Z1 - Z0) * K:.4g})', 'cast_shadow = 0', 'material = SubResource("m_wall")', '']
L += ['[node name="BedroomCeiling" type="MeshInstance3D" parent="Shell"]', f'transform = {tr(((X0 + BW) / 2, H, (Z0 + Z1) / 2))}',
      'mesh = SubResource("bed_ceiling")', 'cast_shadow = 0', 'surface_material_override/0 = SubResource("m_wall")', '']
L += ['[node name="PostFX" parent="." instance=ExtResource("post")]', '']
from bedroom_layout import apply_layout
OUT.write_text(apply_layout("\n".join(L)), encoding="utf-8")
print("wrote", OUT, len(S), "shapes; K =", K)
