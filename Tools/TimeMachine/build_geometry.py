#!/usr/bin/env python3
"""Builds jpex/Maps/geo_TIMEMACHINE.json, the Time Machine's map geometry.

Units are the regions of geo_WORLD.json, except that the countries listed in PIECES are cut
into historical pieces (see Tools/TimeMachine/SPEC.md). Pieces are built from each country's
world outline intersected with its subdivisions from geo_<CC>.json; cut lines come from the
subdivision boundaries, and coastal or border slivers the subdivisions miss are grown into from
the nearest piece. Pieces described by a lon/lat polygon are authored below.

Everything is then noded together on a 0.001° grid and polygonised into a planar partition, so
neighbouring units share identical vertices. Arcs are maximal runs of boundary shared by the
same two units (b = null for coastline; edges on the ±180° / -90° map seams are not arcs).
Arcs are then Douglas-Peucker simplified with fixed endpoints (cut lines between pieces of one
country at CUT_SIMPLIFY; everything else only loses the collinear vertices cutting inserted),
and every unit's fill is rebuilt from its own arcs, so fills and borders agree exactly.
Lakes are filled; enclaves (Lesotho, San Marino, …) stay holes in their surrounding unit.
WORLD-GB is exactly GB-ENG + GB-SCT + GB-WLS + GB-NIR, so it is not a unit of its own.

Usage: /tmp/tmvenv/bin/python Tools/TimeMachine/build_geometry.py
"""

import json
import os
import re
import sys
import time
from collections import defaultdict

import shapely
from shapely.geometry import Point, Polygon, box
from shapely.geometry.polygon import orient
from shapely.ops import linemerge, polylabel, unary_union

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MAPS = os.path.join(ROOT, "jpex", "Maps")
CATALOG = os.path.join(ROOT, "jpex", "WorldCatalog.swift")
OUT = os.path.join(MAPS, "geo_TIMEMACHINE.json")

GRID = 0.001            # output precision and noding grid (degrees)
CUT_SIMPLIFY = 0.012    # Douglas-Peucker tolerance for internal cut lines (degrees)
WORLD_SIMPLIFY = 0.0006  # tolerance for other arcs: drops the collinear vertices cutting inserts
GROW_STEP = 0.02        # region-growing step when filling slivers the subdivisions miss
GROW_STEPS = 30
SLIVER = 0.004          # detached piece parts smaller than this (deg²) that touch another piece are merged

# --------------------------------------------------------------------------------------------
# Authored lon/lat polygons (approximate historical borders).

# Spanish protectorate in northern Morocco (1912-56), incl. Tangier. Southern border from the
# Atlantic near Arbaoua, north of Ouezzane, along the Ouergha watershed to the Moulouya, then
# down the Moulouya to its mouth. Seaward sides are generous; the world outline clips them.
MA_SPANISH = [
    (-7.2, 34.92), (-6.05, 34.92), (-5.95, 34.88), (-5.75, 34.88), (-5.55, 34.93),
    (-5.3, 34.92), (-5.05, 34.86), (-4.8, 34.8), (-4.55, 34.74), (-4.3, 34.76),
    (-4.05, 34.72), (-3.8, 34.68), (-3.55, 34.7), (-3.3, 34.72), (-3.1, 34.75),
    (-2.95, 34.85), (-2.75, 34.95), (-2.55, 35.03), (-2.4, 35.1), (-2.32, 35.14),
    (-2.25, 35.6), (-5.0, 36.3), (-6.2, 36.2), (-7.2, 35.8),
]

# British Southern Cameroons (1919-61) = today's North-West and South-West regions.
# Derived from geoBoundaries CMR ADM1 (simplified); outer sides overlap Nigeria and the sea.
CM_BRITISH = [
    (7.9, 4.63), (7.93, 4.82), (8.02, 5.03), (8.22, 5.39), (8.25, 5.51), (8.22, 5.8),
    (8.35, 6.16), (8.52, 6.36), (8.8, 6.59), (9.05, 6.88), (9.23, 7.0), (9.37, 7.22),
    (9.62, 7.36), (9.82, 7.54), (10.03, 7.63), (10.21, 7.64), (10.46, 7.75), (10.74, 7.74),
    (10.95, 7.63), (11.28, 7.35), (11.6, 7.01), (11.62, 6.93), (11.56, 6.86), (11.6, 6.81),
    (11.52, 6.61), (11.45, 6.6), (11.43, 6.53), (11.36, 6.51), (11.2, 6.54), (11.19, 6.3),
    (11.13, 6.24), (11.01, 6.25), (10.98, 6.08), (10.83, 6.02), (10.7, 6.03), (10.6, 5.84),
    (10.33, 5.81), (10.31, 5.74), (10.28, 5.73), (10.25, 5.77), (10.16, 5.78), (10.1, 5.74),
    (10.11, 5.68), (9.96, 5.58), (9.91, 5.39), (9.75, 5.3), (9.86, 5.06), (9.79, 5.04),
    (9.77, 4.98), (9.8, 4.92), (9.72, 4.84), (9.64, 4.65), (9.58, 4.65), (9.52, 4.55),
    (9.53, 4.43), (9.46, 4.32), (9.45, 4.24), (9.54, 4.22), (9.57, 4.17), (9.45, 4.08),
    (9.4, 3.97), (9.33, 3.92), (9.42, 3.89), (9.47, 3.91), (9.46, 3.99), (9.53, 3.97),
    (9.47, 4.06), (9.49, 4.1), (9.53, 4.03), (9.59, 4.01), (9.7, 4.09), (9.63, 3.95),
    (9.76, 3.94), (9.68, 3.92), (9.76, 3.82), (9.63, 3.87), (9.6, 3.81), (9.55, 3.81),
    (9.65, 3.64), (9.64, 3.55), (9.74, 3.47), (9.64, 3.4), (9.42, 3.32), (9.24, 3.32),
    (9.01, 3.4), (8.66, 3.58), (8.52, 3.71), (8.42, 3.91), (8.2, 3.99), (8.02, 4.16),
    (7.92, 4.39),
]

# South Yemen before 1990: today's Aden, Lahij, Abyan, Shabwah, Hadhramaut, al-Mahrah and
# Socotra governorates plus southern al-Dali' (the old border ran between al-Dali' and
# Qa'tabah). Derived from geoBoundaries YEM ADM1 (simplified).
YE_SOUTH = [
    (44.17, 12.02), (43.91, 11.99), (43.64, 12.07), (43.38, 12.03), (43.06, 12.15),
    (42.9, 12.31), (42.8, 12.52), (42.79, 12.7), (43.2, 12.72), (43.45, 12.69),
    (43.53, 12.68), (43.65, 12.95), (43.71, 12.97), (43.69, 13.08), (43.85, 13.12),
    (43.98, 13.07), (44.0, 13.13), (44.08, 13.09), (44.09, 13.16), (44.16, 13.15),
    (44.13, 13.2), (44.17, 13.25), (44.28, 13.2), (44.34, 13.23), (44.34, 13.34),
    (44.29, 13.37), (44.43, 13.39), (44.33, 13.47), (44.47, 13.53), (44.52, 13.6),
    (44.38, 13.64), (44.41, 13.72), (44.38, 13.78), (44.98, 13.78), (45.1, 13.86),
    (45.14, 13.98), (45.23, 13.97), (45.35, 14.06), (45.38, 13.91), (45.56, 13.9),
    (45.62, 13.83), (45.96, 14.02), (46.06, 14.25), (45.98, 14.34), (45.84, 14.32),
    (45.77, 14.59), (45.65, 14.6), (45.65, 14.72), (45.48, 14.73), (45.52, 14.97),
    (45.7, 15.2), (46.31, 15.61), (47.0, 16.37), (47.0, 16.95), (46.75, 17.28),
    (46.48, 17.25), (46.72, 17.48), (46.99, 17.55), (47.13, 17.83), (47.76, 18.59),
    (47.92, 18.71), (49.0, 19.21), (50.7, 19.38), (51.95, 19.6), (52.19, 19.57),
    (52.44, 19.41), (53.65, 16.9), (53.71, 16.68), (53.66, 16.4), (53.48, 16.18),
    (52.79, 15.91), (52.81, 15.51), (52.75, 15.34), (52.6, 15.17), (51.88, 14.78),
    (50.72, 14.46), (50.32, 14.26), (49.96, 14.22), (49.6, 14.09), (49.11, 13.62),
    (48.88, 13.48), (48.55, 13.4), (48.05, 13.38), (47.65, 13.11), (46.85, 12.85),
    (45.95, 12.8), (45.3, 12.22),
]
YE_SOCOTRA = [(52.0, 11.5), (55.0, 11.5), (55.0, 13.2), (52.0, 13.2)]

# North Vietnam 1954-76: north of the Ben Hai river / 17th parallel.
VN_NORTH = [
    (100.0, 17.0), (106.55, 17.0), (106.8, 17.03), (106.98, 16.98), (107.12, 17.02),
    (110.0, 17.02), (110.0, 25.0), (100.0, 25.0),
]

# Karafuto: Sakhalin south of 50°N, plus all the Kurils (Japanese 1875-1945).
RU_SAKHALIN_BOXES = [box(139.0, 40.0, 145.3, 50.0), box(145.3, 40.0, 160.0, 52.0)]

# --------------------------------------------------------------------------------------------
# Pieces. Each country: list of (piece suffix, name, source). Sources:
#   ("subs", [ids])         union of subdivisions from geo_<CC>.json
#   ("subs_in", ids, geom)  those subdivisions clipped to a lon/lat geometry
#   ("poly", geom)          a lon/lat geometry (clipped to the country)
#   ("disputed", id)        a disputed area of geo_WORLD.json
#   ("rest",)               whatever is left

def P(coords):
    return Polygon(coords)

PIECES = {
    "DE": [
        ("brandenburg", "Brandenburg", ("subs", ["DE-BB", "DE-BE"])),
        ("mecklenburg", "Mecklenburg", ("subs", ["DE-MV"])),
        ("saxony", "Saxony", ("subs", ["DE-SN"])),
        ("saxonyanhalt", "Saxony-Anhalt", ("subs", ["DE-ST"])),
        ("thuringia", "Thuringia", ("subs", ["DE-TH"])),
        ("bavaria", "Bavaria", ("subs", ["DE-BY"])),
        ("badenwurttemberg", "Baden-Württemberg", ("subs", ["DE-BW"])),
        ("hesse", "Hesse", ("subs", ["DE-HE"])),
        ("rhineland", "North Rhine-Westphalia", ("subs", ["DE-NW"])),
        ("palatinate", "Rhineland-Palatinate", ("subs", ["DE-RP", "DE-SL"])),
        ("lowersaxony", "Lower Saxony", ("subs", ["DE-NI", "DE-HB"])),
        ("holstein", "Schleswig-Holstein", ("subs", ["DE-SH", "DE-HH"])),
    ],
    "PL": [
        ("west", "Silesia and Pomerania", ("subs", ["PL-02", "PL-08", "PL-16", "PL-32", "PL-28"])),
        ("posen", "Posen and West Prussia", ("subs", ["PL-30", "PL-04", "PL-22", "PL-24"])),
        ("galicia", "Western Galicia", ("subs", ["PL-12", "PL-18"])),
        ("congress", "Congress Poland", ("subs", ["PL-10", "PL-14", "PL-06", "PL-20", "PL-26"])),
    ],
    "RU": [
        ("kaliningrad", "Kaliningrad", ("subs", ["RU-KGD"])),
        ("amur", "Amur and Primorye", ("subs", ["RU-PRI", "RU-AMU", "RU-YEV", "RU-KHA"])),
        ("tuva", "Tuva", ("subs", ["RU-TY"])),
        ("sakhalin", "South Sakhalin and the Kurils",
         ("subs_in", ["RU-SAK"], unary_union(RU_SAKHALIN_BOXES))),
        ("main", "Russia", ("rest",)),
    ],
    "LT": [
        ("klaipeda", "Klaipėda", ("subs", ["LT-KL"])),
        ("vilnius", "Vilnius", ("subs", ["LT-VL"])),
        ("main", "Lithuania", ("rest",)),
    ],
    "UA": [
        ("galicia", "Eastern Galicia", ("subs", ["UA-46", "UA-26", "UA-61"])),
        ("volhynia", "Volhynia", ("subs", ["UA-07", "UA-56"])),
        ("bukovina", "Northern Bukovina", ("subs", ["UA-77"])),
        ("transcarpathia", "Transcarpathia", ("subs", ["UA-21"])),
        ("main", "Ukraine", ("rest",)),
    ],
    "BY": [
        ("west", "Western Belarus", ("subs", ["BY-HR", "BY-BR"])),
        ("main", "Belarus", ("rest",)),
    ],
    "RO": [
        ("transylvania", "Transylvania", ("subs", [
            "RO-AB", "RO-AR", "RO-BH", "RO-BN", "RO-BV", "RO-CJ", "RO-CS", "RO-CV", "RO-HD",
            "RO-HR", "RO-MM", "RO-MS", "RO-SB", "RO-SJ", "RO-SM", "RO-TM"])),
        ("bukovina", "Southern Bukovina", ("subs", ["RO-SV"])),
        ("main", "Romania", ("rest",)),
    ],
    "BG": [
        ("dobruja", "Southern Dobruja", ("subs", ["BG-08", "BG-19"])),
        ("main", "Bulgaria", ("rest",)),
    ],
    "RS": [
        ("vojvodina", "Vojvodina", ("subs", ["RS-01", "RS-02", "RS-03", "RS-04", "RS-05", "RS-06", "RS-07"])),
        ("main", "Serbia", ("rest",)),
    ],
    "FR": [
        ("alsacelorraine", "Alsace-Lorraine", ("subs", ["FR-67", "FR-68", "FR-57"])),
        ("savoynice", "Savoy and Nice", ("subs", ["FR-73", "FR-74", "FR-06"])),
        ("main", "France", ("rest",)),
    ],
    "IT": [
        ("piedmont", "Piedmont and Liguria", ("subs", ["IT-21", "IT-42", "IT-23"])),
        ("sardinia", "Sardinia", ("subs", ["IT-88"])),
        ("lombardy", "Lombardy", ("subs", ["IT-25"])),
        ("venetia", "Venetia", ("subs", ["IT-34"])),
        ("friuli", "Friuli", ("subs", ["IT-36"])),
        ("trentino", "Trentino and South Tyrol", ("subs", ["IT-32"])),
        ("papal", "Papal States", ("subs", ["IT-62", "IT-55", "IT-57"])),
        ("emilia", "Emilia-Romagna", ("subs", ["IT-45"])),
        ("tuscany", "Tuscany", ("subs", ["IT-52"])),
        ("sicilies", "Two Sicilies", ("subs", ["IT-72", "IT-65", "IT-67", "IT-75", "IT-77", "IT-78", "IT-82"])),
    ],
    "GR": [
        ("old", "Old Greece", ("subs", ["GR-I", "GR-J", "GR-H", "GR-G", "GR-L", "GR-69"])),
        ("ionian", "Ionian Islands", ("subs", ["GR-F"])),
        ("thessaly", "Thessaly", ("subs", ["GR-E"])),
        ("north", "Northern Greece", ("subs", ["GR-D", "GR-C", "GR-B", "GR-A", "GR-K"])),
        ("crete", "Crete", ("subs", ["GR-M"])),
    ],
    # SPEC lists SA-12, but SA-12 is al-Jawf (never Hejaz); SA-11 al-Bahah was. Use SA-11.
    "SA": [
        ("hejaz", "Hejaz", ("subs", ["SA-02", "SA-03", "SA-07", "SA-11"])),
        ("hasa", "Al-Hasa", ("subs", ["SA-04"])),
        ("nejd", "Nejd", ("rest",)),
    ],
    "CN": [
        ("tibet", "Tibet", ("subs", ["CN-XZ"])),
        ("manchuria", "Manchuria", ("subs", ["CN-HL", "CN-JL", "CN-LN"])),
        ("main", "China", ("rest",)),
    ],
    "GH": [
        ("togoland", "British Togoland", ("subs", ["GH-TV", "GH-OT"])),
        ("main", "Ghana", ("rest",)),
    ],
    "US": [
        ("east", "Eastern States", ("subs", [
            "US-ME", "US-NH", "US-VT", "US-MA", "US-RI", "US-CT", "US-NY", "US-NJ", "US-PA",
            "US-DE", "US-MD", "US-DC", "US-VA", "US-WV", "US-NC", "US-SC", "US-GA", "US-AL",
            "US-MS", "US-TN", "US-KY", "US-OH", "US-IN", "US-IL", "US-MI", "US-WI"])),
        ("louisiana", "Louisiana Purchase", ("subs", [
            "US-LA", "US-AR", "US-MO", "US-IA", "US-MN", "US-ND", "US-SD", "US-NE", "US-KS",
            "US-OK", "US-MT", "US-WY", "US-CO"])),
        ("florida", "Florida", ("subs", ["US-FL"])),
        ("texas", "Texas", ("subs", ["US-TX"])),
        ("southwest", "Mexican Cession", ("subs", ["US-CA", "US-NV", "US-UT", "US-AZ", "US-NM"])),
        ("oregon", "Oregon Country", ("subs", ["US-WA", "US-OR", "US-ID"])),
        ("alaska", "Alaska", ("subs", ["US-AK"])),
        ("hawaii", "Hawaii", ("subs", ["US-HI"])),
    ],
    "VN": [
        ("north", "North Vietnam", ("poly", P(VN_NORTH))),
        ("south", "South Vietnam", ("rest",)),
    ],
    "YE": [
        ("south", "South Yemen", ("poly", unary_union([P(YE_SOUTH), P(YE_SOCOTRA)]))),
        ("north", "North Yemen", ("rest",)),
    ],
    "SO": [
        ("somaliland", "Somaliland", ("disputed", "somaliland")),
        ("italian", "Southern Somalia", ("rest",)),
    ],
    "MA": [
        ("spanish", "Northern Morocco", ("poly", P(MA_SPANISH))),
        ("main", "Morocco", ("rest",)),
    ],
    "CM": [
        ("british", "Southern Cameroons", ("poly", P(CM_BRITISH))),
        ("main", "Cameroon", ("rest",)),
    ],
}

# Names for world regions that are not countries in WorldCatalog.swift.
SUBREGION_NAMES = {
    "GB-ENG": "England", "GB-SCT": "Scotland", "GB-WLS": "Wales", "GB-NIR": "Northern Ireland",
}
# Sub-regions take their parent's colour.
def parent_code(code):
    return code.split("-")[0].split("~")[0]

PINNED = {"GB": "rose", "FR": "indigo", "ES": "amber", "PT": "sage", "NL": "coral", "BE": "plum",
          "DE": "slate", "IT": "teal", "RU": "olive", "US": "sky", "JP": "rust", "CN": "gold",
          "TR": "violet", "AT": "sand"}
PALETTE = ["rose", "coral", "amber", "sand", "olive", "sage", "teal", "sky", "indigo", "violet",
           "plum", "slate", "rust", "gold"]

# --------------------------------------------------------------------------------------------
# Parsing

NUM = re.compile(r"-?\d+(?:\.\d+)?(?:[eE]-?\d+)?")


def parse_rings(d):
    rings = []
    for sub in re.split(r"(?=M)", d.strip()):
        nums = [float(x) for x in NUM.findall(sub)]
        pts = list(zip(nums[0::2], nums[1::2]))
        if len(pts) >= 3:
            rings.append(pts)
    return rings


def path_geom(d):
    """Even-odd fill of an SVG path's rings."""
    g = None
    for r in parse_rings(d):
        p = Polygon(r).buffer(0)
        if p.is_empty:
            continue
        g = p if g is None else g.symmetric_difference(p)
    return g if g is not None else Polygon()


def polys(g):
    if g is None or g.is_empty:
        return []
    if g.geom_type == "Polygon":
        return [g]
    if g.geom_type == "MultiPolygon":
        return list(g.geoms)
    if g.geom_type == "GeometryCollection":
        return [p for x in g.geoms for p in polys(x)]
    return []


def fill_holes(g):
    return unary_union([Polygon(p.exterior) for p in polys(g)])


def clean(g):
    return unary_union(polys(g.buffer(0))) if g is not None else Polygon()


# --------------------------------------------------------------------------------------------
# Building pieces

def tile_country(code, W, pieces, subs, disputed):
    """Cuts W into pieces. Returns {piece_id: geometry} covering W."""
    seeds = {}
    for suffix, _name, src in pieces:
        kind = src[0]
        if kind == "subs":
            missing = [s for s in src[1] if s not in subs]
            if missing:
                raise SystemExit(f"{code}: missing subdivisions {missing}")
            seeds[suffix] = unary_union([subs[s] for s in src[1]])
        elif kind == "subs_in":
            seeds[suffix] = unary_union([subs[s] for s in src[1]]).intersection(src[2])
        elif kind == "poly":
            seeds[suffix] = src[1]
        elif kind == "disputed":
            seeds[suffix] = disputed[src[1]]
    rest = [s for s, _n, src in pieces if src[0] == "rest"]
    if rest:
        listed = unary_union(list(seeds.values()))
        base = unary_union(list(subs.values())) if subs and not any(
            src[0] in ("poly", "disputed") for _s, _n, src in pieces) else W
        seeds[rest[0]] = clean(base.difference(listed))

    order = [s for s, _n, _src in pieces]
    cores, taken = {}, Polygon()
    for s in order:
        c = clean(W.intersection(seeds[s]).difference(taken))
        cores[s] = c
        taken = unary_union([taken, c])
    left = clean(W.difference(taken))
    # Grow pieces into what the subdivisions missed, a small step at a time.
    for _ in range(GROW_STEPS):
        if left.is_empty or left.area < 1e-9:
            break
        zone = left.buffer(GROW_STEP * 1.5)
        for s in order:
            near = cores[s].intersection(zone)
            if near.is_empty:
                continue
            g = clean(near.buffer(GROW_STEP).intersection(left))
            if g.is_empty:
                continue
            cores[s] = clean(unary_union([cores[s], g]))
            left = clean(left.difference(g))
    # Anything still unclaimed (outlying islets) goes to the nearest piece.
    for part in polys(left):
        nearest = min(order, key=lambda s: cores[s].distance(part) if not cores[s].is_empty else 1e9)
        cores[nearest] = clean(unary_union([cores[nearest], part]))
    # Slivers: small detached parts of a piece that touch another piece go to the piece they
    # share most boundary with (islands stay where they are).
    for _pass in range(3):
        moved = False
        for s in order:
            parts = sorted(polys(cores[s]), key=lambda p: p.area, reverse=True)
            for part in parts[1:]:
                if part.area > SLIVER:
                    continue
                ring = part.buffer(GRID * 2)
                share = {o: cores[o].intersection(ring).area for o in order if o != s}
                best = max(share, key=share.get) if share else None
                if best is None or share[best] <= 0:
                    continue
                cores[s] = clean(cores[s].difference(part))
                cores[best] = clean(unary_union([cores[best], part]))
                moved = True
        if not moved:
            break
    # Tiny holes in a piece (specks of a neighbouring piece) are filled.
    for s in order:
        for p in polys(cores[s]):
            for hole in p.interiors:
                h = Polygon(hole)
                if h.area > SLIVER:
                    continue
                for o in order:
                    if o != s and cores[o].intersects(h):
                        cores[o] = clean(cores[o].difference(h))
                cores[s] = clean(unary_union([cores[s], h]))
    return {f"{code}~{s}": cores[s] for s in order}


# --------------------------------------------------------------------------------------------
# Output helpers

def fmt(v):
    s = f"{round(v, 3):.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def ring_d(coords, close):
    pts = [(fmt(x), fmt(y)) for x, y in coords]
    if close and len(pts) > 1 and pts[0] == pts[-1]:
        pts = pts[:-1]
    dedup = []
    for p in pts:
        if not dedup or dedup[-1] != p:
            dedup.append(p)
    s = "M" + "L".join(f"{x} {y}" for x, y in dedup)
    return s + ("Z" if close else "")


def fill_d(g):
    parts = []
    for p in polys(g):
        p = orient(p, 1.0)  # exterior counter-clockwise, holes clockwise (nonzero and even-odd agree)
        parts.append(ring_d(p.exterior.coords, True))
        for i in p.interiors:
            parts.append(ring_d(i.coords, True))
    return "".join(parts)


def is_seam(ln):
    xs = [x for x, _ in ln.coords]
    ys = [y for _, y in ln.coords]
    return (all(abs(abs(x) - 180) < 1e-6 for x in xs) or all(abs(y + 90) < 1e-6 for y in ys)
            or all(abs(y - 90) < 1e-6 for y in ys))


# --------------------------------------------------------------------------------------------

def main():
    t0 = time.time()
    world = json.load(open(os.path.join(MAPS, "geo_WORLD.json")))
    catalog = open(CATALOG, encoding="utf-8").read()
    names = dict(re.findall(r'worldPlace\("([A-Z]{2})", name: "([^"]+)"', catalog))
    shared = dict(re.findall(r'"([A-Z]{2})": "([A-Z]{2}-[0-9A-Z]+)"', catalog.split("static let sharedPlaceIDs")[1].split("= [")[1].split("]")[0]))
    for code, region in shared.items():
        SUBREGION_NAMES.setdefault(region, names.get(code, region))
    disputed = {d["id"]: path_geom(d["d"]) for d in world["disputed"]}

    units = {}       # id -> geometry
    meta = {}        # id -> dict(country, name, c)
    region_ids = [r["id"] for r in world["regions"]]
    geoms = {r["id"]: path_geom(r["d"]) for r in world["regions"]}

    # WORLD-GB is exactly the union of GB-ENG/SCT/WLS/NIR, so it is not a unit of its own.
    gb_parts = unary_union([geoms[k] for k in ("GB-ENG", "GB-SCT", "GB-WLS", "GB-NIR")])
    gb_rest = geoms["WORLD-GB"].difference(gb_parts).area
    assert gb_rest < 0.01, f"WORLD-GB has land outside the home nations: {gb_rest}"

    for r in world["regions"]:
        rid = r["id"]
        uid = rid.replace("WORLD-", "")
        if uid == "GB":
            continue
        W = fill_holes(geoms[rid])
        if uid in PIECES:
            sub_path = os.path.join(MAPS, f"geo_{uid}.json")
            subs = {}
            if os.path.exists(sub_path):
                sj = json.load(open(sub_path))
                subs = {s["id"]: clean(path_geom(s["d"])) for s in sj["regions"]}
            tiles = tile_country(uid, W, PIECES[uid], subs, disputed)
            for (suffix, name, _src) in PIECES[uid]:
                pid = f"{uid}~{suffix}"
                units[pid] = tiles[pid]
                meta[pid] = {"country": uid, "name": name, "c": None}
            print(f"  cut {uid} into {len(PIECES[uid])} pieces ({time.time() - t0:.0f}s)", file=sys.stderr)
        else:
            units[uid] = W
            name = names.get(uid) or SUBREGION_NAMES.get(uid) or uid
            meta[uid] = {"country": uid, "name": name, "c": r.get("c")}

    ids = list(units)
    print(f"{len(ids)} units; noding…", file=sys.stderr)

    # ---- Planar partition on the output grid.
    lines = [shapely.set_precision(units[k], GRID).boundary for k in ids]
    noded = shapely.union_all(lines, grid_size=GRID)
    edges = [e for e in getattr(noded, "geoms", [noded]) if e.length > 0]
    faces = [orient(f, 1.0) for f in shapely.polygonize(edges).geoms if f.area > 0]
    print(f"{len(edges)} edges, {len(faces)} faces ({time.time() - t0:.0f}s)", file=sys.stderr)

    geomlist = [units[k] for k in ids]
    areas = [g.area for g in geomlist]
    tree = shapely.STRtree(geomlist)
    face_unit = []
    for f in faces:
        pt = f.representative_point()
        cands = [i for i in tree.query(pt) if geomlist[i].covers(pt)]
        if not cands:
            # tiny faces from snapping: use the unit with the largest overlap
            cands = [i for i in tree.query(f) if geomlist[i].intersection(f).area > f.area * 0.5]
        face_unit.append(min(cands, key=lambda i: areas[i]) if cands else None)

    # Directed segment -> face, for side lookup.
    seg_face = {}
    for fi, f in enumerate(faces):
        for ring in [f.exterior] + list(f.interiors):
            cs = list(ring.coords)
            for a, b in zip(cs, cs[1:]):
                seg_face[(a, b)] = fi

    def sides(e):
        cs = list(e.coords)
        a, b = cs[0], cs[1]
        return seg_face.get((a, b)), seg_face.get((b, a))

    # Tiny unclaimed faces enclosed by land are slivers between data sources: give them to the
    # neighbour they share most boundary with.
    face_edges = defaultdict(list)
    for e in edges:
        l, r = sides(e)
        if l is not None:
            face_edges[l].append((e, r))
        if r is not None:
            face_edges[r].append((e, l))
    for _pass in range(3):
        changed = False
        for fi, f in enumerate(faces):
            if face_unit[fi] is not None or f.area > 2e-4:
                continue
            share = defaultdict(float)
            for e, other in face_edges[fi]:
                u = face_unit[other] if other is not None else None
                share[u] += e.length
            land = {u: v for u, v in share.items() if u is not None}
            if land and share.get(None, 0) == 0:
                face_unit[fi] = max(land, key=land.get)
                changed = True
        if not changed:
            break

    # Specks of a piece left inside a sibling piece by grid snapping join the sibling.
    for fi, f in enumerate(faces):
        u = face_unit[fi]
        if u is None or "~" not in ids[u] or f.area > 1e-4:
            continue
        around = {face_unit[o] if o is not None else None for _e, o in face_edges[fi]}
        around.discard(u)
        if len(around) == 1:
            v = around.pop()
            if v is not None and ids[v].split("~")[0] == ids[u].split("~")[0]:
                face_unit[fi] = v

    # ---- Arcs.
    pair_edges = defaultdict(list)
    seam_edges = defaultdict(list)
    for e in edges:
        l, r = sides(e)
        ul = face_unit[l] if l is not None else None
        ur = face_unit[r] if r is not None else None
        if ul == ur:
            continue
        if is_seam(e):
            for u in (ul, ur):
                if u is not None:
                    seam_edges[u].append(e)
            continue
        a, b = (ul, ur) if ur is None or (ul is not None and ids[ul] < ids[ur]) else (ur, ul)
        pair_edges[(a, b)].append(e)

    def tolerance(a, b):
        if b is not None and "~" in ids[a] and "~" in ids[b] and \
                ids[a].split("~")[0] == ids[b].split("~")[0]:
            return CUT_SIMPLIFY
        return WORLD_SIMPLIFY

    arc_lines = []   # (a, b, LineString)
    for (a, b), es in sorted(pair_edges.items(), key=lambda kv: (ids[kv[0][0]], ids[kv[0][1]] if kv[0][1] is not None else "")):
        merged = linemerge(es)
        tol = tolerance(a, b)
        for ln in getattr(merged, "geoms", [merged]):
            if tol > 0:
                s = ln.simplify(tol, preserve_topology=False)
                closed = ln.is_ring
                if s.is_empty or len(s.coords) < (4 if closed else 2) or \
                        (closed and Polygon(s.coords).area < Polygon(ln.coords).area * 0.5):
                    s = ln
                ln = s
            arc_lines.append((a, b, ln))
    arcs = [{"a": ids[a], "b": ids[b] if b is not None else None, "d": ring_d(ln.coords, False)}
            for a, b, ln in arc_lines]

    # ---- Unit fills, rebuilt from the (simplified) arcs so fills and borders agree exactly.
    unit_faces = defaultdict(list)
    for fi, u in enumerate(face_unit):
        if u is not None:
            unit_faces[u].append(faces[fi])
    unit_lines = defaultdict(list)
    for a, b, ln in arc_lines:
        unit_lines[a].append(ln)
        if b is not None:
            unit_lines[b].append(ln)
    out_units = []
    final = {}
    for i, k in enumerate(ids):
        g0 = unary_union(unit_faces[i]) if unit_faces[i] else Polygon()
        if g0.is_empty:
            print(f"  warning: {k} is empty", file=sys.stderr)
            continue
        ring_lines = unit_lines[i] + seam_edges[i]
        nod = shapely.union_all(ring_lines, grid_size=GRID)
        keep = []
        for f in shapely.polygonize(list(getattr(nod, "geoms", [nod]))).geoms:
            if f.area > 0 and g0.intersection(f).area >= 0.5 * f.area:
                keep.append(f)
        g = unary_union(keep) if keep else g0
        final[k] = g
        c = meta[k]["c"]
        if c is None or not g.buffer(0.05).contains(Point(c)):
            biggest = max(polys(g), key=lambda p: p.area)
            lp = polylabel(biggest, tolerance=0.02)
            c = [round(lp.x, 2), round(lp.y, 2)]
        out_units.append({"id": k, "country": meta[k]["country"], "name": meta[k]["name"],
                          "d": fill_d(g), "c": c})

    # ---- Colours per country (sub-regions share their parent's colour).
    groups = sorted({parent_code(u["country"]) for u in out_units})
    adj = defaultdict(set)
    for arc in arcs:
        if arc["b"] is None:
            continue
        pa, pb = parent_code(meta[arc["a"]]["country"]), parent_code(meta[arc["b"]]["country"])
        if pa != pb:
            adj[pa].add(pb)
            adj[pb].add(pa)
    # Near neighbours across narrow seas count too.
    group_geom = defaultdict(list)
    for k, g in final.items():
        group_geom[parent_code(meta[k]["country"])].append(g)
    gg = {k: unary_union(v) for k, v in group_geom.items()}
    gkeys = list(gg)
    gtree = shapely.STRtree([gg[k] for k in gkeys])
    near = defaultdict(set)
    for k in gkeys:
        for j in gtree.query(gg[k].buffer(1.5)):
            o = gkeys[j]
            if o == k:
                continue
            dist = gg[k].distance(gg[o])
            if dist < 0.6:
                adj[k].add(o)
            elif dist < 1.5:
                near[k].add(o)
    colors = dict(PINNED)
    usage = defaultdict(int)
    for v in colors.values():
        usage[v] += 1
    todo = [g for g in groups if g not in colors]
    while todo:
        # DSatur: most-constrained first.
        def sat(g):
            return (len({colors[n] for n in adj[g] if n in colors}), len(adj[g]))
        todo.sort(key=sat, reverse=True)
        g = todo.pop(0)
        hard = {colors[n] for n in adj[g] if n in colors}
        soft = {colors[m] for n in adj[g] for m in adj[n] if m in colors and m != g}
        soft |= {colors[n] for n in near[g] if n in colors}
        cands = [c for c in PALETTE if c not in hard and c not in soft] or \
                [c for c in PALETTE if c not in hard] or PALETTE
        pick = min(cands, key=lambda c: (usage[c], PALETTE.index(c)))
        colors[g] = pick
        usage[pick] += 1
    out_colors = {}
    for code in sorted(set(groups) | {u["country"] for u in out_units} | set(PINNED)):
        out_colors[code] = colors.get(code) or colors[parent_code(code)]

    data = {"units": out_units, "arcs": arcs, "colors": out_colors}
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    print(f"wrote {OUT}: {len(out_units)} units, {len(arcs)} arcs, "
          f"{os.path.getsize(OUT) / 1024:.0f} KB", file=sys.stderr)


if __name__ == "__main__":
    main()
