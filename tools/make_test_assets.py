"""Synthetic stand-ins for Tripo / Astra / Gemini outputs, to exercise tools/inbox.py.
Writes into inbox/: one good + one deliberately bad file of each kind."""
import json, struct
from io import BytesIO
from pathlib import Path
import numpy as np
import soundfile as sf
from PIL import Image

INBOX = Path(__file__).resolve().parent.parent / "inbox"


def box(sx, sy, sz, y0=0.0):
    v, idx, uv = [], [], []
    for axis in range(3):
        for sign in (-1, 1):
            base = len(v)
            a, b = [i for i in range(3) if i != axis]
            for u, w in ((0, 0), (1, 0), (1, 1), (0, 1)):
                p = [0.0, 0.0, 0.0]
                p[axis] = sign * 0.5
                p[a], p[b] = u - 0.5, w - 0.5
                v.append([p[0] * sx, p[1] * sy + sy / 2 + y0, p[2] * sz]); uv.append([u, w])
            q = [base, base + 1, base + 2, base, base + 2, base + 3]
            idx += q if sign > 0 else q[::-1]
    return np.array(v, np.float32), np.array(uv, np.float32), np.array(idx, np.uint16)


def write_glb(path, verts, uvs, idx, texture=True, anims=()):
    bin_ = bytearray(); views = []; accs = []

    def add(arr, target=None, **acc):
        while len(bin_) % 4: bin_.append(0)
        views.append({"buffer": 0, "byteOffset": len(bin_), "byteLength": arr.nbytes, **({"target": target} if target else {})})
        bin_.extend(arr.tobytes()); accs.append({"bufferView": len(views) - 1, **acc}); return len(accs) - 1

    pos = add(verts, 34962, componentType=5126, count=len(verts), type="VEC3",
              min=verts.min(0).tolist(), max=verts.max(0).tolist())
    uv = add(uvs, 34962, componentType=5126, count=len(uvs), type="VEC2")
    ind = add(idx, 34963, componentType=5123, count=len(idx), type="SCALAR")
    g = {"asset": {"version": "2.0", "generator": "jam-test synthetic"}, "scene": 0,
         "scenes": [{"nodes": [0]}], "nodes": [{"name": "Root", "children": [1]}, {"name": "Body", "mesh": 0}],
         "meshes": [{"primitives": [{"attributes": {"POSITION": pos, "TEXCOORD_0": uv}, "indices": ind, "material": 0}]}],
         "materials": [{"pbrMetallicRoughness": {"baseColorFactor": [0.8, 0.75, 0.7, 1], "metallicFactor": 0}}]}
    if texture:
        buf = BytesIO(); Image.fromarray((np.random.default_rng(0).random((256, 256, 3)) * 255).astype(np.uint8)).save(buf, "PNG")
        png = np.frombuffer(buf.getvalue(), np.uint8)
        while len(bin_) % 4: bin_.append(0)
        views.append({"buffer": 0, "byteOffset": len(bin_), "byteLength": png.nbytes}); bin_.extend(png.tobytes())
        g["images"] = [{"bufferView": len(views) - 1, "mimeType": "image/png"}]
        g["textures"] = [{"source": 0}]
        g["materials"][0]["pbrMetallicRoughness"]["baseColorTexture"] = {"index": 0}
    g["animations"] = []
    for name, amp, period in anims:  # simple bob animation on the Body node
        t = np.linspace(0, period, 9, dtype=np.float32)
        tr = np.stack([np.zeros_like(t), amp * np.abs(np.sin(t / period * 2 * np.pi)), np.zeros_like(t)], 1).astype(np.float32)
        ia = add(t, componentType=5126, count=len(t), type="SCALAR", min=[float(t.min())], max=[float(t.max())])
        oa = add(tr, componentType=5126, count=len(t), type="VEC3")
        g["animations"].append({"name": name, "samplers": [{"input": ia, "output": oa, "interpolation": "LINEAR"}],
                                "channels": [{"sampler": 0, "target": {"node": 1, "path": "translation"}}]})
    if not g["animations"]: del g["animations"]
    while len(bin_) % 4: bin_.append(0)
    g["buffers"] = [{"byteLength": len(bin_)}]; g["bufferViews"] = views; g["accessors"] = accs
    js = json.dumps(g).encode(); js += b" " * (-len(js) % 4)
    out = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(bin_))
    out += struct.pack("<I4s", len(js), b"JSON") + js + struct.pack("<I4s", len(bin_), b"BIN\x00") + bytes(bin_)
    Path(path).write_bytes(out)


v, uv, i = box(0.8, 0.8, 0.8); write_glb(INBOX / "prop_testcrate.glb", v, uv, i)
v, uv, i = box(0.6, 1.7, 0.4); write_glb(INBOX / "creature_test.glb", v, uv, i, anims=[("idle", 0.03, 2.0), ("walk", 0.12, 0.8)])
# bad: 80 m tall, lying-down-ish creature with wrong clip names and no texture
v, uv, i = box(80, 20, 30, y0=-10); write_glb(INBOX / "creature_bad.glb", v, uv, i, texture=False, anims=[("Take 001", 0.1, 1.0)])

sr = 44100; t = np.arange(sr * 4) / sr
sf.write(INBOX / "bgm_good.wav", (0.1 * np.sin(2 * np.pi * 110 * t)).astype(np.float32), sr)          # 440 whole cycles: seamless
sf.write(INBOX / "bgm_click.wav", (0.9 * np.sin(2 * np.pi * 111.3 * t + 0.3)).astype(np.float32), sr)  # non-integer cycles + loud
print("wrote", sorted(p.name for p in INBOX.iterdir() if not p.name.startswith(".")))
