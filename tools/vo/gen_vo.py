"""Voice-over for the monologue: Microsoft neural TTS (edge-tts) + a light "inside a tin robot" filter.

    python tools/vo/gen_vo.py OUT_DIR [--ids 0-1,0-3] [--robot mild|silly|both]

Lines come from LINES below (id -> English text, same ids as docs/narrative_monologue_script.md).
Writes vo_s<stop>_<nn>.ogg per line (see file_name; _<robot> suffix with --robot both).
Needs: pip install edge-tts soundfile numpy
"""
import argparse
import asyncio
import io
import os
import re

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
    # ---- stop 4: the kitchen (father)
    "4-1": ("Who left the stove on?", "-18%", "-8Hz"),
    "4-2": ("...Ah. Me again. Forty-odd... in Marg's apron.", "-24%", "-12Hz"),
    "4-3": ("Pancakes every Sunday. Burnt, every Sunday. ...She never said a word.", "-28%", "-16Hz"),  # fond
    "4-4": ("And the tap's running! Marg'd have my hide.", "-18%", "-8Hz"),
    "4-5": ("The windowsill. That'll take me round to the breaker.", "-22%", "-12Hz"),
    "4-6": ("Ooh-- water and me don't mix any more.", "-20%", "-10Hz"),
    "4-7": ("Sunday's shopping. Never did get put away.", "-22%", "-14Hz"),
    "4-8": ("Ha! Never thought I'd thank a microwave.", "-16%", "-6Hz"),
    "4-9": ("Hope I don't come out burnt...", "-20%", "-8Hz"),
    "4-10": ("Like toast!", "-10%", "-2Hz"),
    "4-11": ("Got a magnet in me, have I? ...Handy.", "-20%", "-8Hz"),
    "4-12": ("That stove's always had a temper.", "-22%", "-12Hz"),
    "4-13": ("Kettle's on. Best idea I've had all night.", "-20%", "-10Hz"),
    "4-14": ("Up we go--!", "-8%", "+0Hz"),
    "4-15": ("...That'll be the dishes.", "-26%", "-14Hz"),       # wince
    "4-16": ("Well. That's one way to do the washing up.", "-22%", "-12Hz"),
    "4-17": ("Lucy's mug. She painted it when she was five.", "-28%", "-14Hz"),
    "4-18": ("Still rings the same. ...She doesn't ring as often.", "-32%", "-18Hz"),  # heavy
    # ---- stop 5: the clothesline (old age)
    "5-1": ("A coat hanger... and the line runs right across the room.", "-22%", "-10Hz"),
    "5-2": ("Maybe... I could ride these over to the breaker.", "-26%", "-12Hz"),          # thinking aloud
    "5-3": ("Marg's clothesline. Strung it through the house when her knees went.", "-30%", "-16Hz"),  # tender
    "5-4": ("Who's ready to fly on the zipline? I AM!", "-2%", "+8Hz"),                     # giddy
    "5-5": ("Lean, you old goat. LEAN!", "-10%", "-2Hz"),
    "5-6": ("Hop the pegs. HUP!", "-8%", "+0Hz"),
    "5-7": ("Oh-- sorry, love.", "-22%", "-10Hz"),
    "5-8": ("Never did like that lamp.", "-18%", "-10Hz"),
    "5-9": ("Every bit of this place... I could walk it with my eyes shut.", "-32%", "-16Hz"),
    "5-10": ("That chair's got my shape in it.", "-30%", "-16Hz"),
    "5-11": ("Whole town's going dark...", "-28%", "-16Hz"),
    "5-12": ("Lived here all my life. Never once saw it from up here.", "-32%", "-16Hz"),
    "5-13": ("...Not much left in me now.", "-34%", "-20Hz"),                               # fading
    "5-14": ("There's the breaker.", "-24%", "-14Hz"),
    "5-15": ("Nearly there.", "-28%", "-16Hz"),
    "5-16": ("Losing isn't fun. That's why I don't do it.", "-16%", "-4Hz"),               # stubborn grin
    # ---- stop 6: the breaker box (the end)
    "6-1": ("Righto. One last job.", "-26%", "-14Hz"),
    "6-2": ("Come on, old girl...", "-30%", "-16Hz"),
    "6-3": ("Take it. ...Take the lot.", "-34%", "-18Hz"),
    "6-4": ("I won't be needing it.", "-38%", "-20Hz"),                   # almost gone
    "6-5": ("...There.", "-40%", "-20Hz"),
    "6-6": ("There they all are.", "-34%", "-14Hz"),                      # warm
    "6-7": ("Sleep tight, old fella.", "-36%", "-16Hz"),
    "6-8": ("Lucy'll see the light from the road. ...She'll know I'm home.", "-34%", "-16Hz"),
}

## How robotic: "mild" = an old man in a tin can; "silly" = cartoon robot buzz on top.
ROBOT = {
    "mild":  {"ring": 0.18, "ring_hz": 32.0, "crush": 0.0},
    "silly": {"ring": 0.45, "ring_hz": 48.0, "crush": 0.35},
}


def file_name(line_id: str) -> str:
    """Script id -> asset name, matching the repo's <type>_<desc> lowercase/underscore convention:
    "0-1" -> vo_s0_01.ogg, "1-2b" -> vo_s1_02b.ogg."""
    stop, rest = line_id.split("-")
    num, suffix = re.match(r"(\d+)(\w*)", rest).groups()
    return f"vo_s{stop}_{int(num):02d}{suffix}.ogg"


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
            name = file_name(i) if len(kinds) == 1 else file_name(i).replace(".ogg", f"_{k}.ogg")
            sf.write(os.path.join(a.out, name), finish(y, sr), sr, format="OGG", subtype="VORBIS")
        print("ok", i, f"{len(x) / sr:.1f}s")


if __name__ == "__main__":
    asyncio.run(main())
