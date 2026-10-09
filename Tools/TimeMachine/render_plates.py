#!/usr/bin/env python3
"""Render Time Machine's prehistoric plate model (jpex/TimeMachinePlates.json).

Applies exactly the rotation math in SPEC.md:
  * a point (lon, lat) is the unit vector v = (cos lat cos lon, cos lat sin lon, sin lat);
  * a keyframe {lat, lon, angle} is a finite rotation about the Euler pole (lat, lon) by
    `angle` degrees, positive counter-clockwise looking down on the pole (Rodrigues);
  * between keyframes the rotation is interpolated by converting each keyframe's axis-angle to
    a unit quaternion and slerping along the shorter arc; outside the keyframes it clamps.

Draws the world at a given age (Ma) as an orthographic globe (configurable centre) next to an
equirectangular whole-world map, each plate filled in its own colour, with the labels and
events of the moment.

Usage:
  render_plates.py                      # renders 0 50 100 150 200 250 into renders/
  render_plates.py 66 180 --center 0,20 # chosen ages, globe centred at lat 0, lon 20
  render_plates.py 250 --out /tmp/x.png
"""
import argparse
import json
import math
import os
import re
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
WORLD = os.path.join(ROOT, "jpex", "Maps", "geo_WORLD.json")
PLATES = os.path.join(ROOT, "jpex", "TimeMachinePlates.json")
RENDERS = os.path.join(HERE, "renders")

# ---------------------------------------------------------------------------------------------
# Rotation math (must match the app)
# ---------------------------------------------------------------------------------------------


def lonlat_to_vec(lon, lat):
    lon = np.radians(np.asarray(lon, dtype=float))
    lat = np.radians(np.asarray(lat, dtype=float))
    return np.stack([np.cos(lat) * np.cos(lon), np.cos(lat) * np.sin(lon), np.sin(lat)], axis=-1)


def vec_to_lonlat(v):
    v = np.asarray(v, dtype=float)
    lon = np.degrees(np.arctan2(v[..., 1], v[..., 0]))
    lat = np.degrees(np.arcsin(np.clip(v[..., 2], -1.0, 1.0)))
    return lon, lat


def rodrigues(v, pole_lat, pole_lon, angle_deg):
    """Rotate unit vector(s) v about the Euler pole by angle (degrees), per SPEC.md."""
    k = lonlat_to_vec(pole_lon, pole_lat)
    th = math.radians(angle_deg)
    v = np.asarray(v, dtype=float)
    kxv = np.cross(np.broadcast_to(k, v.shape), v)
    kdv = (v * k).sum(axis=-1)
    return v * math.cos(th) + kxv * math.sin(th) + np.outer(kdv, k).reshape(v.shape) * (1 - math.cos(th))


def axis_angle_to_quat(pole_lat, pole_lon, angle_deg):
    k = lonlat_to_vec(pole_lon, pole_lat)
    h = math.radians(angle_deg) / 2.0
    return np.array([math.cos(h), *(k * math.sin(h))])


def quat_to_axis_angle(q):
    """Unit quaternion -> (lat, lon, angle) with angle in [0, 180]."""
    q = np.asarray(q, dtype=float)
    q = q / np.linalg.norm(q)
    if q[0] < 0:
        q = -q
    w = min(1.0, q[0])
    s = math.sqrt(max(0.0, 1.0 - w * w))
    angle = math.degrees(2.0 * math.acos(w))
    if s < 1e-12 or angle < 1e-9:
        return 90.0, 0.0, 0.0
    axis = q[1:] / s
    lon, lat = vec_to_lonlat(axis)
    return float(lat), float(lon), angle


def slerp(q0, q1, t):
    q0 = np.asarray(q0, dtype=float)
    q1 = np.asarray(q1, dtype=float)
    d = float(np.dot(q0, q1))
    if d < 0.0:  # shorter arc
        q1 = -q1
        d = -d
    if d > 0.9995:
        q = q0 + t * (q1 - q0)
        return q / np.linalg.norm(q)
    th0 = math.acos(d)
    s0 = math.sin((1 - t) * th0) / math.sin(th0)
    s1 = math.sin(t * th0) / math.sin(th0)
    return s0 * q0 + s1 * q1


def rotation_at(keyframes, ma):
    """(lat, lon, angle) of a plate's rotation at `ma`, slerping between keyframes."""
    ks = keyframes
    if ma <= ks[0]["ma"]:
        k = ks[0]
        return k["lat"], k["lon"], k["angle"]
    if ma >= ks[-1]["ma"]:
        k = ks[-1]
        return k["lat"], k["lon"], k["angle"]
    for a, b in zip(ks, ks[1:]):
        if a["ma"] <= ma <= b["ma"]:
            t = (ma - a["ma"]) / (b["ma"] - a["ma"])
            qa = axis_angle_to_quat(a["lat"], a["lon"], a["angle"])
            qb = axis_angle_to_quat(b["lat"], b["lon"], b["angle"])
            return quat_to_axis_angle(slerp(qa, qb, t))
    raise ValueError(ma)


# ---------------------------------------------------------------------------------------------
# Geometry
# ---------------------------------------------------------------------------------------------

_NUM_PAIR = re.compile(r"(-?\d+(?:\.\d+)?)[ ,](-?\d+(?:\.\d+)?)")


def parse_rings(d):
    rings = []
    for sub in d.split("M")[1:]:
        pts = [(float(a), float(b)) for a, b in _NUM_PAIR.findall(sub)]
        if len(pts) >= 3:
            rings.append(np.array(pts))
    return rings


def unit_id(region_id):
    return region_id[6:] if region_id.startswith("WORLD-") else region_id


def load_world():
    with open(WORLD) as f:
        world = json.load(f)
    return {unit_id(r["id"]): parse_rings(r["d"]) for r in world["regions"]}


def load_plates(path=PLATES):
    with open(path) as f:
        return json.load(f)


def ring_area_lonlat(r):
    x, y = r[:, 0], r[:, 1]
    return 0.5 * abs(np.dot(x, np.roll(y, -1)) - np.dot(y, np.roll(x, -1)))


def densify(r, step=1.0):
    """Insert points so that no segment is longer than `step` degrees (lon/lat space)."""
    out = []
    n = len(r)
    for i in range(n):
        a, b = r[i], r[(i + 1) % n]
        out.append(a)
        dist = max(abs(b[0] - a[0]), abs(b[1] - a[1]))
        if dist > step:
            m = int(dist // step)
            for j in range(1, m + 1):
                out.append(a + (b - a) * j / (m + 1))
    return np.array(out)


# ---------------------------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------------------------

PLATE_COLORS = {
    "NA": "#d9822b", "SA": "#2f9e44", "AF": "#c9a227", "AR": "#e8590c", "EU": "#4263eb",
    "IN": "#e64980", "MG": "#9c36b5", "AU": "#c2255c", "AN": "#99a9b8", "ZE": "#0ca678",
    "PAC": "#fab005",
}
EXTRA_COLORS = ["#845ef7", "#20c997", "#ff6b6b", "#74c0fc", "#ffd43b", "#a9e34b"]


def plate_color(pid, i):
    return PLATE_COLORS.get(pid, EXTRA_COLORS[i % len(EXTRA_COLORS)])


def period_at(model, ma):
    for p in model.get("periods", []):
        if p["end"] <= ma <= p["start"]:
            return p
    return None


def visible_units(model, ma):
    emerged = model.get("emerged", {})
    return {u for p in model["plates"] for u in p["units"] if emerged.get(u, 1e9) >= ma}


def rotate_lonlat(lon, lat, rot):
    v = lonlat_to_vec(lon, lat)
    lat_p, lon_p, ang = rot
    if abs(ang) > 1e-12:
        v = rodrigues(v.reshape(-1, 3), lat_p, lon_p, ang).reshape(v.shape)
    return v


def ortho_project(v, center_lat, center_lon):
    c = lonlat_to_vec(center_lon, center_lat)
    east = np.array([-math.sin(math.radians(center_lon)), math.cos(math.radians(center_lon)), 0.0])
    north = np.cross(c, east)
    x, y, z = (v * east).sum(-1), (v * north).sum(-1), (v * c).sum(-1)
    # points on the far side are pushed onto the limb, which clips polygons well enough
    behind = z < 0
    r = np.hypot(x, y)
    r[r == 0] = 1
    x = np.where(behind, x / r, x)
    y = np.where(behind, y / r, y)
    return x, y, z


_PLATE_SHAPES = {}


def plate_shape(world, units):
    """Present-day land of `units` as one (prepared) shapely geometry in lon/lat."""
    key = tuple(sorted(units))
    if key not in _PLATE_SHAPES:
        import shapely
        from shapely.geometry import Polygon as SPolygon
        from shapely.ops import unary_union

        polys = []
        for u in units:
            for ring in world.get(u, []):
                p = SPolygon(ring)
                if not p.is_valid:
                    p = p.buffer(0)
                if not p.is_empty:
                    polys.append(p)
        g = unary_union(polys) if polys else None
        if g is not None:
            shapely.prepare(g)
        _PLATE_SHAPES[key] = g
    return _PLATE_SHAPES[key]


def inverse_rotate(v, rot):
    lat_p, lon_p, ang = rot
    if abs(ang) < 1e-12:
        return v
    return rodrigues(v, lat_p, lon_p, -ang)


def paint(world, model, rots, vis, v, rgba_out):
    """Colour each point v (N,3, palaeo positions) by the plate whose present-day land it is on.

    Raster fill: robust at the poles and the antimeridian, where rotated outlines are awkward.
    """
    import shapely
    from matplotlib.colors import to_rgba

    for i, plate in enumerate(model["plates"]):
        units = [u for u in plate["units"] if u in vis]
        if not units:
            continue
        g = plate_shape(world, units)
        if g is None:
            continue
        pv = inverse_rotate(v, rots[plate["id"]])
        lon, lat = vec_to_lonlat(pv)
        minx, miny, maxx, maxy = g.bounds
        cand = (lon >= minx) & (lon <= maxx) & (lat >= miny) & (lat <= maxy)
        idx = np.nonzero(cand)[0]
        if len(idx) == 0:
            continue
        inside = shapely.contains_xy(g, lon[idx], lat[idx])
        rgba_out[idx[inside]] = to_rgba(plate_color(plate["id"], i))


def render(model, world, ma, out, center=None, title_extra="", extent=None):
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.colors import to_rgba
    from matplotlib.patches import Circle

    vis = visible_units(model, ma)
    rots = {pid: rotation_at(k, ma) for pid, k in model["rotations"].items()}

    if center is None:
        # centre the globe on Africa's reconstructed centre
        v = rotate_lonlat(np.array([20.0]), np.array([0.0]), rots.get("AF", (90, 0, 0)))
        clon, clat = vec_to_lonlat(v[0])
        center = (float(clat), float(clon))
    clat, clon = center

    fig = plt.figure(figsize=(17, 7.2), facecolor="#0b1020")
    ax1 = fig.add_axes([0.01, 0.04, 0.36, 0.86])
    ax2 = fig.add_axes([0.39, 0.10, 0.60, 0.74])
    for ax in (ax1, ax2):
        ax.set_facecolor("#0b1020")
        ax.set_xticks([])
        ax.set_yticks([])
        for s in ax.spines.values():
            s.set_visible(False)
    ocean = to_rgba("#1d3557")

    # orthographic globe
    n = 560
    gx, gy = np.meshgrid(np.linspace(-1, 1, n), np.linspace(1, -1, n))
    rr = gx ** 2 + gy ** 2
    on = rr <= 1
    c = lonlat_to_vec(clon, clat)
    east = np.array([-math.sin(math.radians(clon)), math.cos(math.radians(clon)), 0.0])
    north = np.cross(c, east)
    gz = np.sqrt(np.clip(1 - rr, 0, 1))
    vg = (gx[on, None] * east + gy[on, None] * north + gz[on, None] * c)
    img = np.zeros((n, n, 4))
    col = np.tile(ocean, (len(vg), 1))
    paint(world, model, rots, vis, vg, col)
    shade = 0.55 + 0.45 * gz[on]  # soft limb darkening
    col[:, :3] *= shade[:, None]
    img[on] = col
    ax1.imshow(img, extent=(-1, 1, -1, 1), zorder=0, interpolation="bilinear")
    ax1.add_patch(Circle((0, 0), 1.0, facecolor="none", edgecolor="#8fb8de", lw=1.0, zorder=3))
    ax1.set_xlim(-1.05, 1.05)
    ax1.set_ylim(-1.05, 1.05)
    ax1.set_aspect("equal")

    # flat map
    x0, x1, y0, y1 = extent if extent else (-180, 180, -90, 90)
    w = 1000
    h = max(2, int(w * (y1 - y0) / (x1 - x0)))
    lo, la = np.meshgrid(np.linspace(x0, x1, w), np.linspace(y1, y0, h))
    vf = lonlat_to_vec(lo.ravel(), la.ravel())
    colf = np.tile(ocean, (len(vf), 1))
    paint(world, model, rots, vis, vf, colf)
    ax2.imshow(colf.reshape(h, w, 4), extent=(x0, x1, y0, y1), zorder=0, interpolation="nearest")
    ax2.set_xlim(x0, x1)
    ax2.set_ylim(y0, y1)
    ax2.set_aspect("equal")

    # graticule (palaeo latitude/longitude)
    for la0 in range(-60, 61, 30):
        lo_ = np.linspace(-180, 180, 361)
        x, y, z = ortho_project(lonlat_to_vec(lo_, np.full_like(lo_, la0)), clat, clon)
        x = np.where(z < 0, np.nan, x)
        ax1.plot(x, y, color="#ffffff", lw=0.8 if la0 == 0 else 0.3, alpha=0.35, zorder=1)
        ax2.axhline(la0, color="#ffffff", lw=0.8 if la0 == 0 else 0.3, alpha=0.35, zorder=1)
    for lo0 in range(-180, 180, 30):
        la_ = np.linspace(-90, 90, 181)
        x, y, z = ortho_project(lonlat_to_vec(np.full_like(la_, lo0), la_), clat, clon)
        x = np.where(z < 0, np.nan, x)
        ax1.plot(x, y, color="#ffffff", lw=0.3, alpha=0.35, zorder=1)
        ax2.axvline(lo0, color="#ffffff", lw=0.3, alpha=0.35, zorder=1)
    legend = [(p["name"], plate_color(p["id"], i)) for i, p in enumerate(model["plates"])]

    # labels
    plate_ids = {p["id"] for p in model["plates"]}
    for lab in model.get("labels", []):
        if not (lab["to"] <= ma <= lab["from"]):
            continue
        if lab["plate"] not in plate_ids:
            continue
        v = rotate_lonlat(np.array([lab["at"][0]]), np.array([lab["at"][1]]), rots[lab["plate"]])
        lon, lat = vec_to_lonlat(v[0])
        big = lab["name"] in ("Pangaea", "Panthalassa", "Tethys Ocean", "Laurasia", "Gondwana",
                              "Atlantic Ocean")
        style = dict(color="white", ha="center", va="center", zorder=5,
                     fontsize=11 if big else 7, fontweight="bold" if big else "normal",
                     style="italic" if "Ocean" in lab["name"] or lab["name"] == "Panthalassa" else "normal")
        ax2.text(float(lon), float(lat), lab["name"], **style)
        x, y, z = ortho_project(v, clat, clon)
        if z[0] > 0:
            ax1.text(float(x[0]), float(y[0]), lab["name"], **style)

    # events within a window of the current age
    for ev in model.get("events", []):
        win = max(2.0, ev["ma"] * 0.08)
        if abs(ev["ma"] - ma) > win:
            continue
        v = rotate_lonlat(np.array([ev["at"][0]]), np.array([ev["at"][1]]), rots[ev["plate"]])
        lon, lat = vec_to_lonlat(v[0])
        ax2.plot(float(lon), float(lat), marker="*", color="#ffec99", ms=14, mec="black", zorder=6)
        ax2.text(float(lon) + 4, float(lat) - 5, f"{ev['title']} ({ev['ma']} Ma)", color="#ffec99",
                 fontsize=8, zorder=6)
        x, y, z = ortho_project(v, clat, clon)
        if z[0] > 0:
            ax1.plot(x[0], y[0], marker="*", color="#ffec99", ms=14, mec="black", zorder=6)

    per = period_at(model, ma)
    head = f"{ma:g} Ma"
    if per:
        head += f" — {per['name']}"
    fig.text(0.5, 0.95, head + title_extra, color=per["color"] if per else "white", ha="center",
             fontsize=20, fontweight="bold")
    fig.text(0.19, 0.01, f"globe centred on {clat:.0f}°, {clon:.0f}°", color="#aaaaaa",
             ha="center", fontsize=9)
    for i, (name, col) in enumerate(legend):
        fig.text(0.40 + (i % 6) * 0.1, 0.05 - (i // 6) * 0.03, "■ " + name, color=col, fontsize=9)
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    fig.savefig(out, dpi=90, facecolor=fig.get_facecolor())
    plt.close(fig)
    return out


def validate(model, world):
    problems = []
    seen = {}
    for p in model["plates"]:
        for u in p["units"]:
            if u in seen:
                problems.append(f"{u} in {seen[u]} and {p['id']}")
            seen[u] = p["id"]
    for u in world:
        if u not in seen:
            problems.append(f"{u} has no plate")
    for u in seen:
        if u not in world:
            problems.append(f"{u} is not a geo_WORLD unit")
    for p in model["plates"]:
        ks = model["rotations"].get(p["id"])
        if not ks:
            problems.append(f"{p['id']} has no rotations")
            continue
        if ks[0]["ma"] != 0 or ks[0]["angle"] != 0:
            problems.append(f"{p['id']} first keyframe is not ma 0 / angle 0")
        if any(b["ma"] <= a["ma"] for a, b in zip(ks, ks[1:])):
            problems.append(f"{p['id']} keyframes not increasing")
    for u in model.get("emerged", {}):
        if u not in seen:
            problems.append(f"emerged: unknown unit {u}")
    pids = {p["id"] for p in model["plates"]}
    for lab in model.get("labels", []):
        if lab["plate"] not in pids:
            problems.append(f"label {lab['name']}: unknown plate {lab['plate']}")
    for ev in model.get("events", []):
        if ev["plate"] not in pids:
            problems.append(f"event {ev['title']}: unknown plate {ev['plate']}")
        if len(ev["title"]) > 34:
            problems.append(f"event title too long: {ev['title']}")
        if len(ev["detail"]) > 200:
            problems.append(f"event detail too long: {ev['title']}")
        if not (0 <= ev["ma"] <= model["maxMa"]):
            problems.append(f"event outside 0..maxMa: {ev['title']}")
    return problems


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ages", nargs="*", type=float, default=[0, 50, 100, 150, 200, 250])
    ap.add_argument("--center", help="globe centre as lat,lon (default: follows Africa)")
    ap.add_argument("--plates", default=PLATES)
    ap.add_argument("--out", help="output file (single age only)")
    ap.add_argument("--outdir", default=RENDERS)
    ap.add_argument("--extent", help="crop the flat map to lon0,lon1,lat0,lat1")
    args = ap.parse_args(argv)

    model = load_plates(args.plates)
    world = load_world()
    problems = validate(model, world)
    for p in problems:
        print("warning:", p, file=sys.stderr)
    center = tuple(float(x) for x in args.center.split(",")) if args.center else None
    for ma in args.ages:
        out = args.out if (args.out and len(args.ages) == 1) else os.path.join(
            args.outdir, f"plates_{ma:g}.png")
        extent = [float(x) for x in args.extent.split(",")] if args.extent else None
        print(render(model, world, ma, out, center, extent=extent))


if __name__ == "__main__":
    main()
