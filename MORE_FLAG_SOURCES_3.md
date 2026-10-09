# Sixteen more collections (batch 3): flag sources

Retrieved 8 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

## Catalog scope

Every collection uses ISO 3166-2 codes as permanent IDs (`<country>-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_<cc>`) as the collection flag. Group IDs are `<country>-<slug>` and are display data only.

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| Iceland (`IS`) | 8 | The eight regions (landshlutar), in their official order IS-1 to IS-8. |
| Estonia (`EE`) | 15 | The fifteen counties (maakonnad); municipalities are not listed. |
| Lithuania (`LT`) | 10 | The ten counties (apskritys); municipalities are not listed. |
| Slovakia (`SK`) | 8 | The eight self-governing regions (kraje). |
| Romania (`RO`) | 42 | Forty-one counties and Bucharest (`RO-B`), grouped by historical region: Transylvania, Wallachia (Muntenia and Oltenia), Moldavia, Dobruja, Banat, Crișana, Maramureș and Bucharest. |
| Bulgaria (`BG`) | 28 | The 28 provinces (oblasti), including Sofia City (`BG-22`) and Sofia Province (`BG-23`). |
| Ukraine (`UA`) | 27 | Twenty-four oblasts; the cities with special status Kyiv (`UA-30`) and Sevastopol (`UA-40`); the Autonomous Republic of Crimea (`UA-43`). |
| Egypt (`EG`) | 27 | The 27 governorates. |
| Kenya (`KE`) | 47 | The 47 counties, grouped by the eight provinces abolished in 2013: Coast, North Eastern, Eastern, Central, Rift Valley, Western, Nyanza and Nairobi. ISO numbers the counties alphabetically, not in constitutional order. |
| Ecuador (`EC`) | 24 | Coast (7), Highlands (10), Amazon (6) and Galápagos. |
| Bolivia (`BO`) | 9 | The nine departments. |
| Uruguay (`UY`) | 19 | The nineteen departments. |
| Cuba (`CU`) | 16 | Fifteen provinces from west to east, in the order used by the national statistics office (ONEI), then the special municipality Isla de la Juventud (`CU-99`). |
| Nepal (`NP`) | 7 | The seven provinces with their current names, in official order (formerly Provinces 1–7): Koshi, Madhesh, Bagmati, Gandaki, Lumbini, Karnali, Sudurpashchim. |
| Mongolia (`MN`) | 22 | Twenty-one provinces (aimags) and the capital, Ulaanbaatar (`MN-1`). |
| Saudi Arabia (`SA`) | 13 | The thirteen regions. ISO 3166-2 has no `SA-13`; Asir is `SA-14`. |

Group assignments that are not clear-cut:

- **Romania.** Counties that span two historical regions are listed under the one usually given for them: Arad and Satu Mare under Crișana (southern Arad is in Banat, northern Satu Mare in Maramureș), Mehedinți under Wallachia (Orșova lies in Banat), Sălaj under Transylvania (much of it was in the Partium), Suceava under Moldavia (it is southern Bukovina) and Vrancea under Moldavia (its south was Wallachian).
- **Ecuador.** Santo Domingo de los Tsáchilas, split from Pichincha in 2007, is counted with the Coast, as in the Spanish Wikipedia's list of the region's seven provinces; some sources count it with the Highlands.

## Names

English names follow Wikidata's English labels and English Wikipedia, without type words that the group already gives ("Harju" for Harju County, "Alytus" for Alytus County, "Cherkasy" for Cherkasy Oblast). The type word is kept where it is part of the name or prevents confusion: Kyiv Oblast (beside the city of Kyiv), Sofia City and Sofia Province, Eastern Province (Saudi Arabia), and Iceland's descriptive region names (Capital Region, Southern Peninsula). Ukrainian names use Ukrainian romanisation (Kyiv, Kharkiv, Odesa, Zaporizhzhia, Zakarpattia). Kenyan names follow common usage (Elgeyo-Marakwet, Taita-Taveta, Trans-Nzoia, Murang'a, Nairobi). Saudi regions use English Wikipedia's forms (Mecca, Medina, Al-Qassim, Al-Baha, Al-Jouf, Hail).

Local names are stored only where they differ from the English name: Icelandic (Höfuðborgarsvæðið), Estonian short county names (Harjumaa), Lithuanian (Alytaus apskritis), Slovak (Banskobystrický kraj), Romanian for Bucharest (București), Bulgarian (Благоевград, София-град, Софийска област), Ukrainian full official names (Черкаська область, Київ, Автономна Республіка Крим), Arabic without the word for governorate or region (القاهرة, الرياض; المنطقة الشرقية keeps it), Spanish for Havana (La Habana), Nepali without प्रदेश (कोशी) and Mongolian Cyrillic without аймаг (Архангай). Romanian county, Kenyan, Ecuadorian, Bolivian, Uruguayan and other Cuban names are the same in English and locally.

## How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`). The flag (P41) was read from the preferred-rank statement, or else from a normal-rank statement without an end date; deprecated statements were ignored. Two items needed fixing: `UA-40` also matched the article on Sevastopol's divisions (the city item was used), and Gandaki Province (`NP-P4`) has no P300 statement.
2. The Wikidata choice was compared with the flag in the English and local-language Wikipedia infoboxes and with Wikimedia Commons categories of subdivision flags. Where they differed, current status was checked against Flags of the World (FOTW, including its summaries of Frank-René Putz, *Der Flaggenkurier* 51/2020, for Egypt), official documents and news reports.
3. Every flag was inspected on contact sheets, before and after conversion, for historical designs, wrong colours, missing parts and broken renders.

Each flag is Wikimedia Commons' PNG render of the linked SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette. The alpha channel is kept whenever a render is not fully opaque; apart from anti-aliased edges, only the Mongolian flags with tassels or cut flies (Selenge, Sükhbaatar, Övörkhangai) have transparent areas. Fifty-four of the chosen files are raster images (PNG, JPEG, GIF or WebP: 37 Kenyan, 10 Egyptian, 4 Uruguayan, 2 Romanian, 1 Mongolian); they were converted the same way from the original file or its 960-pixel thumbnail. Many Kenyan files are small (270–434 pixels wide) and were not enlarged. Artwork is unchanged.

Every file's author, source page and licence ship in `EstoniaFlagCredits.json`, `LithuaniaFlagCredits.json`, `SlovakiaFlagCredits.json`, `RomaniaFlagCredits.json`, `UkraineFlagCredits.json`, `EgyptFlagCredits.json`, `KenyaFlagCredits.json`, `EcuadorFlagCredits.json`, `BoliviaFlagCredits.json`, `UruguayFlagCredits.json` and `MongoliaFlagCredits.json`. Iceland, Bulgaria, Cuba, Nepal and Saudi Arabia use only their national flags, which are already credited in `WorldFlagCredits.json`.

## Notes by collection

- **Estonia, Lithuania, Slovakia, Bolivia.** Official flags as recorded on Wikidata. Beni shows the green flag with eight stars set by its 2007 autonomy statute (Wikidata's preferred statement), not the plain green variant.
- **Romania.** Under Law 141/2015 a county may fly its own flag only once the Government has approved the model by decision. Approvals found: Prahova (2019), Buzău (Government Decision 850/2019), Ilfov (197/2020), Covasna (989/2021, upheld by the High Court of Cassation and Justice in December 2022), Timiș (1129/2021), Mureș (October 2022) and Brașov (578/2026, published 19 August 2026). The other counties and Bucharest have no approved flag; flags they adopted by council decision before 2015, the gallery of county flags on Harghita County's old website, and the many county flags uploaded to Commons in 2026 from the Vexillology fan wiki and Vexilla Mundi are not official and are not shown. Of the seven approved flags, only three have faithful artwork on Commons: Covasna (matching the model annexed to the decision: blue–gold–blue with the arms), Ilfov and Mureș (white with the county arms, as the decisions describe; these two files come from the fan wiki but match the approved models). Buzău's approved flag carries the gold inscription “JUDEȚUL BUZĂU”, Prahova's “JUDEȚUL PRAHOVA” and Timiș's “ROMÂNIA” and “JUDEȚUL TIMIȘ” (checked against the Buzău and Timiș county statutes and a news report of the Prahova decision); the Commons files lack or alter these. Brașov's new blue flag has no artwork yet. These four show the national flag with a note.
- **Bulgaria.** Provinces are deconcentrated state administrations without symbols of their own; the flags in English Wikipedia's province infoboxes are those of the capital municipalities (FOTW lists only municipal flags under each province). Sofia City Province shares its territory with Sofia Capital Municipality, whose flag is not shown.
- **Ukraine.** Flags approved by the oblast councils (and by the Kyiv City Council in 1995 and the Sevastopol City Council in 2000), as recorded on Wikidata. Mykolaiv shows the flag adopted on 16 April 2026. Kharkiv uses Wikidata's preferred file drawn after the image annexed to the 1999 decision. Ivano-Frankivsk uses the file chosen by the Ukrainian Wikipedia, whose blue stripe matches the description (Wikidata's file has a teal stripe). Crimea shows the flag of the Autonomous Republic.
- **Egypt.** Most governorates changed their flags around 2010 and again in 2016, and Commons holds a mix of current and superseded renderings. Choices follow FOTW's 2021 survey: Alexandria (lighthouse flag, 2014), Aswan, Asyut, the Red Sea, Beni Suef, Qena, South Sinai and New Valley (2016 designs), Beheira (2010), Port Said (2011), Dakahlia (2016 dark green flag with the inscribed emblem, replacing Wikidata's 2006 image) and Gharbia (2016 design; the public-domain SVG replaces Wikidata's PNG of the same design). Seven governorates show the national flag (see below).
- **Kenya.** County flags adopted by the county governments since 2013. Twenty-seven counties have no flag on Wikidata; their files come from English Wikipedia and Commons, mostly FOTW drawings. Laikipia shows the striped flag introduced in 2017 (FOTW), not the earlier green flag on Wikidata; Nairobi shows the flag of Nairobi City County adopted in 2013 (green with a yellow triangle), not the old city flag; Mombasa's file follows the 2013 Flag and Emblems Bill. Where an SVG and a raster of the same design exist (Baringo, Busia, Nakuru, Turkana, Wajir), the SVG is used.
- **Ecuador.** The provincial flags as recorded on Wikidata, plus Esmeraldas and Pichincha, which have no flag statement. Guayas's provincial flag is the same as Guayaquil's; the file from the provincial-flag series is used.
- **Uruguay.** Montevideo and Tacuarembó have never adopted departmental flags (FOTW, November 2025; the flags on Commons are labelled unofficial or proposals) and show the national flag.
- **Mongolia.** Aimag flags as recorded on Wikidata, except Orkhon (new flag adopted in September 2024) and Bulgan (flag adopted in 2022). Bayankhongor's only available file is a small 2006 image.
- **Iceland, Saudi Arabia, Cuba, Nepal.** No official flags (see below). Nepal's provinces have adopted emblems but no flags. In Cuba, a blue swallow-tailed flag of the City of Havana has been seen in use, but no legal basis was found; it is not shown.

## National flag fallbacks

| Places | Note shown |
| --- | --- |
| Iceland: all 8 regions | "Iceland's regions have no official flags; the national flag is shown." |
| Saudi Arabia: all 13 regions | "Saudi Arabia's regions have no official flags; the national flag is shown." |
| Cuba: all 15 provinces and Isla de la Juventud | "Cuba's provinces have no official flags; the national flag is shown." |
| Bulgaria: all 28 provinces | "The national flag is shown; <Name> Province has no official flag." (Sofia Province: "… Sofia Province has no official flag.") |
| Nepal: all 7 provinces | "The national flag is shown; <Name> Province has no official flag." |
| Romania: 34 counties | "The national flag is shown; <Name> County has no official flag." |
| Romania: Bucharest | "The national flag is shown; Bucharest has no official flag." |
| Romania: Buzău, Prahova, Timiș | "The national flag is shown; no accurate artwork of <Name> County's official flag is available." |
| Romania: Brașov | "The national flag is shown; artwork for Brașov County's flag, approved in 2026, is not available yet." |
| Uruguay: Montevideo, Tacuarembó | "The national flag is shown; <Name> Department has no official flag." |
| Egypt: Faiyum, Qalyubia, Matrouh | "The national flag is shown; artwork for <Name>'s current governorate flag (2016) is not available." Commons has only the 2006 or 2011 designs. |
| Egypt: Sohag | "… artwork for Sohag's current governorate flag (2020) is not available." Commons has only the 2006 design. |
| Egypt: Luxor, North Sinai | "The national flag is shown; artwork for <Name>'s current governorate flag is not available." Commons has only Luxor's 2003 flag; North Sinai's 2016 flag was reported replaced in late 2025. |
| Egypt: Cairo | "The national flag is shown; no reliable artwork of Cairo Governorate's flag is available." The Commons files are a disputed older design and a recent reconstruction from the emblem. |

## Licences

Most files are public domain, usually as official symbols. The credits name the author and licence for every file; these licences require attribution:

| Licence | Files |
| --- | --- |
| CC BY-SA 4.0 | 17 (Egypt 7, Kenya 5, Uruguay 4, Ecuador 1) |
| CC BY-SA 3.0 | 15 (Egypt 6, Mongolia 4, Ecuador 2, Uruguay 2, Kenya 1) |
| CC BY-SA 2.5 | 7 (Slovakia) |
| CC BY 4.0 | 5 (Kenya) |

Eleven files are CC0. The remaining 147 are public domain; their credits are kept as a courtesy and to make provenance reviewable.

## Files

- Catalogs: `jpex/IcelandCatalog.swift`, `EstoniaCatalog.swift`, `LithuaniaCatalog.swift`, `SlovakiaCatalog.swift`, `RomaniaCatalog.swift`, `BulgariaCatalog.swift`, `UkraineCatalog.swift`, `EgyptCatalog.swift`, `KenyaCatalog.swift`, `EcuadorCatalog.swift`, `BoliviaCatalog.swift`, `UruguayCatalog.swift`, `CubaCatalog.swift`, `NepalCatalog.swift`, `MongoliaCatalog.swift` and `SaudiArabiaCatalog.swift`.
- Flags: 202 imagesets named `<cc>_flag_<code suffix>` (for example `ee_flag_37`, `ua_flag_30`, `ke_flag_01`, `ec_flag_sd`, `mn_flag_1`), each with `flag.png` and the standard `Contents.json`. The 120 fallback places use the existing `world_flag_is`, `world_flag_sa`, `world_flag_cu`, `world_flag_bg`, `world_flag_np`, `world_flag_ro`, `world_flag_uy` and `world_flag_eg` assets.
- Credits: the eleven `*FlagCredits.json` files listed above.
