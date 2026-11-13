"""Synthesize the client's alert sounds (original, public-domain tones).

    python3 scripts/gen_sounds.py src/assets/sounds

Deterministic: the same script always writes byte-identical WAV files.
"""

import math
import struct
import sys
import wave
from pathlib import Path

RATE = 22050


def tone(freqs, seconds, volume=0.5, attack=0.01, release=0.12, harmonics=(1.0, 0.35, 0.15)):
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) if attack else 1.0
        env *= min(1.0, (seconds - t) / release) if release else 1.0
        env *= math.exp(-2.5 * t / seconds)  # bell-like decay
        s = 0.0
        for f in freqs:
            for k, amp in enumerate(harmonics, start=1):
                s += amp * math.sin(2 * math.pi * f * k * t)
        out.append(volume * env * s / (len(freqs) * sum(harmonics)))
    return out


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def write(path, samples):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


def main(out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    # Tell / chat: a soft rising two-note chime.
    write(out / "duris-tell.wav", tone([880], 0.16, 0.45) + tone([1318.5], 0.32, 0.45))
    # Low health: three urgent low pulses.
    pulse = tone([220, 233], 0.14, 0.6, release=0.05, harmonics=(1.0, 0.6, 0.4))
    write(out / "duris-lowhp.wav", pulse + silence(0.06) + pulse + silence(0.06) + pulse)
    # Low movement: one falling two-note cue, gentler than low health.
    write(out / "duris-lowmove.wav", tone([587.3], 0.16, 0.4) + tone([440], 0.3, 0.4))
    # Alert banners (scrying, disarm, sanctuary down): a single bright strike.
    write(out / "duris-alert.wav", tone([1046.5, 1568], 0.45, 0.45))


if __name__ == "__main__":
    main(sys.argv[1])
