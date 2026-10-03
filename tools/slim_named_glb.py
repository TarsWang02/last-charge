"""Slim a heavy Tripo model without Blender.

  python tools/slim_glb.py IN.glb OUT.glb [--tris 25000] [--tex 2048]

1. gltfpack (npm i gltfpack) decimates the mesh to ~--tris triangles, keeping UVs.
2. Embedded textures are downscaled to --tex (base colour) / --tex/2 (normal, roughness).
"""
import argparse, json, shutil, struct, subprocess, sys, tempfile
from io import BytesIO
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from inbox import read_glb, check_glb  # noqa: E402


def gltfpack_exe():
    exe = shutil.which("gltfpack")
    if exe: return exe
    tmp = Path(tempfile.gettempdir()) / "gp" / "node_modules" / ".bin" / "gltfpack.cmd"
    if tmp.exists(): return str(tmp)
    sys.exit("gltfpack not found: run  npm i -g gltfpack")


def write_glb(g, binc, out):
    js = json.dumps(g, separators=(",", ":")).encode(); js += b" " * (-len(js) % 4)
    binc += b"\0" * (-len(binc) % 4)
    Path(out).write_bytes(struct.pack("<4sII", b"glTF", 2, 28 + len(js) + len(binc))
                          + struct.pack("<I4s", len(js), b"JSON") + js
                          + struct.pack("<I4s", len(binc), b"BIN\x00") + binc)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("dst")
    ap.add_argument("--tris", type=int, default=25000); ap.add_argument("--tex", type=int, default=2048)
    a = ap.parse_args()
    g, _ = read_glb(Path(a.src))
    tris = check_glb(Path(a.src)).info["tris"]
    ratio = min(1.0, a.tris / max(tris, 1))
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td) / "lo.glb"
        subprocess.run([gltfpack_exe(), "-kn", "-i", a.src, "-o", str(tmp), "-si", f"{ratio:.5f}", "-noq"], check=True)
        g, binc = read_glb(tmp)
    # role of each image from material slots
    role = {}
    for m in g.get("materials", []):
        if "normalTexture" in m: role[g["textures"][m["normalTexture"]["index"]]["source"]] = "small"
        mr = m.get("pbrMetallicRoughness", {})
        if "metallicRoughnessTexture" in mr: role[g["textures"][mr["metallicRoughnessTexture"]["index"]]["source"]] = "small"
    blobs = []  # rebuild buffer: geometry views as-is, images re-encoded
    new = bytearray()
    for i, bv in enumerate(g["bufferViews"]):
        data = binc[bv.get("byteOffset", 0): bv.get("byteOffset", 0) + bv["byteLength"]]
        img_idx = next((k for k, im in enumerate(g.get("images", [])) if im.get("bufferView") == i), None)
        if img_idx is not None:
            im = Image.open(BytesIO(data)); limit = a.tex // 2 if role.get(img_idx) == "small" else a.tex
            if max(im.size) > limit: im = im.resize((limit, limit * im.height // im.width), Image.LANCZOS)
            buf = BytesIO()
            if g["images"][img_idx].get("mimeType") == "image/png": im.save(buf, "PNG", optimize=True)
            else: im.convert("RGB").save(buf, "JPEG", quality=90)
            data = buf.getvalue()
        while len(new) % 4: new.append(0)
        bv["byteOffset"] = len(new); bv["byteLength"] = len(data); bv["buffer"] = 0
        new.extend(data)
    g["buffers"] = [{"byteLength": len(new)}]
    write_glb(g, bytes(new), a.dst)
    r = check_glb(Path(a.dst)); r.print()
    print(f"{Path(a.src).stat().st_size / 1e6:.1f} MB -> {Path(a.dst).stat().st_size / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
