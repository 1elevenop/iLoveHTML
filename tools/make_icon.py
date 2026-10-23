"""iLoveHTML launcher icon in the New ELEVEN style: <heart> drawn as pixel squares.

Usage: python tools/make_icon.py app   (needs Pillow; rewrites the Android
mipmaps and windows/runner/resources/app_icon.ico)
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

BG = (0, 0, 0)
FG = (242, 239, 234)
ACC = (255, 122, 26)

HEART = [
    ".XX.XX.",
    "XXXXXXX",
    "XXXXXXX",
    ".XXXXX.",
    "..XXX..",
    "...X...",
]
LT = ["..X", ".X.", "X..", ".X.", "..X"]
GT = ["X..", ".X.", "..X", ".X.", "X.."]


def cells(full):
    """(col, row, colour) for every lit pixel."""
    out = []
    if full:
        parts = [(LT, 0, 0, FG), (HEART, 4, 0, ACC), (GT, 12, 0, FG)]
    else:
        parts = [(HEART, 0, 0, ACC)]
    for rows, ox, oy, col in parts:
        for y, r in enumerate(rows):
            for x, ch in enumerate(r):
                if ch == "X":
                    out.append((ox + x, oy + y, col))
    return out


def render(size, *, full=True, content=0.62, bg=True, radius=0.0, ss=4):
    """Draw the mark centred on a size x size canvas, content = share of width used."""
    S = size * ss
    cs = cells(full)
    cols = max(c[0] for c in cs) + 1
    rows = max(c[1] for c in cs) + 1
    pitch = S * content / cols
    sq = pitch * 0.9
    ox = (S - cols * pitch + (pitch - sq)) / 2
    oy = (S - rows * pitch + (pitch - sq)) / 2 + pitch * 0.25

    def layer(colour_filter):
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        for x, y, col in cs:
            if colour_filter(col):
                x0, y0 = ox + x * pitch, oy + y * pitch
                d.rectangle([x0, y0, x0 + sq, y0 + sq], fill=col + (255,))
        return im

    marks = layer(lambda c: True)
    acc = layer(lambda c: c == ACC)
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    if bg:
        base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(base).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * radius), fill=BG + (255,))
        canvas = base
    # The ELEVEN glow: 0 0 6px .8 + 0 0 20px .35, scaled to the pixel pitch.
    for blur, alpha in ((pitch * 0.55, 0.8), (pitch * 1.8, 0.35)):
        g = acc.filter(ImageFilter.GaussianBlur(blur))
        a = g.getchannel("A").point(lambda v: int(v * alpha))
        g.putalpha(a)
        canvas = Image.alpha_composite(canvas, g)
    canvas = Image.alpha_composite(canvas, marks)
    if bg and radius:
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * radius), fill=255)
        canvas.putalpha(Image.composite(canvas.getchannel("A"), mask, mask))
    return canvas.resize((size, size), Image.LANCZOS)


def main(app):
    res = app / "android/app/src/main/res"
    for dens, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        render(px, radius=0.2).save(res / f"mipmap-{dens}/ic_launcher.png")
        # Adaptive foreground: 108dp canvas, mark inside the 66dp safe zone.
        render(px * 108 // 48, bg=False, content=0.54).save(res / f"mipmap-{dens}/ic_launcher_foreground.png")
    sizes = [16, 24, 32, 48, 64, 128, 256]
    imgs = [render(s, full=s >= 48, content=0.62 if s >= 48 else 0.7, radius=0.2) for s in sizes]
    imgs[-1].save(app / "windows/runner/resources/app_icon.ico", sizes=[(s, s) for s in sizes], append_images=imgs[:-1])
    render(512, radius=0.2).save(app / "../docs/icon-preview.png")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
