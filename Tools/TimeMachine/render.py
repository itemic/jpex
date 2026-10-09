#!/usr/bin/env python3
"""Renders a Time Machine era (or the geometry's pieces) to an equirectangular PNG.

Usage:
  render.py <eras.json> <era-id> <out.png> [--bbox lon0,lat0,lon1,lat1] [--geo geo_TIMEMACHINE.json]
  render.py --pieces <out.png> [--bbox lon0,lat0,lon1,lat1]

<eras.json> is either the merged jpex/TimeMachineEras.json ({"polities", "eras": [...]}) or a
fragment ({"polities", "era": {...}}). Resolution follows Tools/TimeMachine/SPEC.md:
  - a unit's assignment is assign[unit id], else assign[country code] for pieces
    ("DE" applies to every DE~ piece);
  - sub-regions (GB-SCT, FR-973, US-PR, …) without an assignment of their own take their
    parent's polity (assigned or implicit), labelled with their own name ("Scotland");
  - anything else unassigned is its implicit modern self: polity id = the country code,
    name from the geometry, colour = that code.
Borders: full between different polities, thin dashed between different labels of one polity,
none within a label. indigenous/unclaimed land is soft with no inner borders; contested is
hatched.
"""

import json
import os
import re
import sys
from collections import defaultdict

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import PathPatch
from matplotlib.path import Path
from matplotlib.colors import to_rgb

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GEO = os.path.join(ROOT, "jpex", "Maps", "geo_TIMEMACHINE.json")

OCEAN = "#0B1630"
COAST = "#9FB3D9"
# Mid-tone hues that read on dark navy.
NAMED = {
    "rose": "#E07A93", "coral": "#EF8B6B", "amber": "#E9A23B", "sand": "#D6C29C",
    "olive": "#A7AE55", "sage": "#86BC93", "teal": "#3FB5A8", "sky": "#64AEE6",
    "indigo": "#7F86E0", "violet": "#A97FDB", "plum": "#C878B4", "slate": "#8C9CB6",
    "rust": "#C8693F", "gold": "#E2CD58",
}
PIECE_COLORS = ["#E07A93", "#3FB5A8", "#E9A23B", "#7F86E0", "#86BC93", "#C878B4", "#EF8B6B",
                "#64AEE6", "#E2CD58", "#A97FDB", "#C8693F", "#A7AE55", "#D6C29C", "#8C9CB6"]

NUM = re.compile(r"-?\d+(?:\.\d+)?")


def parse_d(d):
    """SVG path data -> list of (points, closed)."""
    out = []
    for sub in re.split(r"(?=M)", d):
        if not sub.strip():
            continue
        nums = [float(x) for x in NUM.findall(sub)]
        out.append((list(zip(nums[0::2], nums[1::2])), sub.rstrip().endswith("Z")))
    return out


def fill_path(d):
    verts, codes = [], []
    for pts, _closed in parse_d(d):
        if len(pts) < 3:
            continue
        verts += pts + [pts[0]]
        codes += [Path.MOVETO] + [Path.LINETO] * (len(pts) - 1) + [Path.CLOSEPOLY]
    return Path(verts, codes) if verts else None


def line_path(d):
    verts, codes = [], []
    for pts, closed in parse_d(d):
        if len(pts) < 2:
            continue
        pts = pts + ([pts[0]] if closed else [])
        verts += pts
        codes += [Path.MOVETO] + [Path.LINETO] * (len(pts) - 1)
    return Path(verts, codes) if verts else None


def mix(c, other, t):
    a, b = to_rgb(c), to_rgb(other)
    return tuple(x * (1 - t) + y * t for x, y in zip(a, b))


def parent_of(unit_id):
    return unit_id.split("~")[0].split("-")[0]


def setup(bbox, width=2400):
    lon0, lat0, lon1, lat1 = bbox
    h = width * (lat1 - lat0) / (lon1 - lon0)
    fig = plt.figure(figsize=(width / 100, h / 100), dpi=100)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(lon0, lon1)
    ax.set_ylim(lat0, lat1)
    ax.set_aspect("auto")
    ax.axis("off")
    fig.patch.set_facecolor(OCEAN)
    ax.set_facecolor(OCEAN)
    return fig, ax


def load_era(path, era_id):
    data = json.load(open(path, encoding="utf-8"))
    polities = data.get("polities", {})
    if "eras" in data:
        eras = [e for e in data["eras"] if str(e["id"]) == str(era_id)]
        if not eras:
            raise SystemExit(f"no era {era_id} in {path}")
        era = eras[0]
    else:
        era = data["era"]
    return polities, era


def resolve(geo, polities, era):
    """unit id -> (polity id, label, polity dict)."""
    names = {u["id"]: u["name"] for u in geo["units"]}
    country_names = {}
    for u in geo["units"]:
        if "~" not in u["id"] and "-" not in u["id"]:
            country_names[u["id"]] = u["name"]
    catalog = os.path.join(ROOT, "jpex", "WorldCatalog.swift")
    if os.path.exists(catalog):
        for code, name in re.findall(r'worldPlace\("([A-Z]{2})", name: "([^"]+)"',
                                     open(catalog, encoding="utf-8").read()):
            country_names.setdefault(code, name)
    country_names.setdefault("GB", "United Kingdom")
    assign = era.get("assign", {})

    def implicit(code):
        return {"name": country_names.get(code, code), "flag": f"asset:world_flag_{code.lower()}",
                "color": code, "kind": "state"}

    def split(v):
        pid, _, label = v.partition("|")
        return pid, label or None

    out = {}
    for u in geo["units"]:
        uid = u["id"]
        base = uid.split("~")[0]
        if uid in assign:
            pid, label = split(assign[uid])
        elif "~" in uid and base in assign:
            pid, label = split(assign[base])
        elif "-" in uid:  # sub-region: parent's polity, own name
            parent = parent_of(uid)
            if parent in assign:
                pid, _ = split(assign[parent])
            else:
                pid = parent
            label = names[uid]
        else:
            pid, label = base, None
        pol = polities.get(pid) or (implicit(pid) if re.fullmatch(r"[A-Z]{2}", pid) else None)
        if pol is None:
            print(f"warning: polity {pid} (for {uid}) is not defined", file=sys.stderr)
            pol = {"name": pid, "color": "slate", "kind": "state"}
        out[uid] = (pid, label, pol)
    return out


def colour_of(pol, geo):
    c = pol.get("color", "slate")
    if c in NAMED:
        return NAMED[c]
    named = geo["colors"].get(c) or geo["colors"].get(parent_of(c))
    return NAMED.get(named, "#8C9CB6")


def render_era(eras_path, era_id, out, bbox, geo_path):
    geo = json.load(open(geo_path, encoding="utf-8"))
    polities, era = load_era(eras_path, era_id)
    res = resolve(geo, polities, era)
    fig, ax = setup(bbox)
    units = {u["id"]: u for u in geo["units"]}

    for u in geo["units"]:
        pid, label, pol = res[u["id"]]
        p = fill_path(u["d"])
        if p is None:
            continue
        col = colour_of(pol, geo)
        kind = pol.get("kind", "state")
        if kind in ("indigenous", "unclaimed"):
            fc = mix(col, OCEAN, 0.55)
            ax.add_patch(PathPatch(p, facecolor=fc, edgecolor=fc, lw=0.3, zorder=1))
        elif kind == "contested":
            ax.add_patch(PathPatch(p, facecolor=mix(col, OCEAN, 0.35), edgecolor="none", zorder=1))
            ax.add_patch(PathPatch(p, facecolor="none", edgecolor=mix(col, "white", 0.3),
                                   hatch="////", lw=0, zorder=1.1))
        else:
            ax.add_patch(PathPatch(p, facecolor=col, edgecolor=col, lw=0.3, zorder=1))

    lw_scale = max(0.6, min(2.5, 360 / (bbox[2] - bbox[0]) * 0.5))
    for a in geo["arcs"]:
        p = line_path(a["d"])
        if p is None:
            continue
        if a["b"] is None:
            ax.add_patch(PathPatch(p, facecolor="none", edgecolor=COAST, lw=0.35 * lw_scale,
                                   alpha=0.55, zorder=2))
            continue
        pa, la, pola = res[a["a"]]
        pb, lb, polb = res[a["b"]]
        soft = {pola.get("kind"), polb.get("kind")} & {"indigenous", "unclaimed"}
        if pa != pb:
            ax.add_patch(PathPatch(p, facecolor="none", edgecolor=(0.04, 0.07, 0.15),
                                   lw=(0.7 if soft else 1.1) * lw_scale, zorder=3,
                                   capstyle="round", joinstyle="round"))
        elif la != lb and not soft:
            ax.add_patch(PathPatch(p, facecolor="none", edgecolor=(0.05, 0.09, 0.18),
                                   lw=0.45 * lw_scale, linestyle=(0, (3, 2)), alpha=0.8, zorder=3))

    # Labels: one per (polity, label) group, at the largest unit's label point.
    groups = defaultdict(list)
    for uid, (pid, label, pol) in res.items():
        groups[(pid, label)].append(uid)

    def area(uid):
        x0 = min_x = 1e9
        tot = 0.0
        for pts, _c in parse_d(units[uid]["d"]):
            s = 0.0
            for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]):
                s += x1 * y2 - x2 * y1
            tot += s / 2
        return abs(tot)

    for (pid, label), uids in groups.items():
        big = max(uids, key=area)
        if area(big) < 0.3 * ((bbox[2] - bbox[0]) / 360) ** 2:
            continue
        x, y = units[big]["c"]
        if not (bbox[0] <= x <= bbox[2] and bbox[1] <= y <= bbox[3]):
            continue
        pol = res[big][2]
        text = label or pol["name"]
        sub = pol["name"] if label and label != pol["name"] else None
        ax.text(x, y, text, ha="center", va="center", fontsize=6.5 * lw_scale ** 0.5,
                color="white", zorder=5, fontweight="bold",
                path_effects=[matplotlib.patheffects.withStroke(linewidth=1.6, foreground=(0, 0, 0, 0.55))])
        if sub:
            ax.text(x, y - 1.6 / lw_scale, sub, ha="center", va="center",
                    fontsize=4.8 * lw_scale ** 0.5, color=(1, 1, 1, 0.8), zorder=5,
                    path_effects=[matplotlib.patheffects.withStroke(linewidth=1.2, foreground=(0, 0, 0, 0.5))])

    # Event pins and legend.
    legend = []
    for i, ev in enumerate(era.get("events", []), 1):
        x, y = ev["at"]
        ax.plot([x], [y], "o", ms=9, color="#FFFFFF", mec="#0B1630", mew=1.5, zorder=6)
        ax.text(x, y, str(i), ha="center", va="center", fontsize=6, color="#0B1630",
                fontweight="bold", zorder=7)
        legend.append(f"{i}. {ev.get('year', '')}  {ev.get('title', '')}")
    head = f"{era.get('year', era.get('id'))} — {era.get('title', '')}"
    ax.text(0.01, 0.985, head, transform=ax.transAxes, ha="left", va="top", fontsize=16,
            color="white", fontweight="bold", zorder=8)
    if era.get("summary"):
        ax.text(0.01, 0.955, era["summary"], transform=ax.transAxes, ha="left", va="top",
                fontsize=10, color=(1, 1, 1, 0.8), zorder=8)
    if legend:
        ax.text(0.01, 0.02, "\n".join(legend), transform=ax.transAxes, ha="left", va="bottom",
                fontsize=9, color="white", zorder=8, linespacing=1.4,
                bbox=dict(boxstyle="round,pad=0.6", fc=(0.04, 0.07, 0.15, 0.85), ec=(1, 1, 1, 0.2)))
    fig.savefig(out, facecolor=OCEAN)
    print(f"wrote {out}")


def render_pieces(out, bbox, geo_path):
    geo = json.load(open(geo_path, encoding="utf-8"))
    fig, ax = setup(bbox)
    n = 0
    for u in geo["units"]:
        p = fill_path(u["d"])
        if p is None:
            continue
        if "~" in u["id"]:
            col = PIECE_COLORS[n % len(PIECE_COLORS)]
            n += 1
        else:
            col = "#3A4560"
        ax.add_patch(PathPatch(p, facecolor=col, edgecolor="none", zorder=1))
    for a in geo["arcs"]:
        p = line_path(a["d"])
        if p is None:
            continue
        cut = a["b"] and "~" in a["a"] and "~" in a["b"] and a["a"].split("~")[0] == a["b"].split("~")[0]
        ax.add_patch(PathPatch(p, facecolor="none",
                               edgecolor="white" if cut else ("#9FB3D9" if a["b"] is None else "#111827"),
                               lw=0.8 if cut else 0.5, zorder=3))
    for u in geo["units"]:
        if "~" in u["id"]:
            x, y = u["c"]
            if bbox[0] <= x <= bbox[2] and bbox[1] <= y <= bbox[3]:
                ax.text(x, y, u["id"].split("~")[1], ha="center", va="center", fontsize=7,
                        color="black", zorder=5)
    fig.savefig(out, facecolor=OCEAN)
    print(f"wrote {out}")


def main(argv):
    import matplotlib.patheffects  # noqa: F401
    bbox = (-180.0, -90.0, 180.0, 90.0)
    geo = GEO
    args = []
    i = 0
    while i < len(argv):
        if argv[i] == "--bbox":
            bbox = tuple(float(x) for x in argv[i + 1].split(","))
            i += 2
        elif argv[i] == "--geo":
            geo = argv[i + 1]
            i += 2
        else:
            args.append(argv[i])
            i += 1
    if args and args[0] == "--pieces":
        render_pieces(args[1], bbox, geo)
    elif len(args) == 3:
        render_era(args[0], args[1], args[2], bbox, geo)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main(sys.argv[1:])
