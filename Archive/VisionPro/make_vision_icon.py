#!/usr/bin/env python3
"""Makes the Apple Vision Pro app icon: the original icon pulled apart into the three layers of
`AppIcon.solidimagestack`, which visionOS stacks and shifts against each other as you look at it.

Back is the background colour. Middle is the hollow 都道府県 lettering's light outline, tint on
clear. Front is the white map of Japan, with its arc and island. The original's drop shadow is left
out, since visionOS draws its own shadows between the layers.

The original is a flattened image, so each pixel is unmixed into lettering, shadow and map. The
map hides parts of the lettering, which would show as holes when the layers shift, so the letters
are redrawn there: their insides are traced as round-pen strokes fitted to the parts the map
leaves visible, and the outline is those strokes drawn wider, less the strokes themselves.

Run from anywhere: python3 Scripts/make_vision_icon.py
"""

import json
import math

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from make_app_icons import ASSETS, ORIGINAL, ORIGINAL_BACKGROUND, SCALE, SIZE

STACK = ASSETS / "AppIcon.solidimagestack"

BACKGROUND = ORIGINAL_BACKGROUND
TINT = (187, 234, 246)  # The lettering's outline, as the original has it.
WHITE = (255, 255, 255)
SHADOW = (14.9, 149.3, 182.8)  # The original's shadow mixes toward this dark teal, not black.
OUTLINE = 23.9  # How far the outline reaches beyond the letters' insides.

# The letters' insides, wherever they're under the map or close to it, in the original's pixels.
# ("pen", [(x, y, radius), ...]) is a line drawn with a round pen, which may swell or taper;
# ("box", half width, corner radius, end, end) a straight stroke with flat ends;
# ("poly", corner radius, [corners]) a shape with rounded corners;
# ("hole", ...) a box cut back out, for the small gaps inside 自.
STROKES = [
    # 府
    ("box", 30.5, 22.8, (175.0, 611.6), (431.9, 612.6)),  # 广, across
    ("box", 29.0, 20.0, (321.0, 562.0), (321.0, 610.0)),  # its dot
    ("box", 31.2, 14.1, (182.4, 583.0), (182.3, 787.4)),  # its upright
    ("pen", [(188.3, 761.7, 26.4), (171.6, 805.7, 37.8), (175.4, 834.1, 23.0)]),  # sweeping left
    ("pen", [(283.3, 686.2, 33.8), (282.6, 696.4, 33.2), (266.1, 755.3, 27.7), (237.4, 779.3, 18.1)]),  # 亻
    ("box", 27.9, 21.9, (276.1, 776.4), (275.1, 908.7)),  # 亻's upright
    ("box", 30.8, 25.3, (320.3, 704.6), (486.0, 707.3)),  # 寸, across
    ("box", 31.1, 13.0, (429.5, 662.0), (429.6, 845.0)),  # its upright
    ("pen", [(431.0, 840.0, 31.0), (395.0, 862.0, 31.0)]),  # and hook
    ("pen", [(353.0, 792.6, 24.8), (351.4, 787.8, 26.0)]),  # its dot
    # 県
    ("box", 32.8, 26.5, (590.8, 660.1), (595.6, 847.4)),  # the upright on the left
    ("box", 106.0, 27.4, (645.8, 678.6), (881.6, 678.7)),  # 目
    ("box", 26.5, 24.0, (562.0, 827.0), (895.0, 827.0)),  # the bar under it
    ("pen", [(724.5, 850.2, 31.9), (722.7, 881.4, 34.2)]),  # 小, the middle
    ("pen", [(828.0, 881.2, 12.2), (835.0, 884.5, 18.3)]),  # and right
    # 道
    ("pen", [(697.3, 165.5, 22.0), (862.0, 165.9, 25.9)]),  # 首, across the top
    ("pen", [(740.8, 133.2, 17.3)]),  # its two dots
    ("pen", [(831.0, 137.0, 19.0)]),
    ("poly", 0.1, [(743.7, 182.5), (807.5, 182.0), (802.5, 208.0), (734.8, 207.6)]),  # joining 自
    ("box", 93.4, 25.0, (671.4, 295.8), (898.0, 296.1)),  # 自
    ("hole", 7.5, 3.1, (733.8, 245.1), (834.2, 245.1)),
    ("hole", 7.2, 3.0, (733.8, 294.8), (834.2, 294.8)),
    ("hole", 7.4, 3.0, (733.8, 344.8), (834.2, 344.8)),
    ("pen", [(610.1, 170.5, 18.7), (612.7, 174.1, 17.4), (620.6, 183.3, 14.4)]),  # 辶's dot
    ("poly", 24.7, [(583.7, 279.8), (629.1, 277.0), (624.2, 292.6), (583.1, 292.6)]),  # 辶, across
    ("box", 30.2, 20.0, (620.4, 260.0), (622.2, 420.0)),  # down
    ("pen", [(592.6, 415.0, 31.7), (605.2, 428.6, 30.2), (623.3, 419.2, 31.9), (679.7, 432.8, 29.7)]),  # round
    ("box", 28.5, 25.0, (660.0, 431.3), (878.0, 431.3)),  # and along the bottom
]


def main():
    original = Image.open(ORIGINAL).convert("RGB")
    lettering = unmix(original)

    # The map is whatever's lighter than the lettering can be, and a little around it.
    mapped = Image.new("L", original.size)
    mapped.putdata([255 if v > 1.03 else 0 for v in lettering])
    hidden = mapped.filter(ImageFilter.MaxFilter(5))

    # Middle: the original's lettering where it shows, the redrawn lettering under the map.
    seen = Image.new("L", original.size)
    seen.putdata([round(255 * min(max(v, 0.0), 1.0)) for v in lettering])
    seen = frame(seen)  # The original has a faint light edge; it isn't lettering.
    # All redrawn under the map and its edge, fading into the original just beyond.
    blend = ImageChops.lighter(hidden, hidden.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1)))
    outline = Image.composite(draw_outline(), seen, blend)

    front = map_alpha(original, outline, hidden)

    STACK.mkdir(exist_ok=True)
    write_layer("Back", Image.new("RGB", (SIZE, SIZE), BACKGROUND))
    write_layer("Middle", layer(TINT, outline))
    write_layer("Front", layer(WHITE, front))
    contents = {
        "info": {"author": "xcode", "version": 1},
        "layers": [{"filename": f"{name}.solidimagestacklayer"} for name in ("Front", "Middle", "Back")],
    }
    write_json(STACK / "Contents.json", contents)


def unmix(image):
    """Each pixel is the background mixed toward the lettering's tint, then toward the shadow's
    colour. Finds the first mix for every pixel, from 0 to 1, or past 1 where the map's white is
    lighter still."""
    found = {colour: unmix_colour(colour)[0] for colour in set(image.getdata())}
    return [found[colour] for colour in image.getdata()]


def unmix_colour(colour):
    tint = [t - b for t, b in zip(TINT, BACKGROUND)]
    a, s = 0.0, 0.0
    for _ in range(40):
        # With the shadow known, how far toward the tint; with that known, how much shadow.
        unshaded = [(c - s * k) / (1 - s) for c, k in zip(colour, SHADOW)]
        a = dot([u - b for u, b in zip(unshaded, BACKGROUND)], tint) / dot(tint, tint)
        base = [b + a * t for b, t in zip(BACKGROUND, tint)]
        toward = [k - b for k, b in zip(SHADOW, base)]
        s = min(max(dot([c - b for c, b in zip(colour, base)], toward) / dot(toward, toward), 0.0), 0.9)
    return a, s


def dot(u, v):
    return sum(x * y for x, y in zip(u, v))


def frame(image, width=2):
    """Clears a band around the image's edge."""
    clear = Image.new("L", image.size, 0)
    clear.paste(image.crop((width, width, SIZE - width, SIZE - width)), (width, width))
    return clear


def draw_outline():
    """The redrawn lettering's outline: its insides drawn wider by OUTLINE, less its insides."""
    big = SIZE * SCALE
    wide = Image.new("L", (big, big), 0)
    inside = Image.new("L", (big, big), 0)
    for stroke in STROKES:
        if stroke[0] != "hole":
            draw_stroke(wide, stroke, OUTLINE, 255)
            draw_stroke(inside, stroke, 0, 255)
    for stroke in STROKES:
        if stroke[0] == "hole":
            draw_stroke(inside, stroke, 0, 0)
    return ImageChops.subtract(wide, inside).resize((SIZE, SIZE), Image.BOX)


def draw_stroke(image, stroke, grow, fill):
    draw = ImageDraw.Draw(image)
    kind = stroke[0]
    if kind == "pen":
        points = [(x, y, r + grow) for x, y, r in stroke[1]]
        for x, y, r in points:
            disc(draw, (x, y), r, fill)
        for start, end in zip(points, points[1:]):
            draw.polygon(hull(start, end), fill=fill)
    elif kind == "poly":
        corner, corners = stroke[1] + grow, stroke[2]
        draw.polygon([at(p) for p in corners], fill=fill)
        for start, end in zip(corners, corners[1:] + corners[:1]):
            disc(draw, start, corner, fill)
            draw.polygon(hull(start + (corner,), end + (corner,)), fill=fill)
    else:
        _, half_width, corner, start, end = stroke
        draw.polygon(rounded_box(start, end, half_width + grow, corner + grow, grow), fill=fill)


def at(point):
    """From the original's pixel centres to the drawing's, SCALE times larger."""
    return (point[0] * SCALE + (SCALE - 1) / 2, point[1] * SCALE + (SCALE - 1) / 2)


def disc(draw, centre, radius, fill):
    x, y = at(centre)
    r = radius * SCALE
    draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def hull(start, end):
    """The band joining two discs, (x, y, radius) each, along the lines that touch both."""
    (x0, y0, r0), (x1, y1, r1) = start, end
    length = math.hypot(x1 - x0, y1 - y0)
    if length == 0 or abs(r0 - r1) >= length:
        return [at((x0, y0))] * 3
    ux, uy = (x1 - x0) / length, (y1 - y0) / length
    along = (r0 - r1) / length
    across = math.sqrt(1 - along * along)
    sides = []
    for side in (1, -1):
        nx, ny = along * ux - side * across * uy, along * uy + side * across * ux
        sides.append(((x0 + r0 * nx, y0 + r0 * ny), (x1 + r1 * nx, y1 + r1 * ny)))
    (a, b), (c, d) = sides
    return [at(a), at(b), at(d), at(c)]


def rounded_box(start, end, half_width, corner, grow):
    """A straight stroke with flat ends at `start` and `end` (pushed out by `grow`), its corners
    rounded."""
    (x0, y0), (x1, y1) = start, end
    length = math.hypot(x1 - x0, y1 - y0)
    ux, uy = (x1 - x0) / length, (y1 - y0) / length
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    half_length = length / 2 + grow
    corner = min(corner, half_width, half_length)
    points = []
    for sx, sy, start_angle in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        ax, ay = sx * (half_length - corner), sy * (half_width - corner)
        for step in range(13):
            angle = math.radians(start_angle + step * 7.5)
            px, py = ax + corner * math.cos(angle), ay + corner * math.sin(angle)
            points.append(at((cx + px * ux - py * uy, cy + px * uy + py * ux)))
    return points


def map_alpha(original, outline, hidden):
    """How much of each pixel is the map's white: over the lettering (as redrawn) and the
    original's shadow, solved for where the map is, clear everywhere else."""
    alpha = Image.new("L", original.size, 0)
    pixels, letters, near, out = original.load(), outline.load(), hidden.load(), alpha.load()
    tint = [t - b for t, b in zip(TINT, BACKGROUND)]
    for y in range(SIZE):
        for x in range(SIZE):
            if not near[x, y]:
                continue
            colour = pixels[x, y]
            base = [b + letters[x, y] / 255 * t for b, t in zip(BACKGROUND, tint)]
            out[x, y] = round(255 * white_over(colour, base))
    return alpha


def white_over(colour, base):
    """How much white over `base`, itself perhaps shaded toward the shadow's colour."""
    white, shade = 0.0, 0.0
    toward = [k - b for k, b in zip(SHADOW, base)]
    for _ in range(20):
        under = [b + shade * t for b, t in zip(base, toward)]
        lift = [w - u for w, u in zip(WHITE, under)]
        white = min(max(dot([c - u for c, u in zip(colour, under)], lift) / dot(lift, lift), 0.0), 1.0)
        if white > 0.998:
            return 1.0
        seen = [(c - white * w) / (1 - white) for c, w in zip(colour, WHITE)]
        shade = min(max(dot([s - b for s, b in zip(seen, base)], toward) / dot(toward, toward), 0.0), 0.9)
    return white


def layer(colour, alpha):
    image = Image.new("RGBA", (SIZE, SIZE), colour + (0,))
    image.putalpha(alpha)
    return image


def write_layer(name, image):
    folder = STACK / f"{name}.solidimagestacklayer"
    imageset = folder / "Content.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    image.save(imageset / f"{name}.png")
    write_json(folder / "Contents.json", {"info": {"author": "xcode", "version": 1}})
    contents = {
        "images": [{"filename": f"{name}.png", "idiom": "vision", "scale": "2x"}],
        "info": {"author": "xcode", "version": 1},
    }
    write_json(imageset / "Contents.json", contents)


def write_json(path, contents):
    path.write_text(json.dumps(contents, indent=2) + "\n")


if __name__ == "__main__":
    main()
