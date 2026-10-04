"""Voice-over for the monologue: Microsoft neural TTS (edge-tts) + a light "inside a tin robot" filter.

    python tools/vo/gen_vo.py OUT_DIR [--ids 0-1,0-3] [--robot mild|silly|both]

Lines come from LINES below (id -> English text, same ids as docs/narrative_monologue_script.md).
Writes vo_<id>.ogg (or vo_<id>_<robot>.ogg with --robot both, for comparing).
Needs: pip install edge-tts soundfile numpy
"""
import argparse
import asyncio
import io
import os

import edge_tts
import numpy as np
import soundfile as sf

VOICE = "en-AU-WilliamMultilingualNeural"   # the only Australian male neural voice
RATE = "-22%"                               # slow: an old man thinking out loud
PITCH = "-14Hz"                             # lower / older

## id -> (spoken text, rate, pitch). Spoken text may differ from the subtitle: fillers and punctuation
## are how we steer the delivery (edge-tts has no emotion styles for this voice).
LINES = {
    # ---- prologue: the nightstand (now)
    "0-1": ("Hmm...? ...Where... am I?", "-28%", "-10Hz"),                          # groggy
    "0-2": ("Hang on. That's... my bed.", "-22%", "-12Hz"),
    "0-3": ("And that's... ME?!", "-18%", "-4Hz"),                                  # shock
    "0-4": ("Then... who's THIS?", "-20%", "-6Hz"),
    "0-5": ("Who's that at my desk? ...At this hour?", "-20%", "-12Hz"),            # grumpy
    "0-6": ("Christmas, fifty-three. Mum... Dad... and me, hanging on to that robot like it was gold.", "-26%", "-14Hz"),  # fond
    "0-7": ("...That robot. That's... THIS. I'm in my old tin robot!", "-20%", "-6Hz"),
    "0-8": ("Whoa-- struth!", "-5%", "+2Hz"),                                        # falling
    # ---- stop 1: the toy box (childhood)
    "1-1": ("My old toy box! Mum swore she'd chucked this out.", "-20%", "-10Hz"),
    "1-2": ("Don't like the dark down there. Never did.", "-26%", "-16Hz"),
    "1-2b": ("All aboard! ...Dad built that track.", "-20%", "-10Hz"),
    "1-3": ("Agh! Still scares the daylights out of me. Seventy years on.", "-16%", "-6Hz"),
    "1-4": ("Big Tom. Wouldn't sleep without him till I was nine.", "-26%", "-14Hz"),
    "1-5": ("Costs me a bit. Everything does, these days.", "-28%", "-18Hz"),        # weary
    "1-6": ("Here we go again--!", "-8%", "+0Hz"),
    # ---- stop 2: the desk (teenager)
    "2-1": ("Hang on... isn't that... me?", "-22%", "-8Hz"),
    "2-2": ("Why am I so young? Can't be more than fifteen!", "-18%", "-6Hz"),
    "2-3": ("Struth. Black as pitch. Can't see a blessed thing.", "-22%", "-14Hz"),
    "2-4": ("Every bit of light costs me now.", "-28%", "-18Hz"),
    "2-5": ("My desk was always a maze. Mum reckoned I'd lose my own head in it.", "-22%", "-12Hz"),
    "2-6": ("Door's right down the far end. ...Course it is.", "-22%", "-14Hz"),     # dry
    "2-7": ("Mind the cracks. Always did fall through them.", "-24%", "-14Hz"),
    "2-8": ("Mum always said that rubber'd come in handy.", "-22%", "-10Hz"),
    "2-9": ("There. Good as a bridge.", "-20%", "-10Hz"),
    "2-11": ("Back soon. ...She always was.", "-30%", "-16Hz"),
    "2-12": ("Till the one time... she wasn't.", "-32%", "-18Hz"),                  # heavy
    "2-13": ("The breaker. That's what's gone.", "-20%", "-12Hz"),
    "2-14": ("...Telly's still going, though.", "-22%", "-10Hz"),
    # ---- stop 3: the TV (young man)
    "3-1": ("Ha. There I am again.", "-22%", "-10Hz"),
    "3-2": ("Twenty-two. Hair down to my collar. Thought I was something.", "-22%", "-12Hz"),
    "3-3": ("Every game I ever owned. Never chucked one out.", "-22%", "-12Hz"),
    "3-4": ("Haven't played this since... well. ...Since.", "-30%", "-18Hz"),        # trails off
    "3-5": ("Oi-- what's-- it's pulling me IN--!", "-2%", "+4Hz"),                  # panic
    "3-6": ("Well, I'll be! I'm in the game!", "-14%", "-2Hz"),                       # delight
    "3-7": ("Can't hop this one. Give it a whack!", "-16%", "-8Hz"),
    "3-8": ("Twenty cents a go, back then. Now it's me paying.", "-24%", "-14Hz"),
    "3-9": ("Ha! They've got batteries in here too.", "-16%", "-6Hz"),
    "3-10": ("Let him have a go first. ...Then get him.", "-20%", "-12Hz"),
    "3-11": ("Never could beat this one. Not once.", "-24%", "-14Hz"),
    "3-12": ("Oh, now he's cranky!", "-14%", "-4Hz"),
    "3-13": ("Got there in the end. ...Only took me sixty years.", "-26%", "-14Hz"),
    "3-14": ("...And there goes the telly.", "-28%", "-16Hz"),
    "3-15": ("My old time box.", "-28%", "-14Hz"),
    "3-16": ("My drawing. Me and the robot... beating the dragon.", "-26%", "-12Hz"),
    "3-17": ("Thought I'd be a hero. Ended up a farmer. ...Not a bad trade.", "-26%", "-14Hz"),
}

## How robotic: "mild" = an old man in a tin can; "silly" = cartoon robot buzz on top.
ROBOT = {
    "mild":  {"ring": 0.18, "ring_hz": 32.0, "crush": 0.0},
    "silly": {"ring": 0.45, "ring_hz": 48.0, "crush": 0.35},
}


async def tts(text: str, rate: str = RATE, pitch: str = PITCH) -> tuple[np.ndarray, int]:
    buf = io.BytesIO()
    async for chunk in edge_tts.Communicate(text, VOICE, rate=rate, pitch=pitch).stream():
        if chunk["type"] == "audio":
            buf.write(chunk["data"])
    buf.seek(0)
    data, sr = sf.read(buf, dtype="float32")
    if data.ndim > 1:
        data = data.mean(axis=1)
    return data, sr


def old(x: np.ndarray, sr: int) -> np.ndarray:
    """An old man's wobble: slow uneven vibrato (pitch) + a little tremolo (loudness)."""
    t = np.arange(len(x)) / sr
    rng = np.random.default_rng(7)
    drift = np.interp(t, np.linspace(0, t[-1], 12), rng.normal(0, 1, 12))
    wob = 0.0035 * np.sin(2 * np.pi * 5.2 * t) + 0.0015 * drift      # +-0.5 % pitch
    pos = np.cumsum(1 + wob)
    pos *= (len(x) - 1) / pos[-1]
    y = np.interp(pos, np.arange(len(x)), x)
    return y * (1 + 0.08 * np.sin(2 * np.pi * 6.1 * t))


def robot(x: np.ndarray, sr: int, ring: float, ring_hz: float, crush: float) -> np.ndarray:
    """Cartoon-robot buzz: ring modulation + a bit of sample-and-hold / bit crush, mixed in."""
    t = np.arange(len(x)) / sr
    y = x * (1 - ring) + x * np.sin(2 * np.pi * ring_hz * t) * ring * 1.6
    if crush > 0:
        hold = 3
        c = np.repeat(y[::hold], hold)[:len(y)]
        c = np.round(c * 24) / 24
        y = y * (1 - crush) + c * crush
    return y


def tin(x: np.ndarray, sr: int) -> np.ndarray:
    """Small-speaker band + a few short reflections (a voice in a tin box). Kept light: words stay clear."""
    n = len(x)
    spec = np.fft.rfft(x, n * 2)
    f = np.fft.rfftfreq(n * 2, 1 / sr)
    band = 1 / np.sqrt(1 + (180 / np.maximum(f, 1)) ** 4) / np.sqrt(1 + (f / 5200) ** 4)
    band *= 1 + 0.6 * np.exp(-((f - 1800) / 500) ** 2)   # a tinny presence bump
    y = np.fft.irfft(spec * band)[:n]
    out = y.copy()
    for ms, g in ((2.3, 0.28), (3.7, -0.2), (5.9, 0.14)):  # tight comb = metallic ring
        d = int(sr * ms / 1000)
        out[d:] += g * y[:-d]
    out = np.tanh(out * 1.6) / np.tanh(1.6)                 # a little grit
    return out


def finish(x: np.ndarray, sr: int) -> np.ndarray:
    pad = np.zeros(int(sr * 0.08), dtype=np.float32)       # no clicks at the edges
    x = np.concatenate([pad, x, pad])
    rms = np.sqrt(np.mean(x ** 2)) or 1.0
    x = x * (10 ** (-20 / 20) / rms)                       # -20 dBFS RMS, same as tools/inbox.py
    peak = np.max(np.abs(x))
    if peak > 0.89:                                        # headroom: Vorbis overshoots a little
        x *= 0.89 / peak
    return x.astype(np.float32)


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--ids", default="")
    ap.add_argument("--robot", default="mild", help="mild | silly | both")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    ids = a.ids.split(",") if a.ids else list(LINES)
    kinds = list(ROBOT) if a.robot == "both" else [a.robot]
    for i in ids:
        text, rate, pitch = LINES[i]
        x, sr = await tts(text, rate, pitch)
        x = old(x, sr)
        for k in kinds:
            y = tin(robot(x, sr, **ROBOT[k]), sr)
            name = f"vo_{i}.ogg" if len(kinds) == 1 else f"vo_{i}_{k}.ogg"
            sf.write(os.path.join(a.out, name), finish(y, sr), sr, format="OGG", subtype="VORBIS")
        print("ok", i, f"{len(x) / sr:.1f}s")


if __name__ == "__main__":
    asyncio.run(main())
