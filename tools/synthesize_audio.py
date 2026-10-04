"""Build Farshore's original field-like sound palette, without external samples.

All WAV files below are deterministic procedural synthesis made for this game.
22.05 kHz PCM keeps the offline/mobile memory budget small. Loops overlap across
sample boundaries; one-shots start and end at zero. Run from any directory.
"""
from array import array
from pathlib import Path
import math
import random
import sys
import wave

DESTINATION = Path(__file__).resolve().parent.parent / "game/assets/audio"
RATE = 22050
TAU = math.tau


def filtered_noise(count, seed, smoothing):
    rng = random.Random(seed)
    result = array("f")
    value = 0.0
    for _ in range(count):
        value += (rng.uniform(-1.0, 1.0) - value) * smoothing
        result.append(value)
    return result


def write(name, channels, loop=False, peak=0.60):
    length = len(channels[0])
    if loop:
        overlap = RATE // 3
        length -= overlap
        for channel in channels:
            for i in range(overlap):
                amount = i / overlap
                channel[i] = channel[length + i] * (1.0 - amount) + channel[i] * amount
    else:
        fade = min(RATE // 80, length // 4)
        for channel in channels:
            for i in range(fade):
                channel[i] *= i / fade
                channel[length - i - 1] *= i / fade
    maximum = max(abs(v) for channel in channels for v in channel[:length])
    gain = peak / max(0.001, maximum)
    pcm = array("h")
    for i in range(length):
        for channel in channels:
            pcm.append(round(max(-1.0, min(1.0, channel[i] * gain)) * 32767))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(DESTINATION / (name + ".wav")), "wb") as output:
        output.setparams((len(channels), 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(pcm.tobytes())


def droplets(channel, count, seed, amplitude=0.05, max_duration=0.07):
    """Tiny resonant cavities, with falling frequency and irregular spacing."""
    rng = random.Random(seed)
    for _ in range(count):
        start = rng.randrange(max(1, len(channel) - RATE // 4))
        duration = rng.uniform(0.012, max_duration)
        frequency = rng.uniform(620.0, 1900.0)
        strength = amplitude * rng.uniform(0.25, 1.0)
        phase = 0.0
        for j in range(min(round(duration * RATE), len(channel) - start)):
            t = j / RATE
            phase += TAU * frequency * (1.0 - 0.4 * t / duration) / RATE
            envelope = math.sin(math.pi * t / duration) * math.exp(-t / duration * 4.0)
            channel[start + j] += math.sin(phase) * envelope * strength


def ambience(name, duration, seed, smoothing, character):
    count = round(duration * RATE) + RATE // 3
    channels = []
    for side in range(2):
        data = filtered_noise(count, seed + side * 831, smoothing)
        body = filtered_noise(count, seed + 20 + side * 73, 0.035)
        for i in range(count):
            t = i / RATE
            if character == "water":
                swell = (0.5 + 0.5 * math.sin(TAU * t / 3.9 + side * 0.34)) ** 2
                other = (0.5 + 0.5 * math.sin(TAU * t / 6.1 + 1.4)) ** 3
                data[i] = data[i] * (0.17 + swell * 0.63 + other * 0.22) + body[i] * 0.65
            elif character == "current":
                swell = 0.70 + 0.11 * math.sin(TAU * t / 2.3) + 0.08 * math.sin(TAU * t / 0.79)
                data[i] = data[i] * swell + body[i] * 0.25
            elif character == "wind":
                gust = (0.5 + 0.5 * math.sin(TAU * t / 8.7 + side * 0.12)) ** 2
                data[i] *= 0.19 + 0.72 * gust
            else:
                data[i] = (data[i] - body[i]) * (0.80 + 0.09 * math.sin(TAU * t / 5.3))
        if character == "water":
            droplets(data, round(duration * 9), seed + side, 0.11, 0.11)
        elif character == "rain":
            droplets(data, round(duration * 12), seed + side, 0.20, 0.04)
        channels.append(data)
    write(name, channels, loop=True, peak=0.53)


def swoosh(name, duration, seed, envelope_speed, texture=0.30):
    count = round(duration * RATE)
    data = filtered_noise(count, seed, texture)
    for i in range(count):
        t = i / count
        envelope = math.sin(math.pi * t) ** envelope_speed
        data[i] *= envelope * (1.0 - 0.35 * t)
    write(name, [data], peak=0.59)


def splash(name, duration, seed, strength):
    count = round(duration * RATE)
    data = filtered_noise(count, seed, 0.45)
    body = filtered_noise(count, seed + 1, 0.055)
    for i in range(count):
        t = i / RATE
        attack = min(1.0, t / 0.016)
        decay = math.exp(-t * 7.0 / duration)
        data[i] = (data[i] * 0.55 + body[i] * 1.4) * attack * decay
    droplets(data, 28, seed + 2, strength, 0.13)
    for i in range(count):
        data[i] *= math.exp(-i / count * 1.7)
    write(name, [data], peak=0.62)


def mechanism(name, seed, pulses, friction):
    count = RATE * 2 + RATE // 3
    data = filtered_noise(count, seed, 0.48)
    phase = 0.0
    for i in range(count):
        t = i / RATE
        # Integer-period pulses form a quiet ratchet, with a softer irregular
        # friction bed; no pure sustained sine is used for the reel.
        phase = (t * pulses) % 1.0
        tick = math.exp(-phase * 45.0)
        data[i] *= friction + tick * 0.75
    write(name, [data], loop=True, peak=0.53)


def main():
    DESTINATION.mkdir(exist_ok=True, parents=True)
    ambience("water", 16, 101, 0.14, "water")
    ambience("current", 12, 201, 0.21, "current")
    ambience("wind", 16, 301, 0.032, "wind")
    ambience("rain", 12, 401, 0.57, "rain")
    mechanism("reel", 501, 24.0, 0.032)
    mechanism("drag", 601, 45.0, 0.14)
    swoosh("cast", 0.48, 701, 2.1, 0.25)
    swoosh("hook", 0.17, 801, 1.2, 0.30)
    swoosh("escape", 0.24, 901, 0.5, 0.09)
    splash("splash", 0.74, 1001, 0.30)
    splash("catch", 1.10, 1101, 0.36)
    splash("release", 0.90, 1201, 0.25)
    print("Built 12 original water, weather and tackle sounds.")


if __name__ == "__main__":
    main()
