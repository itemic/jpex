# Unprojected collection maps (`geo_<ID>.json`)

Generated on 8 October 2026. The app bundles these files for offline use; it does not request map data from a network service at runtime.

The 27 files `jpex/Maps/geo_<ID>.json` (JP, AU, CA, CN, FR, DE, IT, ES, CH, GB, US, KR, TW, AT, NL, BE, PL, PT, NO, BR, AR, MX, MY, TH, PH, ID, IN) hold each collection's subdivision outlines in longitude and latitude. The app projects them on the device in the same projection and with the same central meridian as `geo_WORLD.json`, so a country's subdivisions line up with the World map's country outlines.

They contain the same places as the projected `map_<ID>.json` files (see `MAP_SOURCES.md`), but every place is in its true location. There are no insets or frames: Alaska, Hawaii, Okinawa, the overseas departments, the Azores and Madeira, the Canaries, Kinmen and Matsu, and the Australian external territories all sit where they are on the globe.

## File format

```json
{"id": "JP", "width": 360, "height": 180,
 "regions": [{"id": "JP-01", "d": "M141.35 43.06L141.4 43.1L…Z M…Z", "c": [142.8, 43.4]}],
 "disputed": [], "disputedLines": []}
```

- **Coordinates.** `x` is longitude (−180…180) and `y` is latitude (−90…90, north positive, not flipped). `width` and `height` are nominal (360 × 180). There are no frames.
- **Paths.** `d` uses only absolute `M`, `L` and `Z`, with at most 3 decimals. The two numbers of a point are separated by a single space, and the command letter comes directly before x.
  - Each subpath is one ring (`M…Z`), and subpaths are separated by a space.
  - Holes (lakes, enclaves) are extra rings, so fill with the even-odd rule.
- **Regions.** Exactly the same ids as the matching `map_<ID>.json`, including:
  - `WORLD-TW` on China's map;
  - the Australian external territories and `AU-AAT`;
  - the French overseas departments;
  - the US territories.
- **Order.** Regions are sorted by area, largest first, so small places and enclaves draw on top. Area is measured on an equal-area projection, so `AU-AAT` is now Australia's first region.
- **Label point.** `c` is a label point inside the region, in lon/lat. It is Natural Earth's label point if that falls in a substantial part of the drawn shape (at least a quarter of the largest part). Otherwise it is the pole of inaccessibility of the largest part, computed on the equal-area working canvas and converted back. Each one was checked to be inside the region under even-odd filling.
- **Disputed overlays.** `disputed` and `disputedLines` are present in every file. They are empty except in IN, CN, JP, KR and PH, which carry the same overlays as their projected maps (see below).
- **Antimeridian.** No edge crosses ±180°. Only the US file has parts on both sides: Guam, the Northern Mariana Islands, and Alaska's Rat and Near Islands (Attu to Semisopochnoi) lie east of 180°. Natural Earth already splits them, and no polygon straddles the line.
  - With any other central meridian, the app must cut rings where they cross lon₀ ± 180°.
  - Every edge is short, so such a crossing shows up as a longitude jump of more than 180° between consecutive points, just as in `geo_WORLD.json`.
- **Edge length.** No edge is longer than 0.5° (Euclidean in lon/lat), so straight borders bend correctly in curved projections. These include the 49th parallel, the western US and Australian state lines, the Canadian territories and `AU-AAT`'s sector meridians. Longer edges were subdivided linearly in lon/lat.
- **Australian Antarctic Territory.** `AU-AAT` reaches the South Pole. Its rings run along latitude −90 between the sector meridians (44°38′E–136°11′E and 142°02′E–160°E), with a vertex at least every 0.5°.
  - Mercator cannot show −90. The app's Mercator clamps latitude at ±85°, so the territory's southern part is flattened onto that line.

## Sources and licences

These are the same datasets as the projected maps; no new source was added. The table and the licence notes are in `MAP_SOURCES.md`:

- Natural Earth 1:10m (public domain).
- geoBoundaries gbOpen IDN ADM2 and PHL ADM2/ADM3 (CC BY 3.0 IGO). Cite Runfola, D. et al. (2020), *geoBoundaries: A global database of political administrative boundaries*, PLoS ONE 15(4): e0231866.
- Kartverket fylker 2024 (CC BY 4.0, © Kartverket).
- NLSC/MOI county boundaries, version 1140318 (Open Government Data License 1.0).

Every dataset was modified: merged or split as described in `MAP_SOURCES.md`, and simplified.

## Processing

1. **Same geometry as the projected maps.** The lon/lat region geometries were taken from the same builder code that made `map_<ID>.json`, stopped just before projection. Everything listed in `MAP_SOURCES.md` therefore applies unchanged: the dissolves, the id mappings, the fixes and the lake cut-outs. Examples:
   - The Amami islands are in Kagoshima.
   - Dokdo is in `KR-47` and Siachen in `IN-LA`.
   - Maguindanao is split into del Norte and del Sur.
   - Indonesia has its new provinces, and Norway's counties are clipped to land.
   - `WORLD-TW` on China's map is NE's Taiwan plus Matsu.
2. **Working canvas.** Each collection was projected to Equal Earth with its central meridian at the country (the `lon₀` column below). Equal Earth is equal-area, so the area thresholds are true areas everywhere, from Florida to Alaska or Guam. Its poles are lines, so `AU-AAT`'s pole edge survives.
   - The canvas is scaled so one unit is the same ground distance as one unit of `map_<ID>.json` (the "km/unit" column), which lets the projected maps' thresholds carry over.
   - Every canvas vertex remembers its original lon/lat.
3. **Islets and holes.** Connected landmasses smaller than the islet threshold are dropped, but each region's largest part is always kept. Holes smaller than the hole threshold are filled unless another region fills them (enclaves). Three changes from the projected maps:
   - **Small regions.** A region's islet threshold is at most 2% of its own area, so small places keep their islands (Ofu–Olosega in American Samoa, Aguijan in the Northern Marianas, the Cocos atoll).
   - **Exclaves.** A small part that touches another country's land is not an islet, because `geo_WORLD.json` keeps it through the neighbouring country. Kept: Point Roberts (US-WA), Grosse Ile (US-MI), a Thousand Islands island in US-NY, and Wolfe and Howe Islands (CA-ON).
   - **Protected parts.** As on the projected maps, Dokdo (`KR-47`) and Kinmen and Matsu (`WORLD-TW` on China's map) are always kept.
4. **Shared vertices.** Before the topology is built, each region is snapped (GEOS snap, tolerance 0.00001°, about 1 m) to the outlines of the regions it touches, one region after another. This makes both sides of a border carry the same vertices. Without it, a vertex present on only one side, such as where the Maguindanao del Norte/del Sur line meets the provincial border, would be rounded off its neighbour's edge and open a sliver. Snapping changed 16 regions in eight maps (TW 7, BR 2, PH 2, and CA, NL, NO, PL and TH 1 each). A snap that would have changed a region's area by more than one part in a million was discarded.
5. **Simplification.** Coordinates are snapped to a 0.01-unit grid and split into shared arcs, so each border between two regions is stored once and stays identical on both sides. Each arc is simplified once with weighted Visvalingam–Whyatt (k = 0.7), using the same thresholds as the projected maps; CN and IN use coarser thresholds to fit the size budget. As on the projected maps, an open arc keeps at least one interior vertex, unless all its interior vertices are exactly collinear with its ends. Three additions:
   - **Small places.** A region smaller than 3,000 × the threshold is simplified relative to its own size (the threshold is multiplied by area ÷ (3,000 × threshold)). Its shared borders get the finer of the two neighbours' thresholds. Small places therefore keep nearly all their source vertices:
     - Brussels 24 of 24; Vienna 57 of 61; Berlin 122 of 219; Seoul 44 of 44.
     - Hong Kong 231 of 394; Macau 82 of 90; Paris 15 of 15.
     - Guam 45 of 48; Christmas Island 27 of 27; Heard Island 53 of 53.
     - Ceuta 13 of 13; Melilla 6 of 7.
   - **Islands.** An island or lake ring that touches no other region keeps at least five interior vertices when the source has them, so small islands stay recognisable blobs instead of triangles.
   - **Repair.** If simplification makes a region overlap itself under even-odd filling (by more than 0.03 square units), or overlap a neighbour by more than 0.01 square units (0.05 on the projected maps), only the arcs at the defect are refined, and the step repeats.
6. **Output.** The retained vertices are written with their original lon/lat, not projected back, so outlines match `geo_WORLD.json` wherever both kept the same Natural Earth vertex.
   - Edges are subdivided to at most 0.49° before rounding, then coordinates are rounded to 3 decimals (about 110 m). Duplicate points and spikes created by rounding are removed.
   - The only region that collapses at 3 decimals is `AU-CS`. Natural Earth's Coral Sea Islands polygon is a 3-vertex, 0.2 km² speck, so it is written as a ±0.002° square at its location. `AU-AC` (Ashmore and Cartier) is NE's 4-vertex polygon.
7. **Disputed overlays.** These are the same disputed areas and lines as the projected maps, with the same `id`, `name`, `claimants` and `note`, copied from `map_IN/CN/JP/KR/PH.json`.
   - The geometry is Natural Earth's disputed areas and boundary lines in lon/lat (as in `geo_WORLD.json`), with the collection's lakes cut out as in its regions.
   - The overlays are part of the same topology as the regions. Wherever Natural Earth's vertices coincide, an overlay edge or line follows the region border exactly; for example, the Line of Control follows `IN-JK`/`IN-LA`, and `liancourt-rocks` is identical to Dokdo in `KR-47`.
   - On the projected maps, Gilgit-Baltistan, the Trans-Karakoram Tract and the southern Kurils were clipped at the canvas edge. Here they are complete, and the Senkakus are at their true location rather than in the Okinawa inset.

| Map | Regions | Rings | Points | Size | Simplify | Islet | Hole | km/unit | lon₀ |
|---|---|---|---|---|---|---|---|---|---|
| JP | 47 | 129 | 8,825 | 135.5 KB | 0.15 u² ≈ 0.64 km² | 0.6 u² ≈ 2.6 km² | 17 km² | 2.065 | 137° |
| AU | 16 | 127 | 10,493 | 158.3 KB | 0.15 u² ≈ 2.5 km² | 0.6 u² ≈ 10 km² | 67 km² | 4.093 | 132° |
| CA | 13 | 270 | 16,331 | 240.4 KB | 0.45 u² ≈ 13 km² | 3 u² ≈ 89 km² | 118 km² | 5.434 | −91.87° |
| CN | 34 | 99 | 13,872 | 214.2 KB | 0.38 u² ≈ 9.3 km² | 1 u² ≈ 24 km² | 97 km² | 4.936 | 105° |
| FR | 101 | 123 | 14,186 | 185.1 KB | 0.45 u² ≈ 0.64 km² | 0.6 u² ≈ 0.86 km² | 5.7 km² | 1.195 | 3° |
| DE | 16 | 41 | 9,699 | 127.1 KB | 0.12 u² ≈ 0.094 km² | 0.8 u² ≈ 0.63 km² | 3.1 km² | 0.887 | 10.5° |
| IT | 20 | 51 | 7,246 | 96.6 KB | 0.12 u² ≈ 0.21 km² | 0.8 u² ≈ 1.4 km² | 6.9 km² | 1.313 | 12.5° |
| ES | 19 | 43 | 8,006 | 108.0 KB | 0.15 u² ≈ 0.2 km² | 0.6 u² ≈ 0.81 km² | 5.4 km² | 1.165 | −3.5° |
| CH | 26 | 44 | 4,672 | 59.5 KB | 0.12 u² ≈ 0.015 km² | 0.8 u² ≈ 0.1 km² | 0.5 km² | 0.354 | 7.44° |
| GB | 4 | 60 | 6,256 | 84.3 KB | 0.15 u² ≈ 0.23 km² | 0.8 u² ≈ 1.2 km² | 6.1 km² | 1.234 | −2° |
| US | 56 | 320 | 15,084 | 226.2 KB | 0.25 u² ≈ 5.5 km² | 1 u² ≈ 22 km² | 89 km² | 4.706 | −96° |
| KR | 17 | 71 | 4,394 | 64.6 KB | 0.12 u² ≈ 0.051 km² | 0.8 u² ≈ 0.34 km² | 1.7 km² | 0.654 | 127.5° |
| TW | 22 | 64 | 9,886 | 143.8 KB | 0.25 u² ≈ 0.04 km² | 1 u² ≈ 0.16 km² | 0.64 km² | 0.401 | 121° |
| AT | 9 | 11 | 2,399 | 32.6 KB | 0.12 u² ≈ 0.041 km² | 0.8 u² ≈ 0.27 km² | 1.4 km² | 0.584 | 13.33° |
| NL | 12 | 23 | 2,276 | 29.0 KB | 0.12 u² ≈ 0.012 km² | 0.8 u² ≈ 0.081 km² | 0.41 km² | 0.319 | 5.387° |
| BE | 11 | 14 | 1,710 | 21.8 KB | 0.12 u² ≈ 0.0093 km² | 0.8 u² ≈ 0.062 km² | 0.31 km² | 0.278 | 4.359° |
| PL | 16 | 19 | 3,498 | 47.8 KB | 0.12 u² ≈ 0.059 km² | 0.8 u² ≈ 0.4 km² | 2 km² | 0.704 | 19° |
| PT | 20 | 33 | 4,132 | 56.9 KB | 0.15 u² ≈ 0.052 km² | 0.6 u² ≈ 0.21 km² | 1.4 km² | 0.588 | −8.13° |
| NO | 15 | 126 | 11,938 | 157.1 KB | 0.2 u² ≈ 0.46 km² | 1 u² ≈ 2.3 km² | 9.2 km² | 1.515 | 15° |
| BR | 27 | 77 | 12,671 | 189.4 KB | 0.2 u² ≈ 4.3 km² | 0.8 u² ≈ 17 km² | 87 km² | 4.661 | −54° |
| AR | 24 | 33 | 6,000 | 93.4 KB | 0.15 u² ≈ 2.1 km² | 0.8 u² ≈ 11 km² | 57 km² | 3.771 | −64° |
| MX | 32 | 83 | 10,198 | 154.2 KB | 0.15 u² ≈ 1.6 km² | 0.8 u² ≈ 8.4 km² | 42 km² | 3.235 | −102° |
| MY | 16 | 32 | 3,593 | 49.1 KB | 0.12 u² ≈ 0.59 km² | 0.8 u² ≈ 4 km² | 20 km² | 2.225 | 109.5° |
| TH | 77 | 95 | 12,261 | 173.9 KB | 0.2 u² ≈ 0.56 km² | 0.8 u² ≈ 2.2 km² | 11 km² | 1.672 | 101° |
| PH | 83 | 349 | 14,369 | 206.8 KB | 0.3 u² ≈ 1 km² | 1 u² ≈ 3.5 km² | 14 km² | 1.865 | 122° |
| ID | 38 | 253 | 12,473 | 177.9 KB | 0.25 u² ≈ 6.8 km² | 2 u² ≈ 55 km² | 109 km² | 5.226 | 118° |
| IN | 36 | 73 | 13,451 | 214.8 KB | 0.3 u² ≈ 3 km² | 0.8 u² ≈ 8 km² | 40 km² | 3.165 | 80° |

The total is 3,530,859 bytes (3.37 MB). Sizes include the disputed overlays. CN and IN are the only maps whose simplify threshold differs from the projected maps: 0.30 → 0.38 for CN and 0.25 → 0.30 for IN, to stay within 220 KB. Elsewhere the point counts are within a few per cent of the projected maps, except where places are now at true scale, such as Alaska (previously at 0.35×) and the Australian Antarctic Territory.

## Same omissions as the projected maps

These parts were left out of `map_<ID>.json` and are also left out here, so both files show the same places:

- **JP.** Tokyo's Ogasawara and Volcano Islands, Okinotorishima and Minamitorishima.
- **US.** The Northwestern Hawaiian Islands; Swains Island and Rose Atoll; the Northern Mariana Islands north of Saipan.
- **AU.** Macquarie Island and Lord Howe Island.
- **PT.** The Selvagens.
- **BR.** Trindade and Martim Vaz, and the St Peter and St Paul Archipelago.
- **CN.** The Paracel Islands; Hainan is limited to the island.
- **TW.** The remote and disputed islets listed in `MAP_SOURCES.md`.
- **PH.** The Kalayaan Island Group.
- **Not part of their collections.** Svalbard and Jan Mayen (NO) and the Caribbean Netherlands (NL).

Of these, only Macquarie Island (128 km²) is drawn in `geo_WORLD.json`, as part of `WORLD-AU`. When Australia's subdivisions replace the country outline, that speck 1,400 km south-east of Tasmania is not shown. Adding it to `AU-TAS` would stretch Tasmania's bounds to about 55°S, so it was left out for consistency with `map_AU.json`.

## Alignment with `geo_WORLD.json`

For each collection, the union of its regions was compared with its own countries in `geo_WORLD.json`. These are `WORLD-<ID>` plus the shared ids: CN-HK, CN-MO and `WORLD-TW` for CN; the US territories; the French overseas departments; the Australian external territories; and the four UK nations.

- **Areas.** These agree within 1.6% except in three maps:
  - NL is 3.9% smaller, because the IJsselmeer and Markermeer are holes here but land in the world map.
  - TW (+3.3%) and PH (+3.1%) are larger, because their sources (MOI/NLSC and geoBoundaries) are more detailed than the world map.
  - The smaller differences come from lakes, fjords (NO −1.3%) and small islands that the world map drops (JP +1.4%, KR +1.6%).
- **World land missing here.** The farthest point of a world outline from the collection's land is 11 km or less in every map. These gaps are lakes cut out here but not in the world map, such as Lake St. Clair, the Bodensee and Lac Léman. The exception is AU's Macquarie Island (see above).
- **Land here missing from the world map.** These are only small islands that `geo_WORLD.json` drops at world scale (under about 100 km²). Examples: the Daitō Islands, Lampedusa, Dokdo, Matsu, Fernando de Noronha, the Revillagigedo Islands, Lakshadweep, Batanes, Manuʻa, St Kilda and the Coral Sea speck.
- **Displacement.** Nothing is displaced. `AU-AAT` lies 99.9% inside `WORLD-AQ`.

## Validation

Every file was re-parsed and checked for:

- **Grammar.** Numbers have at most 3 decimals, with no exponents or `-0`; spacing is as specified; closed rings have at least 3 distinct points; lines have no `Z`.
- **Ids.** The region id set and count are exactly those of `map_<ID>.json`, with no duplicates.
- **Structure.** Top-level keys and order are as specified.
- **Coordinates.** All are within −180…180 and −90…90. No edge is longer than 0.5° (the maximum is 0.491°), and there are no antimeridian jumps.
- **Label points.** Every `c` is inside its region and every disputed `c` inside its area.
- **Order.** Regions are sorted by equal-area area.
- **Disputed metadata.** Disputed `id`/`name`/`claimants`/`note` and line `id`/`name` match the projected maps.
- **Size budget.** 220 KB (300 KB for US, CA, ID, PH and NO).
- **App parser.** A port of the app's `TravelMap.rings(fromSVG:)` reads every path exactly as the validator does.

Overlap between regions is exactly zero in 23 maps. In the other four it is slivers under a few metres wide, already present at full source detail or left by rounding: PH 0.04 km², NO 0.015 km², PL 0.006 km² and NL 0.004 km².

Previews were rendered in Winkel Tripel (central meridian at the country) over `geo_WORLD.json`'s countries, with the world outline of the country drawn on top, and inspected. They covered JP, US, FR, IN, CN, NO and ID in full, every other collection, and zoomed crops:

- Kanto at about 4× phone zoom, Okinawa and the Senkakus, the Kurils;
- Alaska and the Aleutians across 180°, Hawaii, Puerto Rico and the Virgin Islands, Guam and the Northern Marianas, American Samoa, the Northeast;
- metropolitan France, Paris, and each overseas department;
- Kashmir, India's northeast, Delhi and Puducherry;
- the Pearl River Delta (Hong Kong, Macau) and the Taiwan Strait;
- Oslo, Lofoten and Finnmark; Jakarta and Papua;
- the Australian Antarctic Territory, the ACT and Jervis Bay, and Christmas, Cocos, Norfolk and Heard Islands;
- Brussels, Vienna, Berlin, Seoul and Dokdo, Kinmen and Matsu, Manila and Scarborough Shoal, Bangkok, Mexico City and Buenos Aires.

The US was also rendered with central meridian 0°, which splits Alaska at the edge of the map, to confirm there are no streaks across the map.
