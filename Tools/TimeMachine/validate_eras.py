#!/usr/bin/env python3
"""Validates jpex/TimeMachineEras.json against Tools/TimeMachine/SPEC.md.

Usage: validate_eras.py [eras.json] [--online]

  --online   also checks every commons: flag file exists on Wikimedia Commons (and isn't a redirect)

Errors (exit status 1) are spec violations; warnings are things worth a look.
"""

import json
import math
import os
import re
import sys
import urllib.parse
import urllib.request
from collections import Counter, defaultdict

from shapely.geometry import Point, Polygon
from shapely.ops import unary_union

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GEO = os.path.join(ROOT, "jpex", "Maps", "geo_TIMEMACHINE.json")
ASSETS = os.path.join(ROOT, "jpex", "Assets.xcassets")
CATALOG = os.path.join(ROOT, "jpex", "WorldCatalog.swift")

ORDER = [("1815", 1815), ("1871", 1871), ("1914", 1914), ("1923", 1923), ("1939", 1939),
         ("1949", 1949), ("1960", 1960), ("1976", 1976), ("1990", 1990), ("1993", 1993),
         ("2011", 2011), ("today", 2026)]
NAMED = {"rose", "coral", "amber", "sand", "olive", "sage", "teal", "sky", "indigo", "violet",
         "plum", "slate", "rust", "gold"}
POLITY_KINDS = {"state", "empire", "indigenous", "unclaimed", "contested"}
EVENT_KINDS = {"independence", "unification", "partition", "annexation", "dissolution",
               "colonization", "decolonization", "flag", "rename", "treaty", "revolution"}
EARLIEST_EVENT_YEAR = 1750
NEAR_DEGREES = 3.0
# Empire-kind polities whose colour code is not their metropole (trusteeships, condominiums).
NO_METROPOLE = {"US_TTPI", "NH_CONDOMINIUM"}

errors, warnings = [], []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


NUM = re.compile(r"-?\d+(?:\.\d+)?")


def shape_of(d):
    polys = []
    for sub in re.split(r"(?=M)", d):
        nums = [float(x) for x in NUM.findall(sub)]
        pts = list(zip(nums[0::2], nums[1::2]))
        if len(pts) >= 3:
            p = Polygon(pts)
            if not p.is_valid:
                p = p.buffer(0)
            polys.append(p)
    return unary_union(polys) if polys else None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    online = "--online" in sys.argv
    path = args[0] if args else os.path.join(ROOT, "jpex", "TimeMachineEras.json")
    data = json.load(open(path, encoding="utf-8"))
    geo = json.load(open(GEO, encoding="utf-8"))

    units = {u["id"]: u for u in geo["units"]}
    country_of = {uid: u["country"] for uid, u in units.items()}
    # Codes that may be assigned/used as units: every unit id, plus every country code whose
    # pieces (CC~x) or sub-regions (CC-x) are units (GB, DE, FR, ...).
    children = defaultdict(list)
    for uid in units:
        if "~" in uid:
            children[uid.split("~")[0]].append(uid)
        elif "-" in uid:
            children[uid.split("-")[0]].append(uid)
    unit_codes = set(units) | set(children)
    countries = {u["country"] for u in geo["units"]} | {k for k in children if "~" not in k}
    catalog = dict(re.findall(r'worldPlace\("([A-Z]{2})", name: "([^"]+)"',
                              open(CATALOG, encoding="utf-8").read()))
    catalog.setdefault("GB", "United Kingdom")
    shapes = {}

    def shape(code):
        if code not in shapes:
            if code in units:
                shapes[code] = shape_of(units[code]["d"])
            else:
                parts = [shape(c) for c in children.get(code, [])]
                parts = [p for p in parts if p is not None]
                shapes[code] = unary_union(parts) if parts else None
        return shapes[code]

    def implicit(pid):
        return re.fullmatch(r"[A-Z]{2}", pid) is not None and pid in countries

    # ---------- top level
    if set(data) != {"polities", "eras"}:
        err(f"top-level keys are {sorted(data)}, expected ['eras', 'polities']")
    polities = data.get("polities", {})
    eras = data.get("eras", [])
    got = [(e.get("id"), e.get("year")) for e in eras]
    if got != ORDER:
        err(f"eras out of order or wrong: {got}")

    # ---------- polities
    for pid, p in polities.items():
        where = f"polity {pid}"
        if not re.fullmatch(r"[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)*", pid):
            err(f"{where}: id is not UPPER_SNAKE")
        extra = set(p) - {"name", "flag", "color", "kind"}
        if extra:
            err(f"{where}: unexpected keys {sorted(extra)}")
        if not isinstance(p.get("name"), str) or not p["name"].strip():
            err(f"{where}: missing name")
        kind = p.get("kind")
        if kind not in POLITY_KINDS:
            err(f"{where}: bad kind {kind!r}")
        color = p.get("color")
        if color not in NAMED and color not in countries:
            err(f"{where}: colour {color!r} is neither a unit country code nor a named colour")
        flag = p.get("flag")
        if flag is None:
            if kind in ("state", "empire"):
                warn(f"{where}: {kind} without a flag")
        elif flag.startswith("asset:"):
            m = re.fullmatch(r"asset:(world_flag_[a-z]{2}|history_flag_[a-z0-9_]+)", flag)
            if not m:
                err(f"{where}: malformed asset flag {flag!r}")
            elif not os.path.isdir(os.path.join(ASSETS, m.group(1) + ".imageset")):
                err(f"{where}: asset {m.group(1)} does not exist in Assets.xcassets")
        elif flag.startswith("commons:"):
            name = flag[len("commons:"):]
            if " " in name or not re.search(r"\.(svg|png|jpg|gif)$", name, re.I):
                err(f"{where}: commons flag {name!r} should be a file name with underscores")
        else:
            err(f"{where}: flag {flag!r} must be asset:… or commons:…")
        if implicit(pid):
            want_flag = f"asset:world_flag_{pid.lower()}"
            if flag != want_flag or color != pid or kind != "state":
                err(f"{where}: an id equal to a country code is that country's modern self "
                    f"everywhere; it needs flag {want_flag}, colour {pid}, kind state")
            if pid in catalog and p.get("name") != catalog[pid]:
                warn(f"{where}: name {p.get('name')!r} differs from the catalogue's {catalog[pid]!r}, "
                     f"and shows for today's {pid} too")

    if online:
        check_commons(polities)

    # ---------- eras
    used = Counter()
    resolved_by_era = {}
    prev_year = None
    for era in eras:
        eid = era.get("id")
        where = f"era {eid}"
        extra = set(era) - {"id", "year", "title", "summary", "assign", "events"}
        if extra:
            err(f"{where}: unexpected keys {sorted(extra)}")
        title, summary = era.get("title", ""), era.get("summary", "")
        if not title or len(title) > 32:
            err(f"{where}: title {title!r} is {len(title)} chars (1–32)")
        if not summary or len(summary) > 140:
            err(f"{where}: summary is {len(summary)} chars (1–140)")
        lint_text(where + " summary", summary)

        assign = era.get("assign", {})
        for key, val in assign.items():
            if key not in unit_codes:
                err(f"{where}: assign key {key!r} is not a unit, piece or country with pieces")
            if not isinstance(val, str) or val.count("|") > 1:
                err(f"{where}: assign {key}: bad value {val!r}")
                continue
            pid, sep, label = val.partition("|")
            if sep and not label.strip():
                err(f"{where}: assign {key}: empty label")
            if pid not in polities and not implicit(pid):
                err(f"{where}: assign {key}: polity {pid!r} is not defined")
            used[pid] += 1
            if pid == key and not sep and pid not in polities:
                warn(f"{where}: assign {key} -> {pid} is redundant")

        res = resolve(units, assign)
        resolved_by_era[eid] = res

        # Metropole should join its empire's polity.
        for pid in {v[0] for v in res.values()}:
            p = polities.get(pid)
            if not p or p.get("kind") != "empire" or pid in NO_METROPOLE:
                continue
            code = p.get("color")
            if code in countries:
                members = [u for u in units if country_of[u] == code and "-" not in u]
                if members and not any(res[u][0] == pid for u in members):
                    warn(f"{where}: empire {pid} is used but its metropole {code} is not assigned to it")

        events = era.get("events", [])
        if not 3 <= len(events) <= 8:
            warn(f"{where}: {len(events)} events (spec: 3–8)")
        years = [e.get("year") for e in events]
        if years != sorted(years):
            warn(f"{where}: events are not in chronological order")
        lo = EARLIEST_EVENT_YEAR if prev_year is None else prev_year
        for i, ev in enumerate(events):
            w = f"{where} event {i} ({ev.get('title')!r})"
            extra = set(ev) - {"year", "title", "detail", "at", "units", "from", "to", "kind"}
            if extra:
                err(f"{w}: unexpected keys {sorted(extra)}")
            y = ev.get("year")
            if not isinstance(y, int) or not (lo <= y <= era["year"]):
                err(f"{w}: year {y} outside [{lo}, {era['year']}]")
            elif prev_year is not None and y == prev_year:
                warn(f"{w}: year {y} is the previous era's year; is it after that snapshot?")
            t, dt = ev.get("title", ""), ev.get("detail", "")
            if not t or len(t) > 34:
                err(f"{w}: title is {len(t)} chars (1–34)")
            if not dt or len(dt) > 200:
                err(f"{w}: detail is {len(dt)} chars (1–200)")
            lint_text(w + " detail", dt)
            if ev.get("kind") not in EVENT_KINDS:
                err(f"{w}: bad kind {ev.get('kind')!r}")
            for side in ("from", "to"):
                lst = ev.get(side)
                if not isinstance(lst, list):
                    err(f"{w}: {side} must be a list")
                    continue
                for pid in lst:
                    if pid not in polities and not implicit(pid):
                        err(f"{w}: {side} polity {pid!r} is not defined")
                    used[pid] += 1
            if not ev.get("to"):
                warn(f"{w}: empty 'to'")
            us = ev.get("units") or []
            if not us:
                err(f"{w}: no units")
            bad = [u for u in us if u not in unit_codes]
            for u in bad:
                err(f"{w}: unit {u!r} does not exist")
            at = ev.get("at")
            if (not isinstance(at, list) or len(at) != 2 or not all(isinstance(x, (int, float)) for x in at)
                    or not (-180 <= at[0] <= 180 and -90 <= at[1] <= 90)):
                err(f"{w}: bad 'at' {at!r}")
            else:
                ok = [u for u in us if u in unit_codes]
                if ok:
                    dist = min(distance(shape(u), at) for u in ok)
                    if dist > NEAR_DEGREES:
                        err(f"{w}: 'at' {at} is {dist:.1f}° from the nearest of its units")
            # Consistency with the map: the event's units should show one of its 'to' polities (or
            # their lineage) in this era, and one of its 'from' polities in the previous era.
            leaves = expand(us, units, children)
            if ev.get("to") and leaves and ev.get("kind") not in ("treaty",):
                now = {res[u][0] for u in leaves}
                if not lineage(now, polities) & lineage(ev["to"], polities):
                    warn(f"{w}: none of its units is {ev['to']} on this era's map (they are {sorted(now)})")
            prev_eid = ERA_BEFORE.get(eid)
            if ev.get("from") and leaves and prev_eid in resolved_by_era:
                before = {resolved_by_era[prev_eid][u][0] for u in leaves}
                if not lineage(before, polities) & lineage(ev["from"], polities):
                    warn(f"{w}: none of its units was {ev['from']} on the {prev_eid} map (they were {sorted(before)})")
        prev_year = era.get("year")

    # A unit that is X, then its implicit modern self, then X again usually means an era forgot
    # to assign it (the flag or name would flicker as you scrub).
    ids = [e.get("id") for e in eras]
    for a, b, c in zip(ids, ids[1:], ids[2:]):
        if not all(x in resolved_by_era for x in (a, b, c)):
            continue
        ra, rb, rc = resolved_by_era[a], resolved_by_era[b], resolved_by_era[c]
        for u in units:
            pa, pb, pc = ra[u][0], rb[u][0], rc[u][0]
            if pa == pc and pb != pa and pb == u.split("~")[0].split("-")[0]:
                warn(f"era {b}: {u} is {pa} in {a} and {c} but left as its modern self here")

    for pid in polities:
        if not used[pid]:
            warn(f"polity {pid} is defined but never used")

    for w in warnings:
        print("warning:", w)
    for e in errors:
        print("ERROR:", e)
    n_assign = sum(len(e.get("assign", {})) for e in eras)
    n_events = sum(len(e.get("events", [])) for e in eras)
    print(f"\n{len(eras)} eras, {len(polities)} polities, {n_assign} assignments, {n_events} events: "
          f"{len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


ERA_BEFORE = {ORDER[i][0]: ORDER[i - 1][0] for i in range(1, len(ORDER))}


def lineage(pids, polities):
    """A polity matches itself and anything sharing its colour (the same state under another
    flag or name, e.g. QING and QING_1889)."""
    out = set()
    for pid in pids:
        out.add(pid)
        out.add("colour:" + (polities.get(pid) or {}).get("color", pid))
    return out


def resolve(units, assign):
    """unit id -> (polity id, label) following the renderer/app rules."""
    out = {}
    for uid in units:
        base = uid.split("~")[0]
        if uid in assign:
            v = assign[uid]
        elif "~" in uid and base in assign:
            v = assign[base]
        elif "-" in uid:
            parent = uid.split("-")[0]
            v = assign.get(parent, parent).split("|")[0] + "|" + uid
        else:
            v = base
        pid, _, label = v.partition("|")
        out[uid] = (pid, label or None)
    return out


def expand(codes, units, children):
    out = []
    for c in codes:
        if c in units:
            out.append(c)
        else:
            out += children.get(c, [])
    return out


def distance(shp, at):
    if shp is None:
        return math.inf
    best = math.inf
    for dx in (0, 360, -360):
        p = Point(at[0] + dx, at[1])
        best = min(best, 0.0 if shp.contains(p) else shp.distance(p))
    return best


def lint_text(where, s):
    if "  " in s or s != s.strip():
        warn(f"{where}: stray whitespace")
    if s and s[-1] not in ".!?”)":
        warn(f"{where}: doesn't end with a full stop")


def check_commons(polities):
    names = sorted({p["flag"][8:] for p in polities.values() if (p.get("flag") or "").startswith("commons:")})
    for i in range(0, len(names), 40):
        batch = names[i:i + 40]
        q = urllib.parse.urlencode({"action": "query", "format": "json", "redirects": 1,
                                    "titles": "|".join("File:" + n for n in batch)})
        req = urllib.request.Request("https://commons.wikimedia.org/w/api.php?" + q,
                                     headers={"User-Agent": "jpex-dev/1.0 (terrankroft@gmail.com)"})
        r = json.load(urllib.request.urlopen(req, timeout=30))["query"]
        norm = {n["from"]: n["to"] for n in r.get("normalized", [])}
        redir = {n["from"]: n["to"] for n in r.get("redirects", [])}
        pages = {p["title"]: p for p in r["pages"].values()}
        for n in batch:
            t = norm.get("File:" + n, "File:" + n)
            if t in redir:
                warn(f"commons flag {n} redirects to {redir[t][5:]}")
                t = redir[t]
            if t not in pages or "missing" in pages[t]:
                err(f"commons flag {n} does not exist")


if __name__ == "__main__":
    sys.exit(main())
