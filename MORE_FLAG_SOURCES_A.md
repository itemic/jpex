# Twelve more collections (batch A): flag sources

Retrieved 8 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

## Catalog scope

Every collection uses ISO 3166-2 codes as permanent IDs (`<country>-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_<cc>`) as the collection flag. Group IDs are `<country>-<slug>` and are display data only.

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| Serbia (`RS`) | 25 | The City of Belgrade (`RS-00`) and the 24 administrative districts outside Kosovo (`RS-01` to `RS-24`), grouped by statistical region: Belgrade, Vojvodina (7), Šumadija and Western Serbia (8), Southern and Eastern Serbia (9). |
| Bosnia and Herzegovina (`BA`) | 12 | The ten cantons of the Federation of Bosnia and Herzegovina (`BA-01` to `BA-10`), Republika Srpska (`BA-SRP`) and Brčko District (`BA-BRC`), each entity or district in its own group. |
| Albania (`AL`) | 12 | The twelve counties (qarqe). |
| Montenegro (`ME`) | 25 | The 25 municipalities, including Gusinje and Petnjica (2014), Tuzi (2018) and Zeta (2022). |
| Latvia (`LV`) | 42 | The seven state cities (valstspilsētas) and 35 municipalities (novadi). |
| Luxembourg (`LU`) | 12 | The twelve cantons. |
| Malta (`MT`) | 68 | The 68 local councils, grouped by island: Malta (54) and Gozo (14, Comino being part of Għajnsielem). |
| Belarus (`BY`) | 7 | The six regions (voblasts) and the capital, Minsk (`BY-HM`). |
| Armenia (`AM`) | 11 | The ten provinces (marzer) and the capital, Yerevan (`AM-ER`). |
| Kazakhstan (`KZ`) | 20 | The 17 regions, including Abai (`KZ-10`), Jetisu (`KZ-33`) and Ulytau (`KZ-62`) created in 2022, and the cities of Astana (`KZ-71`), Almaty (`KZ-75`) and Shymkent (`KZ-79`). |
| Uzbekistan (`UZ`) | 14 | The twelve regions (viloyatlar), the Republic of Karakalpakstan (`UZ-QR`) and the capital, Tashkent (`UZ-TK`). |
| Kyrgyzstan (`KG`) | 9 | The seven regions (oblustar) and the cities of Bishkek (`KG-GB`) and Osh (`KG-GO`). |

Scope decisions and differences from the current ISO list:

- **Serbia.** ISO 3166-2:RS also lists five districts in Kosovo (`RS-25` to `RS-29`) under `RS-KM`. They are not included because the app lists Kosovo as a place of its own. The autonomous provinces (`RS-VO`, `RS-KM`) are not listed as places; Vojvodina appears as a group.
- **Bosnia and Herzegovina.** ISO deleted the canton codes `BA-01` to `BA-10` on 27 November 2015; the current list has only `BA-BIH` (the Federation), `BA-SRP` and `BA-BRC`. The cantons are kept, with their former ISO codes as IDs (the numbering is also the cantons' constitutional numbering), so the Federation appears as a group of ten places rather than as one place (`BA-BIH` is not used).
- **Latvia.** The current ISO list still has 43 entries, but Varakļāni Municipality (`LV-102`) was merged into Madona Municipality on 1 July 2025 and is not included, leaving 42. The other ISO entries match the municipalities formed in the 2021 reform. Wikidata has two items for most municipalities (2009–2021 and since 2021); the current items were used.
- **Kazakhstan.** IDs are the numeric codes introduced by ISO on 29 November 2022 (for example `KZ-75` for Almaty, formerly `KZ-ALA`), which also added the three new regions.
- **Montenegro.** The ISO list (25 entries, the last added in 2023 for Zeta) matches the current municipalities; no newer municipality was found.
- **Kyrgyzstan, Uzbekistan, Armenia, Belarus, Albania, Luxembourg, Malta.** Current ISO lists, unchanged.

## Names

English names follow English Wikipedia, without type words that the group or label already gives ("North Bačka" for North Bačka District, "Berat" for Berat County, "Brest" for Brest Region). The type word is kept where it is part of the name or prevents confusion: the Bosnian cantons (Una-Sana Canton, Canton 10), Minsk Region (beside the city of Minsk), Almaty Region, Tashkent Region, Osh Region, and Jelgava, Rēzekne and Ventspils Municipality (beside the state cities of the same names). Malta uses English Wikipedia's forms (Cospicua, Senglea, St. Julian's, St. Paul's Bay, Victoria for Rabat in Gozo, Żebbuġ (Gozo) beside Żebbuġ on Malta). Belarusian regions use the English Wikipedia forms (Gomel, Grodno, Mogilev, Vitebsk); Uzbek regions keep the Uzbek-based spellings English Wikipedia uses (Qashqadaryo, Samarqand, Surxondaryo, Xorazm).

Local names:

- **Serbia:** Serbian Cyrillic with the word for district (Севернобачки округ), as the district names are adjectives; Београд for Belgrade.
- **Bosnia and Herzegovina:** the cantons' official Bosnian names (Unsko-sanski kanton, Kanton Sarajevo, Bosansko-podrinjski kanton Goražde), Република Српска in Cyrillic, Brčko distrikt.
- **Albania:** the definite form with qarku (Qarku i Beratit).
- **Montenegro:** Montenegrin Cyrillic throughout (Андријевица, Херцег Нови, Зета), matching the collection's local name Црна Гора. The Latin forms are identical to the English names, so Cyrillic is the only form that adds information; one script is used consistently.
- **Latvia:** Rīga for Riga (the other state cities are spelled the same in English); the full municipality names in the genitive (Ādažu novads, Dienvidkurzemes novads).
- **Luxembourg:** Luxembourgish canton names as on the Luxembourgish Wikipedia (Clierf, Dikrech, Esch-Uelzecht, Gréiwemaacher, Lëtzebuerg, Miersch, Réiden, Réimech, Veianen, Wolz); Capellen is the same.
- **Malta:** Maltese names with the article where it is part of the official form (Ħ'Attard, Il-Furjana, Raħal Ġdid, Tas-Sliema, Il-Belt Valletta, Ir-Rabat for Victoria); names that are identical in Maltese and English have none.
- **Belarus:** Belarusian (Брэсцкая вобласць, Мінск). **Armenia:** Armenian without the word for province (Արագածոտն, Երևան). **Kazakhstan:** Kazakh with облысы (Алматы облысы beside Алматы). **Uzbekistan:** Uzbek Latin with viloyati (Fargʻona viloyati), Qoraqalpogʻiston Respublikasi, Toshkent. **Kyrgyzstan:** Kyrgyz with облусу (Ош облусу beside Ош).

## How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`). The flag (P41) was read from the preferred-rank statement, or else from a normal-rank statement without an end date; deprecated statements were ignored. Where a code matched several items, the current one was used (the post-2021 Latvian municipalities, the municipality rather than the town for Herceg Novi and Ulcinj).
2. The Wikidata choice was compared with the flags in the English and local-language Wikipedia infoboxes and with the Wikimedia Commons categories of subdivision flags. Status and design were checked against Flags of the World (FOTW), which has pages for every Bosnian canton, Albanian county, Montenegrin municipality and Maltese local council, and against official documents and news reports where FOTW was not conclusive.
3. Every flag was inspected on contact sheets, before and after conversion, side by side with the FOTW images for Albania, Montenegro, Malta and Kyrgyzstan.

Each flag is Wikimedia Commons' PNG render of the linked SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette. The alpha channel is kept whenever a render is not fully opaque (35 files, all only at anti-aliased edges). Fifteen of the chosen files are raster images (13 Montenegrin GIF, PNG and JPEG files, most of them FOTW drawings 432 pixels wide, and the Aizkraukle and Salaspils flags in Latvia); they were converted the same way from the original file, and small images were not enlarged. Where an SVG and a raster of the same design exist (Dobele, Gulbene, Krāslava, Līvāni, Ludza, Ogre, Olaine, Preiļi, Sigulda, Tukums, Valka), the SVG is used. Artwork is unchanged.

Every file's author, source page and licence ship in `SerbiaFlagCredits.json`, `BosniaFlagCredits.json`, `AlbaniaFlagCredits.json`, `MontenegroFlagCredits.json`, `LatviaFlagCredits.json`, `MaltaFlagCredits.json`, `BelarusFlagCredits.json`, `ArmeniaFlagCredits.json`, `KazakhstanFlagCredits.json`, `UzbekistanFlagCredits.json` and `KyrgyzstanFlagCredits.json`. Luxembourg uses only its national flag, which is already credited in `WorldFlagCredits.json`.

## Notes by collection

- **Serbia.** Belgrade shows the city flag, which is square by the city's regulations. The administrative districts are areas of the state administration with no symbols of their own, so they show the national flag. Vojvodina's provincial flag is not used, as the province is a group here, not a place.
- **Bosnia and Herzegovina.** Cantonal flags as prescribed by cantonal law (FOTW cites each law): Una-Sana (2000), Posavina (constitutional amendment of 2000), Tuzla (1999), Zenica-Doboj (2000), Bosnian Podrinje (2001), Central Bosnia (2003), Herzegovina-Neretva (2004), Sarajevo (1999). West Herzegovina's flag was struck from the cantonal constitution by the Federation's Constitutional Court in 1998, but the canton re-adopted the same design by law in 2003; it is shown with the long-standing Commons file of the identical flag of the Croatian Republic of Herzeg-Bosnia, as on Wikidata and English Wikipedia. Canton 10's flag (the same design) was ruled unconstitutional in 1998 and was never re-adopted; the canton still uses it de facto, but it is not official, so the national flag is shown. Republika Srpska shows its entity flag. Brčko District's statute provides that it has no flag other than the national flag. The Federation itself has had no flag since its symbols were annulled in 2007.
- **Albania.** County councils use flags with the county arms or emblem. FOTW documents eight of them from photographs or the county administration: Berat, Durrës, Elbasan, Gjirokastër, Korçë, Kukës, Tirana and Vlorë; they are shown with the 2021 SVGs drawn from the counties' arms, which match FOTW. For Dibër, Fier, Lezhë and Shkodër, the only source is a set of logo flags on the Vexilla Mundi website (copied to Commons in 2025 without an author); with no evidence of use they show the national flag. The Commons files named "Flag of Berat.svg", "Flag of Durrës.svg" and so on are the county flags, not the municipal ones.
- **Montenegro.** Municipal flags as prescribed by the municipal statutes or documented in use by FOTW, as recorded on Wikidata, plus Andrijevica, Budva, Cetinje (the traditional krstaš flag named in its statutes) and Podgorica (2006), which have no flag statement. Bar shows the current flag with gold stripes (2021), not the earlier yellow-striped one. Plav shows the flag described in its statutes; in practice a white flag with the arms is also used. Pljevlja shows the light blue flag documented with the municipality's 2021 decision on symbols (the 2007 statutes had a red-blue-white flag). Danilovgrad's file shows the white flag with the arms; the flag usually hoisted has an added blue border. Zeta, a municipality since 2022, set up a commission for its symbols in 2024; no flag artwork is available, so the national flag is shown.
- **Latvia.** State-city flags and the municipal flags as recorded on Wikidata and the Latvian Wikipedia for the municipalities formed in 2021. Several new municipalities kept the flag of the former municipality of the same name (Dobele, Gulbene, Krāslava, Ludza, Ogre, Olaine, Preiļi, Rēzekne, Saldus, Salaspils, Sigulda, Tukums, Valka); the others adopted new flags (for example Ādaži, Cēsis, Jēkabpils, Saulkrasti, Smiltene, Talsi, Augšdaugava, South Kurzeme, Valmiera), and those files are used rather than the 2010–2021 flags still on some old Wikidata items. Aizkraukle's flag is in de facto official use (no regulation describing it was found). Augšdaugava has two Commons drawings in 2:3 and 1:2; the 1:2 one, used by the Latvian and English Wikipedias, is shown. No artwork of a Kuldīga or Madona Municipality flag was found, so both show the national flag.
- **Luxembourg.** The cantons are administrative districts with no flags or councils. The "Flag of Wiltz Canton" on Commons is not an official flag.
- **Malta.** Local council flags as recorded on Wikidata, compared one by one with FOTW. Where a council has changed its flag, the current one is used: Attard, Birżebbuġa, Lija, Mellieħa, Mġarr, Nadur, Naxxar, Qrendi, Siġġiewi, Xgħajra and Żebbuġ (2000–2001), Mosta (2007) and Floriana (the lion alone, after the sword was removed from the council's arms in 2007, as reported by MaltaToday). Four councils show the national flag: Kalkara changed its flag in 2009 (a yellow and blue banner of arms with a green border) and the only Commons file of the new flag does not match it; Marsaxlokk's file shows a purple saltire instead of the blue of the arms (Argent, a saltire azure); Żabbar's file has a plain saltire instead of the engrailed saltire of the arms (Gules, a saltire engrailed argent); Paola's current flag exists only as a non-free image on English Wikipedia. The Commons redraws from 2025 of Bormla, Gżira and Żurrieq are not used; the long-standing files are kept (the new "Żurrieq" file is also mislabelled as Attard).
- **Belarus.** The regional flags and the flag of Minsk adopted in the 2000s, as recorded on Wikidata.
- **Armenia.** Yerevan has a flag. The provinces have emblems but no flags (FOTW, 2025), so they show the national flag.
- **Kazakhstan.** Astana shows the current flag with the name in Latin letters (2022, Wikidata's preferred statement) and Almaty its city flag. The regions' approved "regional symbols" are emblems used at events, not flags; the region flags on Commons and the English Wikipedia are recent own-work constructions from logos with no source, as is the Shymkent "flag" (2025, built from the city logo). Regions and Shymkent show the national flag.
- **Uzbekistan.** Karakalpakstan shows the flag of the republic (law of 1993). The regions have no flags, and the "Flag of Tashkent" on Commons (2022) is built from the city emblem after a description on a commercial website; it is not shown.
- **Kyrgyzstan.** Regional flags adopted by the regional councils: Talas (the newer flag shown on the region's website since about 2006), Chüy, Batken, Naryn and Issyk-Kul (2015 reports) and Jalal-Abad (December 2021); the cities show the flags of Bishkek and of Osh (2011). Every Wikipedia and Wikidata shows the city of Osh's flag for Osh Region as well; no flag of the region was found, so Osh Region shows the national flag.

## National flag fallbacks

| Places | Note shown |
| --- | --- |
| Luxembourg: all 12 cantons | "Luxembourg's cantons have no official flags; the national flag is shown." |
| Serbia: 24 districts | "The national flag is shown; <Name> District has no official flag." |
| Armenia: 10 provinces | "The national flag is shown; <Name> Province has no official flag." |
| Kazakhstan: 17 regions | "The national flag is shown; <Name> Region has no official flag." |
| Kazakhstan: Shymkent | "The national flag is shown; Shymkent has no official flag." |
| Uzbekistan: 12 regions | "The national flag is shown; <Name> Region has no official flag." (Tashkent Region keeps its name as is) |
| Uzbekistan: Tashkent | "The national flag is shown; Tashkent has no official flag." |
| Kyrgyzstan: Osh Region | "The national flag is shown; Osh Region has no official flag." |
| Bosnia and Herzegovina: Canton 10 | "The national flag is shown; Canton 10's flag was ruled unconstitutional in 1998 and has not been replaced." |
| Bosnia and Herzegovina: Brčko District | "The national flag is shown; Brčko District has no flag of its own and uses the national flag." |
| Albania: Dibër, Fier, Lezhë, Shkodër | "The national flag is shown; <Name> County has no documented flag in use." |
| Montenegro: Zeta | "The national flag is shown; no artwork of a flag for Zeta, a municipality since 2022, is available." |
| Latvia: Kuldīga, Madona | "The national flag is shown; no artwork of a <Name> Municipality flag is available." |
| Malta: Kalkara | "The national flag is shown; no accurate artwork of Kalkara's current flag (2009) is available." |
| Malta: Marsaxlokk, Żabbar | "The national flag is shown; no accurate artwork of <Name>'s flag is available." |
| Malta: Paola | "The national flag is shown; no freely licensed artwork of Paola's flag is available." |

## Licences

Most files are public domain, usually as official symbols. The credits name the author and licence for every file; these licences require attribution:

| Licence | Files |
| --- | --- |
| CC BY-SA 3.0 | 31 (Malta 29, Montenegro 2) |
| CC BY-SA 4.0 | 7 (Montenegro 4, Malta 3) |
| CC BY 3.0 | 1 (Kotor) |
| Free Art License 1.3 | 1 (Safi; copyleft, attribution and a link to the licence required) |

Nineteen files are CC0 (Malta 17, Latvia 2). The remaining 107 are public domain; their credits are kept as a courtesy and to make provenance reviewable. Ten Montenegrin rasters are FOTW drawings (nine by Tomislav Šipek, one by Ivan Sarajčić) that Commons hosts as public-domain insignia.

## Files

- Catalogs: `jpex/SerbiaCatalog.swift` (`serbia`), `BosniaCatalog.swift` (`bosniaAndHerzegovina`), `AlbaniaCatalog.swift` (`albania`), `MontenegroCatalog.swift` (`montenegro`), `LatviaCatalog.swift` (`latvia`), `LuxembourgCatalog.swift` (`luxembourg`), `MaltaCatalog.swift` (`malta`), `BelarusCatalog.swift` (`belarus`), `ArmeniaCatalog.swift` (`armenia`), `KazakhstanCatalog.swift` (`kazakhstan`), `UzbekistanCatalog.swift` (`uzbekistan`) and `KyrgyzstanCatalog.swift` (`kyrgyzstan`).
- Flags: 166 imagesets named `<cc>_flag_<code suffix>` (for example `rs_flag_00`, `ba_flag_srp`, `lv_flag_rix`, `lv_flag_011`, `mt_flag_45`, `kg_flag_gb`), each with `flag.png` and the standard `Contents.json`. The 91 fallback places use the existing `world_flag_rs`, `world_flag_ba`, `world_flag_al`, `world_flag_me`, `world_flag_lv`, `world_flag_lu`, `world_flag_mt`, `world_flag_am`, `world_flag_kz`, `world_flag_uz` and `world_flag_kg` assets.
- Credits: the eleven `*FlagCredits.json` files listed above.
