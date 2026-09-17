#!/usr/bin/env python3
"""Draws AMS Coffee icon candidates: flat calm background, hand-drawn glyph.
Nothing glows, nothing gradients.   python3 tools/make-icons.py
"""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S, SS = 1024, 4
W = S * SS


class Pen:
    def __init__(self, img, ink, seed=7):
        self.d = ImageDraw.Draw(img)
        self.ink = ink
        self.rng = random.Random(seed)

    def wobble(self, points, amp):
        out = []
        n = max(1, len(points) - 1)
        for i, (x, y) in enumerate(points):
            k = math.sin(i / n * math.pi)          # steady at the ends
            out.append((x * SS + self.rng.uniform(-amp, amp) * k * SS,
                        y * SS + self.rng.uniform(-amp, amp) * k * SS))
        return out

    def stroke(self, points, width, amp=3.5):
        pts = self.wobble(points, amp)
        self.d.line(pts, fill=self.ink, width=int(width * SS), joint="curve")
        r = width * SS / 2
        for x, y in (pts[0], pts[-1]):
            self.d.ellipse([x - r, y - r, x + r, y + r], fill=self.ink)

    def arc(self, cx, cy, rx, ry, a0, a1, width, n=48, amp=3.0):
        pts = [(cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a)))
               for a in [a0 + (a1 - a0) * i / n for i in range(n + 1)]]
        self.stroke(pts, width, amp)

    def line_between(self, a, b, width, amp=3.0, n=16):
        pts = [(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n)
               for i in range(n + 1)]
        self.stroke(pts, width, amp)


# ---------------------------------------------------------------- glyphs

def cup_side(p):
    """The original: cup, saucer, two curls of steam."""
    top, bot = 430, 700
    lt, rt, lb, rb = 296, 620, 352, 564
    body = ([(lt + (lb - lt) * i / 20, top + (bot - top) * i / 20) for i in range(21)]
            + [((lb + rb) / 2 + (rb - lb) / 2 * math.cos(math.radians(180 - 180 * i / 24)),
                bot - 6 + 46 * math.sin(math.radians(180 - 180 * i / 24))) for i in range(1, 25)]
            + [(rt - (rt - rb) * (1 - i / 20), top + (bot - top) * (1 - i / 20))
               for i in range(20, -1, -1)])
    p.stroke(body, 34)
    p.line_between((lt + 26, top + 30), (rt - 26, top + 26), 22)
    p.arc(636, 540, 104, 86, -78, 78, 32)
    p.line_between((236, 782), (788, 776), 34)
    for x0, h, ph in [(404, 300, 0.0), (520, 250, 1.1)]:
        p.stroke([(x0 + 34 * math.sin(t / 44 + ph), 384 - t) for t in range(0, h, 6)], 26, 4.0)


def cup_top(p):
    """A cup seen from straight above. Two rings, one handle. Nothing else."""
    p.arc(512, 512, 286, 286, 0, 359, 36, n=90, amp=2.4)
    p.arc(490, 512, 176, 176, 0, 359, 30, n=80, amp=2.2)
    p.arc(800, 512, 70, 92, -96, 96, 32, amp=2.4)


def bean(p):
    """One coffee bean with its seam."""
    p.arc(512, 512, 250, 316, 0, 359, 38, n=96, amp=2.6)
    seam = [(512 + 74 * math.sin(t / 96), 512 - 250 + t) for t in range(0, 500, 6)]
    p.stroke(seam, 34, 3.0)


def portafilter(p):
    """The basket and handle — for someone who actually pulls shots."""
    p.line_between((316, 380), (708, 376), 36)            # rim
    p.line_between((344, 392), (416, 640), 34)            # left wall
    p.line_between((680, 388), (608, 640), 34)            # right wall
    p.arc(512, 628, 96, 52, 0, 180, 34, amp=2.6)          # basket floor
    p.line_between((474, 684), (474, 754), 28)            # spouts
    p.line_between((550, 684), (550, 754), 28)
    p.line_between((712, 378), (884, 372), 40)            # handle


def v60(p):
    """A pour-over cone, dripping."""
    p.line_between((250, 340), (774, 334), 36)            # rim
    p.line_between((280, 352), (486, 690), 34)            # cone
    p.line_between((744, 348), (538, 690), 34)
    p.line_between((486, 690), (538, 690), 34)
    for i, (x, y, r) in enumerate([(512, 762, 20), (512, 830, 14)]):
        p.d.ellipse([(x - r) * SS, (y - r) * SS, (x + r) * SS, (y + r) * SS], fill=p.ink)


GLYPHS = {"cup_side": cup_side, "cup_top": cup_top, "bean": bean,
          "portafilter": portafilter, "v60": v60}

# letter, background, ink, glyph, description
OPTIONS = [
    ("A", (226, 129,  58), (255, 255, 255), "cup_side",    "the one you have"),
    ("B", ( 31, 107,  94), (255, 255, 255), "cup_top",     "deep teal, cup from above"),
    ("C", ( 74,  46,  30), (255, 255, 255), "bean",        "cocoa brown, one bean"),
    ("D", (239, 226, 204), ( 74,  46,  30), "cup_side",    "oat, dark glyph"),
    ("E", (107,  74,  94), (255, 255, 255), "portafilter", "dusty plum, portafilter"),
    ("F", (110, 139, 106), (255, 255, 255), "v60",         "sage, pour-over cone"),
]


def draw(bg, ink, glyph, seed=7):
    img = Image.new("RGB", (W, W), bg)
    GLYPHS[glyph](Pen(img, ink, seed))
    img = img.filter(ImageFilter.GaussianBlur(0.6 * SS / 4))
    return img.resize((S, S), Image.LANCZOS)


def rounded(img, radius_frac=0.235):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1],
        radius=int(img.size[0] * radius_frac), fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


if __name__ == "__main__":
    pick = sys.argv[1].upper() if len(sys.argv) > 1 else None

    if pick:                                   # write the chosen one into the app
        letter, bg, ink, glyph, _ = next(o for o in OPTIONS if o[0] == pick)
        out = "App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
        draw(bg, ink, glyph).save(out)
        print(f"option {letter} written to {out}")
        raise SystemExit

    # otherwise: one contact sheet of every option, labelled
    tile, gap, pad, label_h = 300, 34, 44, 62
    cols = 3
    rows = (len(OPTIONS) + cols - 1) // cols
    sheet_w = pad * 2 + cols * tile + (cols - 1) * gap
    sheet_h = pad * 2 + rows * (tile + label_h) + (rows - 1) * gap
    sheet = Image.new("RGB", (sheet_w, sheet_h), (247, 244, 239))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", 30)
        small = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", 21)
    except OSError:
        font = small = ImageFont.load_default()

    for i, (letter, bg, ink, glyph, note) in enumerate(OPTIONS):
        c, r = i % cols, i // cols
        x = pad + c * (tile + gap)
        y = pad + r * (tile + label_h + gap)
        icon = rounded(draw(bg, ink, glyph).resize((tile, tile), Image.LANCZOS))
        sheet.paste(icon, (x, y), icon)
        d.text((x + tile / 2, y + tile + 14), letter, fill=(40, 30, 25),
               font=font, anchor="ma")
        d.text((x + tile / 2, y + tile + 50), note, fill=(120, 110, 100),
               font=small, anchor="ma")

    sheet.save("/tmp/ams-coffee-icon-options.png")
    print("wrote /tmp/ams-coffee-icon-options.png")
