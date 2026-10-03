"""Generate placeholder OGG audio (ambience drone + creature hum) into assets/audio."""
from pathlib import Path
import numpy as np
import soundfile as sf

SR = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(1)

def seamless(sig):
    # Every component below has an integer number of cycles over the file, so it loops cleanly.
    return (sig / np.max(np.abs(sig)) * 0.5).astype(np.float32)

t = np.arange(SR * 8) / SR  # 8 s
noise = np.fft.irfft(np.fft.rfft(rng.standard_normal(t.size)) * (np.arange(t.size // 2 + 1) < 8 * 200))  # low-passed, periodic
amb = 0.6 * np.sin(2 * np.pi * 55 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 8)) + 0.3 * np.sin(2 * np.pi * 82.5 * t) + noise / np.std(noise) * 0.15
sf.write(OUT / "ambience.ogg", seamless(amb), SR, format="OGG", subtype="VORBIS")

t = np.arange(SR * 2) / SR  # 2 s, mono for 3D
hum = np.sin(2 * np.pi * 110 * t) + 0.5 * np.sin(2 * np.pi * 220 * t) * np.sin(2 * np.pi * 3 * t) ** 2
sf.write(OUT / "hum.ogg", seamless(hum), SR, format="OGG", subtype="VORBIS")
print("wrote", list(OUT.glob("*.ogg")))
