# Map data: Jordan, Oman, Qatar, Kuwait, Bahrain, Iran, Iraq, Cambodia, Laos, Bangladesh, Bhutan, Papua New Guinea and Fiji

Generated on 8 October 2026. The app bundles these files for offline use; it does not request map data from a network service at runtime.

This batch adds 26 files to `jpex/Maps/`. Each of the 13 collections has a projected map `map_<ID>.json` and an unprojected (lon/lat) map `geo_<ID>.json`. No existing file was changed.

## Files

| Map | Regions | `map_` size | `geo_` size | Canvas | km/unit | Simplify map / geo (u²) | Islet (u²) | Hole (u²) | Projection | Frames | Overlays |
|---|---|---|---|---|---|---|---|---|---|---|---|
| JO | 12 | 33.2 KB | 39.5 KB | 895.7 × 1000 | 0.47 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (37°E, k 0.9998; Jordan Transverse Mercator parameters) | – | – |
| OM | 11 | 37.3 KB | 44.4 KB | 769.5 × 1000 | 1.10 | 0.15 / 0.15 | 0.8 | 4 | UTM 40N | – | – |
| QA | 8 | 6.5 KB | 7.8 KB | 501.9 × 1000 | 0.18 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (24.45°N, 51.217°E, k 0.99999; Qatar National Grid parameters) | – | – |
| KW | 6 | 5.9 KB | 7.0 KB | 1000 × 938.1 | 0.19 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (48°E, k 0.9996; KUDAMS/KTM parameters) | – | – |
| BH | 4 | 3.9 KB | 4.4 KB | 568.2 × 1000 | 0.08 | 0.15 / 0.15 | 0.8 | 4 | UTM 39N | – | – |
| IR | 31 | 135.3 KB | 161.7 KB | 1000 × 912.7 | 1.83 | 0.15 / 0.15 | 0.8 | 4 | Lambert conformal conic (29°/37°N, lat₀ 32.5°N, 53.5°E) | – | – |
| IQ | 18 | 60.3 KB | 72.2 KB | 1000 × 991.4 | 0.95 | 0.15 / 0.15 | 0.8 | 4 | Lambert conformal conic (30.5°/36°N, lat₀ 33.2°N, 43.7°E) | – | – |
| KH | 25 | 127.3 KB | 163.3 KB | 1000 × 832.9 | 0.59 | 0.15 / 0.15 | 0.8 | 4 | UTM 48N | – | – |
| LA | 18 | 100.5 KB | 128.6 KB | 841.4 × 1000 | 0.97 | 0.15 / 0.15 | 0.8 | 4 | UTM 48N | – | – |
| BD | 8 | 76.6 KB | 91.3 KB | 734.4 × 1000 | 0.66 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (90°E, k 0.9996; Bangladesh Transverse Mercator parameters) | – | – |
| BT | 20 | 111.1 KB | 131.7 KB | 1000 × 562.3 | 0.34 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (90°E, k 1; Bhutan National Grid / DRUKREF 03 parameters) | – | 2 areas |
| PG | 22 | 72.3 KB | 93.6 KB | 1000 × 688.8 | 1.70 | 0.15 / 0.15 | 0.8 | 4 | Lambert conformal conic (2.5°/9°S, lat₀ 6°S, 150°E) | – | – |
| FJ | 5 | 18.5 KB | 25.9 KB | 980.5 × 1000 | 0.52 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (17°S, 178.75°E, k 0.99985; Fiji Map Grid parameters), longitudes unwrapped across 180° | 1 (Rotuma) | – |

Exact sizes in bytes, map then geo:
- JO 34,028 / 40,444; OM 38,217 / 45,471; QA 6,673 / 7,958; KW 6,003 / 7,151; BH 4,006 / 4,536
- IR 138,508 / 165,565; IQ 61,746 / 73,953; KH 130,399 / 167,198; LA 102,943 / 131,696
- BD 78,488 / 93,489; BT 113,765 / 134,870; PG 74,081 / 95,823; FJ 18,927 / 26,548

Every listed id has a shape: 188 regions in all. None was omitted, and no region is smaller than 3 units, so none is drawn as a marker square. All settings are the previous batches' (`MAP_SOURCES_3.md`): 0.15 u² simplification, 0.8 u² islets, 4 u² holes. All files are well inside the 200 KB / 220 KB budgets.

## Scope (ids)

Ids are exactly the current ISO 3166-2 codes (the same list as `/private/tmp/jpex-world/subdivisions.json`, checked against the ISO change history):

| Map | Count | Notes |
|---|---|---|
| JO | 12 | Governorates. |
| OM | 11 | Governorates after the 2011 reform (ISO update 2015-11-27: OM-BS, OM-BJ, OM-SS, OM-SJ). |
| QA | 8 | Municipalities, including Al Sheehaniya (QA-SH, ISO 2017). |
| KW | 6 | Governorates. |
| BH | 4 | Governorates after the 2014 abolition of the Central Governorate (ISO deleted BH-16 on 2015-11-27): BH-13, BH-14, BH-15, BH-17. |
| IR | 31 | Provinces IR-00…IR-30 (ISO's current numeric codes, Alborz IR-30). |
| IQ | 19 | Governorates. **Halabja (IQ-HA)** became the 19th governorate in 2025; it has no ISO code yet. Its shape is the Halabja, Beyara and Khourmal sub-districts of geoBoundaries gbHumanitarian IRQ ADM3 (CC BY 3.0 IGO), cut from As Sulaymānīyah (IQ-SU); Shahrazur stays in IQ-SU. IQ-KR (Kurdistan Region) is a grouping of IQ-AR, IQ-DA and IQ-SU and is **not** a separate shape. |
| KH | 25 | Provinces and Phnom Penh, including Tbong Khmum (KH-25). |
| LA | 18 | 17 provinces + Vientiane Prefecture (LA-VT), including Xaisomboun (LA-XS). LA-VI is Vientiane Province. |
| BD | 8 | Divisions BD-A…BD-H, including Mymensingh (BD-H). |
| BT | 20 | Dzongkhags. |
| PG | 22 | 20 provinces, the National Capital District and Bougainville (PG-NSB), including Hela (PG-HLA) and Jiwaka (PG-JWK). |
| FJ | 5 | Divisions FJ-C, FJ-E, FJ-N, FJ-W and Rotuma (FJ-R). |

## File format

Both formats are unchanged from the existing files (`MAP_SOURCES.md` → "File format"; `geo_WORLD.json` and `MAP_SOURCES_GEO.md`):

- **`map_<ID>.json`.** Canvas origin top-left, y down, long side exactly 1000 units, 10-unit margins. `d` uses absolute `M`/`L`/`Z` only, at most one decimal, one ring per `M…Z` subpath, even-odd fill. `c` is inside its region. Regions are sorted by drawn area, largest first. `frames` only in FJ; `disputed`/`disputedLines` only in BT (`disputedLines` is `[]`).
- **`geo_<ID>.json`.** `x` = longitude, `y` = latitude (north positive, not flipped), nominal 360 × 180, at most 3 decimals, no edge longer than 0.5° (maximum 0.481°), no ring crosses the antimeridian, same ids as the map file, no insets, sorted by geodesic area. `disputed` and `disputedLines` are present in every geo file (empty except BT's two areas) with the same entries and claimants as the map file.

## Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Natural Earth](https://www.naturalearthdata.com/) 1:10m: Admin 0 map subunits and Admin 1 states and provinces (5.1.1), Admin 0 disputed areas (5.1.1), lakes (5.0.0) | <ul><li>Every country outline: all 13 maps are clipped to NE's map subunits for the country (the same polygons as `geo_WORLD.json`).</li><li>All regions of FJ.</li><li>Iraq's Anbar/Najaf line in the Nukhayb desert.</li><li>BT's two disputed areas; lakes.</li></ul> | Public domain |
| [World Bank Official Boundaries](https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries) (Global Administrative Divisions), Admin 1, version 3 | Regions of JO, OM, KW and IR | CC BY 4.0, © The World Bank |
| [geoBoundaries](https://www.geoboundaries.org/) gbHumanitarian IRQ ADM1 (2019; Iraq Central Statistics Office via OCHA/HDX COD-AB), build `9469f09` | Iraq's 18 governorates | CC BY 3.0 IGO |
| geoBoundaries gbHumanitarian KHM ADM1 (2014; Ministry of Land Management, Urban Planning and Construction, WFP, via HDX), build `9469f09` | Cambodia's 25 provinces | CC BY 3.0 IGO |
| geoBoundaries gbHumanitarian LAO ADM1 (2015; National Geographic Department of Laos, via HDX), build `9469f09` | Laos's 18 provinces | CC BY 3.0 IGO |
| geoBoundaries gbHumanitarian BGD ADM1 (2018; Bangladesh Bureau of Statistics, via HDX), build `9469f09` | Bangladesh's 8 divisions | CC BY 3.0 IGO |
| geoBoundaries gbHumanitarian BTN ADM1 (2019; OCHA ROAP, via HDX), build `9469f09` | Bhutan's 20 dzongkhags | CC BY 3.0 IGO |
| geoBoundaries gbHumanitarian PNG ADM1 (2019; Papua New Guinea National Statistical Office, via HDX), build `9469f09` | PNG's 22 provinces | CC BY 3.0 IGO |
| geoBoundaries gbOpen QAT ADM1 (2015 structure; Qatar Open Data Portal, "GIS statistics"), build `9469f09` | Qatar's 8 municipalities | CC BY 4.0 |
| [Who's On First](https://whosonfirst.org/) `whosonfirst-data-admin-bh` region polygons (last modified 28 September 2023; geometry `src:geom` "whosonfirst" via `us-dshiu`, the US Department of State Humanitarian Information Unit) | Bahrain's 4 governorates | CC BY 4.0 (Who's On First); HIU data is US-government public domain |

geoBoundaries asks users to cite Runfola, D. et al. (2020), *geoBoundaries: A global database of political administrative boundaries*, PLoS ONE 15(4): e0231866. Every dataset was modified: clipped to Natural Earth's land, merged or split as described below, and simplified.

**Datasets checked but not used:**
- **Share-alike / OSM-derived (ODbL):** geoBoundaries gbOpen BHR, IRN, KHM, KWT, LAO and OMN ADM1 (OpenStreetMap via Wambacher); Kontur boundaries for Bahrain.
- **Outdated:**
  - NE: QA (7 pre-2014 municipalities, no Al Sheehaniya), BH (5 governorates incl. the abolished Central), KH (24, no Tbong Khmum), LA (17, no Xaisomboun; both Vientiane units coded LA-VI), BD (7, no Mymensingh), PG (20, no Hela or Jiwaka), IR (Tabas still in Yazd: Yazd 127,565 km² vs ~74,000; NE also codes Tehran and Alborz both IR-07 and uses non-ISO numbers), BT (pre-2000s dzongkhag lines: Pemagatshel 475 km² vs the official 1,023).
  - World Bank Admin 1: QA (9 pre-2004 municipalities), BH (12 old municipal regions).
  - HDX COD-AB Bahrain: FAO GAUL 2008.
- **Less accurate:** NE's JO (Madaba 1,263 km² vs 940 official; Irbid and Aqaba 10–15% off; World Bank matches the official areas), NE's KW (Al ʿĀṣimah is a thin coastal strip smaller than Failaka Island), NE's IQ (Baghdad is the 658 km² city instead of the ~4,555 km² governorate; Babil and Karbala off), geoBoundaries gbOpen IRQ (Baghdad 913 km², Karbala 3,472 km²).
- **World Bank BTN** draws Haa about 600 km² smaller than the other sources (it appears to exclude the area claimed by China), so the OCHA dzongkhags were used.

## Processing

Same pipeline as `MAP_SOURCES_3.md` (scripts in `/private/tmp/jpex-mapB/`, reusing `/private/tmp/jpex-map3/` unchanged):

1. **Regions** mapped to ISO ids by name (tables in `build_b.py`), by ISO code (QA's `shapeISO`, BH's WOF `iso_code`) or NE's `iso_3166_2` (FJ).
2. **Outlines from Natural Earth.** Units were clipped to NE's map subunits for the country (IRQ: `IRR` + `IRK`; PNG: `PNX` + `PNB`), so coasts and international borders are identical to the WORLD maps. Overlaps go to one unit; NE land that no unit covers goes to the adjacent unit (split between neighbours by nearest unit where it touches several); slivers ≤ 5 km² on the wrong side of a mismatched boundary are merged into the unit around them; the topology is rebuilt so neighbours share identical edges.
3. **Lakes** cut out as holes: NE natural lakes of 400 km² or more, plus every lake `geo_WORLD.json` cuts (3,500 km² or more). The geo files cut the same lakes.

   | Map | Lakes cut |
   |---|---|
   | JO | Dead Sea (both basins; Jordan's share) |
   | IR | Lake Urmia (also cut in `geo_WORLD.json`) |
   | IQ | Lake Razazah, Hammar Marsh (Tharthar and Habbaniyah are reservoirs and are not cut) |
   | KH | Tonlé Sap |
   | PG | Lake Murray |

   Reservoirs (Nam Ngum, Kaptai, Tharthar, Habbaniyah) are not cut, as on the other maps.
4. **Projection, islets, simplification, repair, labels and output** exactly as in `MAP_SOURCES_3.md` (0.01-unit grid shared arcs, weighted Visvalingam–Whyatt k = 0.7, local repair, rounding to 0.1; `c` is NE's label point where NE was the region source and it falls in a substantial part, otherwise the pole of inaccessibility of the largest part).
5. **Geo files** as for `geo_WORLD.json`: topology and simplification on the map's main canvas, original lon/lat of the retained vertices, edges densified to ≤ 0.5°, 3 decimals; `c` nudged on the 0.001° grid until inside. FJ is then split at 180° (see below).
6. **Validation** (`validate_b.py`): path grammar; exact id set against ISO (no duplicates); ranges; ≥ 3 points per ring, no repeated closing point; `c` inside (even-odd); sort order; frames inside the canvas; region overlap ≤ 0.044 u² (effectively zero); overlay keys/claimants; geo maximum edge 0.481°, no antimeridian jumps; geo ids and overlays identical to the map's; sizes. All 26 files pass.
7. **Previews** (in `/private/tmp/jpex-mapB/previews/`, inspected): every projected map labelled, zooms of the capitals (Tehran/Alborz/Qom, Phnom Penh, Port Moresby, Vientiane, Manama, Amman), BT's overlays, and every geo file over `geo_WORLD.json` in Winkel Tripel (FJ with central meridian 180°).

## Per-map notes

- **JO.** World Bank governorates. The source has a detached 27 km² "Balqa" piece at Russeifa (36.04°E, 32.02°N), a city of Zarqa governorate (NE agrees): it was given to Zarqa (JO-AZ).
- **OM.** World Bank governorates (areas match NCSI's). The source draws Masirah Island in Al Wusta; Masirah is a wilayat of South Sharqiyah (OM-SJ), so the island was moved there. Musandam (OM-MU) includes the Madha exclave inside the UAE. The World Bank names map as: Al Dhahira North → OM-ZA, Al Sharakih North → OM-SS, Al Batinah North → OM-BS.
- **QA.** Qatar Open Data Portal municipalities (areas match the official ones, e.g. Al Sheehaniya 3,322 km²).
- **KW.** World Bank governorates. Failaka is in Al ʿĀṣimah (KW-KU); Bubiyan in Al Jahrāʾ. NE's 10m outline of Kuwait is coarse; it is kept so the outline matches the world map.
- **BH.** Who's On First's four post-2014 governorates on NE's (coarse) Bahrain outline. Capital (BH-13) includes Sitra; Umm an-Nasan is in Northern (BH-17); the Hawar Islands are in Southern (BH-14).
- **IR.** World Bank provinces (identical to UNHCR's COD-AB): Tabas is in South Khorasan (moved from Yazd in 2013). Abu Musa is in NE's Iran polygon and is drawn in Hormozgan (IR-22); the Greater and Lesser Tunbs are not in NE's land at all. See "Disputed areas".
- **IQ.** Central Statistics Office governorates. The source draws the Nukhayb desert (11,549 km²) in Najaf; it is administered by Anbar, and the official governorate areas (Anbar 138,501 km², Najaf 28,824 km²) count it there. The part of the source's Najaf that NE's Anbar covers was moved to Anbar, so that line follows NE. Halabja is inside As Sulaymānīyah (see Scope).
- **KH.** Ministry of Land Management provinces. Tonlé Sap (not delimited in the source) is cut out; the surrounding provinces meet at its shore. Phnom Penh is an island inside Kandal.
- **LA.** National Geographic Department provinces, with Xaisomboun (re-created 2013 from Vientiane and Xiangkhouang provinces) and Vientiane Capital.
- **BD.** BBS divisions with Mymensingh (split from Dhaka in 2015).
- **BT.** OCHA dzongkhags. NE's Bhutan reaches further north than the source in places; that land (about 1,300 km²) went to Gasa and Bumthang by nearest unit. Bumthang therefore has a strip in the north next to Gasa (where the disputed Pasamlung/Jakarlung valleys are).
- **PG.** NSO provinces with Hela and Jiwaka. Wuvulu Island (not in the source; nearest coast Sandaun) was given to Manus (PG-MRL), whose Western Islands it belongs to. Bougainville is PG-NSB.
- **FJ.** NE divisions. Before projecting, longitudes west of 180° (east of the antimeridian: Lau, Taveuni's and Vanua Levu's eastern tips) were unwrapped by +360°. NE stores its cut edge as −179.99999999999991, so x within 10⁻⁶ of ±180 was snapped to 180 first; NE's halves of Taveuni and Vanua Levu then dissolve, and each island is one ring with no seam. Ceva-i-Ra (Conway Reef, FJ-W, 14 km² in NE, 300 km south-west of Viti Levu) is **omitted from the map file** because it would roughly double the canvas (as the earlier maps omit remote islets such as Ogasawara or Macquarie); it is kept in place in the geo file.

## Insets and frames

| Map | Frames | Contents |
|---|---|---|
| FJ | 1 | Rotuma (FJ-R), top-left at 2× the main scale in the same Fiji Map Grid projection, frame `[10.0, 10.0, 71.6, 37.4]`. Rotuma lies ~450 km north of Vanua Levu; in place it would shrink the main islands by about 40%. |

Fiji's southern Lau islands (Ono-i-Lau, Vatoa, Tuvana) stay in place. No other map has insets: Musandam and Madha (OM), the Hawar Islands (BH), Bougainville and the outer islands (PG), the Gulf islands (IR) all stay in place. Because FJ-R is drawn at 2× on the map, its position in the area-sorted lists differs between the two files.

## Fiji and the antimeridian

- **Map.** Continuous across 180° (see above); FJ-N's Taveuni and Vanua Levu and FJ-E's Lau group are drawn without a seam.
- **Geo file.** FJ-N and FJ-E rings were cut at 180° and the eastern parts shifted by −360°, as in `geo_RU.json` and as `geo_WORLD.json` splits WORLD-FJ. Cut edges lie exactly on 180° and −180°; no ring crosses the antimeridian. The other three regions do not reach 180°.

## Alignment with `geo_WORLD.json`

| Map | Area geo vs world | IoU | Farthest geo vertex outside world | Farthest world vertex outside geo |
|---|---|---|---|---|
| JO | −0.6% | 0.986 | 4 km | 10 km (Dead Sea) |
| OM | +0.1% | 0.991 | 48 km | 0.6 km |
| QA | +1.5% | 0.942 | 9 km | 0.6 km |
| KW | +1.2% | 0.949 | 29 km | 0.6 km |
| BH | +42.8% | 0.586 | 34 km | 0.3 km |
| IR | +0.1% | 0.995 | 75 km | 0.7 km |
| IQ | −0.6% | 0.989 | 12 km | 0.6 km |
| KH | −1.3% | 0.969 | 26 km | 0.6 km (Tonlé Sap) |
| LA | 0.0% | 0.980 | 14 km | 0.7 km |
| BD | 0.0% | 0.948 | 36 km | 0.7 km |
| BT | −0.2% | 0.972 | 6 km | 0.7 km |
| PG | +0.5% | 0.971 | 202 km | 0.7 km |
| FJ | +8.6% | 0.833 | 491 km (Rotuma) | 0.7 km |

Both files come from the same NE polygons; the differences are `geo_WORLD.json`'s coarse world-scale simplification and the islands it drops (Rotuma, Ceva-i-Ra, the outer PNG atolls, small Gulf islands, Hawar). Bahrain is the extreme case: the world map draws it as a single ~480 km² polygon without the Hawar Islands, so the subdivisions extend beyond its outline. Where a lake is cut (Dead Sea, Tonlé Sap, Razazah, Hammar, Murray), the world map's country fill shows through, as with the other `geo_` files.

## Boundary choices and disputed areas

All maps follow the WORLD maps' view: Natural Earth's de facto outlines. Overlays use the same ids, names, claimants and notes as `geo_WORLD.json`; geometry is NE's full-resolution disputed area, simplified with the map's settings and part of the same topology. Claimants follow the `map_IN.json` convention (divisions holding ≥ 10% of the area, or lying ≥ 50% inside it, replace the map's own WORLD id).

| Map | Area | Claimants | Lines |
|---|---|---|---|
| BT | doklam (Doklam; NE B76 "Chumbi salient") | BT-13, WORLD-CN | – |
| BT | bhutan-northwest-valleys (Northwestern Bhutan valleys; NE B75) | BT-33, BT-GA, WORLD-CN | – |

Both lie inside Bhutan's de facto territory and its dzongkhags, so the canvas did not grow. Note: "Administered by Bhutan; claimed by China."

**Not added** (consistency with `geo_WORLD.json`'s selection and with `map_RU.json`, which omits Abkhazia and South Ossetia although they border Russia):
- **Iran–UAE islands.** NE has a disputed area for Abu Musa (B73, "Admin. by Iran; claimed by UAE"), but `geo_WORLD.json` has no layer for it or for the Tunbs, so no overlay was added. Abu Musa is drawn in Hormozgan as NE (de facto) has it; the Tunbs are below NE's resolution.
- **Golan Heights** touches Jordan along the Yarmouk, and the West Bank Green Line ends at the Jordan border; Jordan is not a party to either, and drawing the Golan whole would extend JO's canvas ~70 km north of Jordan.
- **Arunachal Pradesh** and the LAC eastern sector border eastern Bhutan, but the dispute is India–China only, and the area (≈ 84,000 km²) is twice Bhutan's size.
- No other `geo_WORLD.json` area or line lies in or borders OM, QA, KW, BH, IQ, KH, LA, BD, PG or FJ. Bahrain–Qatar (Hawar, settled by the ICJ in 2001) and Kuwait–Saudi Arabia (the Divided Zone, partitioned in 1970) are not disputes in NE's or `geo_WORLD.json`'s data. Iraq's Kurdistan Region is drawn as its three governorates on the CSO's federal governorate lines; the internally disputed territories (e.g. Kirkuk) have no layer in `geo_WORLD.json`.

## Rendering notes

- **Fill rule.** Even-odd: lakes and enclaves are extra rings. Phnom Penh sits inside Kandal. The smallest regions (Kep, Phnom Penh, Port Moresby, Vientiane Capital, Bahrain's Capital and Muharraq, Kuwait's Hawalli) are all larger than 3 units.
- **Overlays.** BT only; draw on top of the regions (hatched). Their outlines coincide with the border segments they follow.
- **Inset.** FJ's Rotuma frame is at 2× the main scale.
- **Coarse outlines.** Kuwait, Bahrain and Qatar are small, so NE's 1:10m coast shows its angularity at full zoom (Bahrain is ~0.08 km per unit). This is deliberate so the outlines match the world map.
