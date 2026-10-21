# Map data: batch D, 24 more countries and the first second-level lists

Generated on 16 October 2026. The app bundles these files for offline use; it does not request map data from a network service at runtime.

This batch adds 48 files to `jpex/Maps/` for 24 countries, each with a projected map `map_<ID>.json` and an unprojected (lon/lat) map `geo_<ID>.json`. It also adds 15 projected maps for the first lists below a country's first level (see "Second level" below). No existing file was changed.

## Files

| Map | Regions | `map_` size | `geo_` size | Canvas | Outline | Projection | Overlays |
|---|---|---|---|---|---|---|---|
| VN | 34 | 132.9 KB | 170.8 KB | 485.1 × 1000 | NE | Transverse Mercator (106°E, k 0.9999) | – |
| AF | 34 | 170.4 KB | 203.0 KB | 1000 × 783.7 | NE | Lambert conformal conic (31°/37°N, lat₀ 34°N, 66.5°E) | – |
| BN | 4 | 19.8 KB | 23.6 KB | 1000 × 810.7 | source | Transverse Mercator (114.7°E) | – |
| MM | 15 | 106.4 KB | 127.3 KB | 460.8 × 1000 | NE | Transverse Mercator (96°E) | – |
| PK | 7 | 58.1 KB | 72.5 KB | 1000 × 979.9 | NE | Lambert conformal conic (27°/34°N, lat₀ 30°N, 69.5°E) | 5 areas, 6 lines |
| GE | 12 | 66.7 KB | 79.1 KB | 1000 × 520.9 | NE | Transverse Mercator (43.5°E) | 2 areas, 2 lines |
| TJ | 5 | 37.0 KB | 44.2 KB | 1000 × 713.5 | NE | Lambert conformal conic (37.5°/40.5°N, lat₀ 39°N, 71°E) | – |
| LB | 8 | 38.1 KB | 45.5 KB | 781.6 × 1000 | source | Transverse Mercator (35.9°E) | 1 area |
| MD | 37 | 82.3 KB | 98.0 KB | 793 × 1000 | NE | Transverse Mercator (28.4°E, k 0.99994; MOLDREF99 parameters) | 1 area, 1 line |
| ZM | 10 | 98.5 KB | 125.1 KB | 1000 × 856.3 | NE | Transverse Mercator (28°E, k 0.9996) | – |
| ZW | 10 | 73.9 KB | 94.4 KB | 1000 × 908.4 | NE | Transverse Mercator (30°E, k 0.9996) | – |
| MZ | 11 | 66.4 KB | 84.8 KB | 639.9 × 1000 | NE | Transverse Mercator (35°E, k 0.9996) | – |
| CM | 10 | 70.1 KB | 76.8 KB | 683.9 × 1000 | NE | Transverse Mercator (12.5°E, k 0.9996) | – |
| BW | 16 | 34.5 KB | 44.4 KB | 955.1 × 1000 | NE | Transverse Mercator (24.5°E, k 0.9996) | – |
| NI | 17 | 82.4 KB | 105.1 KB | 1000 × 893.4 | NE | Transverse Mercator (85.4°W, k 0.9999) | – |
| HT | 10 | 45.8 KB | 58.4 KB | 1000 × 764 | NE | Transverse Mercator (72.8°W, k 0.9999) | – |
| TT | 15 | 19.8 KB | 25.4 KB | 1000 × 928.1 | source | Transverse Mercator (61.2°W, k 0.9999) | – |
| GY | 10 | 74.4 KB | 88.4 KB | 675.9 × 1000 | NE | Transverse Mercator (59°W, k 0.9996) | 1 area, 2 lines |
| SR | 10 | 51.5 KB | 62.8 KB | 980.8 × 1000 | NE | Transverse Mercator (55.7°W, k 0.9996) | – |
| BZ | 6 | 12.4 KB | 15.7 KB | 545.4 × 1000 | NE | Transverse Mercator (88.6°W, k 0.9999) | – |
| WS | 11 | 13.5 KB | 19.8 KB | 1000 × 477.5 | source | Transverse Mercator (172.1°W, k 0.9999) | – |
| VU | 6 | 11.0 KB | 15.3 KB | 461.9 × 1000 | NE | Transverse Mercator (168°E, k 0.9996) | – |
| TO | 5 | 9.0 KB | 13.1 KB | 359.7 × 1000 | source | Transverse Mercator (175°W, k 0.9996) | – |
| SB | 10 | 20.5 KB | 27.1 KB | 1000 × 445.8 | NE | Transverse Mercator (162°E, k 0.9996) | – |

Every listed id has a shape: 313 regions in all. None was omitted. Exact sizes in bytes, map then geo: VN 136,049 / 174,928; AF 174,523 / 207,826; BN 20,239 / 24,200; MM 108,985 / 130,319; PK 59,483 / 74,204; GE 68,297 / 80,953; TJ 37,842 / 45,258; LB 38,983 / 46,637; MD 84,316 / 100,363; ZM 100,891 / 128,102; ZW 75,716 / 96,679; MZ 68,032 / 86,831; CM 71,828 / 78,654; BW 35,375 / 45,477; NI 84,354 / 107,631; HT 46,946 / 59,828; TT 20,303 / 25,976; GY 76,221 / 90,555; SR 52,740 / 64,268; BZ 12,677 / 16,102; WS 13,850 / 20,316; VU 11,246 / 15,649; TO 9,241 / 13,417; SB 20,983 / 27,753. Every file is within the 200 KB / 220 KB budgets (Afghanistan's are the largest).

All thresholds are the earlier batches': 0.15 u² simplification, 0.8 u² islets, 4 u² holes. "Outline" says whether a map is clipped to Natural Earth's outline of the country, the same polygons as `geo_WORLD.json`, or keeps its source's own coastline and borders, because Natural Earth's is coarser than the canvas there (as Malta's map does).

## Scope (ids)

Ids are ISO 3166-2 codes, checked against each code list's change history and Wikidata (see `MORE_FLAG_SOURCES_D.md`, "Catalog scope", for every collection). Points to know:

- **VN.** The 34 provinces and centrally run cities since Vietnam's merger of 1 July 2025 (Resolution 202/2025/QH15). ISO 3166-2:VN still lists the 63 earlier units, so each id is the former code of the unit whose name the new one kept, such as `VN-29` for Quảng Ngãi (with Kon Tum). The World Bank's admin 1 already has the 34 units.
- **PK.** Seven units: the four provinces, Islamabad Capital Territory, Azad Kashmir (`PK-JK`) and Gilgit-Baltistan (`PK-GB`). Natural Earth's separate Federally Administered Tribal Areas were merged into Khyber Pakhtunkhwa, as they were in 2018.
- **MM.** Seven regions, seven states and Nay Pyi Taw Union Territory (`MM-18`), which the World Bank draws and Natural Earth lacks.
- **LB.** The eight governorates of ISO 3166-2:LB. Keserwan-Jbeil, created by law in 2017 but never in operation, is not a region; if it starts operating it can be cut from the World Bank's Kasrouane and Jubail districts as `LB-KJ`.
- **GE, MD.** Listed de jure: Abkhazia (`GE-AB`) under Georgia; Transnistria (`MD-SN`) and Bender (`MD-BD`) under Moldova. South Ossetia is not an ISO unit.
- **BW.** The ten districts (World Bank) and the six town councils of ISO 3166-2:BW (Gaborone, Francistown, Jwaneng, Lobatse, Selebi-Phikwe, Sowa Town), cut from the districts with Natural Earth's polygons.
- **TT.** The fourteen municipal corporations and Tobago (`TT-TOB`); Natural Earth's Eastern and Western Tobago were not used.
- **Not added yet.** Turkmenistan: no openly licensed boundary of Ashgabat (`TM-S`) exists; the World Bank, geoBoundaries and Natural Earth all have only the five regions. Andorra: the World Bank's parishes are far from their official areas (Andorra la Vella 25.6 km² against 12, Encamp 101.6 against 74) and Natural Earth's are worse. Liechtenstein: the World Bank's municipalities are off (Ruggell 4.5 km² against 7.4), and the national dataset (Amt für Bau und Infrastruktur, "Hoheitsgrenzen") carries a share-alike clause. San Marino: only Natural Earth's coarse castelli (Faetano 3.7 km² against 7.8). Their catalogs and flags are researched and kept for when better data appears.

## File format

Both formats are unchanged (`MAP_SOURCES.md` → "File format"; `MAP_SOURCES_GEO.md`). `map_` files have no `frames`; `disputed`/`disputedLines` appear only in the maps listed with overlays. Every `geo_` file has both arrays, empty unless the map has overlays.

## Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Natural Earth](https://www.naturalearthdata.com/) 1:10m: Admin 0 map subunits and Admin 1 states and provinces (5.1.1), Admin 0 disputed areas (5.1.1), Admin 0 boundary lines (land) and disputed-area boundary lines (5.1.0), lakes (5.0.0) | Every country outline marked NE; all regions of PK; Botswana's six town councils; lakes; the disputed areas and lines | Public domain |
| [World Bank Official Boundaries](https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries), Global Administrative Divisions, admin 1 (feature service `World_Bank_Global_Administrative_Divisions` on ArcGIS Online, last edited 28 August 2026) | Regions of VN, AF, BN, MM, GE, TJ, LB, MD, ZM, ZW, MZ, CM, BW (districts), NI, HT, TT, GY, SR, BZ, WS, VU, TO and SB | CC BY 4.0, © The World Bank |

Datasets checked but not used: geoBoundaries gbOpen for LIE, SMR and TTO (OpenStreetMap-derived, ODbL) and BWA (CC BY-SA); Natural Earth's admin 1 where it is out of date (VN's 63 provinces, MM without Nay Pyi Taw, LB's six governorates, MD's split Transnistria, BW without Chobe, TJ and TM under Soviet names).

## Processing

Scripts are in `/private/tmp/jpex-admin2/scripts/` (`mapbuild.py`, `build.py`, `countries.py`, `second.py`, `overlays.py`, `validate.py`). The steps follow `MAP_SOURCES_3.md` and `MAP_SOURCES_B.md`:

1. **Regions** were mapped to their IDs by name (tables in `countries.py`), by Natural Earth's `iso_3166_2` (PK, SM, and Botswana's town councils), by ABS LGA code or by ONS GSS code.
2. **Outlines from Natural Earth.** Units were clipped to NE's map subunits for the country, the same polygons as `geo_WORLD.json`, so coasts and borders match the World map. Overlaps go to the larger unit, and NE land that no unit covers goes to the unit it shares the longest border with. Small countries whose NE outline is coarser than their canvas keep the source's own coastline and borders instead, as Malta's map does (see the table).
3. **Lakes** cut out: Tanganyika, Mweru, Kariba and Bangweulu (ZM); Kariba (ZW); Lake Malawi/Niassa (MZ); Lake Chad (CM); Nicaragua and Managua (NI); Sarygamysh (TM). Every lake `geo_WORLD.json` cuts is cut; reservoirs inside a country (Cahora Bassa, Brokopondo, Mingachevir, Tarbela) are not, as on the earlier maps.
4. **Projection** suited to each country (see the table), fitted to a canvas whose longer side is 1000 units, with 10-unit margins.
5. **Islets** below 0.8 u² are dropped; every region keeps its largest part, and a region's own threshold is at most 2% of its area, so small places keep their islands. **Holes** below 4 u² are filled unless another region lies in them.
6. **Slivers.** Corridors of a region narrower than 0.5 units that run between a lake shore or coast and another region, as NE's and the sources' lines leave in places, go to the neighbour they border most. A region that is thin all over keeps its shape.
7. **Simplification** on shared arcs with mapshaper 0.7: snapping at 0.005 units, `-clean` to make neighbours share identical borders, then weighted Visvalingam–Whyatt (k = 0.7; mapshaper's interval is √(effective area) × 0.65), so neighbours keep identical borders. Thresholds: 0.15 u² (Scotland's councils 0.3 u², to stay within the size budget).
8. **Rounding and repair.** Coordinates are rounded to 0.1 units (0.001° in geo files). Where rounding leaves a pinch, a spike or a local crossing (as across the mouth of a narrow inlet), the ring is split there, so the inlet becomes a hole or the headland a part of its own; parts smaller than 0.02 u² are dropped.
9. **Labels.** `c` is NE's label point where NE has one for the unit and it falls in a substantial part (a quarter of the largest part), otherwise the pole of inaccessibility of the largest part.
10. **Geo files** go through steps 5–9 on an Equal Earth canvas centred on the country, at the map's scale, then back to lon/lat; edges longer than 0.5° are subdivided. They are sorted by area on that canvas.
11. **Validation** (`validate.py`): path grammar; the exact id set; decimals; coordinates inside the canvas (map) or in range (geo); `c` inside its region (even-odd); no ring crossing itself; region overlaps ≤ 0.05 u²; geo edges ≤ 0.5° and no antimeridian jumps; longer side exactly 1000. Every file passes.
12. **Previews** of every map, and of every geo file over `geo_WORLD.json`, were rendered and inspected.

## Per-map notes

- **Lakes cut.** ZM: Tanganyika, Mweru, Kariba, Bangweulu. ZW: Kariba. MZ: Lake Malawi (Niassa). CM: Lake Chad. NI: Lake Nicaragua and Lake Managua.
- **VN.** Natural Earth's outline leaves out the Paracel and Spratly Islands, which `geo_WORLD.json` draws as disputed areas; no other map draws them either.
- **TJ.** Dushanbe is an enclave of the Districts under Central Government Jurisdiction, drawn as a hole with Dushanbe in it.
- **BW.** Francistown, Lobatse, Selebi-Phikwe and Sowa Town are enclaves, drawn as holes in their districts with the town in them; Gaborone and Jwaneng lie where districts meet.
- **TO.** The source's coastline keeps ʻEua, Tongatapu, Haʻapai, Vavaʻu and the Niua Islands, which Natural Earth draws as specks.
- **Small countries** (BN, LB, TT, WS, TO) keep the World Bank's coastlines, so they do not line up exactly with the World map at high zoom; at world zoom they are a few pixels across.

## Disputed areas and lines

Five maps carry overlays, with the same ids, names and notes as `geo_WORLD.json`, built from Natural Earth's full-detail polygons and lines (kept to the World map's extent) and simplified separately from the regions, so they can deviate from the region borders by up to about a unit. Where an area lies in a division of the map's own country, that division's id replaces the country among its claimants, as on the earlier maps.

| Map | Areas | Lines |
|---|---|---|
| PK | `jammu-and-kashmir`, `ladakh` (claimants `WORLD-IN`, `WORLD-PK`), `azad-kashmir` (`PK-JK`, `WORLD-IN`), `gilgit-baltistan` (`PK-GB`, `WORLD-IN`), `siachen-glacier` | `kashmir-line-of-control`, `kashmir-working-boundary`, both Siachen lines, `china-pakistan-boundary-kashmir`, `sir-creek` |
| GE | `abkhazia` (`GE-AB`), `south-ossetia` (`GE-IM`, `GE-MM`, `GE-RL`, `GE-SK`) | `abkhazia-line`, `south-ossetia-line` |
| MD | `transnistria` (`MD-DU`, `MD-SN`) | `transnistria-line` |
| GY | `essequibo` (`GY-BA`, `GY-CU`, `GY-PM`, `GY-PT`, `GY-UT`, `WORLD-VE`) | `venezuela-guyana-line`, `essequibo-claim-line` |
| LB | `shebaa-farms` (`LB-NA`, `WORLD-IL`) | – |

On PK's map, Indian-administered Jammu and Kashmir and Ladakh reach past the canvas's right edge and are clipped there, as Gilgit-Baltistan is at the top of India's map.

## Alignment with `geo_WORLD.json`

The union of each geo file's regions against its country on the World map, on Equal Earth:

| Map | Area geo vs world | IoU |
|---|---|---|
| VN | +0.2% | 0.969 |
| AF | -0.0% | 0.992 |
| BN | +7.5% | 0.806 |
| MM | +0.1% | 0.979 |
| PK | +0.0% | 0.992 |
| GE | +0.1% | 0.978 |
| TJ | +0.4% | 0.974 |
| LB | +4.6% | 0.907 |
| MD | -0.1% | 0.954 |
| ZM | -0.3% | 0.991 |
| ZW | +0.0% | 0.993 |
| MZ | -0.2% | 0.991 |
| CM | -0.1% | 0.990 |
| BW | +0.0% | 0.996 |
| NI | -0.7% | 0.968 |
| HT | +1.3% | 0.939 |
| TT | +5.1% | 0.862 |
| GY | +0.4% | 0.985 |
| SR | -0.4% | 0.987 |
| BZ | +1.4% | 0.961 |
| WS | +15.7% | 0.824 |
| VU | +25.9% | 0.730 |
| TO | +597.8% | 0.084 |
| SB | +16.9% | 0.787 |

The maps clipped to Natural Earth's outline match the World map closely. The small countries with their sources' own coastlines differ more, as Malta's does. VU, SB and TO also keep islands that the World map drops below its islet threshold (about 181 km²). Tonga is a few specks on the World map, so the comparison there means little.

## Second level: places' own subdivisions

These are the app's first lists below a country's first level. Each is a list of one place's own subdivisions, opened from that place's row (and from its region on the country's map), as a country's list opens from the World, or from the small card beside the country's total, whose menu lists every place that has one. It shares the place's ID: `AU-TAS` is Tasmania's local government areas. Each has only a projected map, `map_<parent id>.json`, in the same format as the country maps. There is no `geo_` file, because these lists open from a country's own map, never straight from the World's.

| Map | Places | Size | Canvas | km/unit | Simplify (u²) | Projection | Source |
|---|---|---|---|---|---|---|---|
| AU-TAS | 29 | 163.2 KB | 809 × 1000 | 0.51 | 0.15 | Transverse Mercator (146.6°E) | ABS LGA 2026 |
| AU-NT | 19 | 67.9 KB | 585 × 1000 | 1.70 | 0.15 | Lambert conformal conic (13°/24°S, lat₀ 18.5°S, 133.5°E) | ABS LGA 2026 |
| AU-NSW | 130 | 206.8 KB | 1000 × 800.3 | 1.31 | 0.4 | Lambert conformal conic (30.75°/35.75°S, lat₀ 33.25°S, 147°E) | ABS LGA 2026 |
| AU-VIC | 81 | 142.4 KB | 1000 × 797.5 | 0.83 | 0.3 | Lambert conformal conic (36°/38°S, lat₀ 37°S, 145°E) | ABS LGA 2026 |
| AU-QLD | 78 | 139.6 KB | 719.6 × 1000 | 2.27 | 0.3 | Lambert conformal conic (13°/25°S, lat₀ 19°S, 144°E) | ABS LGA 2026 |
| AU-SA | 71 | 62.9 KB | 893.6 × 1000 | 1.38 | 0.3 | Lambert conformal conic (28°/36°S, lat₀ 32°S, 135°E) | ABS LGA 2026 |
| AU-WA | 137 | 121.6 KB | 845.9 × 1000 | 2.40 | 0.3 | Lambert conformal conic (17.5°/31.5°S, lat₀ 24°S, 121°E) | ABS LGA 2026 |
| GB-SCT | 32 | 158.0 KB | 680.5 × 1000 | 0.70 | 0.3 | British National Grid transverse Mercator | ONS LAD May 2026 BGC |
| GB-WLS | 22 | 174.3 KB | 850.8 × 1000 | 0.24 | 0.15 | British National Grid transverse Mercator | ONS LAD May 2026 BGC |
| GB-NIR | 11 | 111.3 KB | 1000 × 809.5 | 0.18 | 0.15 | Irish Transverse Mercator parameters (8°W) | ONS LAD May 2026 BGC |
| ES-AN | 8 | 95.3 KB | 1000 × 588.4 | 0.53 | 0.15 | Transverse Mercator (community's centre) | World Bank admin 2 |
| ES-AR | 3 | 47.4 KB | 721.5 × 1000 | 0.35 | 0.15 | 〃 | 〃 |
| ES-PV | 3 | 24.8 KB | 1000 × 787.5 | 0.14 | 0.15 | 〃 | 〃 |
| ES-CN | 2 | 26.9 KB | 1000 × 436.3 | 0.47 | 0.15 | 〃 | 〃 |
| ES-CL | 9 | 115.6 KB | 1000 × 803.1 | 0.45 | 0.15 | 〃 | 〃 |
| ES-CM | 5 | 67.6 KB | 1000 × 947.6 | 0.40 | 0.15 | 〃 | 〃 |
| ES-CT | 4 | 55.7 KB | 1000 × 983.8 | 0.27 | 0.15 | 〃 | 〃 |
| ES-EX | 2 | 35.7 KB | 884.3 × 1000 | 0.29 | 0.15 | 〃 | 〃 |
| ES-GA | 4 | 59.4 KB | 955.7 × 1000 | 0.23 | 0.15 | 〃 | 〃 |
| ES-VC | 3 | 27.5 KB | 543.2 × 1000 | 0.33 | 0.15 | 〃 | 〃 |

Islets 0.8 u², holes 4 u², as for the countries. Every place has a shape, and every file passes validation. The km/unit of the five larger states is the main map's scale after fitting their insets in.

### Insets of the capitals

Inner-city councils are a few kilometres across, a unit or two on a state's map, too small to see or tap even zoomed in. Peppermint Grove, Western Australia's smallest at 1.1 km², is 0.4 units on its state's map. So each capital's crowded middle is drawn a second time, enlarged, in a box over the sea (one of the map's `frames`). The copy is part of the same place's path: both copies light up together, and the place's label point and the camera's "main body" (its largest part) are the enlarged copy.

The inset takes the capital's cluster of small councils: councils under a size threshold (the square root of the main part's area, in units) that touch one another, grown from the capital's own council, plus any council they enclose, so the inset has no gaps. Each is copied whole, never clipped, so a larger council beside the cluster isn't copied at all, and its label and camera stay on the main map.

| Map | Inset | Seed | Threshold | Councils | Enlarged | Box |
|---|---|---|---|---|---|---|
| AU-NSW | Sydney | City of Sydney (`17200`) | 10 u | 21, out to Parramatta, Fairfield, Canterbury-Bankstown and Ku-ring-gai | ×6 | Tasman Sea, south-east of Sydney |
| AU-VIC | Melbourne | City of Melbourne (`24600`) | 8.8 u | 9: Melbourne, Yarra, Port Phillip, Stonnington, Glen Eira, Bayside, Maribyrnong, Moonee Valley, Merri-bek | ×4 | Southern Ocean, off western Victoria (not Bass Strait, where it would cover Tasmania on Australia's map as the list flies in) |
| AU-SA | Adelaide | City of Adelaide (`40070`) | 8 u | 14, out to Port Adelaide Enfield, Tea Tree Gully, Mitcham and Marion | ×7 | The Bight, south-west of Eyre Peninsula |
| AU-WA | Perth | City of Perth (`57080`) | 4 u | 18, from Peppermint Grove and Cottesloe to Bassendean, Belmont, Melville and Canning | ×14 | Indian Ocean, west of the South West, widening the map |

Lord Howe Island (`AU-LHI`) is carried in from 600 km out in the Tasman Sea, ×3, into a small box off the north coast; it isn't drawn at its own position. Queensland has no inset: Brisbane's councils are large, and its smallest (Weipa, Wujal Wujal, Cherbourg, Palm Island) are scattered across the north and drawn as dots, as small places are on every map. Councils left outside the insets, such as Perth's middle ring (Stirling, Joondalup, Cockburn, Gosnells) or the regional cities (Mandurah, Bunbury, Port Lincoln, Mount Gambier, Queenscliffe), are 3–8 units across, enough to tap with the map zoomed in.

### Flying in from the country's map

Each second-level map carries `"parentTransform": [a, b, c, d, tx, ty]`, a similarity (scale, rotation, translation, as for `CGAffineTransform`) carrying its units onto its country's map. With it, opening a place's list from its country's flies the way a country's list flies in from the World: the camera dives into the place on the country's map, the subdivisions trace themselves in over it, and they settle into their own map (and back out again, or across from one place's list to another's). Inset copies come along, already at sea where their box will be, so every place keeps one shape as it settles.

The transform was fitted offline (`parent_fit.py`). The subdivisions' outline is their main body, leaving out insets and far-off islands. It is turned through ±20°, then refined to best cover the place's region on the country's map, by area of overlap. Overlap is 0.92–0.99, lowest for Tasmania, a small and coarse shape on Australia's map. The fitted rotations are about +6° for the eastern Australian states, whose maps are centred further east than Australia's, −5° for Western Australia, and under 5° for the rest.

### Scope (ids)

- **Australia** (`AU-<ABS LGA code>`, such as `AU-62810` for Hobart). Tasmania's 29 councils, grouped by the state's three regions (North; North-West and West; South). The Northern Territory's 18 councils, grouped by kind: municipalities, regional councils and shire councils. That includes Groote Archipelago, a regional council since 1 July 2024, split from East Arnhem. The Territory's unincorporated areas (ABS `79399`) are listed as one place too, in an Other areas group. They include Yulara (the Ayers Rock Resort), Nhulunbuy, Alyangula, Litchfield and Mary River national parks, the Cox Peninsula and East Arm. The Darwin Waterfront Precinct, which ABS also lists (`71150`, about 1 km²), is run by a statutory corporation rather than a council; it is drawn as part of Darwin. The ACT has no local government. New South Wales's 128 councils, Victoria's 79, Queensland's 77 (with Weipa, which the ABS lists though its town authority isn't one of them), South Australia's 68 with the Anangu Pitjantjatjara Yankunytjatjara and Maralinga Tjarutja lands, and Western Australia's 137 are grouped by their states' official regions: the NSW regional plans (with Greater Sydney), Victoria's Regional Development Victoria Act regions (with Metropolitan Melbourne), Queensland's regional planning areas, the South Australian Government Regions (Adelaide's four as Metropolitan Adelaide) and Western Australia's Perth metropolitan region and Regional Development Commissions Act regions. Unincorporated areas: Lord Howe Island (`AU-LHI`), whose Board acts as its council, is a place of its own in North Coast, and the rest of ABS `19399` is the Unincorporated Far West; Victoria's alpine resorts (`AU-ARV`, run by Alpine Resorts Victoria: Mount Buller and Mount Stirling, Falls Creek, Mount Hotham, Mount Baw Baw and Lake Mountain) are a place of their own in Hume, and the rest of `29399`, mainly French Island, is Unincorporated areas in Gippsland; South Australia's unincorporated areas (`49399`, mostly the Pastoral Unincorporated Area) are one place in Far North.
- **United Kingdom** (ISO 3166-2:GB, such as `GB-EDH` for the City of Edinburgh). Scotland's 32 council areas, Wales's 22 principal areas, grouped by the four regions of the Welsh Government's corporate joint committees, and Northern Ireland's 11 districts. England is left for later: its county and unitary structure would make one list of about 150 places.
- **Spain** (ISO 3166-2:ES, such as `ES-SE` for Seville). The provinces of the ten communities with more than one. Asturias, the Balearic Islands, Cantabria, Madrid, Murcia, Navarre and La Rioja are single provinces, and Ceuta and Melilla are cities; none of them gets a list.

### Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Australian Bureau of Statistics](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs/edition-4-july-2026-june-2031/non-abs-structures/local-government-areas), Australian Statistical Geography Standard (ASGS) Edition 4, Local Government Areas 2026 (`LGA_2026_AUST_GDA2020`, released 14 October 2026; fields `LGA_CODE26`, `LGA_NAME26`) | Every state's and the Northern Territory's local government areas | CC BY 4.0. Source: Australian Bureau of Statistics |
| [Office for National Statistics](https://geoportal.statistics.gov.uk/), Local Authority Districts (May 2026) Boundaries UK BGC (generalised to 20 m, clipped to the coastline; fields `LAD26CD`, `LAD26NM`, `LAD26NMW`) | Scotland's council areas, Wales's principal areas and Northern Ireland's districts | Open Government Licence v3.0. "Source: Office for National Statistics licensed under the Open Government Licence v.3.0. Contains OS data © Crown copyright and database right 2026." |
| [World Bank Official Boundaries](https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries), Global Administrative Divisions, admin 2 (feature service `World_Bank_Global_Administrative_Divisions`, last edited 28 August 2026) | Spain's provinces | CC BY 4.0, © The World Bank |

Datasets checked but not used: the ONS ultra-generalised (BUC) boundaries, too coarse at council scale; Natural Earth's Spanish provinces, whose 1:10m lines are coarser than these canvases.

### Notes

- **Outlines.** These maps keep their sources' own coastlines rather than Natural Earth's, as the maps of small countries do. The outline of each list's map can therefore differ slightly from the place's outline on its country's map. The two are never drawn together.
- **Tasmania.** Macquarie Island (part of Huon Valley) is omitted, as on Australia's map, because it would stretch the canvas 1,500 km to the south-east. The Furneaux Group (Flinders) and King Island are in place; smaller islands are kept where they pass the islet threshold.
- **Northern Territory.** The unincorporated areas are several separate parts. The largest are around Yulara, Nhulunbuy, Alyangula and the parks south of Darwin.
- **Scotland.** The council areas' sea lochs and islands make a large file, so its simplification threshold is 0.3 u² rather than 0.15 u². Shetland and Orkney are in place.
- **Wales.** Wales is drawn on the British National Grid like the UK map. Its regions are display groups only.
- **Spain.** Enclaves are drawn as holes: the Treviño enclave (Burgos, in Castile and León) inside Álava, and Valle de Villaverde (Cantabria) inside Biscay. In the app, a hole without another place's label is filled, so they show as part of the province around them on the Basque Country's map.
