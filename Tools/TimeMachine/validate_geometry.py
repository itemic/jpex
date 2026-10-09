#!/usr/bin/env python3
"""Checks jpex/Maps/geo_TIMEMACHINE.json.

  - every geo_WORLD region (except WORLD-GB, which is exactly GB-ENG+SCT+WLS+NIR) is a unit,
    or is cut into pieces whose union matches it (symmetric difference < 0.5% of the country);
  - pieces of one country do not overlap; units do not overlap noticeably;
  - every unit's boundary is covered by arcs that reference it (seams on ±180° / -90° excepted);
  - every arc references known units, a != b, and lies on the boundary of both its units;
  - every unit has a name, a country, a label point inside it, and a colour for its country;
  - neighbouring countries have different colours;
  - file size.

Usage: /tmp/tmvenv/bin/python Tools/TimeMachine/validate_geometry.py [geo_TIMEMACHINE.json]
"""

import json
import os
import re
import sys
from collections import defaultdict

import shapely
from shapely.geometry import LineString, MultiLineString, Point, Polygon
from shapely.ops import unary_union

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MAPS = os.path.join(ROOT, "jpex", "Maps")
NAMED = {"rose", "coral", "amber", "sand", "olive", "sage", "teal", "sky", "indigo", "violet",
         "plum", "slate", "rust", "gold"}
NUM = re.compile(r"-?\d+(?:\.\d+)?(?:[eE]-?\d+)?")


def rings(d):
    out = []
    for sub in re.split(r"(?=M)", d):
        nums = [float(x) for x in NUM.findall(sub)]
        pts = list(zip(nums[0::2], nums[1::2]))
        if pts:
            out.append((pts, sub.rstrip().endswith("Z")))
    return out


def area_geom(d):
    g = None
    for pts, _ in rings(d):
        if len(pts) < 3:
            continue
        p = Polygon(pts).buffer(0)
        g = p if g is None else g.symmetric_difference(p)
    return g if g is not None else Polygon()


def line_geom(d):
    ls = []
    for pts, closed in rings(d):
        if closed:
            pts = pts + [pts[0]]
        if len(pts) >= 2:
            ls.append(LineString(pts))
    return MultiLineString(ls)


def parent(code):
    return code.split("~")[0].split("-")[0]


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(MAPS, "geo_TIMEMACHINE.json")
    data = json.load(open(path, encoding="utf-8"))
    world = json.load(open(os.path.join(MAPS, "geo_WORLD.json"), encoding="utf-8"))
    errors, warnings = [], []
    size = os.path.getsize(path)

    units = {u["id"]: u for u in data["units"]}
    geoms = {k: area_geom(u["d"]) for k, u in units.items()}
    print(f"{len(units)} units, {len(data['arcs'])} arcs, {size / 1024:.0f} KB")
    if size > 1.5 * 1024 * 1024:
        warnings.append(f"file is {size / 1024:.0f} KB (> 1.5 MB)")

    # Coverage of geo_WORLD.
    by_country = defaultdict(list)
    for k in units:
        if "~" in k:
            by_country[k.split("~")[0]].append(k)
    worst = 0.0
    for r in world["regions"]:
        uid = r["id"].replace("WORLD-", "")
        if uid == "GB":
            continue
        W = unary_union([Polygon(p.exterior) for p in getattr(area_geom(r["d"]), "geoms", [area_geom(r["d"])])])
        if uid in units:
            continue
        if uid not in by_country:
            errors.append(f"world region {uid} is missing")
            continue
        pieces = [geoms[k] for k in by_country[uid]]
        U = unary_union(pieces)
        sd = U.symmetric_difference(W).area / W.area
        worst = max(worst, sd)
        if sd > 0.005:
            errors.append(f"{uid}: pieces differ from the country by {sd:.2%}")
        tot = sum(p.area for p in pieces)
        if (tot - U.area) / W.area > 0.001:
            errors.append(f"{uid}: pieces overlap ({(tot - U.area) / W.area:.3%})")
        for k in by_country[uid]:
            if geoms[k].is_empty:
                errors.append(f"{k} is empty")
    print(f"pieces tile their countries: worst symmetric difference {worst:.3%}")

    # Overlaps between all units.
    ids = list(geoms)
    tree = shapely.STRtree([geoms[k] for k in ids])
    overlaps = 0
    for i, k in enumerate(ids):
        for j in tree.query(geoms[k]):
            if j > i:
                a = geoms[k].intersection(geoms[ids[j]]).area
                if a > 1e-4:
                    overlaps += 1
                    warnings.append(f"{k} overlaps {ids[j]} by {a:.4f} deg²")
    print(f"unit overlaps > 1e-4 deg²: {overlaps}")

    # Arcs.
    unit_arcs = defaultdict(list)
    for a in data["arcs"]:
        for key in ("a", "b"):
            if a[key] is not None and a[key] not in units:
                errors.append(f"arc references unknown unit {a[key]}")
        if a["a"] == a["b"]:
            errors.append(f"arc with a == b ({a['a']})")
        ln = line_geom(a["d"])
        unit_arcs[a["a"]].append(ln)
        if a["b"] is not None:
            unit_arcs[a["b"]].append(ln)
            for key in ("a", "b"):
                g = geoms.get(a[key])
                if g is not None and ln.length > 0:
                    off = ln.difference(g.boundary.buffer(0.002)).length / ln.length
                    if off > 0.01:
                        errors.append(f"arc {a['a']}|{a['b']} strays {off:.1%} off {a[key]}'s boundary")
    seam_tol = 1e-6
    uncovered_units = 0
    for k, g in geoms.items():
        cover = unary_union(unit_arcs[k]).buffer(0.0015) if unit_arcs[k] else Polygon()
        rest = g.boundary.difference(cover)
        # ignore the map's seams
        parts = [p for p in getattr(rest, "geoms", [rest]) if not p.is_empty]
        bad = 0.0
        for p in parts:
            xs = [c[0] for c in p.coords]
            ys = [c[1] for c in p.coords]
            if all(abs(abs(x) - 180) < 0.002 for x in xs) or all(abs(y + 90) < 0.002 for y in ys):
                continue
            bad += p.length
        if bad > 0.01 * max(g.boundary.length, 1e-9) and bad > 0.01:
            uncovered_units += 1
            errors.append(f"{k}: {bad:.3f}° of boundary not covered by its arcs")
    print(f"units whose boundary is not covered by arcs: {uncovered_units}")

    # Unit fields and colours.
    colors = data.get("colors", {})
    for k, u in units.items():
        if not u.get("name"):
            errors.append(f"{k} has no name")
        if not u.get("country"):
            errors.append(f"{k} has no country")
        if "~" in k and u["country"] != k.split("~")[0]:
            errors.append(f"{k} has country {u['country']}")
        c = u.get("c")
        if not c or not geoms[k].buffer(0.1).contains(Point(c)):
            warnings.append(f"{k}: label point {c} is outside the unit")
        if colors.get(u["country"]) not in NAMED:
            errors.append(f"{k}: no colour for {u['country']}")
    bad_col = set()
    for a in data["arcs"]:
        if a["b"] is None:
            continue
        pa, pb = parent(units[a["a"]]["country"]), parent(units[a["b"]]["country"])
        if pa != pb and colors.get(pa) == colors.get(pb):
            bad_col.add(tuple(sorted((pa, pb))))
    for pa, pb in sorted(bad_col):
        errors.append(f"neighbours {pa} and {pb} share colour {colors.get(pa)}")
    print(f"neighbouring countries sharing a colour: {len(bad_col)}")

    for w in warnings:
        print("warning:", w)
    for e in errors:
        print("ERROR:", e)
    print("OK" if not errors else f"{len(errors)} errors")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
