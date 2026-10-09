# Map data: Russia

Generated on 8 October 2026. The app bundles these files for offline use; it does not request map data from a network service at runtime.

This adds 2 files to `jpex/Maps/`: the projected map `map_RU.json` and the unprojected (lon/lat) map `geo_RU.json`. No existing file was changed.

## Files

| Map | Regions | `map_` size | `geo_` size | Canvas | km/unit | Simplify map / geo (u²) | Islet (u² ≈ km²) | Hole (u²) | Projection | Frames | Overlays |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RU | 83 | 246.2 KB | 282.9 KB | 1000 × 567.4 | 8.14 | 0.23 / 0.28 | 0.8 ≈ 53 | 4 | Lambert conformal conic (52°/70°N, lat₀ 62°N, 100°E) | – | 1 area, 3 lines |

- Exact sizes: `map_RU.json` 252,079 bytes; `geo_RU.json` 289,707 bytes.
- Points: 21,422 in the map's regions and 20,048 in the geo file's regions.
- The simplification thresholds are coarser than the usual 0.15 u² so the files fit their budgets (about 260 KB and 300 KB). The coastline is very long: the Arctic archipelagos, the Kurils and the Pacific coast. 0.15 u² would give 311 KB for the map.
- All 83 ids have a shape. None were omitted, and no region is smaller than 3 units, so none is drawn as a marker square. The smallest regions are RU-SPE, RU-MOW and RU-IN.

## Scope

- **Regions.** Exactly the 83 federal subjects listed in ISO 3166-2:RU, with the ISO codes as ids (RU-MOW, RU-SPE, RU-TA, …).
- **Crimea.** Russia is drawn within its internationally recognised boundaries, as in `geo_WORLD.json` (UN General Assembly resolution 68/262).
  - Crimea and Sevastopol are not in this map. They are UA-43 and UA-40 in the Ukraine map, and part of WORLD-UA in the WORLD maps.
  - No other part of Ukraine is in this map.
  - NE's admin-1 layer files Crimea (UA-43) and Sevastopol (UA-40) under `adm0_a3` RUS. They were excluded by code. The land mask also excludes NE's Crimea subunit (`RUC`).
- **Kaliningrad (RU-KGD)** is included, in its true position. There is no inset (see "Insets").

## File format

Both formats are unchanged from the existing files:
- `map_RU.json` follows `MAP_SOURCES.md` → "File format".
- `geo_RU.json` follows `geo_WORLD.json`, as described in `MAP_SOURCES.md` → "Unprojected world map" and in `MAP_SOURCES_GEO.md`.

In brief:

- **`map_RU.json`.**
  - Canvas: origin top-left, y down, longer side exactly 1000 units, 10-unit margin.
    - The top margin is 12.9 and the right margin 10.3. The canvas was fitted before islets were dropped, and a few Arctic islets near the edges were dropped afterwards.
  - `d`: absolute `M`/`L`/`Z` only, at most one decimal, one ring per `M…Z` subpath, even-odd fill.
  - `c`: a label point inside the region.
  - Regions are sorted by drawn area, largest first.
  - There are no `frames`. `disputed` and `disputedLines` are present.
- **`geo_RU.json`.**
  - `x` is longitude and `y` is latitude, north positive and not flipped. `width`/`height` are nominal (360 × 180).
  - Numbers have at most 3 decimals.
  - No edge is longer than 0.5° (the maximum is 0.490°). Longer edges were subdivided linearly in lon/lat, including the cut edges along 180°.
  - No ring crosses the antimeridian; see "Chukotka and the antimeridian".
  - The ids, overlays and claimants are the same as in `map_RU.json`.
  - Regions are sorted by geodesic area, largest first.
    - The map file is sorted by area on the Lambert canvas. Lambert is conformal, not equal-area, so neighbours of similar size sometimes swap places between the two files: Primorye/Tuva, Omsk/Vologda, Rostov/Saratov, Kalmykia/Nizhny Novgorod/Leningrad, Khakassia/Kostroma, and a few more.

## Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Natural Earth](https://www.naturalearthdata.com/) 1:10m: Admin 1 states and provinces (5.1.1), Admin 0 map subunits (5.1.1), Admin 0 disputed areas (5.1.1), Admin 0 boundary lines (land) and disputed-area boundary lines (5.1.0), lakes (5.0.0) | <ul><li>All 83 federal subjects.</li><li>Russia's outline: map subunits `RUA`, `RUE` and `RUK`, the same polygons as `geo_WORLD.json`'s WORLD-RU.</li><li>The southern Kuril Islands area and the Kuril and Crimea lines.</li><li>Lakes.</li></ul> | Public domain ([terms](https://www.naturalearthdata.com/about/terms-of-use/)) |

Only Natural Earth was used, so nothing new needs crediting beyond the existing Natural Earth entry in `MapCredits.json`.

**Datasets checked but not used:**
- **geoBoundaries gbOpen RUS ADM1** (2017, 83 units): from OpenStreetMap (Wambacher), so ODbL (share-alike).
- **geoBoundaries gbHumanitarian RUS ADM1** (2022): GADM-derived (via HDX COD-AB), and only the 8 federal districts at ADM1.
- **World Bank Official Boundaries Admin 1** (version 3, CC BY 4.0): outdated.
  - It has 89 pre-2005 subjects: Perm, Komi-Permyak, Taymyr, Evenk, Koryak, Ust-Orda and Aga Buryat as separate units, and Chita Oblast.
  - It has the pre-2012 Moscow (990 km², without New Moscow).
  - It has an unnamed 3,600 km² unit at the Stavropol/Kalmykia border.
  - It puts Franz Josef Land in Nenets.

## Processing

1. **Regions.** NE's 85 Russian admin-1 features were mapped to the ISO ids by `iso_3166_2`, with these corrections:
   - **Moscow codes swapped.** NE gives the city of Moscow ("Moskva", the federal city with New Moscow and Zelenograd, 2,854 km²) the code RU-MOS, and Moscow Oblast ("Moskovskaya", 44,002 km²) the code RU-MOW. ISO 3166-2 has them the other way round, so they were swapped. The swap is asserted by name in the build.
   - **UA-43 and UA-40** were excluded (see Scope).
   - **`RU-X01~`**, a 38 km² unnamed island in Baydaratskaya Bay ("Russia minor island"), was left unassigned and given to the adjacent land as below. It goes to Yamalo-Nenets (RU-YAN), and it is below the islet threshold anyway.
   - NE already reflects the 2005–2008 mergers (Perm, Krasnoyarsk, Kamchatka, Irkutsk and Zabaykalsky krais) and Moscow's 2012 expansion. A comparison with the official areas showed no other outdated unit.
2. **Outline from Natural Earth.** The subjects were clipped to NE's map subunits for Russia (`RUA` + `RUE` + `RUK`), the same polygons that make up WORLD-RU in `geo_WORLD.json`. Coastlines and international borders are therefore identical to the WORLD maps.
   - Three Habomai islets (39 km²) that are in NE's admin-1 Sakhalin but not in its admin-0 Russia were dropped with the clip.
   - Land in the mask that no subject covers (0.1 km² of slivers, and the `RU-X01~` island) went to the adjacent subject, as in `MAP_SOURCES_3.md`.
3. **Lakes** were cut out as holes:
   - NE natural lakes of 1,000 km² or more: Baikal, Ladoga, Onega, Taymyr, Khanka, Peipus, Chany, Vygozero, Pyaozero, Beloye, Khantayskoye, Topozero;
   - Lake Pskov (830 km²), which is one water body with Peipus;
   - every lake `geo_WORLD.json` cuts (3,500 km² or more, reservoirs included): the Kuybyshev (NE "Samara"), Rybinsk, Bratsk and Vilyuy reservoirs.

   Other reservoirs are not cut, as on the other maps. The geo file cuts the same lakes as the map.
4. **Projection, islets, simplification, repair and output** follow `MAP_SOURCES.md` → "Processing" and `MAP_SOURCES_3.md`, with the same pipeline and settings except the thresholds in the table:
   - shared-arc topology on a 0.01-unit grid;
   - weighted Visvalingam–Whyatt (k = 0.7), with every arc keeping an interior point;
   - local repair of overlaps;
   - rounding to 0.1;
   - `c` is NE's label point if it falls in a substantial part, otherwise the pole of inaccessibility. The disputed overlays and lines are part of the same topology.
5. **Geo file.** As for `geo_WORLD.json` and `MAP_SOURCES_3.md`:
   - Topology, islet removal and simplification are computed on the map's Lambert canvas (same projection and scale), and the retained vertices keep their original lon/lat.
   - Edges are densified to at most 0.5° and coordinates rounded to 3 decimals.
   - Chukotka is then split at 180° (see below).
6. **Validation.** Both files were re-parsed and checked:
   - path grammar;
   - exact id set against the 83 ISO 3166-2:RU codes, with no duplicates;
   - canvas and lon/lat ranges, at least 3 points per ring and no repeated closing point;
   - `c` inside its region under even-odd, and sort order;
   - overlap between regions: 0.000 u²;
   - overlay keys, claimants and lines; geo overlays identical to the map's;
   - geo: maximum edge 0.490°, no antimeridian jumps;
   - sizes.

   Previews were rendered and inspected:
   - the map with ids and label points, with zooms of European Russia, the Kurils and Chukotka;
   - the overlays;
   - `geo_RU.json` over `geo_WORLD.json` in Winkel Tripel with central meridian 0° and 150°E, with zooms of Chukotka, the Kurils and European Russia.

## Chukotka and the antimeridian

- **Map.** Before projecting, longitudes west of 180° (Chukotka east of 180°, Wrangel Island's eastern half, Big Diomede) were unwrapped by +360°. NE's pieces on either side of 180° were dissolved. Chukotka (RU-CHU) is therefore one continuous region on the map, with no seam or jump. Its mainland and Wrangel Island are each a single ring.
- **Geo file.** RU-CHU's rings were cut at 180° and the eastern parts shifted back by −360°, so no ring crosses the antimeridian.
  - The mainland and Wrangel Island are each two rings of RU-CHU, one on each side of ±180°. The cut edges lie exactly on 180° and −180°.
  - This matches how `geo_WORLD.json` splits WORLD-RU.
  - Chukotka's `c` is NE's label point (170.516°E, 66.752°N).
  - No other region or overlay reaches 180°.

## Insets

None. In the Lambert projection Kaliningrad lies inside the bounding box of the rest of Russia, so drawing it in place costs nothing: the canvas is 7,973 × 4,454 km with or without it. It is at the far left of the map, west of Pskov and Smolensk, separated from the mainland by the blank space where Lithuania and Belarus are.

## Alignment with `geo_WORLD.json`

| Map | Area geo vs world | IoU | Farthest geo vertex outside world | Farthest world vertex outside geo |
|---|---|---|---|---|
| RU | 0.0% (16,859,210 vs 16,863,945 km²) | 0.992 | 121 km | 22 km |

- Both files come from the same NE polygons. The differences are the world map's coarser simplification and the islands it drops.
- The "geo outside world" vertices are on 39 small islands (about 40–80 km² each) that the world map drops. The largest are Arctic islets in Franz Josef Land, the Kara Sea, Severnaya Zemlya, and the New Siberian and De Long Islands.
- The "world outside geo" value is lakes cut here but not in the world map: Chany, Topozero and the others below 3,500 km².

## Boundary choices and disputed areas

Russia follows the same view as the WORLD maps: Natural Earth's de facto outlines, with Crimea assigned to Ukraine. The overlays use the same ids, names and notes as `geo_WORLD.json`'s layers. Their geometry is NE's full-resolution disputed area and boundary lines (same selectors as `geo_WORLD.json`), simplified with this map's settings.

| Area | Claimants | Note |
|---|---|---|
| southern-kuril-islands (Southern Kuril Islands (Northern Territories)) | RU-SAK, WORLD-JP | Administered by Russia; claimed by Japan. |

- **Southern Kurils.**
  - Iturup, Kunashir, Shikotan and the Habomai group are drawn in Sakhalin Oblast (RU-SAK), as NE (de facto) and `geo_WORLD.json` do.
  - The overlay marks them. Its claimants follow the `map_IN.json` convention: the administering subject RU-SAK replaces WORLD-RU.
  - It lies inside the map's regions, so the canvas did not grow.

| Line | Name | On this map |
|---|---|---|
| kuril-islands-line | Japan–Russia line (southern Kuril Islands) | Yes: between Hokkaido and Kunashir and the Habomai islands |
| kuril-japanese-claim-line | Japanese claim line (Iturup–Urup) | Yes: the Friz Strait between Iturup and Urup |
| crimea-boundary | Crimea boundary | Yes, at the canvas's left edge (see below) |

- **`crimea-boundary`.** It was to be included only if it falls on the canvas. It does.
  - In this projection Crimea is just left of Krasnodar Krai, inside the canvas rectangle at x ≈ 0–17. Both segments (Perekop/Syvash and the Kerch Strait) are within the canvas. The Perekop segment is partly in the left margin and was clipped at x = 0, as lines are on every map.
  - Crimea itself is not drawn. On the projected map, the Kerch Strait segment therefore runs just off Krasnodar's Taman coast, and the Perekop segment is in blank space at the left edge.
  - The geo file carries the complete line. Over `geo_WORLD.json` it coincides with WORLD-UA's Crimea, where `geo_WORLD.json` has the same line.
  - If the app should not show it on this map, it is a self-contained entry and can be dropped from `disputedLines` in both files.
- **Not added.**
  - The `crimea` area: it is outside this map's regions and was not requested.
  - `abkhazia-line` and `south-ossetia-line`: they border Russia's Caucasus republics, but their claimants are WORLD-GE only.
  - Russian-occupied areas of Ukraine beyond Crimea, as in the other maps: no stable public-domain boundary exists.

## Rendering notes

- **Fill rule.** Fill regions and overlays with the even-odd rule. Lakes and enclaves are extra rings.
  - Moscow city (RU-MOW) sits inside Moscow Oblast (RU-MOS) and has three parts: the core with New Moscow, Zelenograd, and a small exclave.
  - Saint Petersburg (RU-SPE) is coastal, inside Leningrad Oblast. Adygea is an island inside Krasnodar Krai.
  - All are larger than 3 units, so none needs a marker. Draw in file order (largest first) so the small subjects are on top.
- **Overlays.** Draw them on top of the regions: hatched areas, dashed lines.
  - The `southern-kuril-islands` outline coincides with RU-SAK's southern islands.
  - The Kuril lines run in the sea just off them.
  - The `crimea-boundary` line is at the canvas's left edge (see above).
- **Antimeridian.**
  - On the projected map Chukotka is continuous.
  - In the geo file, the 180° cut appears as a straight edge at ±180°. Renderers that project to a central meridian other than 0° (e.g. 150°E) should stroke region outlines from the fill, not from ring edges, or the cut will show as a hairline through Chukotka and Wrangel Island. The WORLD file has the same cut.
- **Geo file over the world map.** Where a lake is cut, the world map's country fill shows through. Along the Arctic coast, small islets in this file have no counterpart in the world map.
