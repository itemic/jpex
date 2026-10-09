# Sixteen more collections: flag sources

Retrieved 7 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

## Catalog scope

Every collection uses ISO 3166-2 codes as permanent IDs (`<country>-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_<cc>`) as the collection flag. Group IDs are `<country>-<slug>` and are display data only.

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| South Korea (`KR`) | 17 | Seoul, six metropolitan cities and Sejong; nine provinces (Gangwon and Jeonbuk are special self-governing provinces since 2023 and 2024; Jeju since 2006). |
| Taiwan (`TW`) | 22 | Six special municipalities, three provincial cities and 13 counties. |
| Austria (`AT`) | 9 | The nine federal states (numeric ISO codes). |
| Netherlands (`NL`) | 12 | The twelve provinces. The Caribbean special municipalities are not provinces and are not included. |
| Belgium (`BE`) | 11 | Five Flemish provinces, five Walloon provinces and the Brussels-Capital Region (`BE-BRU`), grouped by region. The Flemish and Walloon regions themselves are groups, not places. |
| Poland (`PL`) | 16 | The sixteen voivodeships. |
| Portugal (`PT`) | 20 | Eighteen mainland districts and the autonomous regions of the Azores and Madeira. |
| Norway (`NO`) | 15 | The counties in force since 1 January 2024, after Viken, Vestfold og Telemark, and Troms og Finnmark were dissolved. |
| Brazil (`BR`) | 27 | Twenty-six states and the Federal District, grouped by IBGE region. |
| Argentina (`AR`) | 24 | Twenty-three provinces and the Autonomous City of Buenos Aires, grouped by region. |
| Mexico (`MX`) | 32 | Thirty-one states and Mexico City. |
| Malaysia (`MY`) | 16 | Thirteen states and the federal territories of Kuala Lumpur, Labuan and Putrajaya. |
| Thailand (`TH`) | 77 | Seventy-six provinces and Bangkok, in six geographic regions. Pattaya (`TH-S`) lies within Chon Buri and is not listed separately. |
| Philippines (`PH`) | 83 | Eighty-two provinces, including Maguindanao del Norte and del Sur (2022), and Metro Manila (`PH-00`, the National Capital Region). Island groups follow each province's ISO region: Luzon (regions 01, 02, 03, 05, 15, 40, 41 and Metro Manila), Visayas (06–08) and Mindanao (09–14). |
| Indonesia (`ID`) | 38 | Thirty-eight provinces, including Jakarta, Yogyakarta and the four Papua provinces created in 2022, grouped by the ISO geographical units (Sumatra, Java, Lesser Sunda Islands, Kalimantan, Sulawesi, Maluku Islands, Papua). |
| India (`IN`) | 36 | Twenty-eight states and eight union territories with current names and boundaries, including Dadra and Nagar Haveli and Daman and Diu, and Ladakh. |

## Names

English names follow Wikidata's English labels, checked against ISO 3166-2, without type words that the group already gives (for example "Lower Silesian" for Lower Silesian Voivodeship, "Miaoli" for Miaoli County). Where a city and county share a name the type is kept ("Hsinchu City", "Hsinchu County"). Jeonbuk uses its name since 2024 (formerly North Jeolla).

Local names are stored only where they differ from the English name: Korean (full official names, such as 서울특별시), Traditional Chinese for Taiwan (臺北市, 新竹縣), German, Dutch for Flemish provinces and French for Walloon provinces and Brussels, Polish, Portuguese, Spanish, Malay, Thai (provincial names without the จังหวัด prefix) and Indonesian. Friesland's local name is its official name, Fryslân. Norwegian Bokmål county names are identical to the English names, so Norway has no separate local names. India and the Philippines use English names only.

## How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`), and the flag image (P41) was read from the preferred-rank statement, or else from a normal-rank statement without an end date. Deprecated statements were ignored. For `AR-Z` the search also matched Los Glaciares National Park; the Santa Cruz Province item was used.
2. Places without a usable Wikidata flag, or whose statement pointed to outdated artwork, were filled from Wikimedia Commons and checked against curated lists of current flags: English Wikipedia's province infoboxes (Philippines), Thai Wikipedia's list of current provincial flags (*รายการธงประจำจังหวัดของไทย*), Indonesian Wikipedia's list of provincial flags (*Daftar bendera Indonesia*) and English Wikipedia's *State flags of Mexico*.
3. Every flag was then inspected on per-country contact sheets for historical designs, coats of arms used in place of flags, wrong proportions, and blank or broken renders.

Each flag is Wikimedia Commons' PNG render of the linked SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette. The alpha channel is kept whenever a render is not fully opaque; apart from anti-aliased edges, only Warmian-Masurian and Greater Poland, whose flags have a cut fly, have transparent areas. Sixty-four of the chosen files are raster images (PNG, JPEG, GIF or WebP) rather than SVG; they were converted the same way from the original file or its 960-pixel thumbnail. Artwork is unchanged.

Every file's author, source page and licence ship in `SouthKoreaFlagCredits.json`, `TaiwanFlagCredits.json`, `AustriaFlagCredits.json`, `NetherlandsFlagCredits.json`, `BelgiumFlagCredits.json`, `PolandFlagCredits.json`, `PortugalFlagCredits.json`, `NorwayFlagCredits.json`, `BrazilFlagCredits.json`, `ArgentinaFlagCredits.json`, `MexicoFlagCredits.json`, `MalaysiaFlagCredits.json`, `ThailandFlagCredits.json`, `PhilippinesFlagCredits.json` and `IndonesiaFlagCredits.json`. India uses only the national flag, which is already credited in `WorldFlagCredits.json`.

## Notes by collection

- **South Korea.** Current flags, including Busan's 2023 flag, the flags adopted when Gangwon (2023) and Jeonbuk (2024) became special self-governing provinces, and North Chungcheong's 2023 flag. Most are the government emblem on white, as the local governments fly them.
- **Taiwan.** Taichung, Hsinchu City and Lienchiang County have no flag on Wikidata; government artwork on Commons is used. Taichung shows the city flag introduced in 2025 (a JPEG published by the city government) and Hsinchu County its flag in use since 2019.
- **Austria.** Each state shows its civil state flag (*Landesflagge*), not the service flag with arms (*Landesdienstflagge*), matching the Germany collection. Upper Austria and Tyrol therefore share white-red, and Salzburg, Vienna and Vorarlberg share red-white. Wikidata's preferred files for Upper Austria and Tyrol are the service flags; they were replaced with the civil flag.
- **Netherlands, Belgium, Poland, Brazil, Malaysia.** Official provincial, regional and state flags as recorded on Wikidata. Brussels uses the regional flag adopted in 2015.
- **Portugal.** Districts have no official flags and show the national flag. The Azores and Madeira use their regional flags.
- **Norway.** Østfold, Akershus, Buskerud, Vestfold, Telemark, Troms and Finnmark were re-established on 1 January 2024 and fly their pre-2020 county flags again; those are shown. Agder uses the SVG version of its flag; Trøndelag has no SVG on Commons, so its PNG is used.
- **Argentina.** Jujuy's provincial flag is the Flag of Civil Liberty. It is shown from the file recorded on Wikidata, a redrawing of the original 1813 flag in its proportions (the Commons file name calls it an “unofficial improved version” of earlier renderings).
- **Mexico.** See *Unofficial flags* below. Chiapas is shown with the state coat of arms introduced on 1 January 2026. Guanajuato (2023) and Yucatán (2024) have recently adopted flags with their own designs.
- **Thailand.** Provincial flags follow Thai Wikipedia's list of current flags where Wikidata differs: Saraburi (2021 design), Chachoengsao (seal of the new Wat Sothon ordination hall), Phrae (2023 design), Nan, Ranong and Suphan Buri. Twelve provinces have no flag on Wikidata; eleven were filled from Commons, and Lopburi falls back to the national flag (below). Suphan Buri is described there as blue–vermilion–blue; Flags of the World (2012) describes the middle stripe as red. Samut Songkhram's artwork matches the current description (navy–white–navy, vertical), while a 2000 Ministry of Interior description recorded light blue.
- **Philippines.** Many Wikidata statements still point to 2006 Flags of the World GIFs with superseded seals or colours. Those, and raster files with an SVG equivalent, were replaced with the current designs used in the English Wikipedia province articles, mostly renderings made from the provinces' published descriptions or photographs: Abra, Agusan del Norte, Agusan del Sur, Aklan, Albay, Antique, Aurora, Batangas (2023 flag), Benguet, Biliran, Bukidnon, Camarines Norte, Camarines Sur, Davao del Sur, Ilocos Norte, Laguna, Lanao del Sur, Leyte, Quezon, Samar, Southern Leyte and Surigao del Sur. Apayao, Batanes, Capiz, Maguindanao del Norte and Maguindanao del Sur (the last two created in 2022) have no flag on Wikidata; Commons renderings of their current flags are used. Philippine provincial flag artwork varies in quality and provenance more than the other collections: Camarines Norte's flag is a reconstruction from a photograph, and Rizal's source image has a faint circular mark left of the seal.
- **Indonesia.** Provincial flags as recorded on Wikidata, except Bali, which uses the flag published on the provincial government's website. The four provinces created in 2022 use the flags recorded on Wikidata; for Southwest Papua, Highland Papua and South Papua the file pages cite the regional regulation that sets the flag.

## National flag fallbacks

| Places | Note shown |
| --- | --- |
| Portugal: the 18 districts | "The national flag is shown; <District> District has no official flag." |
| Philippines: Metro Manila | "The national flag is shown; Metro Manila has no official flag." |
| Thailand: Lopburi | "The national flag is shown; artwork for Lopburi's new 2026 provincial flag is not available yet." Lopburi's provincial seal, and with it the flag, was changed by a Prime Minister's Office announcement dated 20 August 2026; no artwork of the new flag exists on Commons yet, and the superseded flag is not shown. |
| India: all 36 states and union territories | "India's states and union territories have no official flags; the national flag is shown." Proposed or regional flags, such as Karnataka's, are not shown. |

## Unofficial flags

Fourteen Mexican states have flags set by state law: Baja California Sur, Coahuila, Colima, Durango, Guanajuato, Guerrero, Jalisco, Oaxaca, Querétaro, Quintana Roo, Tabasco, Tamaulipas, Tlaxcala and Yucatán. The other seventeen states customarily fly their coat of arms on a white field; those flags carry the note "Unofficial flag with the state's coat of arms." Mexico City carries "Unofficial flag with the city's coat of arms." The credits repeat the note. The constitutions of Baja California and Campeche state that the state has no official flag; their customary coat-of-arms flags are shown with the same note. Sources: [State flags of Mexico](https://en.wikipedia.org/wiki/State_flags_of_Mexico) and the state laws it cites.

## Licences

Most files are public domain, usually as official works or insignia. The credits name the author and licence for every file; these licences require attribution:

| Licence | Files |
| --- | --- |
| CC BY-SA 4.0 | 34 (Philippines 22, Thailand 7, Indonesia 3, Norway 2) |
| CC BY-SA 3.0 | 18 (Norway 10, Malaysia 4, Philippines 2, Taiwan 1, Belgium 1) |
| CC BY 4.0 | 12 (Argentina 10, Philippines 2) |
| CC BY-SA 1.0 | 1 (Madeira) |
| CC BY 2.5 AR | 1 (Buenos Aires City) |
| Attribution, Taiwan Government Website Open Information Announcement | 2 (Nantou, Taichung) |

Ten files are CC0. The remaining 321 are public domain; their credits are kept as a courtesy and to make provenance reviewable.

## Files

- Catalogs: `jpex/SouthKoreaCatalog.swift`, `TaiwanCatalog.swift`, `AustriaCatalog.swift`, `NetherlandsCatalog.swift`, `BelgiumCatalog.swift`, `PolandCatalog.swift`, `PortugalCatalog.swift`, `NorwayCatalog.swift`, `BrazilCatalog.swift`, `ArgentinaCatalog.swift`, `MexicoCatalog.swift`, `MalaysiaCatalog.swift`, `ThailandCatalog.swift`, `PhilippinesCatalog.swift`, `IndonesiaCatalog.swift` and `IndiaCatalog.swift`.
- Flags: 399 imagesets named `<cc>_flag_<code suffix>` (for example `kr_flag_11`, `tw_flag_tpe`, `at_flag_1`, `be_flag_bru`, `pl_flag_02`), each with `flag.png` and the standard `Contents.json`. The 56 fallback places use the existing `world_flag_pt`, `world_flag_ph`, `world_flag_th` and `world_flag_in` assets.
- Credits: the fifteen `*FlagCredits.json` files listed above.
