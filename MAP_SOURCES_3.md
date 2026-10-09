# Map data: Iceland, Estonia, Lithuania, Slovakia, Romania, Bulgaria, Ukraine, Egypt, Kenya, Ecuador, Bolivia, Uruguay, Cuba, Nepal, Mongolia and Saudi Arabia

Generated on 8 October 2026. The app bundles these files for offline use; it does not request map data from a network service at runtime.

This batch adds 32 files to `jpex/Maps/`. Each of the 16 collections has a projected map `map_<ID>.json` and an unprojected (lon/lat) map `geo_<ID>.json`. No existing file was changed.

## Files

| Map | Regions | `map_` size | `geo_` size | Canvas | km/unit | Simplify map / geo (u²) | Islet (u² ≈ km²) | Hole (u²) | Projection | Frames | Overlays |
|---|---|---|---|---|---|---|---|---|---|---|---|
| IS | 8 | 45.3 KB | 58.6 KB | 1000 × 693.6 | 0.53 | 0.15 / 0.15 | 0.8 ≈ 0.2 | 4 | Lambert conformal conic (64.25°/65.75°N, 19°W; ISN93 parameters) | – | – |
| EE | 15 | 79.1 KB | 94.7 KB | 1000 × 661.5 | 0.37 | 0.15 / 0.15 | 0.8 ≈ 0.1 | 4 | Lambert conformal conic (58°/59.33°N, 24°E; L-EST97 parameters) | – | – |
| LT | 10 | 35.6 KB | 42.6 KB | 1000 × 767.5 | 0.38 | 0.15 / 0.15 | 0.8 ≈ 0.1 | 4 | Transverse Mercator (24°E, k 0.9998; LKS94 parameters) | – | – |
| SK | 8 | 31.9 KB | 38.4 KB | 1000 × 499.1 | 0.43 | 0.15 / 0.15 | 0.8 ≈ 0.1 | 4 | Lambert conformal conic (48.2°/49.3°N, 19.5°E) | – | – |
| RO | 42 | 223.5 KB | 207.1 KB | 1000 × 705.2 | 0.75 | 0.18 / 0.32 | 0.8 ≈ 0.5 | 4 | Oblique stereographic (46°N, 25°E, k 0.99975; Stereo 70 parameters) | – | – |
| BG | 28 | 181.1 KB | 201.3 KB | 1000 × 664.4 | 0.52 | 0.15 / 0.18 | 0.8 ≈ 0.2 | 4 | Lambert conformal conic (42°/43.33°N, 25.5°E; BGS2005 parameters) | – | – |
| UA | 27 | 176.9 KB | 211.3 KB | 1000 × 678.0 | 1.35 | 0.15 / 0.15 | 0.8 ≈ 1.5 | 4 | Lambert conformal conic (45.7°/51.1°N, 31.2°E) | – | 1 area, 1 line |
| EG | 27 | 52.8 KB | 65.5 KB | 1000 × 906.6 | 1.26 | 0.15 / 0.15 | 0.8 ≈ 1.3 | 4 | Transverse Mercator (31°E, k 1; Egypt Red Belt parameters) | – | 2 areas, 2 lines |
| KE | 47 | 137.5 KB | 160.2 KB | 826.0 × 1000 | 1.10 | 0.15 / 0.15 | 0.8 ≈ 1.0 | 4 | Transverse Mercator (37.9°E, k 0.9996) | – | 1 area, 1 line |
| EC | 24 | 162.8 KB | 206.3 KB | 1000 × 813.8 | 0.90 | 0.15 / 0.15 | 0.8 ≈ 0.6 | 4 | UTM 17S (mainland); Galápagos inset UTM 15S | 1 | – |
| BO | 9 | 42.9 KB | 59.4 KB | 890.7 × 1000 | 1.50 | 0.15 / 0.15 | 0.8 ≈ 1.8 | 4 | Lambert conformal conic (11.9°/20.7°S, 63.6°W) | – | – |
| UY | 19 | 44.2 KB | 60.6 KB | 909.8 × 1000 | 0.55 | 0.15 / 0.15 | 0.8 ≈ 0.2 | 4 | UTM 21S (SIRGAS-ROU98 grid) | – | – |
| CU | 16 | 47.9 KB | 62.8 KB | 1000 × 351.5 | 1.15 | 0.15 / 0.15 | 0.8 ≈ 1.1 | 4 | Lambert conformal conic (20.6°/22.6°N, 79.5°W) | – | – |
| NP | 7 | 68.9 KB | 82.1 KB | 1000 × 569.6 | 0.82 | 0.15 / 0.15 | 0.8 ≈ 0.5 | 4 | Lambert conformal conic (27°/29.8°N, 84.1°E) | – | 1 area |
| MN | 22 | 66.2 KB | 83.4 KB | 1000 × 504.5 | 2.44 | 0.15 / 0.15 | 0.8 ≈ 4.8 | 4 | Lambert conformal conic (43.4°/50.4°N, 103.8°E) | – | – |
| SA | 13 | 88.2 KB | 105.7 KB | 1000 × 828.3 | 2.17 | 0.15 / 0.15 | 0.8 ≈ 3.8 | 4 | Lambert conformal conic (19°/29°N, 45°E) | – | – |

Exact sizes in bytes, map then geo:
- IS 46,437 / 59,972; EE 80,997 / 96,960; LT 36,466 / 43,668; SK 32,696 / 39,283
- RO 228,871 / 212,059; BG 185,445 / 206,173; UA 181,105 / 216,386; EG 54,094 / 67,030
- KE 140,798 / 164,033; EC 166,749 / 211,272; BO 43,921 / 60,823; UY 45,266 / 62,046
- CU 49,035 / 64,300; NP 70,593 / 84,040; MN 67,834 / 85,397; SA 90,342 / 108,275

Every listed id has a shape: 322 regions in all. None were omitted. No region is smaller than 3 units on its map, so none is drawn as a marker square.

## File format

Both formats are unchanged from the existing files:
- `map_<ID>.json` follows `MAP_SOURCES.md` → "File format".
- `geo_<ID>.json` follows `geo_WORLD.json`, as described in `MAP_SOURCES.md` → "Unprojected world map" and in `MAP_SOURCES_GEO.md`.

In brief:

- **`map_<ID>.json`.**
  - Canvas: origin top-left, y down, longer side exactly 1000 units, 10-unit margin.
  - `d`: absolute `M`/`L`/`Z` only, at most one decimal, one ring per `M…Z` subpath, even-odd fill.
  - `c`: a label point inside the region.
  - Regions are sorted by drawn area, largest first.
  - `frames`: only in EC.
  - `disputed` and `disputedLines`: only in UA, EG, KE and NP. NP has no lines, so its `disputedLines` is `[]`.
  - Egypt's canvas has a 33-unit bottom margin instead of 10, because the canvas grows to show Bir Tawil whole (see below).
- **`geo_<ID>.json`.**
  - `x` is longitude and `y` is latitude, north positive and not flipped. `width`/`height` are nominal (360 × 180).
  - Numbers have at most 3 decimals.
  - No edge is longer than 0.5° (Euclidean in lon/lat). Longer edges were subdivided linearly.
  - No ring crosses the antimeridian. All 16 countries lie between 92.0°W (Galápagos) and 119.9°E (Mongolia).
  - The ids are the same as the matching `map_<ID>.json`.
  - There are no insets: the Galápagos sit in their true place.
  - Regions are sorted by geodesic area, largest first. Because EC's map draws the Galápagos at 0.6× scale, EC-W is in a different position in the two files. Every other order agrees with the map file.
  - `disputed` and `disputedLines` are present in every file (empty except in UA, EG, KE and NP). They carry the same entries and claimants as the map file.

## Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Natural Earth](https://www.naturalearthdata.com/) 1:10m: Admin 0 map subunits and Admin 1 states and provinces (5.1.1), Admin 0 disputed areas (5.1.1), Admin 0 boundary lines (land) and disputed-area boundary lines (5.1.0), lakes (5.0.0) | <ul><li>Every country outline: all 16 maps are clipped to NE's country polygons, the same polygons as the WORLD maps.</li><li>All regions of LT, SK, BO and UY.</li><li>All regions of IS except the Austurland/Suðurland boundary, and of CU except the Pinar del Río/Artemisa boundary.</li><li>UA-43 Crimea and UA-40 Sevastopol.</li><li>Disputed areas and lines; lakes.</li></ul> | Public domain |
| [Maa- ja Ruumiamet](https://geoportaal.maaamet.ee/est/Ruumiandmed/Haldus-ja-asustusjaotus-p119.html) (Estonian Land and Spatial Development Board), "Haldus- ja asustusjaotus": `omavalitsus_valispiirini` (municipalities extended to the outer border), data as of 2 September 2026 | Estonia's 15 counties (2017 boundaries), dissolved from municipalities by county code | Open data. Attribution with the data date is required: "Haldus- ja asustusjaotus: Maa- ja Ruumiamet 02.09.2026" |
| [geoBoundaries](https://www.geoboundaries.org/) gbOpen KEN ADM1 (2020; RCMRD GeoPortal / Africa GeoPortal), build `9469f09` | Kenya's 47 counties | Public domain |
| geoBoundaries gbOpen NPL ADM1 (2020; Survey Department of Nepal, OCHA FISS), build `9469f09` | Nepal's 7 provinces (current boundaries: Rukum East in Lumbini, Nawalparasi East in Gandaki) | CC BY 3.0 IGO |
| geoBoundaries gbOpen ROU ADM1 (2017; World Bank), build `9469f09` | Romania's 41 counties and Bucharest | CC BY 4.0 |
| geoBoundaries gbHumanitarian BGR ADM1 (2019; UNICEF via HDX), build `9469f09` | Bulgaria's 28 provinces | CC BY 3.0 IGO |
| geoBoundaries gbHumanitarian UKR ADM1 (2022; State Scientific Production Enterprise "Kartographia" via HDX), build `9469f09` | Ukraine's 24 oblasts and Kyiv city | CC BY 3.0 IGO |
| geoBoundaries gbHumanitarian EGY ADM1 (2017) and gbOpen EGY ADM2 (2020) (CAPMAS via OCHA ROMENA/HDX), build `9469f09` | Egypt's 27 governorates; ADM2 Armant and Isna (Esna) districts moved to Luxor | CC BY 3.0 IGO |
| geoBoundaries gbHumanitarian MNG ADM1 (2020; National Statistical Office of Mongolia via HDX), build `9469f09` | Mongolia's 21 aimags and Ulaanbaatar | CC BY 3.0 IGO |
| [World Bank Official Boundaries](https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries) (Global Administrative Divisions), Admin 1, version 3 (10 September 2026) | <ul><li>Ecuador's 24 provinces.</li><li>Saudi Arabia's 13 regions.</li><li>The redrawn Austurland/Suðurland (IS) and Pinar del Río/Artemisa (CU) boundaries.</li></ul> | CC BY 4.0, © The World Bank |

geoBoundaries asks users to cite Runfola, D. et al. (2020), *geoBoundaries: A global database of political administrative boundaries*, PLoS ONE 15(4): e0231866. Every dataset was modified: clipped to Natural Earth's land, merged or split as described below, and simplified.

**Datasets checked but not used:**
- **Share-alike licences.** geoBoundaries gbOpen ADM1 for ISL, EST, LTU, SVK, UKR, EGY, MNG, SAU, CUB and URY, and gbOpen EST/LTU/SVK/CUB ADM2, are OpenStreetMap-derived (ODbL). gbOpen SAU ADM2 is CC BY-SA.
- **Outdated.**
  - gbOpen ECU ADM1 (CC0, 2011).
  - gbHumanitarian ECU ADM1 (INEC, 2018) still has La Concordia in Esmeraldas and three "zonas no delimitadas".
  - The World Bank Admin 1 data is outdated for Estonia (pre-2017), Lithuania (Pagėgiai, see below) and Egypt (Luxor). It reduces Sevastopol to the 57 km² city core, as Kartographia also does.
- **Licence not permissive.** COD-AB Cuba is GADM-derived.
- **Too coarse.** gbOpen BGR ADM1 (public domain).
- **Inaccessible.**
  - Lithuania's Address Register open data (CC BY 4.0, Registrų centras and data.gov.lt) refused automated requests.
  - EuroGeographics EuroGlobalMap needs a registration token.
  - Eurostat GISCO boundaries carry a non-commercial clause.

## Processing

1. **Regions.** Source units were mapped to the ISO 3166-2 ids:
   - by ISO code where the source has one: NE, KEN, NPL, ROU;
   - by name otherwise: BGR, UKR, EGY, MNG and the World Bank data;
   - Estonia by the EHAK county code (`EE-` + code).
2. **Outlines from Natural Earth.** Each source's units were clipped to NE's polygon for the country, the same geometry as `geo_WORLD.json`'s region. This makes coastlines and international borders identical to the world maps.
   - Overlaps between units go to one of them.
   - NE land that no unit covers (coastal and border slivers, lakes the source leaves out) goes to the adjacent unit. A piece that touches several units is split among them by nearest unit (Voronoi cells of points along each unit's edge), so a strip along a border is shared by the units along it.
   - Small fragments (≤ 5 km²) left on the wrong side of a mismatched source boundary are merged into the unit around them.
3. **Topology rebuild.** For every non-NE source, the region boundaries were noded and polygonized, and the faces reassigned to regions. Each vertex lying on a neighbour's edge was inserted into that edge. Neighbouring regions therefore share exactly the same edges, as in Natural Earth.
4. **Lakes** were cut out as holes. These are NE natural lakes and lagoons; reservoirs are not cut, as on the US map, except Lake Nasser.

   | Map | Rule | Lakes cut |
   |---|---|---|
   | EE | 50 km² or more | Peipus and Pskov, Võrtsjärv |
   | UA | 200 km² or more | Syvash, Dniester Estuary. NE's untitled 245 km² "lake" is the Kaniv Reservoir and is not cut. |
   | EG | 200 km² or more, plus Lake Nasser | Great Bitter Lake, Lake Nasser |
   | KE | 1,000 km² or more | Victoria, Turkana |
   | BO | 150 km² or more | Titicaca, Poopó, Rogaguado, Huaitunas, Concepción |
   | UY | 500 km² or more | Mirim |
   | MN | 250 km² or more | Uvs, Khövsgöl, Har Us, Khyargas, Har, Buyr, Achit |

   - This includes every lake `geo_WORLD.json` cuts (3,500 km² or more: Victoria, Turkana, Titicaca, Nasser, Mirim). The geo files cut the same lakes as the maps, as in `MAP_SOURCES_GEO.md`.
   - The disputed overlays have the same water removed.
5. **Projection, islets, simplification, repair and output** follow `MAP_SOURCES.md` → "Processing", with the same settings:
   - Coordinates are snapped to a 0.01-unit grid and decomposed into shared arcs.
   - Weighted Visvalingam–Whyatt (k = 0.7); every arc keeps an interior point.
   - Self-overlaps or overlaps between regions are repaired by locally lowering the threshold.
   - Coordinates are rounded to 0.1.
   - `c` is NE's label point if it falls in a substantial part of the drawn shape, otherwise the pole of inaccessibility of the largest part.
   - The disputed areas and lines are part of the same topology as the regions in both files, so an overlay edge that follows a region border coincides with it exactly.
6. **Geo files.** As for `geo_WORLD.json`:
   - Topology, islet removal and simplification are computed on the projected map's main canvas (same projection and scale, no insets), and the retained vertices keep their original lon/lat.
   - The vertices are then densified so no edge exceeds 0.5° and rounded to 3 decimals.
   - RO and BG use a coarser threshold in the geo file (0.32 and 0.18 u²) to stay within 220 KB.
   - `c` is NE's label point or the canvas pole of inaccessibility converted back to lon/lat, nudged on the 0.001° grid until it is inside.
7. **Validation.** Every file was re-parsed and checked:
   - path grammar;
   - exact id set against the ISO 3166-2 top-level list, with no duplicates;
   - coordinate ranges, at least 3 points per ring and no repeated closing point;
   - `c` inside its region under even-odd, and sort order;
   - frames inside the canvas;
   - overlap between regions: at most 0.06 u² in any map, effectively zero;
   - overlay keys, claimants and lines;
   - geo: maximum edge 0.49° and no antimeridian jumps;
   - geo ids and overlays identical to the map file;
   - size budgets.

   Previews were rendered and inspected:
   - every projected map, with ids labelled;
   - zooms of the capital areas;
   - every geo file over `geo_WORLD.json` in Winkel Tripel, with the WORLD outline drawn on top.

## Alignment with `geo_WORLD.json`

The union of each geo file's regions was compared with the region `WORLD-<ID>` in `geo_WORLD.json`.

| Map | Area geo vs world | IoU | Farthest geo vertex outside world | Farthest world vertex outside geo |
|---|---|---|---|---|
| IS | −1.7% | 0.941 | 44 km | 1.1 km |
| EE | −2.6% | 0.907 | 59 km | 17 km (Lake Peipus) |
| LT | −0.1% | 0.978 | 9 km | 0.5 km |
| SK | 0.0% | 0.973 | 7 km | 0.5 km |
| RO | −0.1% | 0.986 | 15 km | 0.5 km |
| BG | +0.2% | 0.983 | 12 km | 0.5 km |
| UA | −0.6% | 0.982 | 34 km | 0.8 km |
| EG | −0.1% | 0.994 | 33 km | 0.7 km |
| KE | −0.1% | 0.993 | 17 km | 1.3 km |
| EC | −0.1% | 0.982 | 184 km (Darwin Island) | 0.7 km |
| BO | −0.2% | 0.993 | 21 km | 0.7 km |
| UY | −0.1% | 0.990 | 8 km | 0.7 km |
| CU | +0.7% | 0.945 | 68 km | 0.7 km |
| NP | +0.1% | 0.981 | 18 km | 0.6 km |
| MN | −0.7% | 0.989 | 11 km | 2.4 km |
| SA | +0.1% | 0.997 | 30 km | 0.7 km |

- **Why they differ.** Both files come from the same NE polygons. The remaining differences are `geo_WORLD.json`'s much coarser world-scale simplification (vertices up to ~10 km off the true line) and the islands and lakes it leaves out.
  - Large "geo outside world" values are islands that the world map drops as islets: Darwin and Wolf, cays, Grímsey, Ruhnu, Snake Island, the Farasan Islands.
  - Large "world outside geo" values are lakes cut from the subdivisions but not from the world map: Peipus, the Mongolian lakes.
- **Drawing over the world map.**
  - Where a lake is cut, the world map's country fill shows through the subdivisions. The same happens in the other `geo_` files.
  - Along coasts, thin slivers of the world outline can show beyond the detailed subdivisions at high zoom.

## Insets and frames

| Map | Frames | Contents |
|---|---|---|
| EC | 1 | The Galápagos (EC-W) at 0.6× the mainland scale, top-left, in the Pacific west of Esmeraldas and Manabí. Projected in UTM 15S, frame `[10.0, 10.0, 221.0, 242.5]`. It includes Darwin and Wolf Islands. |

All other maps have no insets. Remote islands stay in place: Grímsey and the Westman Islands (IS), Ruhnu (EE), Snake Island (UA), the Farasan Islands (SA), Isla de la Juventud and the cays (CU).

## Per-map notes

- **IS.**
  - NE's 9 units, with Reykjavík (`IS-0`) merged into the Capital Region (IS-1).
  - NE predates Statistics Iceland's move of Hornafjörður from Austurland to Suðurland on 1 December 2020. NE's IS-7 ∪ IS-8 was therefore re-divided as the World Bank data draws them, so Hornafjörður (Höfn, Öræfi) is in IS-8.
- **EE.**
  - NE's counties predate the 2017 administrative reform. For example, Lihula and Virtsu, Värska and Pala are in the wrong county there.
  - The counties were instead dissolved from Maa- ja Ruumiamet's municipalities and clipped to NE's land.
  - The coast is NE's: islands are generalised, and many islets are missing as on the world map.
  - Lake Peipus, Lake Pskov and Võrtsjärv are cut out. Piirissaar (Tartu County) remains as an island in the lake.
- **LT.** NE as is.
  - **Known issue:** NE (and the World Bank data) still draw Pagėgiai municipality (537 km²) in Klaipėda County. It moved to Tauragė County in 2000.
  - No permissive source with current county boundaries could be downloaded (see above).
  - This affects only that area. It can be fixed by re-dividing LT-KL ∪ LT-TA with the Lithuanian Address Register data (CC BY 4.0) if it can be obtained.
- **SK, BO, UY.** NE as is. A cross-check against other datasets showed no outdated units.
- **RO.**
  - geoBoundaries' World Bank counties, because NE's are inaccurate around the capital: NE's Bucharest is 285 km² and contains Otopeni and Voluntari, which are in Ilfov.
  - Here Bucharest is 235 km² and Ilfov 1,570 km².
- **BG.**
  - geoBoundaries' UNICEF provinces, because NE's are inaccurate: NE has Topolovgrad in Yambol, Haskovo about 1,500 km² too small, and Yambol and Kardzhali too large.
  - The areas now match the official ones within about 3%.
- **UA.**
  - Kartographia's oblasts, because NE's Kyiv city is twice its real size: NE includes Irpin and Vyshneve.
  - Crimea (UA-43) and Sevastopol (UA-40) come from NE, because the source reduces Sevastopol to its 57 km² core. They are placed first, so their outline, which the `crimea` overlay shares, is NE's exactly.
  - The Kinburn Peninsula (UA-48), the Arabat Spit's northern part and Dzharylhach (UA-65) are separate parts.
  - A small Kyiv-oblast piece east of the Dnipro at the Belarusian border is kept as the source draws it.
  - The Kakhovka Reservoir (drained since 2023) and the other Dnipro reservoirs are not cut out.
- **EG.**
  - CAPMAS governorates. The source still has the pre-2009 Luxor (the city area only, 596 km²; NE has the 11 km² city core).
  - The Armant and Esna districts (CAPMAS ADM2) were moved from Qena to Luxor, with the strip of Qena's west-bank desert beside them south of 25.82°N. Luxor is now the Nile valley from Esna to Al-Qurna and Luxor city.
  - The desert hinterland east of the river stays with Qena, because the source does not delimit it.
  - Tiran and Sanafir are left out of Egypt and drawn in Saudi Arabia's Tabuk (see Boundary choices).
- **KE.**
  - RCMRD counties. The Ilemi Triangle is part of Turkana (KE-43), as NE's Kenya includes it.
  - The source's southern border lies slightly inside NE's. The sliver between them was shared among Migori, Narok and Kajiado by nearest county.
- **EC.**
  - World Bank provinces. NE's are coarse and swap the codes of Napo and Tungurahua: NE's `EC-N` polygon contains Ambato.
  - The World Bank data has the resolved boundary disputes:
    - La Concordia in Santo Domingo de los Tsáchilas;
    - Manga del Cura in Manabí;
    - Las Golondrinas in Imbabura;
    - El Piedrero split between Cañar and Guayas.
- **CU.**
  - NE provinces. NE's Pinar del Río/Artemisa boundary predates the 2011 division: Bahía Honda, San Cristóbal and Candelaria are wrongly in Pinar del Río. It was redrawn from the World Bank data.
  - The World Bank data was not used elsewhere because it puts Cayo Coco in Camagüey instead of Ciego de Ávila.
  - The Guantánamo Bay naval base is part of Guantánamo (CU-14), as the WORLD maps merge it into Cuba.
- **NP.** The Survey Department of Nepal's 7 provinces. NE still has the 14 pre-2015 zones.
- **MN.**
  - NSO aimags. NE's Govisümber is 647 km² instead of 5,542 km², and NE's Ulaanbaatar lacks its Baganuur and Bagakhangai exclaves.
  - Those exclaves are separate parts of MN-1. Darkhan-Uul and Orkhon are islands inside Selenge and Bulgan.
- **SA.**
  - World Bank regions. Saudi regional boundaries in the deserts differ widely between sources. NE's Najran and Tabuk are 30–40% smaller than official figures, and its Al Jawf and Northern Borders much larger. The World Bank data matches the official proportions better.
  - Tiran and Sanafir are in Tabuk (SA-07).

## Boundary choices and disputed areas

Each map follows the same view as the WORLD maps: Natural Earth's de facto outlines, with the previous agent's choices (`MAP_SOURCES.md` → "Boundary choices"). The overlays use the same ids, names and notes as `geo_WORLD.json`'s layers. Their geometry is NE's full-resolution disputed areas and boundary lines, simplified with each map's settings. Claimants are `geo_WORLD.json`'s, adapted with the convention of `map_IN.json`: an area that lies in the map's own divisions lists those divisions instead of the map's country. A division counts if it holds at least a tenth of the area, or if at least half of the division lies inside the area.

| Map | Area | Claimants | Lines |
|---|---|---|---|
| UA | crimea (Crimea) | UA-40, UA-43, WORLD-RU | crimea-boundary (Perekop/Syvash and Kerch Strait segments) |
| EG | halaib-triangle (Hala'ib Triangle) | EG-BA, WORLD-SD | egypt-sudan-22nd-parallel, egypt-sudan-1902-line |
| EG | bir-tawil (Bir Tawil) | none | (as above) |
| KE | ilemi-triangle (Ilemi Triangle) | KE-43, WORLD-SS | ilemi-line |
| NP | kalapani (Kalapani) | WORLD-IN, WORLD-NP | – |

- **Crimea.** UA-43 and UA-40 are drawn with Ukraine's internationally recognised boundaries. The overlay marks the area administered by Russia since 2014.
- **Egypt and Sudan.**
  - Egypt's southern boundary is NE's, as in `geo_WORLD.json`: the Hala'ib Triangle is inside the Red Sea governorate, and Bir Tawil, south of 22°N, is outside Egypt.
  - EG's canvas extends below the border so that Bir Tawil is drawn whole.
- **Kalapani.** The area lies outside Nepal's regions (NE puts it in India), so its claimants stay WORLD ids. It is NE's small "Near Om Parvat" polygon. Nepal's 2020 map claims a larger area (Limpiyadhura–Lipulekh–Kalapani).
- **Clipping.** Disputed lines are clipped to the canvas in the map files (the Ilemi line runs north beyond the triangle) and are complete in the geo files.
- **Not added**, for consistency with the selection in `geo_WORLD.json`. All are in Natural Earth and can be added:
  - **Ukraine.** Russian-occupied areas beyond Crimea, and Russia's 2022 claims to the Donetsk, Luhansk, Zaporizhzhia and Kherson oblasts. No stable public-domain boundary exists, and NE's 2014 Donetsk and Luhansk lines are out of date.
  - **Uruguay.** The Corner of Artigas (Rincón de Artigas) and Brazilian Island: dormant claims, which the previous agent also left out.
  - **Cuba.** Guantánamo Bay, a lease merged into Cuba as on the WORLD maps.
  - **Saudi Arabia and Egypt.** NE lists Tiran and Sanafir as "administered by Egypt, claimed by Saudi Arabia". Both governments agreed in 2016 that they are Saudi (ratified by Egypt in 2017), so they are drawn in Tabuk with no overlay. `geo_WORLD.json` drops both islets, so the world map is not affected.
  - **Kenya.** Migingo Island in Lake Victoria (Kenya–Uganda): a rock of about 0.2 ha, not in NE.
- No other territorial dispute applies to IS, EE, LT, SK, RO, BG, EC, BO, MN or SA.

## Rendering notes

- **Fill rule.** Fill regions and overlays with the even-odd rule: lakes and enclaves are extra rings.
  - Ulaanbaatar sits inside Töv; Darkhan-Uul and Orkhon sit inside Selenge and Bulgan; Bucharest sits inside Ilfov; Kyiv sits inside Kyivska; Sofia city sits inside Sofia province; Nairobi and Montevideo are small.
  - All of these are larger than 3 units, so none needs a marker.
- **Overlays.** Draw them on top of the regions: hatched areas, dashed lines.
  - The `crimea` outline coincides with UA-43 ∪ UA-40.
  - The `halaib-triangle` and `ilemi-triangle` outlines coincide with the borders they follow.
  - Bir Tawil and Kalapani lie outside every region of their maps.
- **Inset.** EC's Galápagos inset is at a different scale from the mainland.
- **Geo files over the world map.** Where a lake is cut, the world map's country fill shows through (see above).
