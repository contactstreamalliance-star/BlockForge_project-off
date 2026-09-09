from __future__ import annotations

import math
import random
import wave
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
TEXTURES = ROOT / "assets" / "textures" / "blocks"
AUDIO = ROOT / "assets" / "audio"
UI = ROOT / "assets" / "ui"


def pixel_texture(name: str, base: tuple[int, int, int], accents: list[tuple[int, int, int]]) -> None:
    rng = random.Random(name)
    img = Image.new("RGBA", (16, 16), base + (255,))
    px = img.load()
    for y in range(16):
        for x in range(16):
            shift = rng.randint(-6, 6)
            color = tuple(max(0, min(255, c + shift)) for c in base)
            px[x, y] = color + (255,)
    draw = ImageDraw.Draw(img)
    for color in accents:
        for _ in range(4):
            x = rng.randrange(16)
            y = rng.randrange(16)
            w = rng.randrange(1, 5)
            h = rng.randrange(1, 2)
            draw.rectangle((x, y, min(15, x + w), min(15, y + h)), fill=color + (255,))
    img.save(TEXTURES / f"{name}.png")


def grass_side() -> None:
    pixel_texture("grass_side", (112, 83, 55), [(92, 68, 47), (134, 100, 66)])
    img = Image.open(TEXTURES / "grass_side.png").convert("RGBA")
    draw = ImageDraw.Draw(img)
    draw.rectangle((0, 0, 15, 2), fill=(76, 136, 58, 255))
    draw.rectangle((0, 2, 15, 3), fill=(62, 111, 49, 255))
    for x in range(0, 16, 5):
        draw.rectangle((x, 3, min(15, x + 1), 4), fill=(89, 151, 66, 255))
    img.save(TEXTURES / "grass_side.png")


def log_top() -> None:
    img = Image.new("RGBA", (16, 16), (129, 86, 45, 255))
    draw = ImageDraw.Draw(img)
    for box, color in [
        ((1, 1, 14, 14), (178, 125, 67, 255)),
        ((3, 3, 12, 12), (210, 153, 86, 255)),
        ((5, 5, 10, 10), (158, 104, 55, 255)),
        ((7, 7, 8, 8), (92, 58, 31, 255)),
    ]:
        draw.rectangle(box, outline=color, width=1)
    img.save(TEXTURES / "log_top.png")


def glass() -> None:
    img = Image.new("RGBA", (16, 16), (116, 205, 220, 120))
    draw = ImageDraw.Draw(img)
    draw.rectangle((0, 0, 15, 15), outline=(220, 255, 255, 210))
    draw.line((3, 2, 3, 9), fill=(235, 255, 255, 190))
    draw.line((5, 2, 5, 5), fill=(235, 255, 255, 160))
    draw.line((10, 11, 13, 11), fill=(70, 145, 150, 180))
    img.save(TEXTURES / "glass.png")


def planks() -> None:
    img = Image.new("RGBA", (16, 16), (177, 124, 68, 255))
    draw = ImageDraw.Draw(img)
    for y in [3, 8, 13]:
        draw.line((0, y, 15, y), fill=(103, 66, 35, 255))
    for x, y0, y1 in [(5, 0, 3), (11, 4, 8), (3, 9, 13), (13, 14, 15)]:
        draw.line((x, y0, x, y1), fill=(119, 76, 40, 255))
    draw.line((1, 1, 4, 1), fill=(210, 154, 88, 255))
    draw.line((7, 5, 10, 5), fill=(145, 92, 49, 255))
    draw.line((10, 10, 14, 10), fill=(212, 157, 91, 255))
    img.save(TEXTURES / "planks.png")


def cobble() -> None:
    img = Image.new("RGBA", (16, 16), (113, 117, 112, 255))
    draw = ImageDraw.Draw(img)
    stones = [
        ((0, 0, 4, 4), (137, 140, 134)),
        ((5, 0, 9, 3), (96, 101, 97)),
        ((10, 0, 15, 5), (150, 152, 145)),
        ((0, 5, 3, 9), (98, 102, 98)),
        ((4, 4, 9, 9), (131, 135, 128)),
        ((10, 6, 15, 10), (91, 96, 92)),
        ((0, 10, 5, 15), (151, 153, 146)),
        ((6, 10, 10, 15), (105, 109, 104)),
        ((11, 11, 15, 15), (126, 130, 124)),
    ]
    for rect, color in stones:
        draw.rectangle(rect, fill=color + (255,), outline=(68, 72, 68, 255))
    img.save(TEXTURES / "cobble.png")


def ore_texture(name: str, base: tuple[int, int, int], fleck: tuple[int, int, int]) -> None:
    pixel_texture(name, base, [(max(0, base[0] - 20), max(0, base[1] - 20), max(0, base[2] - 20)), fleck])
    img = Image.open(TEXTURES / f"{name}.png").convert("RGBA")
    draw = ImageDraw.Draw(img)
    rng = random.Random(name + "_ore")
    for _ in range(8):
        x = rng.randrange(1, 14)
        y = rng.randrange(1, 14)
        draw.rectangle((x, y, min(15, x + 1), min(15, y + 1)), fill=fleck + (255,))
    img.save(TEXTURES / f"{name}.png")


def workbench() -> None:
    top = Image.new("RGBA", (16, 16), (153, 98, 48, 255))
    draw = ImageDraw.Draw(top)
    draw.rectangle((0, 0, 15, 15), outline=(71, 42, 23, 255))
    draw.line((0, 5, 15, 5), fill=(90, 54, 28, 255))
    draw.line((5, 0, 5, 15), fill=(90, 54, 28, 255))
    draw.rectangle((8, 8, 13, 13), outline=(219, 166, 91, 255))
    top.save(TEXTURES / "workbench_top.png")

    side = Image.new("RGBA", (16, 16), (133, 82, 41, 255))
    draw = ImageDraw.Draw(side)
    draw.rectangle((0, 0, 15, 15), outline=(67, 42, 24, 255))
    draw.rectangle((2, 3, 13, 13), outline=(91, 55, 30, 255))
    draw.line((2, 8, 13, 8), fill=(91, 55, 30, 255))
    draw.line((7, 3, 7, 13), fill=(91, 55, 30, 255))
    side.save(TEXTURES / "workbench_side.png")


def water() -> None:
    img = Image.new("RGBA", (16, 16), (48, 116, 178, 210))
    draw = ImageDraw.Draw(img)
    for y in [3, 8, 13]:
        draw.line((0, y, 15, y), fill=(93, 170, 218, 230))
    draw.line((1, 5, 5, 5), fill=(29, 86, 140, 220))
    draw.line((8, 11, 13, 11), fill=(104, 184, 232, 230))
    img.save(TEXTURES / "water.png")


def make_icon() -> None:
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(64, 8), (112, 34), (64, 60), (16, 34)], fill=(95, 166, 63, 255))
    draw.polygon([(16, 34), (64, 60), (64, 118), (16, 91)], fill=(121, 82, 48, 255))
    draw.polygon([(112, 34), (64, 60), (64, 118), (112, 91)], fill=(91, 67, 50, 255))
    draw.line([(64, 8), (112, 34), (112, 91), (64, 118), (16, 91), (16, 34), (64, 8)], fill=(31, 37, 29, 255), width=4)
    img.save(UI / "icon.png")


def write_wav(name: str, notes: list[tuple[float, float]], volume: float = 0.25, sample_rate: int = 22050) -> None:
    frames: list[int] = []
    for freq, duration in notes:
        count = int(duration * sample_rate)
        for i in range(count):
            if freq <= 0:
                sample = 0
            else:
                t = i / sample_rate
                square = 1 if math.sin(2 * math.pi * freq * t) >= 0 else -1
                envelope = min(1, i / max(1, count * 0.08)) * max(0, 1 - i / count)
                sample = int(square * envelope * volume * 32767)
            frames.append(sample)
    with wave.open(str(AUDIO / f"{name}.wav"), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(b"".join(int(s).to_bytes(2, "little", signed=True) for s in frames))


def main() -> None:
    TEXTURES.mkdir(parents=True, exist_ok=True)
    AUDIO.mkdir(parents=True, exist_ok=True)
    UI.mkdir(parents=True, exist_ok=True)

    pixel_texture("grass_top", (74, 139, 58), [(96, 163, 72), (55, 104, 45), (82, 151, 64)])
    grass_side()
    pixel_texture("dirt", (118, 80, 49), [(92, 60, 39), (145, 102, 63), (130, 89, 55)])
    pixel_texture("stone", (122, 124, 119), [(99, 102, 97), (145, 147, 140), (112, 115, 110)])
    pixel_texture("granite", (139, 101, 91), [(101, 72, 66), (171, 126, 113), (118, 82, 76)])
    pixel_texture("clay", (105, 126, 132), [(78, 99, 105), (134, 154, 158), (93, 115, 121)])
    ore_texture("coal_ore", (112, 116, 113), (37, 36, 34))
    ore_texture("iron_ore", (119, 116, 108), (197, 125, 70))
    pixel_texture("sand", (205, 187, 119), [(225, 208, 140), (179, 163, 99), (216, 198, 128)])
    pixel_texture("log_side", (124, 82, 42), [(88, 56, 30), (166, 110, 58), (143, 94, 48)])
    log_top()
    pixel_texture("leaves", (48, 111, 52), [(68, 139, 64), (36, 82, 39), (83, 151, 73)])
    planks()
    cobble()
    glass()
    water()
    pixel_texture("marble", (207, 210, 215), [(172, 177, 187), (236, 238, 242), (145, 151, 166)])
    workbench()
    make_icon()

    write_wav("break", [(130, 0.035), (86, 0.045), (55, 0.035)], 0.32)
    write_wav("place", [(82, 0.035), (118, 0.05)], 0.26)
    write_wav("jump", [(220, 0.035), (300, 0.055)], 0.2)
    write_wav("menu", [(440, 0.04), (660, 0.06)], 0.18)
    write_wav("step", [(64, 0.035)], 0.13)
    melody = [(330, 0.08), (392, 0.08), (494, 0.08), (392, 0.08)]
    write_wav("music", melody, 0.08, sample_rate=8000)


if __name__ == "__main__":
    main()
