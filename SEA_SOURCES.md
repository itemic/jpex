# Sea map (`geo_SEAS.json`)

Generated on 16 October 2026. The app bundles this file for offline use; it does not request map data from a network service at runtime.

`jpex/Maps/geo_SEAS.json` holds the 103 regions of the Seas list: the 101 sea areas of the International Hydrographic Organization (IHO) as published by Marine Regions, plus the Caspian Sea and the Dead Sea from Natural Earth. The seas tile Natural Earth's 1:10m ocean without gaps or overlaps, so their coastline is Natural Earth's coastline, the same source as `geo_WORLD.json`.

## File format

The format is the one described in `MAP_SOURCES_GEO.md` (lon/lat, absolute `M`/`L`/`Z`, at most 3 decimals, even-odd rings, no edge longer than 0.5°, no edge across ±180°), with these differences:

```json
{"id": "SEAS", "width": 360, "height": 180, "keepsHoles": true,
 "regions": [{"id": "SEAS-north-atlantic-ocean", "d": "M…Z M…Z", "c": [-44.59, 26.54]}],
 "disputed": [], "disputedLines": []}
```

- **`keepsHoles: true`.** Holes in a sea are islands, not lakes. The app must keep them instead of filling them.
- **Ids.** `SEAS-` plus a lowercase, hyphenated slug of the sea's cleaned English name (table below). Ids are stored in users' data, so they must never change. Display names may change later.
- **No disputed overlays.** `disputed` and `disputedLines` are empty.
- **Order.** Regions are sorted by area on Equal Earth (EPSG:8857), largest first. The Dead Sea is last.
- **Label point.** `c` is the pole of inaccessibility (GEOS maximum inscribed circle, 500 m tolerance) of the region's largest part. It is computed on an Equal Earth canvas centred on 0°, or on 180° for the seas with parts on both sides of the antimeridian, so their two halves are joined. The Arctic Ocean, which contains the North Pole, uses a north-polar Lambert azimuthal equal-area canvas, because Equal Earth's pole is a line that pushes the label off the pole. Its label is at 85.79°N, 176.19°E (the app's Mercator clamps that to 85°). Each `c` is rounded to 2 decimals and checked to be inside under even-odd filling.
- **Antimeridian.** The South and North Pacific, Southern Ocean, Arctic Ocean, Bering Sea and Chukchi Sea have parts on both sides of ±180°, split there. The East Siberian Sea touches +180° only. The two sides of the cut match to within 0.005°.
- **Poles.** The Arctic Ocean's outer ring runs up the +180° meridian, along latitude 90 from 180° to −180° (736 vertices, at most 0.49° apart) and down the −180° meridian, just as `WORLD-AQ` does along −90. Nothing reaches −90: the Southern Ocean ends at the Antarctic coast.
- **Ice shelves are water.** Natural Earth's ocean includes the Antarctic ice shelves (Ross, Ronne–Filchner and others), and `WORLD-AQ` in `geo_WORLD.json` leaves them out too. They therefore belong to the Southern Ocean, so the sea and country maps fit together.

Size: 689,182 bytes (673 KB), 103 regions, 1,039 rings, 47,157 points.

## Sources and licences

| Source | Used for | Licence |
|---|---|---|
| [Marine Regions](https://www.marineregions.org/): *The intersect of the Exclusive Economic Zones and IHO sea areas*, **version 5** (Flanders Marine Institute, released 9 October 2024), [doi:10.14284/699](https://doi.org/10.14284/699). Downloaded on 16 October 2026 from the public, anonymous WFS `https://geo.vliz.be/geoserver/MarineRegions/wfs`, layer `MarineRegions:eez_iho` (title "The intersect of the Exclusive Economic Zones and IHO areas (v5)"), as GeoJSON in 6 pages: 572 features, 101 IHO seas | The 101 IHO seas: their identity, their names and the limits between them | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (stated on the dataset's IMIS record at the DOI) |
| [Natural Earth](https://www.naturalearthdata.com/) 1:10m physical, `ne_10m_ocean` **version 5.1.1**, from the official CDN `https://naciscdn.org/naturalearth/10m/physical/` | The water mask and every coastline; the Caspian Sea (Natural Earth's ocean includes it) | Public domain ([terms](https://www.naturalearthdata.com/about/terms-of-use/)) |
| Natural Earth 1:10m `ne_10m_lakes` **version 5.0.0**, same CDN | The Dead Sea (its two features named "Dead Sea", `ne_id` 1159126747 and 1159126865: the northern basin and the southern evaporation ponds) | Public domain |

Not used:
- Marine Regions' standalone *IHO Sea Areas* v3 layer (`MarineRegions:iho`), which is CC BY-NC-SA 4.0. The intersect's IMIS record lists IHO Sea Areas v3 and the Maritime Boundaries Geodatabase v12 as its source datasets. The intersect itself is published under CC BY 4.0, and only the intersect was downloaded.
- World EEZ v12 (not needed).
- Anything from OpenStreetMap.

No form was filled in, and no personal details were given to download anything.

Every dataset was modified: dissolved, clipped, merged, reassigned and simplified as described below.

### Attribution

Marine Regions' required citation, to go in Acknowledgements and `MapCredits.json` (with a link to the licence and a note that the data was modified):

> Flanders Marine Institute (2024). The intersect of the Exclusive Economic Zones and IHO sea areas, version 5. Available online at https://www.marineregions.org/. https://doi.org/10.14284/699

Marine Regions also asks users not to re-host its downloads (the app ships only the derived, simplified outlines) and to tell info@marineregions.org when the data is used in a product. That email has not been sent; the user should decide.

Natural Earth needs no attribution. Crediting "Made with Natural Earth" is customary and already covered by the app's existing credit.

## Regions

The `iho_name` column is the exact `iho_sea` value in the source. MRGID is the IHO sea's Marine Regions id (`iho_mrgid`). Area is the water area on Equal Earth before simplification and before small islands are filled. Ocean is the grouping written to `seas_manifest.json`.

| Id | Display name | IHO name (source) | MRGID | Ocean | Area (km²) |
|---|---|---|---|---|---|
| `SEAS-south-pacific-ocean` | South Pacific Ocean | South Pacific Ocean | 1910 | pacific | 76,191,046 |
| `SEAS-north-pacific-ocean` | North Pacific Ocean | North Pacific Ocean | 1908 | pacific | 64,605,912 |
| `SEAS-indian-ocean` | Indian Ocean | Indian Ocean | 1904 | indian | 57,904,788 |
| `SEAS-south-atlantic-ocean` | South Atlantic Ocean | South Atlantic Ocean | 1914 | atlantic | 40,286,716 |
| `SEAS-north-atlantic-ocean` | North Atlantic Ocean | North Atlantic Ocean | 1912 | atlantic | 34,293,738 |
| `SEAS-southern-ocean` | Southern Ocean | Southern Ocean | 1907 | southern | 22,057,613 |
| `SEAS-philippine-sea` | Philippine Sea | Philippine Sea | 4300 | pacific | 5,583,422 |
| `SEAS-arctic-ocean` | Arctic Ocean | Arctic Ocean | 1906 | arctic | 5,188,307 |
| `SEAS-arabian-sea` | Arabian Sea | Arabian Sea | 4268 | indian | 4,191,383 |
| `SEAS-coral-sea` | Coral Sea | Coral Sea | 4364 | pacific | 4,083,841 |
| `SEAS-tasman-sea` | Tasman Sea | Tasman Sea | 4365 | pacific | 3,338,171 |
| `SEAS-south-china-sea` | South China Sea | South China Sea | 4332 | pacific | 3,325,553 |
| `SEAS-caribbean-sea` | Caribbean Sea | Caribbean Sea | 4287 | atlantic | 2,816,834 |
| `SEAS-bering-sea` | Bering Sea | Bering Sea | 4310 | pacific | 2,352,131 |
| `SEAS-bay-of-bengal` | Bay of Bengal | Bay of Bengal | 4273 | indian | 2,181,204 |
| `SEAS-sea-of-okhotsk` | Sea of Okhotsk | Sea of Okhotsk | 4309 | pacific | 1,613,728 |
| `SEAS-gulf-of-mexico` | Gulf of Mexico | Gulf of Mexico | 4288 | atlantic | 1,546,612 |
| `SEAS-norwegian-sea` | Norwegian Sea | Norwegian Sea | 2353 | atlantic | 1,455,912 |
| `SEAS-barents-sea` | Barents Sea | Barentsz Sea | 4247 | arctic | 1,419,747 |
| `SEAS-mozambique-channel` | Mozambique Channel | Mozambique Channel | 4261 | indian | 1,380,048 |
| `SEAS-great-australian-bight` | Great Australian Bight | Great Australian Bight | 4276 | indian | 1,320,877 |
| `SEAS-greenland-sea` | Greenland Sea | Greenland Sea | 2356 | arctic | 1,200,282 |
| `SEAS-mediterranean-eastern-basin` | Eastern Mediterranean | Mediterranean Sea - Eastern Basin | 4280 | mediterranean | 1,167,824 |
| `SEAS-northwestern-passages` | Northwestern Passages | The Northwestern Passages | 5698 | arctic | 1,075,333 |
| `SEAS-japan-sea` | Sea of Japan | Japan Sea | 4307 | pacific | 1,062,766 |
| `SEAS-arafura-sea` | Arafura Sea | Arafura Sea | 4347 | pacific | 1,012,326 |
| `SEAS-kara-sea` | Kara Sea | Kara Sea | 4246 | arctic | 894,387 |
| `SEAS-labrador-sea` | Labrador Sea | Labrador Sea | 4291 | atlantic | 873,490 |
| `SEAS-hudson-bay` | Hudson Bay | Hudson Bay | 4252 | arctic | 840,162 |
| `SEAS-laccadive-sea` | Laccadive Sea | Laccadive Sea | 4269 | indian | 835,352 |
| `SEAS-east-china-sea` | East China Sea | Eastern China Sea | 4302 | pacific | 757,505 |
| `SEAS-davis-strait` | Davis Strait | Davis Strait | 4250 | atlantic | 766,271 |
| `SEAS-gulf-of-guinea` | Gulf of Guinea | Gulf of Guinea | 4286 | atlantic | 742,666 |
| `SEAS-solomon-sea` | Solomon Sea | Solomon Sea | 4361 | pacific | 735,516 |
| `SEAS-banda-sea` | Banda Sea | Banda Sea | 4349 | pacific | 686,575 |
| `SEAS-east-siberian-sea` | East Siberian Sea | East Siberian Sea | 4244 | arctic | 636,198 |
| `SEAS-andaman-sea` | Andaman Sea | Andaman or Burma Sea | 4274 | indian | 607,198 |
| `SEAS-java-sea` | Java Sea | Java Sea | 4338 | pacific | 559,963 |
| `SEAS-baffin-bay` | Baffin Bay | Baffin Bay | 4253 | arctic | 538,788 |
| `SEAS-north-sea` | North Sea | North Sea | 2350 | atlantic | 526,950 |
| `SEAS-laptev-sea` | Laptev Sea | Laptev Sea | 4245 | arctic | 511,348 |
| `SEAS-mediterranean-western-basin` | Western Mediterranean | Mediterranean Sea - Western Basin | 4279 | mediterranean | 474,799 |
| `SEAS-celebes-sea` | Celebes Sea | Celebes Sea | 4359 | pacific | 451,769 |
| `SEAS-red-sea` | Red Sea | Red Sea | 4264 | indian | 445,549 |
| `SEAS-beaufort-sea` | Beaufort Sea | Beaufort Sea | 4256 | arctic | 433,323 |
| `SEAS-timor-sea` | Timor Sea | Timor Sea | 4344 | indian | 428,042 |
| `SEAS-gulf-of-alaska` | Gulf of Alaska | Gulf of Alaska | 4312 | pacific | 420,929 |
| `SEAS-black-sea` | Black Sea | Black Sea | 3319 | mediterranean | 421,549 |
| `SEAS-yellow-sea` | Yellow Sea | Yellow Sea | 4303 | pacific | 408,017 |
| `SEAS-caspian-sea` | Caspian Sea | — (Natural Earth) | — | inland | 397,056 |
| `SEAS-chukchi-sea` | Chukchi Sea | Chukchi Sea | 4257 | arctic | 348,426 |
| `SEAS-bismarck-sea` | Bismarck Sea | Bismarck Sea | 4360 | pacific | 340,948 |
| `SEAS-sulu-sea` | Sulu Sea | Sulu Sea | 4358 | pacific | 333,229 |
| `SEAS-gulf-of-thailand` | Gulf of Thailand | Gulf of Thailand | 4334 | pacific | 294,378 |
| `SEAS-gulf-of-st-lawrence` | Gulf of St. Lawrence | Gulf of St. Lawrence | 4290 | atlantic | 292,345 |
| `SEAS-gulf-of-aden` | Gulf of Aden | Gulf of Aden | 4265 | indian | 259,321 |
| `SEAS-persian-gulf` | Persian Gulf | Persian Gulf | 4266 | indian | 244,574 |
| `SEAS-molucca-sea` | Molucca Sea | Molukka Sea | 4354 | pacific | 218,271 |
| `SEAS-baltic-sea` | Baltic Sea | Baltic Sea | 2401 | atlantic | 217,029 |
| `SEAS-tyrrhenian-sea` | Tyrrhenian Sea | Tyrrhenian Sea | 3386 | mediterranean | 216,960 |
| `SEAS-celtic-sea` | Celtic Sea | Celtic Sea | 2351 | atlantic | 215,834 |
| `SEAS-hudson-strait` | Hudson Strait | Hudson Strait | 4251 | arctic | 202,620 |
| `SEAS-makassar-strait` | Makassar Strait | Makassar Strait | 4339 | pacific | 195,221 |
| `SEAS-strait-of-malacca` | Strait of Malacca | Malacca Strait | 4275 | indian | 193,308 |
| `SEAS-aegean-sea` | Aegean Sea | Aegean Sea | 3315 | mediterranean | 191,063 |
| `SEAS-gulf-of-california` | Gulf of California | Gulf of California | 4314 | pacific | 179,097 |
| `SEAS-bay-of-biscay` | Bay of Biscay | Bay of Biscay | 2359 | atlantic | 174,676 |
| `SEAS-ionian-sea` | Ionian Sea | Ionian Sea | 3351 | mediterranean | 171,562 |
| `SEAS-seram-sea` | Seram Sea | Ceram Sea | 4351 | pacific | 159,499 |
| `SEAS-adriatic-sea` | Adriatic Sea | Adriatic Sea | 3314 | mediterranean | 139,664 |
| `SEAS-coastal-waters-of-southeast-alaska-and-british-columbia` | Coastal Waters of Southeast Alaska and British Columbia | The Coastal Waters of Southeast Alaska and British Columbia | 4313 | pacific | 131,073 |
| `SEAS-gulf-of-bothnia` | Gulf of Bothnia | Gulf of Bothnia | 2402 | atlantic | 117,354 |
| `SEAS-bass-strait` | Bass Strait | Bass Strait | 4366 | indian | 111,489 |
| `SEAS-gulf-of-oman` | Gulf of Oman | Gulf of Oman | 4267 | indian | 110,231 |
| `SEAS-savu-sea` | Savu Sea | Savu Sea | 4343 | pacific | 104,901 |
| `SEAS-flores-sea` | Flores Sea | Flores Sea | 4341 | pacific | 101,359 |
| `SEAS-white-sea` | White Sea | White Sea | 4248 | arctic | 89,834 |
| `SEAS-english-channel` | English Channel | English Channel | 2389 | atlantic | 81,721 |
| `SEAS-balearic-sea` | Balearic Sea | Balearic (Iberian Sea) | 3322 | mediterranean | 79,742 |
| `SEAS-halmahera-sea` | Halmahera Sea | Halmahera Sea | 4353 | pacific | 74,457 |
| `SEAS-gulf-of-tomini` | Gulf of Tomini | Gulf of Tomini | 4355 | pacific | 55,472 |
| `SEAS-alboran-sea` | Alboran Sea | Alboran Sea | 3324 | mediterranean | 54,152 |
| `SEAS-irish-sea` | Irish Sea | Irish Sea and St. George's Channel | 2357 | atlantic | 46,209 |
| `SEAS-inner-seas-off-the-west-coast-of-scotland` | Inner Seas off the West Coast of Scotland | Inner Seas off the West Coast of Scotland | 4283 | atlantic | 45,373 |
| `SEAS-bali-sea` | Bali Sea | Bali Sea | 4340 | pacific | 39,235 |
| `SEAS-sea-of-azov` | Sea of Azov | Sea of Azov | 3320 | mediterranean | 38,563 |
| `SEAS-kattegat` | Kattegat | Kattegat | 2374 | atlantic | 36,004 |
| `SEAS-lincoln-sea` | Lincoln Sea | Lincoln Sea | 4254 | arctic | 36,487 |
| `SEAS-gulf-of-bone` | Gulf of Bone | Gulf of Boni | 4350 | pacific | 33,075 |
| `SEAS-skagerrak` | Skagerrak | Skagerrak | 2379 | atlantic | 32,906 |
| `SEAS-rio-de-la-plata` | Río de la Plata | Rio de La Plata | 4325 | atlantic | 31,582 |
| `SEAS-gulf-of-finland` | Gulf of Finland | Gulf of Finland | 2407 | atlantic | 30,016 |
| `SEAS-gulf-of-riga` | Gulf of Riga | Gulf of Riga | 2409 | atlantic | 18,585 |
| `SEAS-seto-inland-sea` | Seto Inland Sea | Seto Naikai or Inland Sea | 4306 | pacific | 18,067 |
| `SEAS-ligurian-sea` | Ligurian Sea | Ligurian Sea | 3363 | mediterranean | 17,006 |
| `SEAS-bay-of-fundy` | Bay of Fundy | Bay of Fundy | 4289 | atlantic | 16,044 |
| `SEAS-sea-of-marmara` | Sea of Marmara | Sea of Marmara | 3369 | mediterranean | 11,822 |
| `SEAS-gulf-of-suez` | Gulf of Suez | Gulf of Suez | 4262 | indian | 10,443 |
| `SEAS-bristol-channel` | Bristol Channel | Bristol Channel | 3141 | atlantic | 5,801 |
| `SEAS-gulf-of-aqaba` | Gulf of Aqaba | Gulf of Aqaba | 4263 | indian | 3,548 |
| `SEAS-singapore-strait` | Singapore Strait | Singapore Strait | 4336 | pacific | 2,907 |
| `SEAS-strait-of-gibraltar` | Strait of Gibraltar | Strait of Gibraltar | 3346 | mediterranean | 1,636 |
| `SEAS-dead-sea` | Dead Sea | — (Natural Earth) | — | inland | 853 |

### Name cleaning

Display names follow the IHO identity but use current English spellings. All names are proper nouns, so they keep their capitals, as the app's sentence-case rule allows. Changed names:

| IHO name (source) | Display name | Id |
|---|---|---|
| Barentsz Sea | Barents Sea | `SEAS-barents-sea` |
| Japan Sea | Sea of Japan | `SEAS-japan-sea` |
| Eastern China Sea | East China Sea | `SEAS-east-china-sea` |
| Molukka Sea | Molucca Sea | `SEAS-molucca-sea` |
| Ceram Sea | Seram Sea | `SEAS-seram-sea` |
| Gulf of Boni | Gulf of Bone | `SEAS-gulf-of-bone` |
| Andaman or Burma Sea | Andaman Sea | `SEAS-andaman-sea` |
| Malacca Strait | Strait of Malacca | `SEAS-strait-of-malacca` |
| Seto Naikai or Inland Sea | Seto Inland Sea | `SEAS-seto-inland-sea` |
| Balearic (Iberian Sea) | Balearic Sea | `SEAS-balearic-sea` |
| Mediterranean Sea - Western Basin | Western Mediterranean | `SEAS-mediterranean-western-basin` |
| Mediterranean Sea - Eastern Basin | Eastern Mediterranean | `SEAS-mediterranean-eastern-basin` |
| Irish Sea and St. George's Channel | Irish Sea | `SEAS-irish-sea` |
| Rio de La Plata | Río de la Plata | `SEAS-rio-de-la-plata` |
| The Northwestern Passages | Northwestern Passages | `SEAS-northwestern-passages` |
| The Coastal Waters of Southeast Alaska and British Columbia | Coastal Waters of Southeast Alaska and British Columbia | `SEAS-coastal-waters-of-southeast-alaska-and-british-columbia` |

The source already spells "Chukchi Sea" this way. Every other name is unchanged.

The Japan Sea and the two Mediterranean basins keep their IHO word order in the id (`SEAS-japan-sea`, `SEAS-mediterranean-western-basin`), as requested. Every other id is the slug of the display name.

The two longest names, "Coastal Waters of Southeast Alaska and British Columbia" and "Inner Seas off the West Coast of Scotland", are the IHO names. They may need a shorter display name in the UI. Their ids should stay as they are.

Disputed and contested names are kept as IHO publishes them: Sea of Japan (East Sea), Persian Gulf (Arabian Gulf), South China Sea, and Gulf of Mexico (renamed "Gulf of America" by the US in 2025). If the app wants to show alternative names, it can change the display names; the ids stay.

### Ocean groups

`ocean` is a judgment call for grouping in the UI, not an IHO attribute:
- **arctic:** Arctic Ocean, Lincoln, Greenland, Barents, White, Kara, Laptev, East Siberian, Chukchi and Beaufort Seas, Northwestern Passages, Baffin Bay, Hudson Bay and Hudson Strait.
- **atlantic:** North and South Atlantic, Norwegian Sea, North Sea, Baltic Sea and its gulfs (Bothnia, Finland, Riga), Kattegat, Skagerrak, English and Bristol Channels, Irish Sea, Inner Seas off the West Coast of Scotland, Celtic Sea, Bay of Biscay, Labrador Sea, Davis Strait, Gulf of St. Lawrence, Bay of Fundy, Gulf of Mexico, Caribbean Sea, Gulf of Guinea and Río de la Plata.
- **mediterranean:** both Mediterranean basins, Strait of Gibraltar, Alboran, Balearic, Ligurian, Tyrrhenian, Ionian, Adriatic and Aegean Seas, Sea of Marmara, Black Sea and Sea of Azov.
- **indian:** Indian Ocean, Arabian, Laccadive, Andaman and Red Seas, Bay of Bengal, Mozambique Channel, Gulfs of Aden, Suez, Aqaba and Oman, Persian Gulf, Strait of Malacca, Timor Sea, Great Australian Bight and Bass Strait.
- **pacific:** North and South Pacific and every other sea of the western Pacific and the Indonesian archipelago (including the Arafura, Java, Savu, Flores and Bali Seas and the Singapore Strait), plus Tasman and Coral Seas.
- **southern:** the Southern Ocean.
- **inland:** the Caspian Sea and the Dead Sea.

## Southern Ocean

The source has it. Marine Regions' IHO data includes "Southern Ocean" (MRGID 1907), bounded by 60°S, so no region had to be carved out of the South Atlantic, South Pacific and Indian Oceans. It is `SEAS-southern-ocean`, 22.06 million km² including the ice shelves. Its only coast in `geo_WORLD.json` is `WORLD-AQ`.

## Processing

Scripts are in `/tmp/jpex-72-seas/scripts` (outside the repository); `run_all.sh` runs them in order. Python 3.14 runs in its own venv (shapely 2.2 / GEOS 3.14, pyproj, numpy, matplotlib), always with `-I`. Downloads were kept in their own directory, `/tmp/jpex-72-seas/downloads`.

1. **Dissolve** (`s1_dissolve.py`). The 572 features of the intersect were unioned by `iho_mrgid` into 101 seas. All coordinates were already within ±180°. Invalid features were repaired with `make_valid` first.
2. **Clean coverage** (`s1b_clean.py`).
   - The 101 seas were made an exact polygon coverage with GEOS's coverage cleaner (snapping 1e-7°). The only mismatch was between Río de la Plata and the South Atlantic.
   - The coverage was then thinned with topology-preserving Visvalingam–Whyatt (`coverage_simplify`, tolerance 0.004°, i.e. triangles below about 0.2 km² at the equator), from 9.31 to 2.15 million vertices.
   - This only thins Marine Regions' very detailed coastline, which Natural Earth's replaces anyway, and the inter-sea limits. Those limits are mostly straight lines and stay within tens of metres.
3. **Water mask** (`s3_partition.py`). Natural Earth's ocean was clipped to the frame, and coordinates within 1e-7° of ±180°/±90° were snapped onto it. It has two parts: the world ocean and the Caspian Sea.
4. **Fill small islands.** Island holes smaller than **150 km²** (Equal Earth area) were filled:
   - 5,677 of the world ocean's 6,809 holes, leaving 1,132;
   - 4 small island pieces cut by the antimeridian (6–140 km²);
   - all 16 of the Caspian's holes.

   Islands of at least 150 km² stay as holes.
5. **Clip.** Each IHO sea was intersected with the filled world ocean.
   - Water that Marine Regions has but Natural Earth calls land was dropped: 615,930 km². Examples: grounded Antarctic ice, Lake Ladoga (27,646 km², inside Marine Regions' Gulf of Finland), Nettilling Lake on Baffin Island (in the Northwestern Passages) and the Siberian river deltas.
6. **Leftover water.** Natural Earth water that no IHO sea covered (907,075 km² in 257,352 pieces) was given to the nearest sea.
   - Each piece's outline was sampled (every 0.01°), and each sample took the sea of the nearest Marine Regions coast segment (segments shared by two seas excluded).
   - Pieces whose samples all named one sea went to it. The 652 pieces that named several seas were split along a Voronoi diagram of their labelled samples.
   - The 55 pieces over 1,000 km² are almost all Antarctic ice-shelf areas, which went to the Southern Ocean. The rest are coastal slivers where Natural Earth's coastline lies landward of Marine Regions', plus lagoons and deltas, for example Lake Manzala (1,114 km², Eastern Mediterranean) and Chilika Lake (869 km², Bay of Bengal).
   - **No internal waters were missing.** The Seto Inland Sea, White Sea, Gulf of St. Lawrence, Río de la Plata and Bay of Fundy are complete in the source. Their final areas are within 2% of Marine Regions' own figures (the White Sea is 1.7% smaller, the others within 0.5%).
7. **Inland seas.** The Caspian Sea (Natural Earth ocean part, 397,056 km²) and the Dead Sea (the two `ne_10m_lakes` features, 853 km²) were added as their own regions.
   - Natural Earth's 10m lakes do not contain the Caspian; its ocean layer does.
   - In `geo_WORLD.json` the Dead Sea lies inside the land of JO, IL and PS. It is drawn over them.
8. **Detached parts.** After the coverage was cleaned again (snapping 1e-9°), each part of a sea other than its largest that was smaller than **25 km²** was merged into the neighbouring sea with the longest shared border. 53 parts were merged; the largest were 17.5 km² of Arctic Ocean near Svalbard (into the Barents Sea) and 17.3 km² of Skagerrak (into the North Sea). No sea lost all its parts. Seas that still have several parts include the Kattegat, Andaman Sea, Bismarck Sea and the antimeridian seas.
9. **Simplification** (`s4_simplify.py`, mapshaper 0.7.87).
   - Edges longer than 0.25° were subdivided in a canonical direction, so both neighbours got identical vertices. Everything was then projected to Equal Earth (EPSG:8857).
   - A land layer (the frame minus all seas, 1,155 polygons) was added, so that coastlines are arcs shared with land and every coast/antimeridian corner is a node that cannot be simplified away.
   - The layer was simplified with `-simplify weighted keep-shapes interval=4000` (4 km). Shared borders between seas are stored once and stay identical. mapshaper repaired 39 intersections.
   - Trial intervals of 3 and 4.5 km gave about 864 and 617 KB.
10. **Output** (`s5_output.py`).
    - Retained vertices were mapped back to their exact original lon/lat with a lookup table (0 misses).
    - Rings with fewer than 6 vertices that touch no other sea (small islands, and the Dead Sea basins) were rebuilt from their original vertices with Visvalingam–Whyatt down to 6 vertices, so they are not triangles. 478 rings were rebuilt; 6 were left as they were, because the rebuilt ring would have touched another ring.
    - Edges were subdivided to at most 0.49°, coordinates rounded to 3 decimals, and duplicate points and A–B–A spikes removed. No ring collapsed.
    - Finally the label points were computed and the regions sorted by area.

## Validation

`s7_validate.py` re-parses the file. Results:
- **Structure.** Top-level keys and their order, header values, region keys and id pattern: correct.
- **Ids.** 103 regions, all unique.
- **Grammar.** At most 3 decimals, no exponents, no `-0` and no trailing zeros. Rings are closed by `Z` without repeating the first point and have at least 3 distinct points. A port of the app's `TravelMap.rings(fromSVG:)` reads every path exactly as the validator does.
- **Coordinates and edges.** All within range. The longest edge is 0.4906°. No edge jumps across ±180°.
- **Labels.** Every `c` is inside its region under even-odd.
- **Order.** Regions are sorted by Equal Earth area.
- **Overlaps.** None: 0 km² between all pairs of regions.
- **Gaps.** Apart from islands, the union of all seas has a single hole smaller than 20 km²: 16.6 km² at Key Largo. That is real land, which Natural Earth joins to the mainland by a hairline and simplification separated.
- **Ring touches.** Two are harmless under even-odd: in `SEAS-coastal-waters-of-southeast-alaska-and-british-columbia` one ring touches itself at a single vertex near Sitka, and in `SEAS-arafura-sea` two rings meet at points. There are no proper crossings.
- **Antimeridian.** The two sides agree to within 0.005°. The exceptions are two Fijian islands (Vanua Levu's eastern tip and Taveuni), whose piece on one side was under 150 km² and was filled.

Previews (plate carrée with `geo_WORLD.json` outlines; north and south polar views; the Pacific seam; Europe; South-East Asia; and a sheet of close-ups of the Tyrrhenian, Gibraltar, Marmara, Singapore, Suez/Aqaba/Dead Sea, Seto Inland Sea, Río de la Plata, Fundy, the Danish straits, Bristol/Irish Sea, Gulf of Finland and Caspian) were rendered to `/tmp/jpex-72-seas/preview*.png` and inspected.

## Coasts table

`s6_coasts.py` works out, for every region of `geo_WORLD.json` (255 regions, including GB-ENG, FR-971, US-PR, CN-HK, AU-CX and the like), which seas its coast touches.

It uses the unsimplified seas from step 8, without the island filling of step 4.

**Method.**
1. **Cells.** The world was cut into 10° × 10° cells between 80°S and 80°N, plus two polar caps. The cell edges are offset slightly from round degrees, so borders along round parallels are not split ambiguously.
2. **Projection.** In each cell the region outlines and the nearby seas were projected to an azimuthal equidistant projection centred on the cell (on the pole for the caps). Seas within reach were included, with copies shifted by 360° across the antimeridian. Everything was densified to 0.05° first.
3. **Coast only.** Outline segments on the ±180° cut or on a pole were dropped.
   - Land borders were dropped too: segments shared with a neighbouring region (15,363 segments).
   - Regions that overlap each other are not neighbours: WORLD-GB and its four nations, and Italy with San Marino and the Vatican. Their shared segments were kept.
   - Land borders that lie inside a sea were kept as coast: the 12 border segments through the Dead Sea.
4. **`km`.** The coast length within **12 km** of each sea (seas buffered by 12 km). This is the measure asked for. Coast near the point where two seas meet counts for both.
5. **`nearest_km`.** The coast was cut into pieces of at most 500 m, and each piece was given only to the nearest sea within 12 km. This removes junction false positives. For example, Marine Regions' Ligurian Sea limit reaches the coast at the French–Italian border (7.54°E, 43.784°N), so France gets 7.6 km of Ligurian `km` but 0 `nearest_km`.

**Threshold** (`coasts_final.json`). A sea is kept if its `nearest_km` is at least **5 km**, or at least **15%** of the region's total coast length within 12 km of any sea. The region's top sea is always kept if it has at least 1 km.
- The suggested 20 km floor was lowered to 5 km because the nearest-sea split already removes junction effects. Remaining noise is at most 1.5 km (Sri Lanka/Indian Ocean 0.5, Indonesia/North Pacific 1.0, São Tomé/North Atlantic 1.5).
- A 20 km floor would have dropped real short coasts:
  - Eilat (Israel, Gulf of Aqaba, 11 km);
  - Kelantan (Malaysia, Gulf of Thailand, 20 km), from the IHO line to Kota Bharu;
  - east of Cape Palmas (Liberia, Gulf of Guinea, 18 km);
  - south of Butrint (Albania, Ionian Sea, 6 km);
  - north of Cabo Delgado (Mozambique, Indian Ocean, 10 km);
  - Jeju (South Korea, East China Sea, 10 km).
- Lists are ordered by `nearest_km`, longest first.

**Outputs** (outside the repository):
- `/tmp/jpex-72-seas/coasts.json`: every sea within 12 km, with `km` and `nearest_km`.
- `/tmp/jpex-72-seas/coasts_final.json`: the thresholded lists.
- `/tmp/jpex-72-seas/coast_totals.json`: each region's total coast.
- `/tmp/jpex-72-seas/seas_manifest.json`: per sea, in file order: `id`, `name`, `iho_name` (null for the two Natural Earth seas), `mrgid` (null for them too), `area_km2`, `ocean`, `c` and `countries`. `countries` holds the World regions whose thresholded list contains the sea, longest coast first.

213 regions have a coast and 42 are landlocked. The landlocked ones are the 41 landlocked countries that do not border the Caspian, plus Kosovo.

Checked by eye:
- WORLD-FR: English Channel, Western Mediterranean, Bay of Biscay, Tyrrhenian Sea (Corsica's east coast), Celtic Sea, North Sea.
- WORLD-IT: Tyrrhenian, Adriatic, Ionian, Western Mediterranean (Sardinia's west coast), Eastern Mediterranean, Ligurian.
- WORLD-JP: Sea of Japan, Philippine Sea, North Pacific, East China Sea, Seto Inland Sea, Sea of Okhotsk.
- WORLD-EG: Eastern Mediterranean, Red Sea, Gulf of Suez, Gulf of Aqaba.
- WORLD-TR: Black Sea, Aegean, Eastern Mediterranean, Sea of Marmara.
- WORLD-RU: 16 seas, from the Kara Sea to the Baltic, including the Caspian, Sea of Azov, Black Sea and Arctic Ocean.
- WORLD-US: Bering, SE Alaska/BC coastal waters, North Atlantic, Gulf of Alaska, Gulf of Mexico, North Pacific, Chukchi, Beaufort, Bay of Fundy.
- WORLD-AU: Indian Ocean, Great Australian Bight, Coral, Arafura, Timor, Bass Strait, Tasman, South Pacific (Macquarie Island).
- WORLD-KZ: Caspian Sea.
- WORLD-JO: Dead Sea, Gulf of Aqaba.
- WORLD-AT: none.
- WORLD-SG: Singapore Strait.
- WORLD-MC: Western Mediterranean only (see the Ligurian note above).
- WORLD-PA: North Pacific, Caribbean.
- WORLD-CL: South Pacific, South Atlantic.
- WORLD-GB: Inner Seas off the West Coast of Scotland, North Sea, Irish Sea, English Channel, Bristol Channel, North Atlantic, Celtic Sea.
- GB-ENG: the same without the Inner Seas and the North Atlantic.

IHO-correct but surprising:
- Germany gets the Kattegat: the IHO limit of the Baltic in the Little Belt runs from Falshöft, which puts Flensburg Fjord in the Kattegat.
- Greece gets the Adriatic: the north of Corfu.
- The Northern Mariana Islands get only the Philippine Sea: their 9 km of North Pacific coast falls under the thresholds.

## In the app

- `jpex/SeasCatalog.swift` lists the 103 seas from `seas_manifest.json`, under their ocean groups, by the cleaned names above. Each place's ID is the region's ID, so it must never change.
- `jpex/SeaCoasts.swift` holds `coasts_final.json` as one line per World region: the seas' IDs without `SEAS-`, longest coast first. An empty line means the region has no coast. A country's page shows its own seas, then any more from its places that are World regions of their own, such as Guadeloupe for France. A country whose only seas are the Caspian or the Dead Sea is called landlocked, and the inland sea is shown beside it.
- Seas known by more than one name (`seasWithOtherNames`) use the IHO's name unless the person picks another in Settings, Seas. The choices are:
  - Sea of Japan or East Sea;
  - Yellow Sea or West Sea;
  - South China Sea, West Philippine Sea or East Sea;
  - Persian Gulf or Arabian Gulf;
  - Gulf of Mexico or Gulf of America.
- The Atlas has a Coasts layer (`MapColouring.coasts`, `CoastKey`, `CoastsKey`). It colours each World place by the ocean of its longest coast, as the Seas list groups the seas, or as landlocked, and tints the seas themselves by ocean beneath the land. Learn's and the Atlas's cards say "Coasts" with the oceans, such as "Atlantic, Mediterranean". The Black Sea and the inland seas go by their own names there.
