"""Asset intake for jam-test.

  python tools/inbox.py check            # check everything in inbox/, print PASS/WARN/FAIL + reasons
  python tools/inbox.py ingest [--verify] # check, then copy passing files into assets/, convert audio
                                          # to .ogg, run Godot import (and optionally launch the game
                                          # to confirm the asset loaded). Prints elapsed seconds.

Naming rules (so the game picks files up with zero code changes):
  creature_*.glb -> assets/models/creature.glb   (rigged + animated, needs idle & walk/run clips)
  prop_*.glb     -> assets/models/prop.glb
  other *.glb    -> assets/models/<name>.glb
  bgm_* / amb_*  -> looping music/ambience (seam checked)   sfx_* -> one-shots
  ambience.* / hum.* replace the placeholder sounds directly.
  tex_*.png/jpg/webp -> assets/textures/<name>.png, resized to TEX_SIZE (tex_wall* = corridor walls)
Loops (bgm_/amb_) are auto-fixed on ingest: leading/trailing silence and baked-in fade-out are
trimmed, then the end is crossfaded into the start so the file loops without a gap or click.
"""
import json, re, shutil, struct, subprocess, sys, time
from io import BytesIO
from pathlib import Path
import numpy as np
import soundfile as sf
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
INBOX, MODELS, AUDIO = ROOT / "inbox", ROOT / "assets" / "models", ROOT / "assets" / "audio"
TEXTURES = ROOT / "assets" / "textures"
IMAGE_EXT = {".png", ".jpg", ".jpeg", ".webp"}
TEX_SIZE = 512
LOOP_XFADE_SEC = 2.0
GODOT = r"D:\Godot_v4.7.2-stable_win64_console.exe"

MAX_TRIS = {"creature": 60_000, "prop": 30_000, "other": 50_000}
MAX_TEX = 2048
HEIGHT_RANGE = (0.05, 20.0)  # metres; outside = scale almost certainly wrong
IDLE_RE = re.compile(r"idle", re.I)
MOVE_RE = re.compile(r"walk|run|move|locomot", re.I)
AUDIO_EXT = {".wav", ".mp3", ".ogg", ".flac", ".aiff", ".aif"}
TARGET_RMS_DB, RMS_TOL = -20.0, 4.0


class Report:
    def __init__(self, name):
        self.name, self.fails, self.warns, self.info = name, [], [], {}

    def fail(self, m): self.fails.append(m)
    def warn(self, m): self.warns.append(m)

    @property
    def status(self): return "FAIL" if self.fails else ("WARN" if self.warns else "PASS")

    def print(self):
        print(f"[{self.status}] {self.name}  {json.dumps(self.info, ensure_ascii=False)}")
        for m in self.fails: print(f"    FAIL: {m}")
        for m in self.warns: print(f"    WARN: {m}")


def role_of(p: Path):
    n = p.stem.lower()
    return "creature" if n.startswith("creature") else "prop" if n.startswith("prop") else "other"


# ------------------------------------------------------------------ glTF
def read_glb(p: Path):
    data = p.read_bytes()
    magic, ver, _ = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or ver != 2:
        raise ValueError("not a glTF 2.0 binary (.glb)")
    off, js, binc = 12, None, b""
    while off < len(data):
        ln, typ = struct.unpack_from("<I4s", data, off)
        chunk = data[off + 8: off + 8 + ln]
        if typ == b"JSON": js = json.loads(chunk)
        elif typ == b"BIN\x00": binc = chunk
        off += 8 + ln
    return js, binc


def node_matrix(n):
    if "matrix" in n: return np.array(n["matrix"], float).reshape(4, 4).T
    t = np.eye(4); t[:3, 3] = n.get("translation", [0, 0, 0])
    x, y, z, w = n.get("rotation", [0, 0, 0, 1])
    r = np.eye(4); r[:3, :3] = [[1 - 2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                                [2*(x*y+z*w), 1 - 2*(x*x+z*z), 2*(y*z-x*w)],
                                [2*(x*z-y*w), 2*(y*z+x*w), 1 - 2*(x*x+y*y)]]
    s = np.diag(list(n.get("scale", [1, 1, 1])) + [1])
    return t @ r @ s


def check_glb(p: Path) -> Report:
    r, role = Report(p.name), role_of(p)
    try:
        g, binc = read_glb(p)
    except Exception as e:
        r.fail(f"cannot parse: {e}"); return r
    acc, nodes = g.get("accessors", []), g.get("nodes", [])
    tris, lo, hi = 0, np.full(3, np.inf), np.full(3, -np.inf)

    def walk(i, parent):
        nonlocal tris, lo, hi
        n = nodes[i]; m = parent @ node_matrix(n)
        if "mesh" in n:
            for prim in g["meshes"][n["mesh"]]["primitives"]:
                if prim.get("mode", 4) != 4: continue
                pos = acc[prim["attributes"]["POSITION"]]
                cnt = acc[prim["indices"]]["count"] if "indices" in prim else pos["count"]
                tris += cnt // 3
                if "min" in pos and "max" in pos:
                    mn, mx = np.array(pos["min"]), np.array(pos["max"])
                    corners = np.array([[a, b, c, 1] for a in (mn[0], mx[0]) for b in (mn[1], mx[1]) for c in (mn[2], mx[2])])
                    w = (m @ corners.T).T[:, :3]
                    lo, hi = np.minimum(lo, w.min(0)), np.maximum(hi, w.max(0))
        for c in n.get("children", []): walk(c, m)

    scene = g.get("scenes", [{}])[g.get("scene", 0)] if g.get("scenes") else {"nodes": list(range(len(nodes)))}
    for i in scene.get("nodes", []): walk(i, np.eye(4))
    size = hi - lo
    r.info.update(role=role, tris=tris, size_m=[round(float(v), 3) for v in size],
                  min_y=round(float(lo[1]), 3), materials=len(g.get("materials", [])))

    if tris == 0: r.fail("no triangle geometry")
    elif tris > MAX_TRIS[role]: r.fail(f"{tris} tris > budget {MAX_TRIS[role]} for {role} (decimate in Tripo / Blender)")
    if np.isfinite(size).all():
        h = float(size[1])
        if not HEIGHT_RANGE[0] <= h <= HEIGHT_RANGE[1]:
            r.warn(f"height {h:.3f} m looks wrong (expected {HEIGHT_RANGE}); game auto-fits but check export units")
        if role == "creature" and size[1] < max(size[0], size[2]) * 0.8:
            r.warn("creature is wider/deeper than tall: likely lying down (Z-up export?) - check orientation")
        if abs(lo[1]) > 0.1 * max(h, 1e-6):
            r.warn(f"pivot not at feet (min y = {lo[1]:.3f}); game re-centres automatically")
    else:
        r.fail("no POSITION min/max; cannot measure size")

    if not g.get("materials"): r.warn("no materials (will render default grey)")
    texs = []
    for img in g.get("images", []):
        if "uri" in img:
            r.fail(f"external texture '{img['uri']}' - export as self-contained .glb"); continue
        bv = g["bufferViews"][img["bufferView"]]
        try:
            im = Image.open(BytesIO(binc[bv.get("byteOffset", 0): bv.get("byteOffset", 0) + bv["byteLength"]]))
            texs.append(f"{im.width}x{im.height}")
            if max(im.size) > MAX_TEX: r.warn(f"texture {im.width}x{im.height} > {MAX_TEX} (slow import, VRAM); downscale")
        except Exception as e:
            r.fail(f"unreadable embedded texture: {e}")
    r.info["textures"] = texs
    if g.get("materials") and not texs: r.warn("materials but no textures (flat colours only)")

    anims = [a.get("name", f"anim{i}") for i, a in enumerate(g.get("animations", []))]
    r.info.update(animations=anims, skins=len(g.get("skins", [])),
                  joints=sum(len(s["joints"]) for s in g.get("skins", [])))
    if role == "creature":
        if not g.get("skins"): r.warn("no skin/skeleton (only node animation possible)")
        if not any(IDLE_RE.search(a) for a in anims): r.fail(f"no idle clip (clips: {anims or 'none'})")
        if not any(MOVE_RE.search(a) for a in anims): r.fail(f"no walk/run clip (clips: {anims or 'none'})")
        if anims and not any(a in ("idle", "walk") for a in anims):
            r.warn("clip names differ from game defaults 'idle'/'walk' - set anim_idle/anim_move on Stalker, or rename")
    return r


# ------------------------------------------------------------------ audio
def db(x): return 20 * np.log10(max(float(x), 1e-9))


def check_audio(p: Path) -> Report:
    r = Report(p.name)
    try:
        info = sf.info(str(p)); x, sr = sf.read(str(p), always_2d=True, dtype="float32")
    except Exception as e:
        r.fail(f"cannot decode: {e}"); return r
    mono = x.mean(1)
    rms, peak = db(np.sqrt(np.mean(mono ** 2))), db(np.max(np.abs(x)))
    r.info.update(format=f"{info.format}/{info.subtype}", sr=sr, ch=x.shape[1], sec=round(len(x) / sr, 2),
                  rms_db=round(rms, 1), peak_db=round(peak, 1))
    if sr not in (44100, 48000): r.warn(f"sample rate {sr} (expected 44.1k/48k)")
    if peak > -0.3: r.warn(f"peak {peak:.1f} dBFS - clipping risk")
    if abs(rms - TARGET_RMS_DB) > RMS_TOL:
        r.warn(f"loudness {rms:.1f} dBFS RMS vs target {TARGET_RMS_DB}+-{RMS_TOL}; ingest will normalise")
    n = p.stem.lower()
    if is_loop(p):
        k = max(1, int(sr * 0.01))
        jump = float(np.max(np.abs(x[0] - x[-1])))
        edge = db(np.sqrt(np.mean(x[-k:] ** 2))) - db(np.sqrt(np.mean(x[:k] ** 2)))
        r.info.update(seam_jump=round(jump, 3), seam_edge_db=round(edge, 1))
        if jump > 0.1: r.warn(f"loop seam click: last->first sample jump {jump:.2f}; ingest will crossfade")
        elif abs(edge) > 6: r.warn(f"loop seam level mismatch {edge:.1f} dB between end and start")
        if db(np.sqrt(np.mean(x[:k] ** 2))) < -60 or db(np.sqrt(np.mean(x[-k:] ** 2))) < -60:
            r.warn("starts/ends in silence -> audible gap when looping (fade in/out baked in?)")
    if n.startswith("hum") or n.startswith("sfx3d"):
        if x.shape[1] > 1: r.warn("stereo file for a 3D source; will be downmixed to mono")
    return r


def is_loop(p: Path): return p.stem.lower().startswith(("bgm", "amb", "loop")) or p.stem.lower() == "ambience"


# ------------------------------------------------------------------ images
def check_image(p: Path) -> Report:
    r = Report(p.name)
    try:
        im = Image.open(p); im.load()
    except Exception as e:
        r.fail(f"cannot decode: {e}"); return r
    w, h = im.size
    a = np.asarray(im.convert("RGB"), float)
    neigh = (np.abs(np.diff(a, axis=1)).mean() + np.abs(np.diff(a, axis=0)).mean()) / 2
    lr, tb = np.abs(a[:, 0] - a[:, -1]).mean() / neigh, np.abs(a[0] - a[-1]).mean() / neigh
    lum = a.mean(2)
    # baked lighting: big brightness gradient across the image = not a flat albedo
    q = [lum[:h // 2, :w // 2].mean(), lum[:h // 2, w // 2:].mean(), lum[h // 2:, :w // 2].mean(), lum[h // 2:, w // 2:].mean()]
    r.info.update(size=f"{w}x{h}", mode=im.mode, seam_lr=round(lr, 2), seam_tb=round(tb, 2),
                  mean_lum=round(float(lum.mean()), 1), quadrant_spread=round(max(q) - min(q), 1))
    if w != h: r.warn("not square")
    if (w & (w - 1)) or (h & (h - 1)): r.warn(f"not power of two; ingest resizes to {TEX_SIZE}")
    if max(lr, tb) > 2.5: r.fail(f"not seamless (edge mismatch {max(lr, tb):.1f}x normal pixel variation) - visible seam when tiled")
    elif max(lr, tb) > 1.5: r.warn(f"edges slightly mismatched ({max(lr, tb):.1f}x) - may show a faint seam")
    if max(q) - min(q) > 25: r.warn("uneven brightness across image (baked lighting / vignette?) - tiling will show a pattern")
    return r


def ingest_image(p: Path):
    TEXTURES.mkdir(parents=True, exist_ok=True)
    out = TEXTURES / (p.stem + ".png")
    Image.open(p).convert("RGB").resize((TEX_SIZE, TEX_SIZE), Image.LANCZOS).save(out)
    return out


def make_loop(x, sr, xf_sec=LOOP_XFADE_SEC):
    """Trim silence + baked fade-out, then equal-power crossfade the tail into the head."""
    m = np.abs(x).max(1)
    nz = np.where(m > 10 ** (-60 / 20))[0]
    x = x[nz[0]: nz[-1] + 1]
    # fade detection: last 0.25 s block that is still within 6 dB of the median level
    k = int(sr * 0.25)
    blk = np.array([np.sqrt(np.mean(x[i:i + k] ** 2)) for i in range(0, len(x) - k, k)])
    ok = np.where(20 * np.log10(np.maximum(blk, 1e-9)) > 20 * np.log10(np.median(blk)) - 6)[0]
    x = x[: (ok[-1] + 1) * k]
    n = int(sr * xf_sec)
    t = np.linspace(0, np.pi / 2, n)[:, None]
    tail = x[-n:] * np.cos(t) + x[:n] * np.sin(t)  # ends as the head begins
    return np.concatenate([x[n:-n], tail])


# ------------------------------------------------------------------ ingest
def ingest_audio(p: Path):
    x, sr = sf.read(str(p), always_2d=True, dtype="float32")
    rms = np.sqrt(np.mean(x.mean(1) ** 2))
    gain = 10 ** ((TARGET_RMS_DB - db(rms)) / 20)
    if is_loop(p):
        before = len(x) / sr
        x = make_loop(x, sr)
        print(f"  loop fix: {before:.1f}s -> {len(x) / sr:.1f}s (trimmed silence/fade, {LOOP_XFADE_SEC}s crossfade)")
    x = x * min(gain, 0.98 / max(np.max(np.abs(x)), 1e-9))
    if p.stem.lower().startswith(("hum", "sfx3d")): x = x.mean(1, keepdims=True)
    out = AUDIO / (p.stem + ".ogg")
    # libsndfile's Vorbis encoder overflows the stack on long single writes: write 1 s chunks
    with sf.SoundFile(str(out), "w", sr, x.shape[1], format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(x), sr):
            f.write(x[i:i + sr])
    return out


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    t0 = time.perf_counter()
    files = [f for f in sorted(INBOX.iterdir()) if f.is_file() and not f.name.startswith(".")]
    reports = []
    for f in files:
        ext = f.suffix.lower()
        if ext == ".glb": rep = check_glb(f)
        elif ext in IMAGE_EXT: rep = check_image(f)
        elif ext in AUDIO_EXT: rep = check_audio(f)
        else:
            rep = Report(f.name); rep.fail(f"unsupported type {ext} (models: .glb only; audio: {sorted(AUDIO_EXT)})")
        rep.print(); reports.append((f, rep))
    t_check = time.perf_counter() - t0
    print(f"check: {len(files)} files, {sum(r.status == 'FAIL' for _, r in reports)} failed, {t_check:.1f}s")
    if cmd != "ingest": return
    done = []
    for f, rep in reports:
        if rep.status == "FAIL": continue
        if f.suffix.lower() == ".glb":
            role = role_of(f)
            dst = MODELS / (f"{role}.glb" if role != "other" else f.name)
            shutil.copy2(f, dst)
        elif f.suffix.lower() in IMAGE_EXT:
            dst = ingest_image(f)
        else:
            dst = ingest_audio(f)
        done.append(dst); print("  ->", dst.relative_to(ROOT))
        (INBOX / "_done").mkdir(exist_ok=True)
        shutil.move(str(f), str(INBOX / "_done" / f.name))
    t1 = time.perf_counter()
    res = subprocess.run([GODOT, "--headless", "--path", str(ROOT), "--import"], capture_output=True, text=True, errors="replace")
    errs = [l for l in (res.stdout + res.stderr).splitlines() if "ERROR" in l]
    print(f"godot import: {time.perf_counter() - t1:.1f}s, exit {res.returncode}", *errs[:10], sep="\n  ")
    if "--verify" in sys.argv:
        t2 = time.perf_counter()
        res = subprocess.run([GODOT, "--path", str(ROOT), "--", "--autotest", f"--shots={ROOT / 'shots'}"],
                             capture_output=True, text=True, errors="replace", timeout=120)
        for l in (res.stdout + res.stderr).splitlines():
            if any(k in l for k in ("[stalker]", "prop loaded", "AUTOTEST", "ERROR", "missing animation")): print("  game:", l[:400])
        print(f"game verify: {time.perf_counter() - t2:.1f}s")
    print(f"TOTAL inbox -> in game: {time.perf_counter() - t0:.1f}s")


if __name__ == "__main__":
    main()
