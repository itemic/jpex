# Map data

Retrieved and generated on 7 October 2026; disputed-area layers, `geo_WORLD.json`, the Western Sahara correction and Taiwan on China's map added on 8 October 2026. The app bundles these files for offline use; it does not request map data from a network service at runtime.

The 28 files in `jpex/Maps/` named `map_<ID>.json` (`map_WORLD.json`, `map_JP.json`, …) contain projected, simplified outlines for every place in the corresponding collection. `jpex/Maps/geo_WORLD.json` holds the same world regions in geographic coordinates for runtime projection (see below). `jpex/MapCredits.json` lists the sources for Settings → Acknowledgements.

## File format

```json
{"id": "JP", "width": 784.2, "height": 1000.0,
 "regions": [{"id": "JP-01", "d": "M512.3 80.1L520.4 82.2L519 85Z M600 90L601.5 92L598 93Z", "c": [530.2, 101.7]}],
 "frames": [[10.0, 10.0, 424.7, 208.2]]}
```

- Planar canvas, origin top-left, y grows down. The longer side is exactly 1000 units, with a 10-unit margin.
- `d` uses only absolute `M`, `L` and `Z`, at most one decimal, one ring per `M…Z` subpath. Holes (lakes, enclaves) are extra rings, so fill with the even-odd rule.
- `c` is a label or marker point inside the region. It is NE's hand-placed label point if that falls in a substantial part of the drawn shape; otherwise it is the pole of inaccessibility of the largest part.
- Regions are sorted by area, largest first, so enclaves and small places draw on top.
- `frames` lists `[x, y, w, h]` rectangles around insets. It is omitted when a map has no insets.

## Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Natural Earth](https://www.naturalearthdata.com/) 1:10m, version 5.1.1: Admin 0 map subunits, Admin 1 states and provinces (with and without large lakes), Admin 0 disputed areas; lakes (5.0.0); Admin 0 boundary lines (land) and disputed-area boundary lines (5.1.0); minor islands (4.1.0) | WORLD (both files) and 23 country maps; Norway's coastline; lakes in ID and PH; disputed areas and lines; Taiwan (with Matsu from minor islands) on China's map | Public domain ([terms](https://www.naturalearthdata.com/about/terms-of-use/)) |
| [geoBoundaries](https://www.geoboundaries.org/) gbOpen IDN ADM2 (2020; BPS – Statistics Indonesia, WFP, OCHA ROAP), simplified release, build `9469f09` | Indonesia | CC BY 3.0 IGO |
| geoBoundaries gbOpen PHL ADM2 (build `41af8f1`) and ADM3 (build `9469f09`) (2020; NAMRIA, PSA, OCHA Philippines), simplified releases | Philippines | CC BY 3.0 IGO |
| [Kartverket – Administrative enheter fylker](https://kartkatalog.geonorge.no/metadata/administrative-enheter-fylker/6093c8a8-fa80-11e6-bc64-92361f002671) via Geonorge (`Basisdata_0000_Norge_4258_Fylker_GeoJSON`, data dated December 2025) | Norway's 15 counties (2024) | CC BY 4.0, © Kartverket |
| [NLSC, Ministry of the Interior – 直轄市、縣市界線 (TWD97)](https://data.gov.tw/dataset/7442), version 1140318 | Taiwan's 22 units | [Open Government Data License, version 1.0](https://data.gov.tw/license) |

geoBoundaries asks users to cite Runfola, D. et al. (2020), *geoBoundaries: A global database of political administrative boundaries*, PLoS ONE 15(4): e0231866. Every dataset was modified: reprojected, merged or split as described below, and simplified.

Datasets checked but not used: geoBoundaries IDN ADM1 and TWN ADM1/ADM2 (OpenStreetMap-derived, ODbL), NOR ADM1 (2020–23 counties), and IND ADM1 (2011).

## Processing

1. **Regions.** Source units were mapped to the app's ids, then dissolved or split where needed. Notable lakes from NE's lakes layer were cut out as holes; the thresholds are listed per map below.
2. **Projection and layout.** Each map uses a projection suited to its extent; see the table. Insets are projected separately, placed in a box, and outlined in `frames`.
3. **Islets.** Polygons are grouped into connected landmasses, and any landmass smaller than the islet threshold is dropped. Each region's largest part is always kept, so no listed place disappears. Holes smaller than the hole threshold are filled. Holes occupied by another region (enclaves) are always kept.
4. **Simplification.** Coordinates are snapped to a 0.01-unit grid and decomposed into shared arcs: each border between two regions is stored once. Every arc is simplified once with weighted Visvalingam–Whyatt (mapshaper-style weighting, k = 0.7), so neighbouring regions keep identical borders. Each arc keeps at least one interior point and each closed ring at least three, so small islands stay polygons instead of collapsing.
5. **Repair.** If simplification makes a region's parts overlap under even-odd filling, or makes two regions overlap by more than 0.05 square units, the threshold for the arcs involved is cut to a quarter and the step repeats, falling back to full detail.
6. **Output.** Coordinates are rounded to 0.1. A place smaller than about 0.35 units, which would collapse when rounded, is written as a 0.6-unit square at its location; this applies to 17 WORLD regions.
7. **Validation.** Every file is re-parsed and checked: path grammar, coordinates inside the canvas, id set (no unknown, duplicate or missing ids), `c` inside its path under even-odd, sort order, frames and size budget. A preview PNG of every map was rendered and inspected. Total overlap between regions is effectively zero in every map, which confirms the shared borders are consistent.

Thresholds are in canvas units: square units for areas, with 1000 units across the longer side. "km/unit" is the scale of the main map.

| Map | Regions | Size | Canvas | km/unit | Simplify (u²) | Islet (u² ≈ km²) | Hole (u²) | Projection |
|---|---|---|---|---|---|---|---|---|
| WORLD | 254 | 399.9 KB | 1000 × 500.9 | 34.7 | 0.10 | 0.15 ≈ 181 | 0.6 | Equal Earth, central meridian 0° |
| JP | 47 | 104.9 KB | 908.8 × 1000 | 2.07 | 0.15 | 0.6 ≈ 2.6 | 4 | Lambert conformal conic (33°/44°N, 137°E) |
| AU | 16 | 88.9 KB | 1000 × 955.2 | 4.09 | 0.15 | 0.6 ≈ 10 | 4 | Albers (18°/36°S, 132°E; EPSG:3577 parameters) |
| CA | 13 | 150.9 KB | 1000 × 862.6 | 5.43 | 0.45 | 3.0 ≈ 89 | 4 | Lambert conformal conic (Statistics Canada, EPSG:3347 parameters) |
| CN | 34 | 170.7 KB | 1000 × 839.6 | 4.94 | 0.30 | 1.0 ≈ 24 | 4 | Albers (25°/47°N, 105°E) |
| FR | 101 | 161.9 KB | 1000 × 907.2 | 1.20 | 0.45 | 0.6 ≈ 0.9 | 4 | Lambert-93 parameters |
| DE | 16 | 109.4 KB | 742.8 × 1000 | 0.89 | 0.12 | 0.8 ≈ 0.6 | 4 | Lambert conformal conic (48.67°/53.67°N, 10.5°E) |
| IT | 20 | 82.3 KB | 762.4 × 1000 | 1.31 | 0.12 | 0.8 ≈ 1.4 | 4 | Lambert conformal conic (38°/46°N, 12.5°E) |
| ES | 19 | 90.1 KB | 1000 × 930.5 | 1.17 | 0.15 | 0.6 ≈ 0.8 | 4 | Lambert conformal conic (37°/43°N, 3.5°W) |
| CH | 26 | 53.7 KB | 1000 × 640.9 | 0.35 | 0.12 | 0.8 ≈ 0.1 | 4 | Swiss oblique Mercator (LV95 parameters) |
| GB | 4 | 70.7 KB | 792.3 × 1000 | 1.23 | 0.15 | 0.8 ≈ 1.2 | 4 | British National Grid transverse Mercator |
| US | 56 | 121.9 KB | 1000 × 696.2 | 4.71 | 0.25 | 1.0 ≈ 22 | 4 | Albers (29.5°/45.5°N, 96°W) |
| KR | 17 | 50.8 KB | 1000 × 940.2 | 0.65 | 0.12 | 0.8 ≈ 0.3 | 4 | Transverse Mercator (127.5°E; Korea 2000 Unified) |
| TW | 22 | 109.6 KB | 704.0 × 1000 | 0.40 | 0.25 | 1.0 ≈ 0.2 | 4 | Transverse Mercator (121°E; TWD97 TM2) |
| AT | 9 | 27.3 KB | 1000 × 521.4 | 0.58 | 0.12 | 0.8 ≈ 0.3 | 4 | Lambert conformal conic (46°/49°N, 13.33°E) |
| NL | 12 | 26.1 KB | 843.6 × 1000 | 0.32 | 0.12 | 0.8 ≈ 0.1 | 4 | Oblique stereographic (RD New parameters) |
| BE | 11 | 19.7 KB | 1000 × 819.3 | 0.28 | 0.12 | 0.8 ≈ 0.1 | 4 | Lambert conformal conic (Belgian Lambert 2008 parameters) |
| PL | 16 | 39.8 KB | 1000 × 933.3 | 0.70 | 0.12 | 0.8 ≈ 0.4 | 4 | Transverse Mercator (19°E; PUWG 1992 parameters) |
| PT | 20 | 47.0 KB | 955.8 × 1000 | 0.59 | 0.15 | 0.6 ≈ 0.2 | 4 | Transverse Mercator (PT-TM06 parameters) |
| NO | 15 | 133.0 KB | 795.4 × 1000 | 1.52 | 0.20 | 1.0 ≈ 2.3 | 4 | UTM zone 33N |
| BR | 27 | 141.9 KB | 1000 × 939.8 | 4.66 | 0.20 | 0.8 ≈ 17 | 4 | Albers (2°/22°S, 54°W) |
| AR | 24 | 65.1 KB | 478.1 × 1000 | 3.77 | 0.15 | 0.8 ≈ 11 | 4 | Albers (28°/48°S, 64°W) |
| MX | 32 | 115.0 KB | 1000 × 647.1 | 3.24 | 0.15 | 0.8 ≈ 8 | 4 | Lambert conformal conic (17.5°/29.5°N, 102°W; INEGI) |
| MY | 16 | 39.1 KB | 1000 × 343.5 | 2.23 | 0.12 | 0.8 ≈ 4 | 4 | Mercator (true scale at 4°N, 109.5°E) |
| TH | 77 | 139.0 KB | 548.8 × 1000 | 1.67 | 0.20 | 0.8 ≈ 2.2 | 4 | Transverse Mercator (101°E) |
| PH | 83 | 146.0 KB | 592.8 × 1000 | 1.87 | 0.30 | 1.0 ≈ 3.5 | 4 | Transverse Mercator (122°E) |
| ID | 38 | 158.3 KB | 1000 × 383.2 | 5.23 | 0.25 | 2.0 ≈ 55 | 4 | Mercator (118°E) |
| IN | 36 | 176.2 KB | 923.6 × 1000 | 3.17 | 0.25 | 0.8 ≈ 8 | 4 | Lambert conformal conic (12.47°/35.17°N, 80°E) |

Every listed id has a shape. None were omitted, including AU-AAT. CN's count includes the extra `WORLD-TW` region; the IN, CN, JP, KR and PH sizes include their disputed overlays. JP's width grew from 784.2 to 908.8 to fit the southern Kurils overlay; its existing coordinates did not change.

## Insets and frames

| Map | Frames | Contents |
|---|---|---|
| US | 7 | Alaska at 0.35× and Hawaii's main islands at 1×, bottom-left, each in its own Albers projection. Then a row along the bottom, each territory fitted to its box: Guam, Northern Mariana Islands, American Samoa, Puerto Rico, US Virgin Islands. |
| FR | 5 | Equal boxes down the left side, in the Bay of Biscay, in INSEE order: 971 Guadeloupe, 972 Martinique, 973 Guyane, 974 La Réunion, 976 Mayotte. Each is fitted to its box, so the scales differ. Mainland and Corsica form the main map. |
| ES | 1 | Canary Islands at 0.8× main scale, bottom-left, below Ceuta's latitude. Ceuta, Melilla and the Balearics stay in place. |
| PT | 2 | Azores, top-left, and Madeira, below it, fitted to their boxes. |
| JP | 1 | Okinawa at the same scale as the main map, top-left: the whole prefecture, from Yonaguni to the Daitō Islands. |
| AU | 7 | Cocos (Keeling), Christmas Island and Ashmore and Cartier top-left; Coral Sea Islands and Norfolk Island top-right; Heard Island and the Australian Antarctic Territory bottom-left. Each territory is fitted to its box. Ashmore and Cartier and Coral Sea are capped at 40× main scale because they are reef specks. |
| TW | 2 | Lienchiang (Matsu) above Kinmen, top-left, each fitted to its box. I added these because Taiwanese maps conventionally box them, and keeping them in place would shrink the main island by about a quarter. |

All other maps have no insets.

## Per-map notes

- **WORLD.** Built from NE map subunits. The French overseas departments, US territories, Hong Kong, Macau and the Australian external territories use the shared ids (FR-971…, US-PR…, CN-HK, CN-MO, AU-CX, AU-CC, AU-NF, AU-HM).
  - The four UK nations come from the subunits; `WORLD-GB` is their exact union, so its outline matches theirs.
  - Merged: Corsica into France; Svalbard and Jan Mayen into WORLD-SJ; the nine US Minor Outlying Islands units into WORLD-UM; Ascension and Tristan da Cunha into WORLD-SH; Ashmore and Cartier and the Coral Sea Islands into WORLD-AU.
  - Lakes of 3,500 km² or more are cut out.
  - Western Sahara (WORLD-EH) is the whole territory; see Boundary choices. This 8 October correction changed only WORLD-MA and WORLD-EH; the previous file is kept outside the project as `map_WORLD.before_westernsahara_fix.json`.
- **JP.** NE assigns the Amami islands to Okinawa; they were moved back to Kagoshima. Tokyo keeps its mainland and the Izu Islands. The Ogasawara and Volcano Islands, Okinotorishima and Minamitorishima are omitted because they would stretch the frame. Lakes of 60 km² or more are cut out, which includes Lake Biwa. NE includes the Senkaku islets in Okinawa.
- **AU.**
  - Jervis Bay Territory comes from NE's unnamed `AU-X02~` unit.
  - Macquarie Island (Tasmania) and Lord Howe Island (New South Wales) are omitted as remote.
  - The external territories come from NE Admin 0.
  - AU-AAT is NE's Antarctica clipped to 44°38′E–136°11′E and 142°02′E–160°E, which excludes Adélie Land, in a south-polar Lambert azimuthal projection.
- **CA.** NE "without large lakes" variant, plus lakes of 1,500 km² or more.
- **CN.**
  - 31 provincial units from NE, plus Hong Kong and Macau from Admin 0.
  - NE's separate Paracel Islands unit is dropped, and Hainan is limited to the island and nearby islets.
  - Lakes of 1,000 km² or more are cut out.
  - Taiwan is not part of the CN collection, but the map carries an extra region `WORLD-TW` so the app can colour it on China's map when the user turns off "Taiwan counts as a country".
    - It is NE's Taiwan subunit (Taiwan, Penghu, Kinmen, Green and Orchid Islands) plus the Matsu Islands (Nangan, Beigan, Juguang, Dongyin) from NE's minor-islands layer.
    - It uses the same Albers projection and transform as the CN regions, so it lines up with Fujian. Kinmen and Matsu are protected from islet removal.
    - It is inserted in area order (position 28 of 34). Every other region is byte-for-byte unchanged, and the canvas did not change.
- **FR.** Overseas codes were mapped: GP→971, MQ→972, GF→973, RE→974, YT→976. Lac Léman is cut out.
- **IT, ES, GB.** Dissolved from NE provinces or units: Italy by NE's region code, Spain by autonomous community (Ceuta and Melilla stay separate), and the UK by `geonunit`. Lakes cut out: Garda, Trasimeno and others in Italy; Lough Neagh in the UK.
- **DE, AT, CH, NL, BE, PL.** Straight from NE. PL letter codes were mapped to the numeric ISO codes PL-02…PL-32. The NL Caribbean special municipalities are excluded. Lakes cut out: Bodensee, Müritz, the Swiss lakes, the IJsselmeer and Markermeer, and the Masurian lakes.
- **US.**
  - Built from NE's "without large lakes" variant, plus natural lakes of 900 km² or more: Great Salt Lake, Lake of the Woods, Rainy Lake, Lake Okeechobee, Lake Champlain, Lake St. Clair and Laguna Madre. Reservoirs are not cut out because they read as borders.
  - Hawaii keeps only its main islands.
  - American Samoa is Tutuila and Manuʻa; Swains Island and Rose Atoll are omitted.
  - The Northern Mariana Islands inset shows Saipan, Tinian, Aguijan and Rota; the uninhabited northern islands are omitted so the box stays legible.
- **KR.** Dokdo is in NE's Admin 0 subunits but not its Admin 1 data, so it was added to Gyeongsangbuk-do (KR-47). It is protected from islet removal; it is a sub-pixel speck at normal size.
- **TW.** Uses the MOI/NLSC data. Omitted from the frames:
  - Yilan's Diaoyutai/Senkaku claim (de facto Japanese)
  - Keelung's Pengjia, Mianhua and Huaping islets
  - Kaohsiung's Pratas and Itu Aba
  - Kinmen's Wuqiu and Dongding
- **PT.** The Selvagens are omitted from the Madeira inset.
- **NO.** Kartverket's 2024 county polygons include sea areas, so they were intersected with NE's Norway mainland land polygon. 2,353 km² of NE land fell outside the county polygons, in 60 small border slivers. Each sliver was given to the county it shares the longest boundary with. Svalbard and Jan Mayen are excluded. Mjøsa is cut out.
- **BR.** Trindade and Martim Vaz and the St Peter and St Paul Archipelago are omitted as remote, east of 31°W. Lakes and reservoirs of 1,000 km² or more are cut out.
- **AR.** Lakes of 500 km² or more are cut out.
- **MX.** MX-DIF was mapped to MX-CMX. Arrecife Alacranes, an unnamed NE unit, was merged into Yucatán. Lake Chapala is cut out.
- **MY, TH.** Straight from NE; Thailand has lakes of 250 km² or more cut out.
- **PH.**
  - The four NCR districts were merged into PH-00 (Metro Manila).
  - City of Isabela was merged into Basilan, and Cotabato City into Maguindanao del Norte.
  - Maguindanao was split using its 36 municipalities per Republic Act 11550:
    - del Norte (12): Barira, Buldon, Datu Blah T. Sinsuat, Datu Odin Sinsuat, Kabuntalan, Matanog, Northern Kabuntalan, Parang, Sultan Kudarat, Sultan Mastura, Talitay, Upi.
    - del Sur (24), including Pagagawan (now Datu Montawal).
  - Compostela Valley is PH-COM (Davao de Oro).
  - The Kalayaan Island Group (Spratlys) is omitted.
  - Laguna de Bay is cut out.
- **ID.**
  - Each 2020 regency was assigned to its province by overlap with NE's 33 provinces.
  - New provinces come from regency lists:
    - Kalimantan Utara: Bulungan, Malinau, Nunukan, Tana Tidung, Tarakan.
    - Papua Selatan: Merauke, Boven Digoel, Mappi, Asmat.
    - Papua Tengah: Nabire, Puncak Jaya, Paniai, Mimika, Puncak, Dogiyai, Intan Jaya, Deiyai.
    - Papua Pegunungan: Jayawijaya, Lanny Jaya, Mamberamo Tengah, Nduga, Pegunungan Bintang, Tolikara, Yahukimo, Yalimo.
    - Papua Barat Daya: Sorong (city and regency), Sorong Selatan, Raja Ampat, Tambrauw, Maybrat.
    - Papua and Papua Barat keep the remaining regencies.
  - Lake and reservoir features in the source (Danau Toba, Waduk Cirata and others) were excluded, so they become holes.
- **IN.** NE already has Ladakh, Telangana and the merged Dadra and Nagar Haveli and Daman and Diu. Old codes were mapped: OR→OD, UT→UK, CT→CG, TG→TS. The Siachen Glacier was added to Ladakh; see below.

## Boundary choices

The maps follow Natural Earth's default, de facto worldview, with the merges the brief asked for and these decisions:

- **Merged:**
  - The UN buffer zone and the Akrotiri and Dhekelia Sovereign Base Areas into Cyprus. Northern Cyprus was later split back out as its own region, `WORLD-XC`, along the `northern-cyprus` area's Green Line edge, and its area now names both as claimants; the app counts it as Cyprus unless the person chooses to count it on its own.
  - Somaliland and Puntland into Somalia.
  - Baikonur into Kazakhstan.
  - Guantánamo Bay into Cuba.
  - The two Korean DMZ halves into South and North Korea.
  - The UNDOF zone into Syria.
  - Diego Garcia into the British Indian Ocean Territory.
- **Crimea.** NE draws it as a Russian subunit; it is assigned to Ukraine (WORLD-UA), the position of UN General Assembly resolution 68/262.
- **Western Sahara.** NE's default view puts the Moroccan-administered part (177,849 km², NE disputed area B19) inside Morocco and leaves "W. Sahara" as the 90,495 km² strip east of the Berm. WORLD-EH is the whole territory, as ISO 3166-1 EH and the UN list of non-self-governing territories define it, and WORLD-MA is Morocco without it. Both world files use this.
- **Siachen Glacier.** NE marks it as indeterminate; it is assigned to India, which has administered it since 1984: WORLD-IN and Ladakh (IN-LA). Dropping it would leave a visible gap.
- **Dropped, as they have no id:** Bir Tawil, Bajo Nuevo Bank, Serranilla Bank, Scarborough Reef, the Spratly and Paracel Islands, the Southern Patagonian Ice Field (1,409 km², a small notch on the Argentina–Chile border), Brazilian Island and Clipperton Island.
- **Left as NE draws them:**
  - The Golan Heights within Israel.
  - Kashmir along the Line of Control and Line of Actual Control: Aksai Chin in China, Gilgit-Baltistan and Azad Kashmir in Pakistan.
  - Arunachal Pradesh in India.
  - The southern Kurils in Russia, so JP's Hokkaido excludes them.
  - Dokdo/Takeshima with South Korea.
  - The Senkaku islets with Japan.
  - Kosovo (WORLD-XK), Palestine (WORLD-PS) and Taiwan (WORLD-TW) as separate regions.
- These choices only decide which region an area is coloured with. Contested areas and lines are also listed in the disputed layers below, so the app can draw them softly.
  - The Falklands under WORLD-FK, not Argentina.

## Very small regions

These regions are smaller than 3 units in both directions, so the app should rely on the `c` marker for them:

- **WORLD (69):** microstates, small island states and territories, including Hong Kong, Macau, Singapore, Luxembourg, Malta and the French and US island territories.
- **AU:** AU-CS, a speck inside its box.
- **CN:** CN-MO.
- **IN:** IN-LD (Lakshadweep).

Four WORLD slivers (WORLD-VG, BM, KY and BQ) are thinner than the 0.1 grid, so their `c` lies on the sliver's centreline rather than strictly inside it.

## Unprojected world map (`geo_WORLD.json`)

Same 255 region ids as `map_WORLD.json`, including the four UK nations, `WORLD-GB` and the shared ids. The order is the same, by area on Equal Earth, largest first. Coordinates are geographic degrees so the app can project at runtime and morph between projections by interpolating the same vertices.

```json
{"id": "WORLD", "width": 360, "height": 180,
 "regions": [{"id": "WORLD-RU", "d": "M47.63 43.96L47.67 44L47.76 43.93…Z …", "c": [112.34, 61.59]}],
 "disputed": [{"id": "golan-heights", "name": "Golan Heights", "claimants": ["WORLD-IL", "WORLD-SY"],
               "note": "Administered by Israel since 1967; claimed by Syria.", "d": "M35.82 33.41L35.8 33.25L35.89 32.94…Z", "c": [35.75, 32.94]}],
 "disputedLines": [{"id": "kashmir-line-of-control", "name": "Line of Control (Kashmir)", "d": "M77.05 35.11L77.01 34.99L76.75 34.89…"}]}
```

- **Coordinates.** `x` is longitude (−180…180) and `y` is latitude (−90…90, north positive, not flipped). Paths use absolute `M`/`L`/`Z` with up to 2 decimals, and negative numbers occur. Fill with the even-odd rule. `width`/`height` are nominal (360 × 180) and there are no frames.
- **Antimeridian.** Rings are split at ±180° as in Natural Earth, and no edge crosses it (the largest longitude step on any edge is 1°). Russia, Fiji, the US (Aleutians), Kiribati and Antarctica have parts on both sides.
- **Antarctica.** WORLD-AQ is a closed polygon running along latitude −90 between (180, −90) and (−180, −90), with a vertex at least every 1°, so it fills correctly in flat projections. Mercator cannot show −90: clamp latitudes (e.g. to ±85°) or skip Antarctica there.
- **Densification.** Every edge longer than 1° in longitude or latitude is subdivided (linear in lon/lat). Long straight borders and parallels, such as 49°N, the Antarctic pole edge and antimeridian cuts, therefore curve correctly in Winkel Tripel, Robinson or an orthographic globe. An orthographic globe still needs horizon (back-face) clipping.
- **Simplification.** Shared-arc topology and weighted Visvalingam–Whyatt are computed on the same Equal Earth canvas as `map_WORLD.json` (1000 units wide), and the retained vertices keep their original lon/lat.
  - Simplify threshold 0.065 u², islet threshold 0.08 u² (≈ 100 km²), hole threshold 0.3 u², lakes of 3,500 km² or more cut out. Defects are repaired only on the arcs that cause them.
  - Shared borders are identical between neighbours. Disputed polygons and lines are part of the same topology, so a disputed line coincides exactly with the region border it follows (e.g. the Line of Control with the India–Pakistan border).
  - About 45,000 region vertices; 587 KB (601,118 bytes) against a 650 KB budget.
- **Small places.** Anything that collapses at 0.01° is written as a 0.02° square at its location; this applies only to WORLD-VA. `c` is NE's label point if it lies in a substantial part, otherwise the pole of inaccessibility on the equal-area canvas, converted back to lon/lat and checked to be inside.
- **Validation.** Grammar, the region id set and order, ranges, closed rings, no antimeridian jumps, Antarctica's corners and validity, claimants, `c` inside every region and disputed area, and the size budget are all checked. Previews in Winkel Tripel and Robinson, with disputed areas hatched and disputed lines dashed, were rendered and inspected.

## Disputed areas and lines

Sources: Natural Earth 1:10m Admin 0 disputed areas (5.1.1), Admin 0 boundary lines (land) and the boundary lines of disputed areas (5.1.0). All are public domain. The polygons share their vertices with the map subunits, so their outlines coincide with region borders in `geo_WORLD.json`.

**Format.** Both arrays appear in `geo_WORLD.json` (lon/lat) and, in each map's own canvas coordinates, in `map_IN.json`, `map_CN.json`, `map_JP.json`, `map_KR.json` and `map_PH.json`.

- `disputed`: `{"id", "name", "claimants", "note", "d", "c"}`. Polygons use the same path grammar as the regions and are meant to be drawn on top of them (hatched or blurred).
  - `claimants` are WORLD ids, sorted alphabetically so no order is implied. In a country map, an area that lies inside one of that map's divisions uses the division ids instead of the map's own country (e.g. `["IN-LA", "WORLD-PK"]` for Ladakh on India's map).
  - `note` is a short neutral description: "Administered by X; claimed by Y".
- `disputedLines`: `{"id", "name", "d"}`, open polylines using `M`/`L` only (no `Z`) for contested boundary segments. Several segments may share one entry.

**Selection.** This covers every area requested, plus closely related parts of the same disputes (Shebaa Farms, East Jerusalem, the India–China patches, Kalapani, Doklam and the northwestern Bhutan valleys). It also covers the East Asian island disputes (Dokdo/Takeshima, Senkaku/Diaoyu, Paracels, Spratlys and Scarborough Shoal), so Japan's three territorial disputes and the South China Sea are treated alike.

**Not included.** All of these are in NE and can be added if wanted:
- Whole-territory sovereignty claims over stable administrations: Taiwan, the Falklands and South Georgia, Gibraltar, Ceuta, Melilla and the Spanish plazas, Chagos, Mayotte and the Îles Éparses, Guatemala's claim to Belize, the Philippine claim to Sabah, Olivenza.
- Pakistan's claim to Junagadh.
- Dormant boundary claims: the Courantyne and Lawa headwaters, the Corner of Artigas, and small river islands.
- Leases and overlays: Baikonur, Guantánamo, Diego Garcia, the Korean DMZ, the UNDOF zone and the Cyprus buffer zone.
- NE entries that are out of date by 2026: Artsakh, the 2014 Donetsk and Luhansk lines, Hans Island, Tiran and Sanafir, and Mbane.
- Russian-occupied Ukraine beyond Crimea: no stable public-domain boundary exists.

**Areas (37).** In `geo_WORLD.json` claimants are WORLD ids; the collection maps that also carry each area are listed.

| id | name | claimants | also in |
|---|---|---|---|
| golan-heights | Golan Heights | IL, SY | – |
| shebaa-farms | Shebaa Farms | IL, LB | – |
| east-jerusalem | East Jerusalem | IL, PS | – |
| jammu-and-kashmir | Jammu and Kashmir (Indian-administered) | IN, PK | IN (IN-JK, WORLD-PK) |
| ladakh | Ladakh (Indian-administered) | IN, PK | IN (IN-LA, WORLD-PK) |
| azad-kashmir | Azad Kashmir (Pakistani-administered) | IN, PK | IN |
| gilgit-baltistan | Gilgit-Baltistan (Pakistani-administered) | IN, PK | IN (clipped at the canvas top) |
| siachen-glacier | Siachen Glacier | IN, PK | IN (IN-LA, WORLD-PK) |
| aksai-chin | Aksai Chin (Chinese-administered) | CN, IN | IN; CN (CN-XJ, CN-XZ, WORLD-IN) |
| trans-karakoram-tract | Trans-Karakoram Tract (Shaksgam Valley) | CN, IN | IN (clipped at the canvas top); CN (CN-XJ, WORLD-IN) |
| demchok | Demchok | CN, IN | IN (IN-LA, WORLD-CN); CN |
| samdu-valleys | Samdu valleys | CN, IN | IN (IN-HP, WORLD-CN); CN |
| tirpani-valleys | Tirpani valleys | CN, IN | IN (IN-UK, WORLD-CN); CN |
| barahoti | Barahoti | CN, IN | IN (IN-UK, WORLD-CN); CN |
| kalapani | Kalapani | IN, NP | IN (IN-UK, WORLD-NP) |
| arunachal-pradesh | Arunachal Pradesh | CN, IN | IN (IN-AR, WORLD-CN); CN |
| doklam | Doklam | BT, CN | IN; CN |
| bhutan-northwest-valleys | Northwestern Bhutan valleys | BT, CN | CN |
| western-sahara | Western Sahara | EH, MA | – |
| crimea | Crimea | RU, UA | – |
| northern-cyprus | Northern Cyprus | CY, XC | – |
| abkhazia | Abkhazia | GE | – |
| south-ossetia | South Ossetia | GE | – |
| transnistria | Transnistria | MD | – |
| somaliland | Somaliland | SO | – |
| halaib-triangle | Hala'ib Triangle | EG, SD | – |
| bir-tawil | Bir Tawil | none (claimed by neither) | – |
| ilemi-triangle | Ilemi Triangle | KE, SS | – |
| abyei | Abyei | SD, SS | – |
| southern-kuril-islands | Southern Kuril Islands (Northern Territories) | JP, RU | JP |
| essequibo | Guayana Esequiba (Essequibo) | GY, VE | – |
| kosovo | Kosovo | RS, XK | – |
| liancourt-rocks | Dokdo / Takeshima (Liancourt Rocks) | JP, KR | JP; KR (KR-47, WORLD-JP) |
| senkaku-islands | Senkaku / Diaoyu Islands | CN, JP, TW | JP (JP-47, in the Okinawa inset); CN |
| paracel-islands | Paracel Islands | CN, TW, VN | – |
| spratly-islands | Spratly Islands | BN, CN, MY, PH, TW, VN | – |
| scarborough-shoal | Scarborough Shoal | CN, PH, TW | PH |

**Lines (30), all in `geo_WORLD.json`:**
- Kashmir:
  - `kashmir-line-of-control` Line of Control (Kashmir); `kashmir-working-boundary` Working Boundary (Jammu–Sialkot)
  - `siachen-actual-ground-position-line` Actual Ground Position Line (Siachen); `siachen-nj9842-karakoram-pass` NJ9842–Karakoram Pass line (Siachen)
  - `china-pakistan-boundary-kashmir` China–Pakistan boundary in Kashmir; `sir-creek` Sir Creek
- India–China: `lac-western-sector`, `lac-middle-sector`, `lac-eastern-sector` Line of Actual Control (western, middle and eastern sectors)
- Israel and its neighbours:
  - `green-line-west-bank` Green Line (West Bank); `green-line-gaza` Green Line (Gaza)
  - `golan-ceasefire-line` Ceasefire line (Golan Heights, 1974); `golan-1967-line` Pre-1967 line (Golan Heights)
- Europe and the Caucasus: `crimea-boundary` Crimea boundary; `cyprus-green-line` Green Line (Cyprus); `abkhazia-line`; `south-ossetia-line`; `transnistria-line`; `kosovo-serbia-line` Kosovo–Serbia boundary
- Africa:
  - `somaliland-puntland-line` Somaliland–Puntland line
  - `western-sahara-berm` Moroccan Berm (Western Sahara); `morocco-western-sahara-line` Morocco–Western Sahara boundary (27°40′N)
  - `egypt-sudan-22nd-parallel` Egypt–Sudan boundary (22nd parallel); `egypt-sudan-1902-line` Egypt–Sudan administrative line (1902)
  - `ilemi-line` Ilemi Triangle line; `abyei-line` Abyei line
- Japan–Russia: `kuril-islands-line` Japan–Russia line (southern Kuril Islands); `kuril-japanese-claim-line` Japanese claim line (Iturup–Urup)
- Venezuela–Guyana: `venezuela-guyana-line` Venezuela–Guyana boundary (1899 award); `essequibo-claim-line` Venezuelan claim line (Essequibo River)

**Collection maps.** The overlays were added without changing any existing region.

- They use each map's existing projection and transform; the Okinawa inset's transform for the Senkakus on JP. Each overlay was simplified with that map's thresholds, rounded to 0.1 and clipped to the canvas.
- Where they reach past the top of a canvas, they are clipped: Gilgit-Baltistan is 53% visible and the Trans-Karakoram Tract 45% on IN; the southern Kurils are 87% visible on JP.
- JP's width grew to 908.8 (right side only) to fit the Kurils.
- Lines on these maps:
  - IN: all nine Kashmir and LAC lines above.
  - CN: the three LAC sectors and the China–Pakistan boundary.
  - JP: the two Kuril lines.
- In the country maps, overlay edges were simplified separately from the region borders, so they can deviate from them by up to about a unit. This is meant for soft rendering.

## Sixteen more collections (added 8 October 2026)

These collections were added with the same pipeline, file format, thresholds and validation as the maps above: Ireland (IE), Sweden (SE), Denmark (DK), Finland (FI), Czechia (CZ), Croatia (HR), Greece (GR), Hungary (HU), Chile (CL), Colombia (CO), Peru (PE), Türkiye (TR), the United Arab Emirates (AE), Sri Lanka (LK), New Zealand (NZ) and South Africa (ZA).

- Each has a projected map, `map_<ID>.json`, and an unprojected file, `geo_<ID>.json`, for drawing the subdivisions in the World map's projection. The geo files are described below.
- Region ids are ISO 3166-2 codes. Every id has a shape and nothing was left out.
- No new map has `disputed` or `disputedLines` arrays, because none of `geo_WORLD.json`'s disputed areas or lines lies in or borders these countries (see Boundary choices).

### Sources and licences

| Source | Used for | Licence |
|---|---|---|
| Natural Earth 1:10m (the same files and versions as above) | The regions of 14 maps (all except FI and PE); the coastlines, lakes and Åland of FI; the coastline and Lake Titicaca of PE | Public domain |
| [Statistics Finland – Maakunnat 2026 (1:1 000 000)](https://stat.fi/en/services/statistical-data-services/geographic-data/statistical-areas/municipality-based-statistical-units), WFS layer `tilastointialueet:maakunta1000k_2026`, downloaded 8 October 2026 | Finland's 18 mainland regions (2021–2026 boundaries) | CC BY 4.0, "Source: Statistics Finland" |
| geoBoundaries gbOpen PER ADM2 (2020; IGN Peru, OCHA ROLAC), `PER-ADM2-86281439`, simplified release, build `9469f09` | Peru's internal boundaries | CC BY 3.0 IGO |
| geoBoundaries gbOpen COL ADM2 (2020; DANE), `COL-ADM2-7082276`, simplified release, build `9469f09` | San Andrés, Providencia and Santa Catalina | CC BY 4.0 |

Natural Earth is out of date for two of these countries:
- **Finland.** NE has the boundaries from before 2021, when Iitti moved from Kymenlaakso to Päijät-Häme and Kuhmoinen from Central Finland to Pirkanmaa.
- **Peru.** NE's Callao barely overlaps the real one, and its Lima Province differs from IGN's by 22% of its area.

Datasets checked but not used:
- OpenStreetMap-derived, so ODbL or CC BY-SA: geoBoundaries FIN ADM1/ADM2, ARE ADM1, COL ADM1, LKA ADM1/ADM2, HRV ADM1/ADM2, TUR ADM1/ADM2, CHL ADM2 and HUN ADM2.
- Open, but not needed because NE is current: the other geoBoundaries ADM1 sets for these countries.

### Projected maps

| Map | Regions | Size | Canvas | km/unit | Simplify (u²) | Islet (u² ≈ km²) | Hole (u²) | Lakes cut out | Projection |
|---|---|---|---|---|---|---|---|---|---|
| IE | 26 | 83.2 KB | 702.4 × 1000 | 0.45 | 0.12 | 0.8 ≈ 0.16 | 4 | ≥ 100 km² | Transverse Mercator (Irish Transverse Mercator parameters) |
| SE | 21 | 79.5 KB | 429.6 × 1000 | 1.57 | 0.15 | 0.8 ≈ 2.0 | 4 | ≥ 300 km² | Transverse Mercator (15°E; SWEREF 99 TM) |
| DK | 5 | 27.6 KB | 825.0 × 1000 | 0.36 | 0.12 | 0.8 ≈ 0.1 | 4 | – | UTM zone 32N (Bornholm inset: UTM zone 33N) |
| FI | 19 | 137.3 KB | 577.4 × 1000 | 1.16 | 0.15 | 0.8 ≈ 1.1 | 4 | ≥ 400 km² | Transverse Mercator (27°E; ETRS-TM35FIN) |
| CZ | 14 | 45.1 KB | 1000 × 577.3 | 0.50 | 0.12 | 0.8 ≈ 0.2 | 4 | – | Lambert conformal conic (49°/50.5°N, 15.5°E) |
| HR | 21 | 60.9 KB | 1000 × 987.8 | 0.47 | 0.12 | 0.8 ≈ 0.2 | 4 | – | Transverse Mercator (16.5°E; HTRS96/TM) |
| GR | 14 | 74.5 KB | 978.4 × 1000 | 0.79 | 0.12 | 0.8 ≈ 0.5 | 4 | – | Transverse Mercator (24°E; Greek Grid) |
| HU | 20 | 29.1 KB | 1000 × 625.8 | 0.52 | 0.12 | 0.8 ≈ 0.2 | 4 | ≥ 100 km² | Swiss oblique Mercator (EOV parameters) |
| CL | 16 | 92.2 KB | 439.6 × 1000 | 4.36 | 0.15 | 0.8 ≈ 15 | 4 | ≥ 400 km² | Transverse Mercator (71.5°W) |
| CO | 33 | 112.9 KB | 738.0 × 1000 | 1.89 | 0.15 | 0.8 ≈ 2.8 | 4 | – | Transverse Mercator (MAGNA-SIRGAS Origen-Nacional parameters) |
| PE | 26 | 163.2 KB | 691.7 × 1000 | 2.07 | 0.15 | 0.8 ≈ 3.4 | 4 | ≥ 400 km² | UTM zone 18S |
| TR | 81 | 102.0 KB | 1000 × 446.8 | 1.70 | 0.15 | 0.8 ≈ 2.3 | 4 | natural lakes ≥ 400 km² | Lambert conformal conic (37°/41°N, 35°E) |
| AE | 7 | 17.3 KB | 1000 × 783.0 | 0.50 | 0.12 | 0.8 ≈ 0.2 | 4 | – | UTM zone 40N |
| LK | 9 | 23.1 KB | 578.4 × 1000 | 0.44 | 0.12 | 0.8 ≈ 0.16 | 4 | – | Transverse Mercator (SLD99 Sri Lanka Grid parameters) |
| NZ | 17 | 63.1 KB | 697.3 × 1000 | 1.47 | 0.15 | 0.8 ≈ 1.7 | 4 | ≥ 120 km² | Transverse Mercator (173°E; NZTM2000) |
| ZA | 9 | 55.5 KB | 1000 × 876.0 | 1.65 | 0.15 | 0.8 ≈ 2.2 | 4 | – | Albers (24°/33°S, 25°E) |

No region is smaller than 3 units across, so none of these maps needs marker-only places.

### Insets and frames

| Map | Frames | Contents |
|---|---|---|
| CL | 2 | Rapa Nui (Easter Island) and the Juan Fernández Islands (Robinson Crusoe, Santa Clara, Alejandro Selkirk), left of the mainland near their own latitudes. Each is fitted to its box and drawn in a local transverse Mercator. They belong to CL-VS, whose label point stays on mainland Valparaíso. |
| CO | 1 | San Andrés and Providencia, top-left, fitted to the box with their true relative positions. |
| DK | 1 | Bornholm, top-right in the Kattegat, at the same scale as the main map. Danish maps conventionally box it, and keeping it in place would shrink the main map by about a fifth. DK-84's label point stays on Zealand. |
| NZ | 1 | The Chatham Islands (Chatham and Pitt), at the same scale as the main map in the Chatham Islands Transverse Mercator. The box sits east of Canterbury, near the islands' latitude. |

### Per-map notes

- **IE.** NE's 34 units were dissolved by ISO code:
  - Dublin is Dublin City, Fingal, South Dublin and Dún Laoghaire–Rathdown.
  - Cork, Galway, Limerick and Waterford include their cities.
  - Tipperary is North and South Tipperary.
  - Lough Derg and Lough Ree are cut out. NE's lakes layer has no Lough Corrib or Lough Mask.
- **SE.** Straight from NE. Nine lakes are cut out: Vänern, Vättern, Mälaren, Storsjön, Hjälmaren, Torneträsk, Uddjaure, Siljan, and NE's unnamed Ströms Vattudal system, which reaches the Norwegian border.
- **DK.** Straight from NE. Ertholmene, which belongs to no region, is not in NE.
- **FI.**
  - NE's Finland land polygon was split along Statistics Finland's 2026 regions, as for Norway. The 1,957 km² of NE land outside the regions, mostly coastal slivers and islets, went to the region with the longest shared boundary.
  - FI-01 is NE's Åland subunit, the same source as the World map's FI-01.
  - Eleven NE lakes of 400 km² or more are cut out, from the Saimaa and Päijänne systems to Inarijärvi, Oulujärvi, Pielinen and the Lokka reservoir.
- **CZ.** NE's letter codes were mapped to the numeric codes: PR→10, ST→20, JC→31, PL→32, KA→41, US→42, LI→51, KR→52, PA→53, VY→63, JM→64, OL→71, ZL→72, MO→80.
- **HR.** NE codes Požega-Slavonia (Wikidata Q58111) as HR-12, so it was recoded HR-11.
- **GR.**
  - NE's GR-A1 is Attica (GR-I).
  - Mount Athos (GR-69) is already a separate NE unit, so it did not need splitting from Central Macedonia.
  - Kastellorizo is not in NE's Greece, so it is missing. It is in NE's minor-islands layer only, and adding it would shrink the map by about 12%.
- **HU.** The 23 cities with county rights in NE were merged into their counties, for example Debrecen into Hajdú-Bihar and Szeged and Hódmezővásárhely into Csongrád-Csanád. Budapest is HU-BU. Lake Balaton is cut out.
- **CL.**
  - NE already has Ñuble (2018). There is no Antarctic claim.
  - Salas y Gómez and the Desventuradas (San Félix and San Ambrosio, 1–2 km² each) are omitted from Valparaíso.
  - Four lakes are cut out: General Carrera/Buenos Aires, O'Higgins/San Martín, Llanquihue and Ranco.
  - NE gives the Southern Patagonian Ice Field to neither Chile nor Argentina, so it is a notch in the eastern border, as in the World map.
- **CO.**
  - Bogotá is NE's "Bogota" unit, which NE codes CO-CUN; it was recoded CO-DC.
  - Malpelo Island, an unnamed NE unit 500 km offshore that belongs to Valle del Cauca, is omitted as remote.
  - CO-SAP uses DANE's island outlines, because NE's are crude and offset by up to about 1 km. Roncador Cay and the other remote cays are not included.
  - Elsewhere NE was kept. Its department lines differ from DANE's by 3–6% of their area, which is normal generalization.
- **PE.**
  - The 196 IGN provinces were assigned to regions by overlap with NE, then checked against the official list. Gran Chimú was corrected to La Libertad; NE's lines put 58% of it in Cajamarca.
  - Lima Province is PE-LMA, Callao is PE-CAL, and the other nine provinces of Lima form PE-LIM.
  - The result was fitted to NE's Peru land outline, as for Finland. The 10,516 km² of NE land outside IGN's provinces includes the lake.
  - Lake Titicaca's Peruvian part is cut out.
- **TR.** Straight from NE. Lakes Van, Tuz, Beyşehir and Eğirdir are cut out. Reservoirs such as Atatürk and Keban are not, because they lie on provincial borders and would read as borders, as on the US map.
- **AE.** NE has two "neutral zone" units.
  - NE describes AE-X02~ as under joint control between Ajman and Oman. It is the Masfut area, Ajman's inland exclave, so it was merged into AE-AJ. NE's Ajman otherwise lacks Masfut.
  - AE-X01~ (13 km²) is jointly administered by Fujairah and Sharjah. It was merged into AE-SH, with which it shares the longer border (6.8 km against 5.7 km).
  - Oman's Madha exclave is a hole in the map, with Sharjah's Nahwa inside it.
- **LK.** NE's 25 districts were dissolved into the nine provinces using NE's province codes.
- **NZ.**
  - The outlying islands (Kermadec, Three Kings, Auckland, Campbell, Antipodes, Bounty and Snares) belong to no region and are excluded. Tokelau, the Cook Islands, Niue and the Ross Dependency are excluded too.
  - Lakes of 120 km² or more are cut out: Taupō, Te Anau, Wakatipu, Wānaka, Pukaki, Hāwea and Manapōuri.
- **ZA.** NE's ZA-NL was mapped to ZA-KZN and ZA-GT to ZA-GP. NE matches the post-2011 provincial boundaries. Lesotho and Eswatini are holes. The Prince Edward Islands (Western Cape) are omitted from the projected map; they are in the geo file.

### Boundary choices and disputed areas

- **None apply.** No disputed area or line in `geo_WORLD.json` lies in or borders any of these countries. The nearest are Northern Cyprus, about 70 km across the sea from Türkiye, and Abkhazia and South Ossetia, about 100 km from Türkiye beyond Georgia's Adjara. So none of the 32 new files has `disputed` or `disputedLines`.
- **Not in `geo_WORLD.json`'s layers, so not added.** Either could be added later:
  - Abu Musa (NE disputed area B73) and the Greater and Lesser Tunbs, administered by Iran and claimed by the UAE. NE draws them in Iran, so they are not on AE's maps.
  - The undemarcated Southern Patagonian Ice Field section of the Chile–Argentina border; see CL above.

### Shared Åland id

`WORLD-AX` was renamed `FI-01` in `map_WORLD.json` (position 215 of 254) and `geo_WORLD.json` (position 196). Geometry, label point and order are unchanged. Finland's two files also use `FI-01` for Åland, from the same NE subunit.

### Unprojected country files (`geo_<ID>.json`)

```json
{"id": "IE", "width": 360, "height": 180,
 "regions": [{"id": "IE-CO", "d": "M-9.918 51.619L-9.916 51.629…Z …", "c": [-8.721, 52.061]}]}
```

- **Format.** The same as `geo_WORLD.json`: `x` is longitude and `y` is latitude, north positive and not flipped.
  - Paths use absolute `M`/`L`/`Z` with at most 3 decimals (about 100 m). Fill with the even-odd rule.
  - No edge is longer than 0.5° in longitude or latitude, and no ring crosses the antimeridian. New Zealand's Chatham Islands, at 176°W, are separate rings.
  - Regions are sorted by Equal Earth area, largest first.
  - The ids are exactly those of the projected map. There are no frames or overlays.
- **True locations.** Every part is in its true place, including those boxed in the projected maps: Bornholm, Rapa Nui, the Juan Fernández Islands, San Andrés and Providencia, and the Chatham Islands. The Prince Edward Islands are included in ZA-WC because `geo_WORLD.json` has Marion Island in WORLD-ZA. Places omitted from the projected maps for other reasons are also omitted here, such as Malpelo, the Desventuradas and NZ's outlying islands.
- **Lining up with `geo_WORLD.json`.**
  - **Land borders.** These use `geo_WORLD.json`'s own border vertices. Any piece of a country that `geo_WORLD.json` gives to a neighbour and that touches the shared border was removed. Real land that `geo_WORLD.json` gives to the country but the source lacks was added to the adjacent region. `geo_WORLD.json`'s border vertices were pinned during simplification, so neighbours drawn from `geo_WORLD.json` meet the subdivisions with no gap or overlap.
    - Points where the source border crossed those edges were dropped, so each shared edge is exactly `geo_WORLD.json`'s.
    - The only exception is where an internal border meets the national border. That junction lies on a long `geo_WORLD.json` edge and is rounded to 3 decimals, so it can sit up to about 60 m off. The resulting slivers are at most about 60 m wide and total under 5 km² per country.
    - `geo_WORLD.json` edges between 0.5° and 1° long gain a midpoint here, because of the 0.5° rule. The midpoint lies on the same straight line in longitude and latitude, so once projected it is off by a negligible amount.
  - **Coastlines.** These keep Natural Earth's finer detail, and islands smaller than `geo_WORLD.json`'s islet threshold (about 95 km²) are kept. So the coast differs from the world outline by about 0.5–1 km typically and up to about 10 km where `geo_WORLD.json` cuts across bays.
  - **Rendering.** Draw a country's subdivisions in place of its world shape, and keep drawing the neighbours from `geo_WORLD.json`. If the world shape is drawn underneath, its coarser coast will show through in places.
- **Simplification.**
  - Topology and weighted Visvalingam–Whyatt run on the projected map's canvas: same projection and scale, with the main territory's longer side 1000 units. Retained vertices keep their original longitude and latitude.
  - The thresholds are 0.35 u² to simplify, 2 u² for islets and 6 u² for holes. That is coarser than the projected maps and meant for a whole country on a phone zoomed about 4×.
  - For small countries Natural Earth itself is the limit: Ireland keeps about 83% of its 5,164 source vertices.
- **Label points.** `c` is NE's label point if it lies in a substantial part, otherwise the pole of inaccessibility of the largest part. It is checked to be inside its region.

| File | Size | Points | `geo_WORLD` border vertices pinned | Distance from `geo_WORLD` land border: p99 / max | Coast vs `geo_WORLD`: median / p90 / max |
|---|---|---|---|---|---|
| geo_IE | 82.3 KB | 6,009 | 16 | 27 m / 35 m | 0.9 / 2.7 / 7.8 km |
| geo_SE | 72.4 KB | 5,319 | 75 | 37 m / 1.8 km¹ | 1.0 / 3.1 / 8.9 km |
| geo_DK | 31.3 KB | 2,381 | 2 | 43 m / 456 m² | 1.0 / 3.1 / 9.5 km |
| geo_FI | 131.5 KB | 9,697 | 86 | 34 m / 49 m | 0.7 / 2.1 / 7.9 km |
| geo_CZ | 36.7 KB | 2,692 | 71 | 33 m / 46 m | landlocked |
| geo_HR | 55.5 KB | 4,056 | 67 | 51 m / 1.5 km² | 0.7 / 2.3 / 6.7 km |
| geo_GR | 75.1 KB | 5,524 | 39 | 660 m / 10.1 km² | 0.9 / 2.6 / 9.8 km |
| geo_HU | 25.6 KB | 1,847 | 62 | 46 m / 66 m | landlocked |
| geo_CL | 75.2 KB | 4,845 | 217 | 276 m / 8.4 km¹ | 0.9 / 3.0 / 9.6 km |
| geo_CO | 98.2 KB | 7,136 | 189 | 34 m / 76 m | 0.7 / 1.9 / 5.2 km |
| geo_PE | 135.0 KB | 8,939 | 182 | 19 m / 114 m | 0.5 / 1.8 / 5.7 km |
| geo_TR | 103.7 KB | 7,464 | 94 | 42 m / 263 m | 0.7 / 2.4 / 7.2 km |
| geo_AE | 18.2 KB | 1,328 | 37 | 34 m / 184 m | 0.6 / 1.9 / 4.1 km |
| geo_LK | 25.5 KB | 2,010 | – | no land border | 0.5 / 1.5 / 4.5 km |
| geo_NZ | 73.6 KB | 4,717 | – | no land border | 0.7 / 2.6 km; max 608 km³ |
| geo_ZA | 51.3 KB | 3,545 | 152 | 24 m / 50 m | 0.6 / 1.9 / 6.5 km |

The median distance from `geo_WORLD.json`'s land border is 0 m in every file.

¹ Where `geo_WORLD.json`'s border runs through a lake that is cut out here: Ströms Vattudal in SE; General Carrera and O'Higgins in CL. ² Where the last segment of `geo_WORLD.json`'s border runs out to its coarser coast, over what is sea in the finer coastline: Flensburg Fjord in DK, Neum Bay in HR, and the Butrint channel at the Greek–Albanian border. ³ NZ's Auckland and Campbell Islands are in WORLD-NZ but belong to no NZ region.

### Validation

- **Projected maps.** Re-parsed and checked: key order, path grammar (absolute `M`/`L`/`Z`, at most one decimal, closed rings), id sets, coordinates inside the canvas, 10-unit margins, `c` inside under even-odd, sort order, frames, size, and overlap between regions. Overlap is at most 0.005 u² per map.
- **Geo files.** Checked: grammar (at most 3 decimals, no `-0`), ids identical to the projected map, ranges, edge length at most 0.5°, `c` inside, sort order, overlap between regions (at most 0.16 km²), size, and the line-up figures above.
- **World files.** The rename was checked against the previous versions: only that id changed.
- **Previews.** Labelled previews of every projected map, and previews of every geo file over `geo_WORLD.json`'s neighbours in Equal Earth, were rendered and inspected. These included close-ups of the borders, insets and 4× zooms.
