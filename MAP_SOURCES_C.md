# Map data: Venezuela, Paraguay, Guatemala, Costa Rica, Panama, Dominican Republic, Jamaica, Honduras, El Salvador, Nigeria, Tanzania, Ghana, Senegal, Rwanda, Namibia, Tunisia and Algeria

Generated on 8 October 2026. The app bundles these files for offline use; it does not request map data from a network service at runtime.

This batch adds 34 files to `jpex/Maps/`. Each of the 17 collections has a projected map `map_<ID>.json` and an unprojected (lon/lat) map `geo_<ID>.json`. No existing file was changed.

## Files

| Map | Regions | `map_` size | `geo_` size | Canvas | km/unit | Projection | Frames | Overlays |
|---|---|---|---|---|---|---|---|---|
| VE | 25 | 100.2 KB | 121.7 KB | 1000 × 765.3 | 1.72 | Lambert conformal conic (4°/10°N, lat₀ 7°N, 65°W) | – | 1 area, 2 lines |
| PY | 18 | 89.2 KB | 121.7 KB | 941.7 × 1000 | 0.94 | UTM 21S | – | – |
| GT | 22 | 107.6 KB | 137.5 KB | 957.3 × 1000 | 0.46 | Transverse Mercator (90.5°W, k 0.9998; GTM parameters) | – | – |
| CR | 7 | 66.4 KB | 81.5 KB | 1000 × 949.4 | 0.38 | Transverse Mercator (84°W, k 0.9999; CRTM05 parameters) | – | – |
| PA | 14 | 90.6 KB | 110.3 KB | 1000 × 424.9 | 0.66 | UTM 17N | – | – |
| DO | 32 | 124.2 KB | 158.6 KB | 1000 × 686.3 | 0.40 | UTM 19N | – | – |
| JM | 14 | 18.5 KB | 23.9 KB | 1000 × 406.1 | 0.24 | Lambert conformal conic (18°N, 77°W, k 1; JAD2001 Jamaica Metric Grid parameters) | – | – |
| HN | 18 | 73.4 KB | 93.6 KB | 1000 × 740.7 | 0.69 | UTM 16N | – | – |
| SV | 14 | 49.9 KB | 63.6 KB | 1000 × 551.2 | 0.27 | Lambert conformal conic (13.317°/14.25°N, lat₀ 13.783°N, 89°W; El Salvador Lambert parameters) | – | – |
| NG | 37 | 168.7 KB | 181.2 KB | 1000 × 812.2 | 1.34 | Transverse Mercator (lat₀ 4°N, 8.5°E, k 0.99975; Nigeria Mid Belt parameters) | – | – |
| TZ | 31 | 179.0 KB | 214.6 KB | 1000 × 992.0 | 1.22 | Transverse Mercator (35°E, k 0.9996) | – | – |
| GH | 16 | 141.0 KB | 156.3 KB | 699.1 × 1000 | 0.73 | Transverse Mercator (lat₀ 4.667°N, 1°W, k 0.99975; Ghana National Grid parameters) | – | – |
| SN | 14 | 62.3 KB | 79.6 KB | 1000 × 730.8 | 0.68 | UTM 28N | – | – |
| RW | 5 | 28.1 KB | 33.4 KB | 1000 × 868.3 | 0.23 | Transverse Mercator (30°E, k 0.9999; Rwanda TM parameters) | – | – |
| NA | 14 | 41.5 KB | 53.8 KB | 1000 × 918.2 | 1.47 | Lambert conformal conic (19.5°/26.5°S, lat₀ 23°S, 18.5°E) | – | – |
| TN | 24 | 80.7 KB | 92.7 KB | 493.8 × 1000 | 0.81 | UTM 32N | – | – |
| DZ | 58 | 115.7 KB | 134.9 KB | 1000 × 975.9 | 2.11 | Lambert conformal conic (24°/33°N, lat₀ 28°N, 3°E) | – | – |

Exact sizes in bytes, map then geo:
- VE 102,608 / 124,584; PY 91,314 / 124,608; GT 110,166 / 140,814; CR 68,019 / 83,486; PA 92,819 / 112,937
- DO 127,217 / 162,433; JM 18,970 / 24,508; HN 75,158 / 95,846; SV 51,145 / 65,171; NG 172,698 / 185,561
- TZ 183,255 / 219,737; GH 144,408 / 160,086; SN 63,776 / 81,527; RW 28,767 / 34,170; NA 42,531 / 55,084
- TN 82,645 / 94,915; DZ 118,500 / 138,112

Every listed id has a shape: 361 regions in all. None was omitted, and no region is smaller than 3 units, so none is drawn as a marker square. All settings are the previous batches' (`MAP_SOURCES_3.md`, `MAP_SOURCES_B.md`): 0.15 u² simplification (map and geo), 0.8 u² islets, 4 u² holes. All files are within the 200 KB / 220 KB budgets (TZ's geo file is the largest at 214.6 KB).

## Scope (ids)

Ids are exactly the current ISO 3166-2 codes (the list in `/private/tmp/jpex-world/subdivisions.json`, which the catalog agent uses). Units are the codes that are not groupings: DO's ten development regions (`DO-33`…`DO-42`) group the provinces and are not shapes; TZ, GH, SN and NA "regions" have no children and are the units.

| Map | Count | Notes |
|---|---|---|
| VE | 25 | 23 states (VE-X is La Guaira, formerly Vargas), Distrito Capital (VE-A) and Dependencias Federales (VE-W). Guayana Esequiba is not a region (see "Disputed areas"). |
| PY | 18 | 17 departments + Asunción (PY-ASU). |
| GT | 22 | Departments. |
| CR | 7 | Provinces. |
| PA | 14 | 10 provinces (incl. Panamá Oeste, PA-10) and the 4 comarcas with ISO codes: Emberá (PA-EM), Guna Yala (PA-KY), Ngäbe-Buglé (PA-NB) and **Naso Tjër Di (PA-NT)**. The corregimiento-level comarcas (Madungandí, Wargandí) have no ISO code and stay in their provinces. |
| DO | 32 | 31 provinces + Distrito Nacional (DO-01). |
| JM | 14 | Parishes. |
| HN | 18 | Departments. |
| SV | 14 | Departments. The 2024 reform into 44 municipalities is below this level; ISO still lists the 14 departments. |
| NG | 37 | 36 states + FCT (NG-FC). |
| TZ | 31 | Regions, incl. Songwe (TZ-31), Geita, Katavi, Njombe, Simiyu and the five Zanzibar regions (TZ-06, 07, 10, 11, 15). |
| GH | 16 | Regions after the 2018–19 split (Ahafo, Bono, Bono East, North East, Oti, Savannah, Western North). |
| SN | 14 | Regions. |
| RW | 5 | Kigali City and four provinces. |
| NA | 14 | Regions, incl. Kavango East/West (NA-KE, NA-KW); NA-CA is Zambezi, NA-KA ǁKaras. |
| TN | 24 | Governorates. |
| DZ | 58 | **ISO 3166-2:DZ has 58 provinces** (DZ-49…DZ-58 added 2022-11-29 for the ten wilayas created in 2019). Algeria has since adopted a territorial-organisation law creating 11 more wilayas (numbers 59–69: Aflou, Barika, El Kantara, Bir El Ater, El Aricha, Ksar Chellala, Aïn Oussera, Messaad, Ksar El Boukhari, Bou Saâda, El Abiodh Sidi Cheikh; to take effect from 1 January 2027 per press reports). ISO has not added them, so the map follows ISO's 58. |

## File format

Both formats are unchanged from the existing files (`MAP_SOURCES.md` → "File format"; `geo_WORLD.json` and `MAP_SOURCES_GEO.md`):

- **`map_<ID>.json`.** Canvas origin top-left, y down, long side exactly 1000 units, 10-unit margins (VE's right margin is 121.7 units because the canvas extends to show the Essequibo overlay whole). `d` uses absolute `M`/`L`/`Z` only, at most one decimal, one ring per `M…Z` subpath, even-odd fill. `c` is inside its region. Regions are sorted by drawn area, largest first. No `frames`. `disputed`/`disputedLines` only in VE.
- **`geo_<ID>.json`.** `x` = longitude, `y` = latitude (north positive), nominal 360 × 180, at most 3 decimals, no edge longer than 0.5° (maximum 0.488°), no ring crosses the antimeridian, same ids as the map file, no insets, sorted by geodesic area. `disputed` and `disputedLines` are present in every geo file (empty except VE) with the same entries and claimants as the map file.

## Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Natural Earth](https://www.naturalearthdata.com/) 1:10m: Admin 0 map subunits (5.1.1), Admin 0 disputed areas (5.1.1), Admin 0 boundary lines (land) and disputed-area boundary lines (5.1.0), lakes (5.0.0) | <ul><li>Every country outline: all 17 maps are clipped to NE's map subunits for the country (TZ: `TZA` + `TZZ`), the same polygons as `geo_WORLD.json`.</li><li>VE's Essequibo area and its two lines; lakes.</li></ul> | Public domain |
| [World Bank Official Boundaries](https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries) (Global Administrative Divisions), Admin 1, version 3 | Regions of VE, PY, GT, CR, DO, JM, HN, SV, NG, TZ, GH, SN, RW, NA, TN, and DZ's 48 pre-2019 wilayas (outer lines) | CC BY 4.0, © The World Bank |
| [OCHA / HDX COD-AB Panama](https://data.humdata.org/dataset/cod-ab-pan) (`pan_admin_boundaries`, version 01; INEC Panamá boundaries of 15 June 2020, reviewed 30 October 2025), admin 1 and admin 3 | Panama's 10 provinces and 3 older comarcas; the Teribe corregimiento used for Naso Tjër Di | CC BY-IGO (OCHA) |
| [geoBoundaries](https://www.geoboundaries.org/) gbHumanitarian DZA ADM2 (2020; UNHCR, via HDX), build `9469f09` | The 1,541 Algerian communes used to carve the ten 2019 wilayas out of their parent wilayas | CC BY 3.0 IGO |

geoBoundaries asks users to cite Runfola, D. et al. (2020), *geoBoundaries: A global database of political administrative boundaries*, PLoS ONE 15(4): e0231866. Every dataset was modified: clipped to Natural Earth's land, merged or split as described below, and simplified.

**Datasets checked but not used:**
- **Share-alike / OSM-derived (ODbL, CC BY-SA):** geoBoundaries gbOpen CRI, DZA, GTM, HND, PAN, TUN and TZA ADM1 (OpenStreetMap via Wambacher), gbOpen GHA, JAM and SLV ADM1 (OSM, CC BY-SA 2.0).
- **GADM-derived:** geoBoundaries gbHumanitarian JAM, PAN and SLV ADM1.
- **Restrictive licence:** geoBoundaries gbAuthoritative CRI, GHA, NGA and SEN (UN SALB data licence).
- **Outdated:** NE admin 1 for GH (10 pre-2018 regions), NA (13; one Kavango, "Caprivi"), TZ (30, no Songwe), TN (23, no Ariana as a separate unit), PA (no Panamá Oeste or Naso Tjër Di), DZ (48), VE (still "Vargas"); World Bank and geoBoundaries DZA ADM1 (48); OCHA COD-AB PAN and ANATI's 2025 official DPA service (13 units, no Naso Tjër Di — see below); gbHumanitarian VEN (24 units), DOM (10 development regions only), TUN (6).

## Processing

Same pipeline as `MAP_SOURCES_3.md` and `MAP_SOURCES_B.md` (scripts in `/private/tmp/jpex-mapC/`: `build_c.py`, `run_c.py`, `validate_c.py`, `render_geo_c.py`, reusing `/private/tmp/jpex-map3/` unchanged):

1. **Regions** mapped to ISO ids by name (tables in `build_c.py`).
2. **Outlines from Natural Earth.** Units were clipped to NE's map subunits for the country, so coasts and international borders are identical to the WORLD maps. Overlaps go to one unit; NE land that no unit covers goes to the adjacent unit (split between neighbours by nearest unit where it touches several; this is how the Niger Delta's creeks and mangroves, about 8,500 km² that the World Bank leaves as water, reached Bayelsa, Delta and Rivers); slivers ≤ 5 km² are merged into the unit around them; the topology is rebuilt so neighbours share identical edges.
3. **Lakes** cut out as holes: NE natural lakes of 400 km² or more, plus every lake `geo_WORLD.json` cuts (3,500 km² or more). The geo files cut the same lakes.

   | Map | Lakes cut |
   |---|---|
   | GT | Lago de Izabal |
   | TZ | Victoria, Tanganyika (Tanzania's shares), Rukwa, Eyasi, Natron, Manyara |
   | GH | Lake Volta (a reservoir, but 7,960 km²: `geo_WORLD.json` cuts it) |
   | RW | Lake Kivu (Rwanda's share) |

   Not cut: reservoirs below 3,500 km² (Guri, Itaipú, Yguazú, Kainji, Gatún); Lago de Valencia (331 km²) and Lago Enriquillo (285 km²) are below 400 km². NE's unnamed 431 km² "lake" in Paraguay is the Yguazú reservoir and is not cut. Lake Maracaibo is sea in NE (as on the world map). Lake Malawi/Nyasa does not overlap NE's Tanzania (NE's border follows the shore).
4. **Projection, islets, simplification, repair, labels and output** exactly as in `MAP_SOURCES_3.md`.
5. **Geo files** as for `geo_WORLD.json`: topology and simplification on the map's main canvas, original lon/lat of the retained vertices, edges densified to ≤ 0.5°, 3 decimals.
6. **Validation** (`validate_c.py`): path grammar; exact id set against ISO (no duplicates); ranges; ≥ 3 points per ring, no repeated closing point; `c` inside (even-odd); sort order; region overlap ≤ 0.002 u²; overlay keys/claimants; geo maximum edge 0.488°, no antimeridian jumps; geo ids and overlays identical to the map's; sizes. All 34 files pass.
7. **Previews** (in `/private/tmp/jpex-mapC/previews/`, inspected): every projected map labelled, zooms, VE's overlays, and every geo file over `geo_WORLD.json` in Winkel Tripel.

## Per-map notes

- **VE.** World Bank states. Islands are VE-W (Los Roques, La Orchila, La Tortuga, La Blanquilla, Las Aves, Los Testigos as far as NE draws them); Margarita, Coche and Cubagua are Nueva Esparta. **Isla de Aves** (VE-W, 0.6 km² in NE, 15.7°N, ~550 km north of the coast) is omitted from the map file because it would add ~40% to the canvas height; it is also below the geo file's islet threshold, so neither file draws it. Lake Maracaibo is sea.
- **PY.** World Bank departments and Asunción.
- **GT.** World Bank departments.
- **CR.** World Bank provinces. **Isla del Coco** (Puntarenas, 24 km², 5.5°N 87°W, ~550 km south-west of the mainland) is **omitted from the map file** (it would more than double the canvas; an inset of a 24 km² island is not useful); it is kept in place in CR-P in the geo file. The Gulf of Nicoya islands (Chira, San Lucas) and Isla del Caño are in Puntarenas.
- **PA.** OCHA COD-AB (INEC) provinces and comarcas. **Naso Tjër Di (PA-NT) is an approximation.** The comarca was created by Law 188 of 4 December 2020 (1,606 km², carved from Changuinola district, Bocas del Toro), but no official geometry has been published: INEC notes that its corregimientos are not yet in the official DPA because of inconsistencies in the law's limits, and ANATI's 2025 DPA service still has 13 units. PA-NT is drawn as the **Teribe corregimiento** (857 km² in COD-AB; it contains Sieyik and the Teribe valley, the comarca's core), removed from Bocas del Toro. The real comarca is about twice as large and extends further into the La Amistad highlands; replace the shape when INEC/ANATI publish it.
- **DO.** World Bank provinces. The source draws Isla Saona in La Romana; it belongs to La Altagracia (San Rafael del Yuma municipality), so it was moved to DO-11. Beata and Alto Velo are in Pedernales.
- **JM.** World Bank parishes. The Pedro and Morant Cays are below NE's resolution.
- **HN.** World Bank departments. The **Swan Islands** (Islas del Cisne, 17.4°N 83.9°W) are in NE's land and the source's Islas de la Bahía, and are drawn in place in HN-IB, as NE has them; the canvas is width-limited, so they add empty sea at the top but do not shrink the mainland. The Gulf of Fonseca islands are in Valle.
- **SV.** World Bank departments; the Gulf of Fonseca islands (Meanguera, Conchagüita) are in La Unión.
- **NG.** World Bank states (OSGOF lines). See step 2 for the Niger Delta.
- **TZ.** World Bank regions, with Songwe. Mafia Island is in Pwani (TZ-19); Unguja and Pemba are split into the five Zanzibar regions.
- **GH.** World Bank regions after the 2018–19 split (areas match the official ones: Savannah 35,851 km², Northern 24,842, North East 9,077).
- **SN.** World Bank regions.
- **RW.** World Bank provinces. NE's Rwanda polygon includes Lake Kivu's Rwandan waters; Kivu is cut here (it is below the world map's 3,500 km² rule), so RW's area is 4.9% below the world map's.
- **NA.** World Bank regions with Kavango East/West and Zambezi; Walvis Bay is in Erongo.
- **TN.** World Bank governorates; Djerba is in Médenine, the Kerkennah Islands in Sfax, La Galite in Bizerte.
- **DZ.** World Bank wilayas for the 48 older wilayas' outer lines; the ten wilayas created by Law 19-12 (December 2019) and coded DZ-49…DZ-58 by ISO in 2022 were carved out of their parent wilayas using their communes (geoBoundaries/UNHCR commune layer, matched by name inside the parent):

  | New wilaya | From | Communes | Area here |
  |---|---|---|---|
  | DZ-49 Timimoun | Adrar | Timimoun, Ouled Saïd, Aougrout, Deldoul, Metarfa, Charouine, Talmine, Ouled Aïssa, Tinerkouk, Ksar Kaddour | 65,447 km² |
  | DZ-50 Bordj Badji Mokhtar | Adrar | Bordj Badji Mokhtar, Timiaouine | 132,216 km² |
  | DZ-51 Ouled Djellal | Biskra | Ouled Djellal, Doucen, Chaïba, Sidi Khaled, Besbes, Ras El Miad | 11,266 km² |
  | DZ-52 Béni Abbès | Béchar | Béni Abbès, Tamtert, Igli, El Ouata, Kerzaz, Timoudi, Béni Ikhlef, Ouled Khoudir, Ksabi, Tabelbala | 111,112 km² |
  | DZ-53 In Salah | Tamanrasset | In Salah, Foggaret Ezzaouia, In Ghar | 138,106 km² |
  | DZ-54 In Guezzam | Tamanrasset | In Guezzam, Tin Zaouatine | 98,392 km² |
  | DZ-55 Touggourt | Ouargla | Touggourt, Nezla, Tebesbest, Zaouia El Abidia, Témacine, Blidet Amor, Megarine, Sidi Slimane, Taïbet, Benaceur, M'Naguer, El Hadjira, El Alia | 18,889 km² |
  | DZ-56 Djanet | Illizi | Djanet, Bordj El Haouas | 88,950 km² |
  | DZ-57 El M'Ghair | El Oued | El M'Ghair, Sidi Khellil, Oum Touyour, Still, Djamaa, Sidi Amrane, Tendla, M'Rara | 8,086 km² |
  | DZ-58 El Meniaa | Ghardaïa | El Meniaa (El Goléa), Hassi Gara, Hassi Fehal | 58,541 km² |

  Each parent's World Bank outline was split between the parent and its new wilayas by their commune polygons (gaps between the two sources assigned by adjacency). Desert commune lines are coarse in the source (straight segments); areas are within roughly 10% of the published ones.

## Alignment with `geo_WORLD.json`

| Map | Area geo vs world | IoU | Farthest geo vertex outside world | Farthest world vertex outside geo |
|---|---|---|---|---|
| VE | 0.0% | 0.989 | 139 km (Federal Dependencies islets) | 0.8 km |
| PY | +0.1% | 0.993 | 11 km | 0.7 km |
| GT | −0.3% | 0.981 | 18 km | 0.6 km |
| CR | 0.0% | 0.966 | 502 km (Isla del Coco) | 0.8 km |
| PA | +0.3% | 0.945 | 25 km | 0.7 km |
| DO | −0.4% | 0.970 | 13 km | 0.7 km |
| JM | −0.3% | 0.946 | 8 km | 0.5 km |
| HN | +0.5% | 0.971 | 182 km (Swan Islands) | 0.6 km |
| SV | +1.5% | 0.954 | 16 km | 0.6 km |
| NG | −0.2% | 0.994 | 9 km | 0.7 km |
| TZ | −0.4% | 0.986 | 27 km | 0.7 km |
| GH | −0.7% | 0.972 | 12 km | 0.7 km |
| SN | −0.4% | 0.981 | 19 km | 0.6 km |
| RW | −4.9% | 0.928 | 6 km | 17 km (Lake Kivu) |
| NA | 0.0% | 0.996 | 7 km | 0.7 km |
| TN | +0.2% | 0.985 | 15 km | 0.6 km |
| DZ | 0.0% | 0.998 | 9 km | 0.6 km |

Both files come from the same NE polygons; the differences are `geo_WORLD.json`'s coarse world-scale simplification, the small islands it drops, and lakes cut here but not in the world map (Kivu, Izabal, Rukwa and the other TZ lakes below 3,500 km²).

## Boundary choices and disputed areas

All maps follow the WORLD maps' view: Natural Earth's de facto outlines. Overlays use the same ids, names, claimants and notes as `geo_WORLD.json`; geometry is NE's full-resolution disputed area/lines, simplified with the map's settings and part of the same topology. Claimants follow the `map_IN.json` convention.

| Map | Overlay | Claimants / note | Lines |
|---|---|---|---|
| VE | `essequibo` — Guayana Esequiba (Essequibo), NE B56 | `WORLD-GY`, `WORLD-VE`; "Administered by Guyana; claimed by Venezuela." | `venezuela-guyana-line` (Venezuela–Guyana boundary (1899 award)), `essequibo-claim-line` (Venezuelan claim line (Essequibo River)) |

The area lies outside Venezuela's de facto territory and none of its states (it is not part of any VE region, and no VE id is a claimant, like Aksai Chin on `map_IN.json`). The canvas grows east to show it whole (right margin 121.7 units on the regions). The 1899-award line coincides with Venezuela's eastern border; the claim line runs along the Essequibo river, the area's eastern edge. Draw overlays on top of the regions (hatched, dashed lines).

**Not added:**
- **Western Sahara** touches Algeria's south-western border (Tindouf), but Algeria is not a claimant; consistent with JO/Golan in `MAP_SOURCES_B.md`, no overlay. The Moroccan Berm and the 27°40′N line do not enter Algeria.
- No other `geo_WORLD.json` area or line lies in or borders PY, GT, CR, PA, DO, JM, HN, SV, NG, TZ, GH, SN, RW, NA or TN (Belize–Guatemala, Bakassi, the Tanzania–Malawi lake boundary and the Gulf of Fonseca have no layer in `geo_WORLD.json`).

## Rendering notes

- **Fill rule.** Even-odd: lakes and enclaves are extra rings. The smallest regions (Distrito Capital and La Guaira VE, Asunción, Distrito Nacional, Kingston, Kigali, Tunis, Alger, Dakar, Dar es Salaam, Mjini Magharibi) are all larger than 3 units.
- **Omitted islets (map only):** Isla del Coco (CR), Isla de Aves (VE). No insets in this batch.
- **Approximation:** PA-NT (Naso Tjër Di) — see "Per-map notes".
