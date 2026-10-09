#!/usr/bin/env python3
"""Makes the alternate app icons, and the small previews Settings shows of them.

Japan's colours recolour the original icon, so its 都道府県 artwork stays exactly as drawn.
The other countries are drawn from the app's own outlines in `jpex/Maps/geo_<ID>.json`, white on
colour over hollow lettering, in the original's style. China's licence plates are drawn for each
place with a short name in `jpex/ChinaCatalog.swift`: its character, white on plate blue. The
European Union's members get the blue band their plates start with: the ring of stars over the
country's code, in white.

Run from anywhere: python3 Scripts/make_app_icons.py
"""

import json
import math
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent / "jpex"
ASSETS = ROOT / "Assets.xcassets"
ORIGINAL = ASSETS / "AppIcon.appiconset" / "Icon_1024x1024.png"
ORIGINAL_BACKGROUND = (38, 189, 226)

SIZE = 1024
SCALE = 4  # Drawn larger, then scaled down, for smooth edges.
PREVIEW_SIZE = 240

ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"
MARU = "/System/Library/Fonts/ヒラギノ丸ゴ ProN W4.ttc"
GOTHIC_KR = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
HEI_SC = ("/System/Library/Fonts/Hiragino Sans GB.ttc", 2)  # W6

PLATE_BLUE = (16, 70, 184)

DIN = "/System/Library/Fonts/Supplemental/DIN Alternate Bold.ttf"
EU_BLUE = (0, 51, 153)
EU_YELLOW = (255, 204, 0)

# Each member of the European Union, by ISO code, with the code on its plates' blue band.
EUROPEAN_PLATES = {
    "AT": "A", "BE": "B", "BG": "BG", "HR": "HR", "CY": "CY", "CZ": "CZ", "DK": "DK", "EE": "EST",
    "FI": "FIN", "FR": "F", "DE": "D", "GR": "GR", "HU": "H", "IE": "IRL", "IT": "I", "LV": "LV",
    "LT": "LT", "LU": "L", "MT": "M", "NL": "NL", "PL": "PL", "PT": "P", "RO": "RO", "SK": "SK",
    "SI": "SLO", "ES": "E", "SE": "S",
}

# Japan, recoloured. The first is the original, the primary icon.
JAPAN = [
    ("JapanRed", (226, 58, 72)),
    ("JapanGreen", (72, 172, 96)),
    ("JapanPink", (238, 112, 158)),
    ("JapanPurple", (124, 86, 196)),
    ("JapanNight", (30, 42, 78)),
]

# Other maps: (name, country ID, background, lettering lines, font, bounds to keep as
# (west, south, east, north), or None for everything).
COUNTRIES = [
    ("Korea", "KR", (22, 158, 150), ["대한", "민국"], (GOTHIC_KR, 16), None),
    ("Taiwan", "TW", (46, 168, 112), ["臺", "灣"], (MARU, 1), (119.2, 21.8, 122.2, 25.4)),
    ("UnitedStates", "US", (42, 72, 160), ["USA"], (ROUNDED, "Heavy", 1.9), (-125, 24, -66, 50)),
    ("UnitedKingdom", "GB", (200, 44, 64), ["UK"], (ROUNDED, "Heavy"), None),
    ("France", "FR", (52, 96, 214), ["FRA", "NCE"], (ROUNDED, "Heavy"), (-6, 41, 10, 52)),
    ("Italy", "IT", (30, 150, 86), ["ITA", "LIA"], (ROUNDED, "Heavy"), None),
    ("Australia", "AU", (238, 138, 40), ["AUST", "RALIA"], (ROUNDED, "Heavy"), (112, -45, 155, -9)),
]

LETTERING_TINT = 0.7  # How far the lettering's outline is from the background toward white.


def main():
    original = Image.open(ORIGINAL).convert("RGB")
    write_preview("Japan", original)
    for name, background in JAPAN:
        icon = recolour(original, background)
        write_icon(name, icon)
        write_preview(name, icon)
    for name, country, background, lines, font, bounds in COUNTRIES:
        icon = draw_country(country, background, lines, font, bounds)
        write_icon(name, icon)
        write_preview(name, icon)
    for code, character in chinese_short_names():
        icon = draw_plate(character)
        write_icon(f"Plate-{code}", icon)
        write_preview(f"Plate-{code}", icon)
    for country, sign in EUROPEAN_PLATES.items():
        icon = draw_european_plate(sign)
        write_icon(f"EUPlate-{country}", icon)
        write_preview(f"EUPlate-{country}", icon)


def chinese_short_names():
    """Each place's code and licence-plate character, as the app lists them."""
    catalog = (ROOT / "ChinaCatalog.swift").read_text()
    return re.findall(r'\("([A-Z]{2})", "[^"]+", "[^"]+", "(.)",', catalog)


def draw_plate(character):
    """A Chinese car plate: white on blue, in a fine white rim, with its two bolts at the top,
    and the character tall and narrow, pressed up out of the metal."""
    big = SIZE * SCALE
    image = Image.new("RGB", (big, big), PLATE_BLUE)

    # Light falls from above across the metal.
    sheen = Image.linear_gradient("L").resize((big, big)).point(lambda v: round((255 - v) * 0.16))
    image.paste((255, 255, 255), mask=sheen)

    draw = ImageDraw.Draw(image)
    inset, rim = 92 * SCALE, 16 * SCALE
    image.paste((255, 255, 255), mask=squircle_rim(big, inset, rim))

    # The character fills a box a little over half as wide as it's tall, as plates set them (their
    # own typeface isn't published). Squeezing thins the upright strokes, so widen them back a
    # little, short of filling the gaps in busy characters such as 藏.
    font = ImageFont.truetype(HEI_SC[0], 600 * SCALE, index=HEI_SC[1])
    left, top, right, bottom = font.getbbox(character)
    pad = 20 * SCALE
    glyph = Image.new("L", (right - left + 2 * pad, bottom - top + 2 * pad), 0)
    ImageDraw.Draw(glyph).text((pad - left, pad - top), character, font=font, fill=255)
    glyph = glyph.crop(glyph.getbbox())
    height = 580 * SCALE
    width = round(height * 0.56)
    glyph = glyph.resize((width, height), Image.LANCZOS)
    letters = Image.new("L", (big, big), 0)
    origin = ((big - width) // 2, (big - height) // 2 + 40 * SCALE)
    for dx in range(-3 * SCALE, 3 * SCALE + 1, SCALE):
        layer = Image.new("L", (big, big), 0)
        layer.paste(glyph, (origin[0] + dx, origin[1]))
        letters = ImageChops.lighter(letters, layer)

    # Pressed: a soft shadow below, a highlight above.
    shadow = ImageChops.offset(letters, 0, 10 * SCALE).filter(ImageFilter.GaussianBlur(8 * SCALE))
    image.paste((0, 20, 70), mask=shadow.point(lambda v: round(v * 0.45)))
    image.paste((255, 255, 255), mask=letters)

    # The bolts that hold the plate on, in its top corners.
    for x in (0.27, 0.73):
        center, radius = (x * big, 0.205 * big), 30 * SCALE
        draw.ellipse(
            (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
            fill=(200, 206, 214), outline=(120, 130, 146), width=4 * SCALE)
        draw.line(
            (center[0] - radius * 0.55, center[1], center[0] + radius * 0.55, center[1]),
            fill=(120, 130, 146), width=6 * SCALE)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def recolour(image, background):
    """Each pixel of the original is its background mixed toward white (or, in shadow, black);
    keep that mix, over a new background."""
    old = ORIGINAL_BACKGROUND
    pixels = []
    for r, g, b in image.getdata():
        lightening = [(c - o) / (255 - o) for c, o in zip((r, g, b), old)]
        darkening = [(c - o) / o for c, o in zip((r, g, b), old)]
        if sum(lightening) >= 0:
            t = max(0.0, min(1.0, sum(lightening) / 3))
            pixels.append(tuple(round(n + (255 - n) * t) for n in background))
        else:
            t = max(-1.0, sum(darkening) / 3)
            pixels.append(tuple(round(n * (1 + t)) for n in background))
    result = Image.new("RGB", image.size)
    result.putdata(pixels)
    return result


def draw_country(country, background, lines, font_spec, bounds):
    big = SIZE * SCALE
    tint = tuple(round(n + (255 - n) * LETTERING_TINT) for n in background)
    image = Image.new("RGB", (big, big), background)
    draw_lettering(image, lines, font_spec, background, tint)

    land = land_mask(country, bounds, big)
    shadow = Image.new("L", (big, big), 0)
    shadow.paste(land, (0, 10 * SCALE))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14 * SCALE)).point(lambda v: v * 0.22)
    image.paste((0, 0, 0), mask=shadow)
    image.paste((255, 255, 255), mask=land)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def load_font(font_spec, size):
    path, face = font_spec[:2]
    if isinstance(face, int):
        return ImageFont.truetype(path, size, index=face)
    font = ImageFont.truetype(path, size)
    font.set_variation_by_name(face)
    return font


def draw_lettering(image, lines, font_spec, background, tint):
    """Hollow letters with a thick light outline, filling the square in even rows."""
    if len(font_spec) > 2:
        draw_tall_lettering(image, lines, font_spec, background, tint)
        return
    big = image.size[0]
    margin = 70 * SCALE
    stroke = 22 * SCALE
    width = big - 2 * margin
    row_height = (big - 2 * margin) / len(lines)

    # One size for every row: the largest at which each fits its share of the square.
    probe = 200 * SCALE
    font = load_font(font_spec, probe)
    fit = math.inf
    for line in lines:
        left, top, right, bottom = font.getbbox(line, stroke_width=stroke)
        fit = min(fit, width / (right - left), row_height * 0.94 / (bottom - top))
    font = load_font(font_spec, int(probe * fit))

    draw = ImageDraw.Draw(image)
    for row, line in enumerate(lines):
        left, top, right, bottom = font.getbbox(line, stroke_width=stroke)
        x = (big - (right - left)) / 2 - left
        y = margin + row_height * row + (row_height - (bottom - top)) / 2 - top
        draw.text((x, y), line, font=font, fill=tint, stroke_width=stroke, stroke_fill=tint)
        draw.text((x, y), line, font=font, fill=background)


def draw_tall_lettering(image, lines, font_spec, background, tint):
    """Like `draw_lettering`, but with the letters drawn taller by the font spec's third value,
    for short words that would otherwise hide behind a wide map. The outline is grown around
    the stretched letters, so it stays as even as the others'."""
    big = image.size[0]
    stretch = font_spec[2]
    margin = 70 * SCALE
    stroke = 22 * SCALE
    inset = margin + stroke
    short = round(big / stretch)
    row_height = (short - 2 * inset / stretch) / len(lines)

    probe = 200 * SCALE
    font = load_font(font_spec, probe)
    fit = math.inf
    for line in lines:
        left, top, right, bottom = font.getbbox(line)
        fit = min(fit, (big - 2 * inset) / (right - left), row_height / (bottom - top))
    font = load_font(font_spec, int(probe * fit))

    letters = Image.new("L", (big, short), 0)
    draw = ImageDraw.Draw(letters)
    for row, line in enumerate(lines):
        left, top, right, bottom = font.getbbox(line)
        x = (big - (right - left)) / 2 - left
        y = inset / stretch + row_height * row + (row_height - (bottom - top)) / 2 - top
        draw.text((x, y), line, font=font, fill=255)
    letters = letters.resize((big, big), Image.LANCZOS)

    # Grow the letters by `stroke` in every direction: the letters, shifted all around a disc.
    outline = letters.copy()
    for radius in range(stroke, 0, -4 * SCALE):
        steps = max(8, round(2 * math.pi * radius / (2 * SCALE)))
        for step in range(steps):
            angle = 2 * math.pi * step / steps
            dx, dy = round(radius * math.cos(angle)), round(radius * math.sin(angle))
            outline = ImageChops.lighter(outline, ImageChops.offset(letters, dx, dy))
    image.paste(tint, mask=outline)
    image.paste(background, mask=letters)


def land_mask(country, bounds, big):
    """The country's outline, white on black, fitted into the middle of the square."""
    file = json.loads((ROOT / "Maps" / f"geo_{country}.json").read_text())
    rings = []
    for region in file["regions"]:
        for part in re.split(r"(?=M)", region["d"]):
            points = [(float(x), float(y)) for x, y in re.findall(r"(-?[\d.]+)[ ,](-?[\d.]+)", part)]
            if len(points) < 3:
                continue
            lon, lat = points[0]
            if bounds and not (bounds[0] <= lon <= bounds[2] and bounds[1] <= lat <= bounds[3]):
                continue
            rings.append(points)

    # Leave out specks too small to see on a home screen.
    areas = [abs(polygon_area(ring)) for ring in rings]
    largest = max(areas)
    rings = [ring for ring, area in zip(rings, areas) if area > largest * 0.0004]

    # Longitude narrows toward the poles; squeeze it at the country's middle latitude.
    lats = [lat for ring in rings for _, lat in ring]
    squeeze = math.cos(math.radians((min(lats) + max(lats)) / 2))
    projected = [[(lon * squeeze, -lat) for lon, lat in ring] for ring in rings]

    xs = [x for ring in projected for x, _ in ring]
    ys = [y for ring in projected for _, y in ring]
    span_x, span_y = max(xs) - min(xs), max(ys) - min(ys)
    box = 660 * SCALE
    fit = box / max(span_x, span_y)
    offset_x = (big - span_x * fit) / 2 - min(xs) * fit
    offset_y = (big - span_y * fit) / 2 - min(ys) * fit

    mask = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(mask)
    for ring in projected:
        points = [(x * fit + offset_x, y * fit + offset_y) for x, y in ring]
        # A hairline outline closes the seams between neighbouring regions.
        draw.polygon(points, fill=255, outline=255, width=2 * SCALE)
    return mask


def polygon_area(ring):
    return sum(x0 * y1 - x1 * y0 for (x0, y0), (x1, y1) in zip(ring, ring[1:] + ring[:1])) / 2


def draw_european_plate(sign, margin=80, band=1.0):
    """The blue band at the start of a European plate: the Union's ring of twelve gold stars
    over the country's code. It fills the plate's black rim, which sits well inside the icon's
    edge with white plate around it, so none of it looks cut off by the Home Screen's mask.
    A `band` under 1 leaves that much of the plate's white beside it instead."""
    big = SIZE * SCALE
    image = Image.new("RGB", (big, big), (255, 255, 255))
    draw = ImageDraw.Draw(image)
    margin, rim = margin * SCALE, 24 * SCALE
    band_right = round(big * band)
    # The band runs to the rim, never past it into the plate's white margin.
    band = Image.new("L", (big, big), 0)
    ImageDraw.Draw(band).rectangle((0, 0, band_right, big), fill=255)
    image.paste(EU_BLUE, mask=ImageChops.multiply(squircle_mask(big, margin), band))
    image.paste((20, 20, 20), mask=squircle_rim(big, margin, rim))
    band_right = min(band_right, big - margin)
    middle = (margin + band_right) / 2

    # The stars, each with a point straight up, around a ring as on the flag.
    ring, star = 0.205 * big, 0.042 * big
    ring_y = 0.37 * big
    for index in range(12):
        angle = 2 * math.pi * index / 12
        x, y = middle + ring * math.sin(angle), ring_y - ring * math.cos(angle)
        points = []
        for point in range(10):
            radius = star if point % 2 == 0 else star * 0.382
            turn = math.pi * point / 5
            points.append((x + radius * math.sin(turn), y - radius * math.cos(turn)))
        draw.polygon(points, fill=EU_YELLOW)

    font = ImageFont.truetype(DIN, 100 * SCALE)
    left, top, right, bottom = font.getbbox(sign)
    fit = min((band_right - margin - 2 * rim) * 0.78 / (right - left), 0.24 * big / (bottom - top))
    font = ImageFont.truetype(DIN, round(100 * SCALE * fit))
    left, top, right, bottom = font.getbbox(sign)
    draw.text(
        (middle - (left + right) / 2, 0.775 * big - (top + bottom) / 2), sign, font=font, fill=(255, 255, 255))
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def squircle_mask(big, inset):
    """The Home Screen's icon shape, near enough a superellipse, drawn `inset` in from its edge
    all the way round, so a rim drawn with it runs parallel to the icon's own edge."""
    n, half = 5, big / 2
    points = []
    for step in range(2048):
        t = 2 * math.pi * step / 2048
        c, s = math.cos(t), math.sin(t)
        x = math.copysign(abs(c) ** (2 / n), c)
        y = math.copysign(abs(s) ** (2 / n), s)
        # Step inward along the curve's normal, the gradient of |x|^n + |y|^n.
        nx = math.copysign(abs(x) ** (n - 1), x)
        ny = math.copysign(abs(y) ** (n - 1), y)
        length = math.hypot(nx, ny)
        points.append((half + x * half - inset * nx / length, half + y * half - inset * ny / length))
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def squircle_rim(big, inset, width):
    """A band `width` wide around the inside of `squircle_mask(big, inset)`."""
    return ImageChops.subtract(squircle_mask(big, inset), squircle_mask(big, inset + width))


def write_icon(name, image):
    folder = ASSETS / f"AppIcon-{name}.appiconset"
    folder.mkdir(exist_ok=True)
    image.save(folder / "Icon_1024x1024.png")
    contents = {
        "images": [
            {"filename": "Icon_1024x1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def write_preview(name, image):
    folder = ASSETS / f"IconPreview-{name}.imageset"
    folder.mkdir(exist_ok=True)
    image.resize((PREVIEW_SIZE, PREVIEW_SIZE), Image.LANCZOS).save(folder / "preview.png")
    contents = {
        "images": [{"filename": "preview.png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


if __name__ == "__main__":
    main()
