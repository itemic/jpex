# Map data: Serbia, Bosnia and Herzegovina, Albania, Montenegro, Latvia, Luxembourg, Malta, Belarus, Armenia, Kazakhstan, Uzbekistan and Kyrgyzstan

Generated on 8 October 2026. The app bundles these files for offline use; it does not request map data from a network service at runtime.

This batch adds 24 files to `jpex/Maps/`. Each of the 12 collections has a projected map `map_<ID>.json` and an unprojected (lon/lat) map `geo_<ID>.json`. No existing file was changed.

## Files

| Map | Regions | `map_` size | `geo_` size | Canvas | km/unit | Simplify map / geo (u²) | Islet (u²) | Hole (u²) | Projection | Frames | Overlays |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RS | 25 | 96.2 KB | 114.8 KB | 755.2 × 1000 | 0.45 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (21°E, k 0.9999; Gauss–Krüger zone 7, the Serbian grid) | – | 1 line |
| BA | 12 | 58.0 KB | 69.3 KB | 1000 × 977.3 | 0.32 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (18°E, k 0.9999; Gauss–Krüger zone 6) | – | – |
| AL | 12 | 43.4 KB | 52.2 KB | 452.7 × 1000 | 0.34 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (20°E, k 1; Albanian TM 2010 / KRGJSH-2010) | – | – |
| ME | 25 | 15.5 KB | 18.3 KB | 837.7 × 1000 | 0.19 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (19.3°E, k 0.9999) | – | – |
| LV | 43 | 164.5 KB | 196.2 KB | 1000 × 600.1 | 0.46 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (24°E, k 0.9996; LKS-92 / Latvia TM) | – | – |
| LU | 12 | 72.2 KB | 71.1 KB | 700.4 × 1000 | 0.083 | 0.15 / 0.15 | 0.8 | 4 | Transverse Mercator (49.83°N, 6.17°E, k 1; LUREF) | – | – |
| MT | 68 | 18.3 KB | 21.4 KB | 1000 × 934.2 | 0.036 | 0.15 / 0.15 | 0.8 | 4 | UTM 33N (ETRS89 / UTM 33N grid) | – | – |
| BY | 7 | 51.8 KB | 61.7 KB | 1000 × 849.4 | 0.66 | 0.15 / 0.15 | 0.8 | 4 | Lambert conformal conic (52°/55°N, 28°E) | – | – |
| AM | 11 | 23.6 KB | 28.2 KB | 1000 × 996.5 | 0.28 | 0.15 / 0.15 | 0.8 | 4 | UTM 38N (ARMREF02 / UTM 38N grid) | – | – |
| KZ | 20 | 90.2 KB | 109.5 KB | 1000 × 566.7 | 3.02 | 0.15 / 0.15 | 0.8 | 4 | Lambert conformal conic (44°/52°N, 67°E) | – | – |
| UZ | 14 | 37.9 KB | 45.3 KB | 1000 × 661.3 | 1.47 | 0.15 / 0.15 | 0.8 | 4 | Lambert conformal conic (38.5°/43.5°N, 64.5°E) | – | – |
| KG | 9 | 62.3 KB | 74.9 KB | 1000 × 494.3 | 0.95 | 0.15 / 0.15 | 0.8 | 4 | Lambert conformal conic (40°/42.5°N, 74.7°E) | – | – |

Exact sizes in bytes, map then geo:
- RS 98,463 / 117,572; BA 59,431 / 71,010; AL 44,392 / 53,460; ME 15,837 / 18,766
- LV 168,489 / 200,881; LU 73,915 / 72,827; MT 18,727 / 21,958; BY 53,034 / 63,227
- AM 24,123 / 28,846; KZ 92,395 / 112,150; UZ 38,858 / 46,428; KG 63,827 / 76,685

Every listed id has a shape: 258 regions in all. None were omitted, and no region is smaller than 3 units on its map, so none is drawn as a marker square. All maps use the previous batches' settings (0.15 u² simplification, 0.8 u² islets, 4 u² holes); no file needed a coarser threshold.

## Scope and ids

The ids are ISO 3166-2 codes, agreed with the catalog agent:

| Map | Ids | Count | Difference from the ISO top level |
|---|---|---|---|
| RS | RS-00 (Belgrade), RS-01 … RS-24 (districts) | 25 | ISO's top level is RS-00, RS-08…RS-24, RS-KM and RS-VO; the Vojvodina districts RS-01…RS-07 are ISO children of RS-VO. Kosovo's districts RS-25…RS-29 (children of RS-KM) are not in this map; Kosovo is its own place in the app (WORLD-XK). |
| BA | BA-01 … BA-10 (Federation cantons), BA-SRP, BA-BRC | 12 | The ISO list in `subdivisions.json` has only BA-BIH, BA-SRP and BA-BRC. BA-BIH is replaced by its ten cantons. |
| AL, ME, LV, LU, MT, BY, AM, KZ, UZ, KG | the ISO top level | 12, 25, 43, 12, 68, 7, 11, 20, 14, 9 | None. ME has 25 (Gusinje ME-22, Petnjica ME-23, Tuzi ME-24 and Zeta ME-25 included; no newer municipality exists). LV has the 43 units of the 2021 reform (7 state cities, 36 municipalities incl. Varakļāni). KZ has the 2022 regions (Abai KZ-10, Jetisu KZ-33, Ulytau KZ-62) and the current codes. |

## File format

Both formats are unchanged from the existing files (`MAP_SOURCES.md` → "File format"; `geo_WORLD.json` as described in `MAP_SOURCES.md` and `MAP_SOURCES_GEO.md`):
- **`map_<ID>.json`**: canvas origin top-left, y down, longer side exactly 1000 units, 10-unit margin; `d` with absolute `M`/`L`/`Z` only, at most one decimal, one ring per subpath, even-odd fill; `c` inside the region; regions sorted by drawn area. No `frames`. `disputed`/`disputedLines` only in RS (`disputed` is `[]` there).
- **`geo_<ID>.json`**: x = longitude, y = latitude (north positive), at most 3 decimals, no edge longer than 0.5° (maximum 0.486°), no ring crosses the antimeridian, same ids as the map file, no insets, sorted by geodesic area. `disputed` and `disputedLines` are present in every file (empty except RS's line).

## Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Natural Earth](https://www.naturalearthdata.com/) 1:10m: Admin 0 map subunits and Admin 1 states and provinces (5.1.1), Admin 0 boundary lines (land) (5.1.0), lakes (5.0.0) | <ul><li>Every country outline except Malta's: the maps are clipped to NE's country polygons, the same polygons as the WORLD maps (Serbia = subunits `SRS` + `SRV`, without Kosovo; Bosnia = `BHF` + `BIS` + `BHB`; Kazakhstan = `KAZ` + Baikonur `KAB`).</li><li>All regions of BY.</li><li>Montenegro's 21 older municipalities.</li><li>The Kosovo–Serbia line; lakes.</li></ul> | Public domain |
| [World Bank Official Boundaries](https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries) (Global Administrative Divisions), Admin 1, version 3 (10 September 2026) | Serbia's 25 districts (incl. Belgrade); Albania's 12 counties; Armenia's 11 provinces; Kazakhstan's 20 regions and cities (the current 2022 division); Uzbekistan's 14 regions | CC BY 4.0, © The World Bank |
| World Bank Official Boundaries, Admin 2 (the same dataset's ADM2 layer, from the World Bank's `WB_GAD` feature service on ArcGIS Online, last edited 16 September 2026) | Malta's 68 local councils, and Malta's coastline | CC BY 4.0, © The World Bank |
| [geoBoundaries](https://www.geoboundaries.org/) gbOpen BIH ADM2 (2013; Wikimedia Commons), build `f549eab` | Bosnia's 10 cantons, Republika Srpska and Brčko District | Public domain |
| geoBoundaries gbOpen LVA ADM1 (2021; Geoportal of Latvia / Valsts zemes dienests), build `9469f09` | Latvia's 43 municipalities and state cities | CC BY 4.0 |
| geoBoundaries gbHumanitarian KGZ ADM1 (2018; Ministry of Emergency Situations of the Kyrgyz Republic via OCHA/HDX), build `9469f09` | Kyrgyzstan's 7 regions, Bishkek and Osh | CC BY 3.0 IGO |
| [Administration du cadastre et de la topographie](https://data.public.lu/fr/datasets/limites-administratives-du-grand-duche-de-luxembourg/) (ACT), "Limites administratives du Grand-Duché de Luxembourg", `limadmin.geojson` layer `cantons`, published 5 October 2026 | Luxembourg's 12 cantons | CC0 1.0 |
| [Wikidata](https://www.wikidata.org/) (P131 "located in" and P625 coordinates of the settlements of Gusinje, Petnjica, Tuzi, Zeta, Berane, Plav and Podgorica municipalities) | Seed points for re-dividing Berane, Plav and Podgorica (see ME) | CC0 1.0 |
| [GeoNames](https://www.geonames.org/) `ME.txt` (populated places already filed under Gusinje, Petnjica and Tuzi) | Additional seed points for the same | CC BY 4.0 |

geoBoundaries asks users to cite Runfola, D. et al. (2020), *geoBoundaries: A global database of political administrative boundaries*, PLoS ONE 15(4): e0231866. Every dataset was modified: clipped to Natural Earth's land (except Malta), merged or split as described below, and simplified.

**Credits needed beyond the existing Natural Earth entry:** World Bank (CC BY 4.0: RS, AL, AM, KZ, UZ, MT), geoBoundaries / Geoportal of Latvia (CC BY 4.0: LV), geoBoundaries / Kyrgyz MES via OCHA (CC BY 3.0 IGO: KG), geoBoundaries (public domain: BA; citation requested), ACT Luxembourg (CC0: LU), GeoNames (CC BY 4.0: ME) and Wikidata (CC0: ME).

**Datasets checked but not used:**
- **Share-alike / OSM-derived (ODbL).** geoBoundaries gbOpen ADM1 for SRB, MNE, LUX, KAZ, UZB and KGZ, and gbOpen SRB/LUX/KAZ ADM2; Kontur boundaries for Montenegro and Malta. gbOpen KGZ ADM2 is CC BY-SA.
- **GADM-derived.** geoBoundaries gbHumanitarian ALB ADM1/ADM2.
- **Unclear licence.** gbOpen MLT ADM1 (traced from a d-maps.com map). Montenegro's national geoportal could not be reached; Malta's open data portal refused automated requests. Eurostat GISCO LAU carries a non-commercial clause.
- **Outdated or wrong.**
  - NE ADM1 for Latvia (119 pre-2021 municipalities), Luxembourg (the 3 districts abolished in 2015), Kazakhstan (pre-2022, old codes), Kyrgyzstan (no Osh city) and Montenegro (21 municipalities).
  - World Bank Admin 1 for Montenegro (21 municipalities) and Bosnia (3 entities); World Bank Admin 2 for Montenegro (no names).
  - Minsk city is 87 km² in both the World Bank data and gbHumanitarian BLR ADM1 (UNICEF): only the inner districts. NE (607 km²) was used for all of Belarus instead; see BY.
  - NE's Bosnian entity line is off: NE's Federation is 28,800 km² (official 26,110) and its Republika Srpska 22,900 km² (official 24,641); NE files Posavina Canton under BA-SRP.
  - NE's Serbian districts are less accurate than the World Bank's (e.g. Podunavski 1,393 km² vs official 1,248; Braničevski 4,196 vs 3,865), and NE's Malta has no Grand Harbour, Comino or detailed coast.
  - gbHumanitarian KAZ ADM1 (2019) predates the 2022 regions.

## Processing

Unchanged from `MAP_SOURCES_3.md` → "Processing" (same scripts): source units mapped to ISO ids; clipped to NE's country polygon, with uncovered NE land (coastal and border slivers, lakes the source leaves out) given to the adjacent unit, split by nearest unit where it touches several, and small stray fragments (≤ 5 km²) merged into the unit around them; topology rebuilt so neighbours share identical edges; lakes cut as holes; projection, islet removal, weighted Visvalingam–Whyatt simplification on shared arcs with local repair, rounding; geo files simplified on the map's canvas and keeping the original lon/lat of retained vertices, densified to ≤ 0.5° edges.

Source units were mapped by ISO code where the source has one (NE BY, gbOpen LVA) and by name otherwise. Two corrections:
- gbOpen LVA gives Rēzeknes novads Preiļi's code (`LV-073`); it is LV-077.
- The World Bank's "Baikonur" unit (the 38 km² town) is merged into Kyzylorda Region (KZ-43), and so is NE's Baikonur subunit (the 6,500 km² leased area), which the WORLD maps also merge into Kazakhstan. ISO 3166-2 has no code for Baikonur; it is Kazakh territory in Kyzylorda Region, leased to Russia.

**Lakes cut out** (NE natural lakes; reservoirs are not cut). The geo files cut the same lakes; every lake `geo_WORLD.json` cuts in these countries (Balkhash, the Aral Sea parts, Sarygamysh, Issyk-Kul, Zaysan) is among them.

| Map | Rule | Lakes cut |
|---|---|---|
| AL | 200 km² or more | Skadar, Ohrid, Prespa (Albanian parts) |
| ME | 200 km² or more | Skadar (Montenegrin part) |
| LV | 50 km² or more | Lubāns, Rāzna |
| BY | 50 km² or more | Narach |
| AM | 500 km² or more | Sevan |
| KZ | 1,000 km² or more, plus Zaysan (NE classes it as a reservoir; it is a natural lake raised by the Bukhtarma dam) | Balkhash, Zaysan, North Aral Sea, South Aral Sea (Kazakh part), Alakol, Tengiz |
| UZ | 1,000 km² or more | South Aral Sea (Uzbek part), Aydar, Sarygamysh (Uzbek part) |
| KG | 1,000 km² or more | Issyk-Kul |
| RS, BA, LU, MT | – | none |

**Validation.** Every file was re-parsed and checked: path grammar; exact id sets (the lists above), no duplicates; ranges, ≥ 3 points per ring, no repeated closing point; `c` inside its region under even-odd; sort order; overlap between regions (at most 0.005 u², effectively zero); overlay keys and claimants; geo maximum edge (0.486°) and antimeridian; geo ids and overlays identical to the map file; size budgets (200 KB map, 220 KB geo). Previews were rendered with ids labelled and inspected, and every geo file was drawn over `geo_WORLD.json` in Winkel Tripel with the WORLD outline on top.

## Alignment with `geo_WORLD.json`

| Map | Area geo vs world | IoU | Farthest geo vertex outside world | Farthest world vertex outside geo |
|---|---|---|---|---|
| RS | +0.3% | 0.967 | 13.8 km | 0.6 km |
| BA | +0.3% | 0.969 | 14.5 km | 0.6 km |
| AL | +0.3% | 0.948 | 15.2 km | 9.7 km (Lake Skadar) |
| ME | −2.2% | 0.924 | 8.3 km | 4.2 km (Lake Skadar) |
| LV | −0.5% | 0.976 | 7.0 km | 0.4 km |
| LU | −3.7% | 0.905 | 5.3 km | 0.4 km |
| MT | +287% | 0.222 | 16.7 km | 1.3 km |
| BY | 0.0% | 0.987 | 11.8 km | 0.6 km |
| AM | −5.6% (Sevan) | 0.913 | 8.4 km | 0.5 km |
| KZ | −0.3% | 0.991 | 49.6 km (islands the world map drops) | 0.9 km |
| UZ | −1.0% | 0.978 | 39.8 km (islands the world map drops) | 1.6 km |
| KG | +0.1% | 0.975 | 11.5 km | 0.6 km |

The remaining differences come from `geo_WORLD.json`'s much coarser world-scale simplification, the islands it drops, and lakes cut here but not in the world map (Skadar, Sevan, the smaller Kazakh lakes): there the world map's country fill shows through, as in the other `geo_` files.

**Malta is the exception.** NE's Malta polygon is cruder than the councils themselves (no Grand Harbour, no Comino, a generalised coast), and `geo_WORLD.json` draws Malta as a single 82 km² triangle without Gozo. To keep the 68 councils recognisable, MT uses the World Bank coastline (the union of its councils) instead of NE's land, so it does not line up with the world map's Malta at high zoom. At world zoom Malta is a few pixels across.

## Per-map notes

- **RS.**
  - World Bank districts clipped to NE's Serbia without Kosovo. The source's Serbia is slightly smaller than NE's along the Bosnian, Montenegrin and Kosovo borders; that land (about 1,200 km², mostly thin strips) went to the adjacent districts.
  - The Kosovo area is not part of the map. Kosovo's districts RS-25…RS-29 are not included.
  - Belgrade (RS-00) includes its outer municipalities (3,234 km² officially; 3,197 km² in the source).
- **BA.**
  - geoBoundaries' ten cantons, Republika Srpska and Brčko District. Their areas match the official ones within a few per cent (e.g. Posavina 331 km² vs 325, Republika Srpska 25,115 vs 24,641, Brčko 487 vs 493).
  - The source's outline was clipped to NE's Bosnia, so the inter-entity line is the source's while the international border is NE's.
- **AL.** World Bank counties (post-2015 boundaries). Lake Skadar, Ohrid and Prespa are cut out.
- **ME.**
  - NE's 21 municipalities (closer to the official areas on the coast than the World Bank data, whose Tivat is 111 km² instead of 46).
  - **The four new municipalities are approximate reconstructions.** No permissive dataset has their boundaries. Berane (→ Berane + Petnjica, 2013), Plav (→ Plav + Gusinje, 2014) and Podgorica (→ Podgorica + Tuzi, 2018, + Zeta, 2022) were each re-divided by nearest settlement:
    - seeds are the settlements Wikidata places in each municipality (P131), plus GeoNames places already filed under Gusinje, Petnjica and Tuzi; a seed whose four nearest seeds all belong to another municipality was moved to it;
    - each parent was split into the Voronoi cells of its seeds;
    - the new/parent boundary was then offset towards the official areas (Petnjica 173 km², Gusinje 157 km², Tuzi 236 km²), but never across a settlement; slivers under ~20 m wide were removed.
  - Resulting areas: Petnjica 206 km² (official 173), Berane 529 (544); Gusinje 196 (157), Plav 312 (329); Tuzi 236 (236), Zeta 174, Podgorica 1,027. Zeta was not calibrated (no reliable official area found). Boundaries may be off by a few kilometres; every settlement is in its own municipality.
  - If a permissive source with the current municipalities appears (e.g. Montenegro's cadastre), ME-03, ME-13, ME-16 and ME-22…ME-25 should be redrawn from it.
  - Lake Skadar is cut out; it lies mainly in Zeta, Bar and Cetinje.
- **LV.** The Geoportal of Latvia's 43 units of the 2021 reform. The seven state cities (Rīga, Daugavpils, Jelgava, Jūrmala, Liepāja, Rēzekne, Ventspils) are separate regions, mostly inside their surrounding municipality.
- **LU.** ACT's 12 cantons (current; the districts were abolished in 2015). NE's Luxembourg outline is coarse at this scale (0.08 km per unit): the cantons' inner boundaries are detailed, the international border is NE's.
- **MT.**
  - World Bank local councils with the World Bank coastline (see above). Comino is part of Għajnsielem (MT-13); Filfla, a separate unit in the source, is part of Żurrieq (MT-68).
  - The source's two Rabats and two Żebbuġs were told apart by region: Rabat Gozo (Victoria) MT-45, Rabat Malta MT-46, Żebbuġ Gozo MT-65, Żebbuġ Malta MT-66.
  - The smallest councils (Mdina, Isla, Valletta, Ta' Xbiex, Pietà, Fontana) are all larger than 3 units.
- **BY.** NE as is. **Known issue:** NE's Minsk city (BY-HM) is 607 km², larger than the official 409 km²; no permissive source draws Minsk correctly (World Bank and UNICEF: 87 km²).
- **AM.**
  - World Bank provinces; Lake Sevan is cut out of Gegharkunik.
  - The Artsvashen exclave (NE draws it as Armenian) is part of Gegharkunik; the Azerbaijani exclaves inside Armenia are outside the map, as in NE.
- **KZ.**
  - World Bank regions: the current 17 regions and 3 cities, including Abai (from East Kazakhstan), Jetisu (from Almaty Region) and Ulytau (from Karaganda), all created on 8 June 2022. Areas match the official ones (Abai 186,179 km², Jetisu 118,726, Ulytau 188,905).
  - Baikonur is in Kyzylorda Region (see above). Astana, Almaty and Shymkent are islands inside their surrounding regions.
  - Mangystau got 11,900 km² of NE land the source leaves out along the Caspian shore (the source's coastline is further inland).
- **UZ.** World Bank regions. Tashkent city (UZ-TK, 344 km²) is an island inside Tashkent Region. The Aral Sea remnant, Aydar and Sarygamysh are cut out.
- **KG.**
  - The Ministry of Emergency Situations' regions with Bishkek and Osh cities. Osh city is 45 km² here (the official city area is about 182 km²); Bishkek 150 km² (official 170).
  - The Uzbek and Tajik enclaves (Sokh, Shakhimardan, Vorukh, …) are holes, as in NE.

## Boundary choices and disputed areas

Each map follows the WORLD maps' view: Natural Earth's de facto outlines.

| Map | Area | Claimants | Lines |
|---|---|---|---|
| RS | – | – | `kosovo-serbia-line` (Kosovo–Serbia boundary) |

- **Kosovo.** Serbia is drawn without Kosovo, which the app shows as its own place (WORLD-XK). The `kosovo-serbia-line` from `geo_WORLD.json` (NE boundary line between `SRB` and `KOS`, the same selector) runs along Serbia's southern border and is drawn as a disputed line in both RS files, with the same id and name. As the task specified, the `kosovo` area itself (claimants WORLD-RS, WORLD-XK) is not added to the RS map; it can be added from the same NE polygon (`B57`) if wanted, which would extend the RS canvas south to include Kosovo.
- **No other overlay applies.** None of `geo_WORLD.json`'s disputed areas or lines touch BA, AL, ME, LV, LU, MT, BY, AM, KZ, UZ or KG. Transnistria is Moldova's. Nagorno-Karabakh is not in `geo_WORLD.json`'s layers (and is not part of Armenia's map). The Kyrgyz–Tajik and Kyrgyz–Uzbek border settlements are not represented as disputes; the borders are NE's.

## Rendering notes

- **Fill rule.** Fill regions with the even-odd rule: lakes, enclaves and city islands are extra rings (Belgrade is not an island; Minsk, Astana, Almaty, Shymkent, Tashkent, Bishkek, Osh, the Latvian state cities, Mdina and Mtarfa, Fontana are islands inside their neighbours).
- **Overlay.** Draw RS's disputed line on top of the regions, dashed. It coincides with Serbia's outline.
- **Geo files over the world map.** Where a lake is cut, the world map's country fill shows through. Malta's councils do not match the world map's Malta outline (see above).
