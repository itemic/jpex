#!/usr/bin/env python3
"""Makes the alternate app icons, each with a dark version for a dark Home Screen, and the small
previews Settings shows of them.

Japan's colours recolour the original icon, so its 都道府県 artwork stays exactly as drawn.
The other countries are drawn from the app's own outlines in `jpex/Resources/Maps/geo_<ID>.json`, white on
colour over hollow lettering, in the original's style. China's licence plates are drawn for each
place with a short name in `jpex/Places/Countries/ChinaCatalog.swift`: its character, white on plate blue. The
European Union's members get the blue band their plates start with: the ring of stars over the
country's code, in white. Japan also comes in neon: its 都道府県 and islands bent in tubes of
light, lit up on a dark brick wall.

A dark icon moves the colour from the background into the artwork, and leaves the background
clear for the system to fill with its own dark, as Apple asks. The plates keep their colours,
subdued, with only their surrounds gone dark. The neon one is dark already, so it stays as it is.

Run from anywhere with a Python that has Pillow: /usr/bin/python3 Scripts/make_app_icons.py
"""

import colorsys
import json
import math
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent / "jpex"
ASSETS = ROOT / "Resources" / "Assets.xcassets"
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

DARK_LETTERING = 0.5  # How strongly the lettering's outline shows in a dark icon, the map being 1.
DARK_LUMINANCE = 0.16  # The least luminance a dark icon's colour is lifted to, to stand out.
# The system's backdrop for dark icons, near enough, from top to bottom: for the previews only,
# since the icons themselves leave it clear.
DARK_BACKDROP = ((49, 49, 49), (20, 20, 20))
DARK_EU_RIM = (72, 72, 76)
DARK_BOLT = ((96, 102, 112), (62, 68, 80))  # The bolts' heads and slots, in shadow.

# Neon: glass tubes, lit, on a dark brick wall.
NEON_PINK = (255, 56, 168)
NEON_CYAN = (36, 214, 255)
TUBE = 14  # How wide a tube is, at icon size.
NEON_WALL = ((30, 22, 52), (10, 8, 24))  # The wall in the dark, from top to bottom.


def main():
    original = Image.open(ORIGINAL).convert("RGB")
    # The primary icon is the original itself, so only its dark version is made here.
    sky = recolour_dark(original, ink(ORIGINAL_BACKGROUND))
    write_icon("Japan", None, sky)
    write_preview("Japan", original, sky)
    for name, background in JAPAN:
        icon = recolour(original, background)
        dark = recolour_dark(original, ink(background))
        write_icon(name, icon, dark)
        write_preview(name, icon, dark)
    # Lit up in the dark already, the neon one looks the same on a dark Home Screen.
    neon = draw_neon(neon_japan())
    write_icon("JapanNeon", neon, neon)
    write_preview("JapanNeon", neon)
    for name, country, background, lines, font, bounds in COUNTRIES:
        icon, dark = draw_country(country, background, lines, font, bounds)
        write_icon(name, icon, dark)
        write_preview(name, icon, dark)
    for code, character in chinese_short_names():
        icon, dark = draw_plate(character)
        write_icon(f"Plate-{code}", icon, dark)
        write_preview(f"Plate-{code}", icon, dark)
    for country, sign in EUROPEAN_PLATES.items():
        icon, dark = draw_european_plate(sign)
        write_icon(f"EUPlate-{country}", icon, dark)
        write_preview(f"EUPlate-{country}", icon, dark)


def chinese_short_names():
    """Each place's code and licence-plate character, as the app lists them."""
    catalog = (ROOT / "Places" / "Countries" / "ChinaCatalog.swift").read_text()
    return re.findall(r'\("([A-Z]{2})", "[^"]+", "[^"]+", "(.)",', catalog)


def draw_plate(character):
    """A Chinese car plate: white on blue, in a fine white rim, with its two bolts at the top,
    and the character tall and narrow, pressed up out of the metal. In the dark, the rim and
    character take the blue, and the bolts sit in shadow."""
    big = SIZE * SCALE
    image = Image.new("RGB", (big, big), PLATE_BLUE)

    # Light falls from above across the metal.
    sheen = Image.linear_gradient("L").resize((big, big)).point(lambda v: round((255 - v) * 0.16))
    image.paste((255, 255, 255), mask=sheen)

    draw = ImageDraw.Draw(image)
    inset, rim = 92 * SCALE, 16 * SCALE
    edge = squircle_rim(big, inset, rim)
    image.paste((255, 255, 255), mask=edge)

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
    shadow = shadow.point(lambda v: round(v * 0.45))
    image.paste((0, 20, 70), mask=shadow)
    image.paste((255, 255, 255), mask=letters)
    draw_bolts(draw, big, (200, 206, 214), (120, 130, 146))

    colour = ink(PLATE_BLUE)
    dark = Image.new("RGBA", (big, big), colour + (0,))
    dark = lay(dark, colour, edge)
    dark = lay(dark, (0, 0, 0), shadow)
    dark = lay(dark, colour, letters)
    draw_bolts(ImageDraw.Draw(dark), big, *DARK_BOLT)
    return image.resize((SIZE, SIZE), Image.LANCZOS), dark.resize((SIZE, SIZE), Image.LANCZOS)


def draw_bolts(draw, big, head, slot):
    """The bolts that hold the plate on, in its top corners."""
    for x in (0.27, 0.73):
        center, radius = (x * big, 0.205 * big), 30 * SCALE
        draw.ellipse(
            (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
            fill=head, outline=slot, width=4 * SCALE)
        draw.line(
            (center[0] - radius * 0.55, center[1], center[0] + radius * 0.55, center[1]),
            fill=slot, width=6 * SCALE)


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


def recolour_dark(image, colour):
    """The original's artwork in `colour`, for the dark: its white map in full, its lettering's
    light outline fainter, its shadow as it was, and its background clear."""
    old = ORIGINAL_BACKGROUND
    pixels = []
    for r, g, b in image.getdata():
        lightening = [(c - o) / (255 - o) for c, o in zip((r, g, b), old)]
        darkening = [(c - o) / o for c, o in zip((r, g, b), old)]
        if sum(lightening) >= 0:
            t = max(0.0, min(1.0, sum(lightening) / 3))
            # The outline is LETTERING_TINT of the way to white, the map all the way.
            if t < LETTERING_TINT:
                alpha = DARK_LETTERING * t / LETTERING_TINT
            else:
                alpha = DARK_LETTERING + (1 - DARK_LETTERING) * (t - LETTERING_TINT) / (1 - LETTERING_TINT)
            pixels.append(colour + (round(alpha * 255),))
        else:
            t = min(1.0, -sum(darkening) / 3)
            pixels.append((0, 0, 0, round(t * 255)))
    result = Image.new("RGBA", image.size)
    result.putdata(pixels)
    return result


def ink(colour):
    """A colour to draw with on the dark: the same hue and saturation, lightened if need be until
    it stands out from the system's dark backdrop."""
    hue, lightness, saturation = colorsys.rgb_to_hls(*(c / 255 for c in colour))
    while luminance(colour) < DARK_LUMINANCE and lightness < 1:
        lightness = min(1.0, lightness + 0.005)
        colour = tuple(round(c * 255) for c in colorsys.hls_to_rgb(hue, lightness, saturation))
    return colour


def luminance(colour):
    """A colour's relative luminance, from 0 for black to 1 for white."""
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in (c / 255 for c in colour)]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def lay(image, colour, mask):
    """`image` with `colour` laid over it where `mask` is."""
    top = Image.new("RGBA", image.size, colour + (0,))
    top.putalpha(mask)
    return Image.alpha_composite(image, top)


def draw_country(country, background, lines, font_spec, bounds):
    """The country's outline, white over hollow lettering on its colour; and in the dark, both in
    its colour, the lettering fainter."""
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

    # The lettering's outline alone, as a mask.
    lettering = Image.new("L", (big, big), 0)
    draw_lettering(lettering, lines, font_spec, 0, 255)
    colour = ink(background)
    dark = Image.new("RGBA", (big, big), colour + (0,))
    dark = lay(dark, colour, lettering.point(lambda v: round(v * DARK_LETTERING)))
    dark = lay(dark, (0, 0, 0), shadow)
    dark = lay(dark, colour, land)
    return image.resize((SIZE, SIZE), Image.LANCZOS), dark.resize((SIZE, SIZE), Image.LANCZOS)


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
    file = json.loads((ROOT / "Resources" / "Maps" / f"geo_{country}.json").read_text())
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
    A `band` under 1 leaves that much of the plate's white beside it instead. In the dark, the
    white plate around it goes, and its rim turns grey to stand out."""
    big = SIZE * SCALE
    image = Image.new("RGB", (big, big), (255, 255, 255))
    draw = ImageDraw.Draw(image)
    margin, rim = margin * SCALE, 24 * SCALE
    band_right = round(big * band)
    # The band runs to the rim, never past it into the plate's white margin.
    band = Image.new("L", (big, big), 0)
    ImageDraw.Draw(band).rectangle((0, 0, band_right, big), fill=255)
    band = ImageChops.multiply(squircle_mask(big, margin), band)
    edge = squircle_rim(big, margin, rim)
    image.paste(EU_BLUE, mask=band)
    image.paste((20, 20, 20), mask=edge)
    band_right = min(band_right, big - margin)
    draw_band(draw, big, margin, rim, band_right, sign)

    dark = Image.new("RGBA", (big, big), EU_BLUE + (0,))
    dark = lay(dark, EU_BLUE, band)
    dark = lay(dark, DARK_EU_RIM, edge)
    draw_band(ImageDraw.Draw(dark), big, margin, rim, band_right, sign)
    return image.resize((SIZE, SIZE), Image.LANCZOS), dark.resize((SIZE, SIZE), Image.LANCZOS)


def draw_band(draw, big, margin, rim, band_right, sign):
    """The stars, each with a point straight up, around a ring as on the flag, over the code."""
    middle = (margin + band_right) / 2
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


def draw_neon(tubes):
    """A neon sign from its tubes, each a mask and a colour: lit white-hot along the middle and
    in its colour to its edges, glowing out over a dark brick wall, whose bricks show only where
    the light falls on them."""
    near = Image.new("RGB", (SIZE, SIZE), 0)
    far = Image.new("RGB", (SIZE, SIZE), 0)
    glass = []
    for mask, colour in tubes:
        tube = mask.reduce(SCALE)
        # The wide glow spreads from a fattened tube, so it stays smooth even where it's faint.
        fat = tube.filter(ImageFilter.GaussianBlur(5)).point(lambda v: min(255, v * 3))
        near = ImageChops.add(near, tinted(glow(tube, 3, 1.2), colour))
        near = ImageChops.add(near, tinted(glow(fat, 14, 0.7), colour))
        far = ImageChops.add(far, tinted(glow(fat, 46, 0.5), colour))
        # The middle of the tube, white-hot.
        core = mask.filter(ImageFilter.GaussianBlur(TUBE * SCALE / 4)).point(
            lambda v: max(0, min(255, round((v - 190) * 255 / 50)))).reduce(SCALE)
        glass.append((tube, core, colour))
    image = ImageChops.add(ImageChops.add(neon_wall(), ImageChops.multiply(far, bricks())), near)
    for tube, core, colour in glass:
        image.paste(mix(colour, (255, 255, 255), 0.3), mask=tube)
        image.paste(mix(colour, (255, 255, 255), 0.85), mask=core)
    return image


def glow(mask, radius, strength):
    """Light spreading out from a tube."""
    return mask.filter(ImageFilter.GaussianBlur(radius)).point(lambda v: min(255, round(v * strength)))


def tinted(mask, colour):
    """`colour`, as bright as `mask`, on black."""
    return Image.merge("RGB", [mask.point(lambda v, c=c: round(v * c / 255)) for c in colour])


def mix(colour, other, t):
    """`colour`, taken `t` of the way to `other`."""
    return tuple(round(a + (b - a) * t) for a, b in zip(colour, other))


def neon_wall():
    """The wall behind a neon sign, in the dark, darker still toward its corners."""
    top, bottom = NEON_WALL
    wall = Image.new("RGB", (SIZE, SIZE), top)
    wall.paste(bottom, mask=Image.linear_gradient("L").resize((SIZE, SIZE)))
    corners = Image.radial_gradient("L").resize((SIZE, SIZE)).point(lambda v: round(v * 0.45))
    wall.paste((0, 0, 0), mask=corners)
    return wall


def bricks():
    """How much of a sign's light the wall gives back: most from the bricks, varying a little from
    brick to brick, and less from the mortar between them."""
    wall = Image.new("L", (SIZE, SIZE), 120)
    draw = ImageDraw.Draw(wall)
    height, width, mortar = 46, 112, 6
    for row in range(SIZE // height + 1):
        shift = width / 2 if row % 2 else 0
        for column in range(-1, SIZE // width + 1):
            x, y = column * width + shift, row * height
            shade = 205 + (row * 7 + column * 13) % 5 * 12
            draw.rounded_rectangle(
                (x + mortar / 2, y + mortar / 2, x + width - mortar / 2, y + height - mortar / 2),
                radius=4, fill=shade)
    wall = wall.filter(ImageFilter.GaussianBlur(1.2))
    return Image.merge("RGB", (wall,) * 3)


def tube_mask():
    """An empty mask to bend tubes in, at drawing size."""
    return Image.new("L", (SIZE * SCALE, SIZE * SCALE), 0)


def grown(mask, distance):
    """A mask grown by about `distance` at icon size, to leave a gap around what's in front."""
    sigma = distance / 2 * SCALE
    return mask.filter(ImageFilter.GaussianBlur(sigma)).point(lambda v: 255 if v > 6 else 0)


def behind(mask, cover):
    """`mask` with what `cover` hides taken out."""
    return ImageChops.subtract(mask, cover)


def neon_japan():
    """The original icon in neon: 都道府県 in cyan, a tube for each stroke as a shop sign bends
    them, behind the islands traced in pink."""
    big = SIZE * SCALE
    original = Image.open(ORIGINAL).convert("RGB")
    old = ORIGINAL_BACKGROUND
    # The original's map is all that's white in it.
    land = Image.new("L", original.size)
    land.putdata([
        255 if sum((c - o) / (255 - o) for c, o in zip(pixel, old)) / 3 > 0.93 else 0
        for pixel in original.getdata()])
    # Okinawa, in its inset at the bottom right, is too small to trace.
    ImageDraw.Draw(land).ellipse((700, 760, 990, 1050), fill=0)
    # A little smaller, so the lettering shows round it, and smoothed of the specks and inlets no
    # tube could follow.
    size = round(SIZE * 0.86)
    shrunk = Image.new("L", (SIZE, SIZE), 0)
    shrunk.paste(land.resize((size, size), Image.BICUBIC), ((SIZE - size) // 2, (SIZE - size) // 2))
    land = shrunk.resize((big, big), Image.BICUBIC).filter(ImageFilter.GaussianBlur(9 * SCALE))
    land = land.point(lambda v: 255 if v >= 128 else 0)
    coast = land.filter(ImageFilter.GaussianBlur(4 * SCALE)).point(lambda v: 255 if 10 <= v <= 245 else 0)

    font = ImageFont.truetype(MARU, 400 * SCALE)
    letters = tube_mask()
    for character, center in zip("都道府県", ((284, 280), (740, 280), (284, 744), (740, 744))):
        left, top, right, bottom = font.getbbox(character)
        pad = 20 * SCALE
        glyph = Image.new("L", (right - left + 2 * pad, bottom - top + 2 * pad), 0)
        ImageDraw.Draw(glyph).text((pad - left, pad - top), character, font=font, fill=255)
        glyph = glyph.crop(glyph.getbbox())
        fit = 330 * SCALE / max(glyph.size)
        glyph = glyph.resize((round(glyph.size[0] * fit), round(glyph.size[1] * fit)), Image.LANCZOS)
        corner = (round(center[0] * SCALE - glyph.size[0] / 2), round(center[1] * SCALE - glyph.size[1] / 2))
        letters.paste(255, corner, glyph)
    # The font's strokes, thinned to a tube's width.
    letters = letters.filter(ImageFilter.GaussianBlur(3 * SCALE)).point(lambda v: max(0, min(255, (v - 206) * 8)))
    return [(behind(letters, grown(land, 34)), NEON_CYAN), (coast, NEON_PINK)]


def write_icon(name, image, dark):
    """Saves an icon and its dark version as an app icon set. Japan's is the primary set, whose
    image is the original, so it's given as None and left as it is."""
    folder = ASSETS / ("AppIcon.appiconset" if name == "Japan" else f"AppIcon-{name}.appiconset")
    folder.mkdir(exist_ok=True)
    if image is not None:
        image.save(folder / "Icon_1024x1024.png")
    dark.save(folder / "Icon_1024x1024_dark.png")
    contents = {
        "images": [
            {"filename": "Icon_1024x1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
                "filename": "Icon_1024x1024_dark.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def write_preview(name, image, dark=None):
    """Saves a small copy of an icon for Settings to show, with its dark version, over the dark
    the system would put behind it, for Dark Mode."""
    folder = ASSETS / f"IconPreview-{name}.imageset"
    folder.mkdir(exist_ok=True)
    image.resize((PREVIEW_SIZE, PREVIEW_SIZE), Image.LANCZOS).save(folder / "preview.png")
    images = [{"filename": "preview.png", "idiom": "universal"}]
    if dark is not None:
        backdrop = dark_backdrop(dark.size[0])
        backdrop.alpha_composite(dark)
        backdrop.convert("RGB").resize((PREVIEW_SIZE, PREVIEW_SIZE), Image.LANCZOS).save(folder / "preview_dark.png")
        images.append({
            "appearances": [{"appearance": "luminosity", "value": "dark"}],
            "filename": "preview_dark.png",
            "idiom": "universal",
        })
    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def dark_backdrop(size):
    """The system's dark behind an icon, near enough: a gentle fall from grey to near black."""
    top, bottom = DARK_BACKDROP
    fall = Image.linear_gradient("L").resize((size, size))
    backdrop = Image.new("RGBA", (size, size), top + (255,))
    backdrop.paste(bottom, mask=fall)
    return backdrop


if __name__ == "__main__":
    main()
