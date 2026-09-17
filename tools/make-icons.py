#!/usr/bin/env python3
"""Draws the AMS Coffee app icon.

  python3 tools/make-icons.py            install the chosen icon
  python3 tools/make-icons.py --sheet    write a contact sheet of alternatives

The chosen one: flat clay background, one solid hand-drawn coffee bean, its
seam cut back out of the bean in the background colour. Nothing glows, nothing
gradients, and it stays readable at home-screen size.
"""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S, SS = 1024, 4                     # final size, and supersampling
W = S * SS

CLAY = (138, 90, 60)
INK = (255, 255, 255)

OUT = "App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"


# ---------------------------------------------------------------- geometry

def rot(pts, deg, cx=512, cy=512):
    a = math.radians(deg)
    return [((x - cx) * math.cos(a) - (y - cy) * math.sin(a) + cx,
             (x - cx) * math.sin(a) + (y - cy) * math.cos(a) + cy) for x, y in pts]


def wobbled(pts, amp, seed):
    """Nudge a path so it looks drawn by a hand, not by a compass.
    Steady at the ends, loose in the middle — that is how a pen behaves."""
    rng = random.Random(seed)
    out = []
    n = max(1, len(pts) - 1)
    for i, (x, y) in enumerate(pts):
        k = math.sin(i / n * math.pi)
        out.append((x * SS + rng.uniform(-amp, amp) * k * SS,
                    y * SS + rng.uniform(-amp, amp) * k * SS))
    return out


def bean_outline(rx, ry, tilt, cx=512, cy=512):
    pts = [(cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a)))
           for a in range(0, 361, 3)]
    return rot(pts, tilt, cx, cy)


def bean_seam(ry, tilt, cx=512, cy=512, amp=78):
    """The S down the middle of a coffee bean."""
    pts = [(cx + amp * math.sin(i / 80 * 2 * math.pi),
            cy - ry * 0.82 + i / 80 * ry * 1.64) for i in range(81)]
    return rot(pts, tilt, cx, cy)


def ink_line(d, pts, width, colour, amp=2.2, seed=3):
    p = wobbled(pts, amp, seed)
    d.line(p, fill=colour, width=int(width * SS), joint="curve")
    r = width * SS / 2
    for x, y in (p[0], p[-1]):
        d.ellipse([x - r, y - r, x + r, y + r], fill=colour)


# ---------------------------------------------------------------- glyphs

def filled_bean(img, bg=CLAY):
    """The chosen mark: a solid bean with its seam cut back out."""
    d = ImageDraw.Draw(img)
    d.polygon(wobbled(bean_outline(238, 310, -16), 2.0, 1), fill=INK)
    ink_line(d, bean_seam(310, -16), 54, bg, seed=5)


def cropped_bean(img, bg=CLAY):
    """Oversized, running off the tile."""
    d = ImageDraw.Draw(img)
    d.polygon(wobbled(bean_outline(400, 520, -24, 470, 512), 2.0, 2), fill=INK)
    ink_line(d, bean_seam(520, -24, 470, 512, amp=120), 74, bg, seed=5)


def outlined_bean(img, bg=CLAY):
    """Outline only — calmer, less distinctive."""
    d = ImageDraw.Draw(img)
    ink_line(d, bean_outline(232, 302, -14), 46, INK, seed=1)
    ink_line(d, bean_seam(302, -14), 42, INK, seed=2)


CHOSEN = filled_bean

ALTERNATIVES = [
    ("1", filled_bean, CLAY, "filled bean, seam cut through  (chosen)"),
    ("2", cropped_bean, CLAY, "oversized, cropped by the tile"),
    ("3", outlined_bean, CLAY, "outline only"),
]


# ---------------------------------------------------------------- output

def render(glyph, bg=CLAY):
    img = Image.new("RGB", (W, W), bg)
    glyph(img, bg)
    img = img.filter(ImageFilter.GaussianBlur(0.6 * SS / 4))
    return img.resize((S, S), Image.LANCZOS)


def rounded(img, frac=0.235):
    """Only for the preview sheet — the real icon must stay a full square."""
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1],
        radius=int(img.size[0] * frac), fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def write_sheet(path="/tmp/ams-coffee-icon-options.png"):
    big, small, gap, pad, lab = 300, 92, 40, 46, 66
    w = pad * 2 + len(ALTERNATIVES) * big + (len(ALTERNATIVES) - 1) * gap
    h = pad * 2 + big + lab + small + 26
    sheet = Image.new("RGB", (w, h), (247, 244, 239))
    d = ImageDraw.Draw(sheet)
    try:
        f1 = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", 30)
        f2 = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", 20)
    except OSError:
        f1 = f2 = ImageFont.load_default()

    for i, (letter, glyph, bg, note) in enumerate(ALTERNATIVES):
        x, y = pad + i * (big + gap), pad
        full = render(glyph, bg)
        tile = rounded(full.resize((big, big), Image.LANCZOS))
        sheet.paste(tile, (x, y), tile)
        d.text((x + big / 2, y + big + 12), letter, fill=(40, 30, 25), font=f1, anchor="ma")
        d.text((x + big / 2, y + big + 46), note, fill=(120, 110, 100), font=f2, anchor="ma")
        tiny = rounded(full.resize((small, small), Image.LANCZOS))
        sheet.paste(tiny, (int(x + big / 2 - small / 2), y + big + lab + 12), tiny)

    d.text((pad, h - 20), "bottom row = actual size on a home screen",
           fill=(150, 140, 130), font=f2, anchor="ls")
    sheet.save(path)
    print("wrote", path)


if __name__ == "__main__":
    if "--sheet" in sys.argv:
        write_sheet()
    else:
        render(CHOSEN).save(OUT)
        print("wrote", OUT)
