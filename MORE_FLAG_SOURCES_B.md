# Thirteen more collections (batch B): flag sources

Retrieved 8 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

## Catalog scope

Every collection uses current ISO 3166-2 codes as permanent IDs (`<country>-<code>`). The code suffix is the abbreviation, and the national flag (`world_flag_<cc>`) is the collection flag. Group IDs are `<country>-<slug>` and are display data only.

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| Jordan (`JO`) | 12 | The twelve governorates, grouped by the three planning regions (aqalim): North (Ajloun, Irbid, Jerash, Mafraq), Central (Amman, Balqa, Madaba, Zarqa) and South (Aqaba, Karak, Ma'an, Tafilah). |
| Oman (`OM`) | 11 | The eleven governorates. |
| Qatar (`QA`) | 8 | The eight municipalities in ISO 3166-2:QA, including Al Shahaniya (`QA-SH`, added by ISO in 2017). |
| Kuwait (`KW`) | 6 | The six governorates. |
| Bahrain (`BH`) | 4 | The four governorates. ISO deleted the Central Governorate (`BH-16`) in 2015, so there is no `BH-16`. |
| Iran (`IR`) | 31 | The 31 provinces, with ISO's codes as renumbered on 24 November 2020 (`IR-00` Markazi to `IR-30` Alborz). Grouped by the five regions set up by the Ministry of the Interior on 22 June 2014 (Hamshahri Online, 22 June 2014; English Wikipedia, "Regions of Iran"). |
| Iraq (`IQ`) | 18 | The 18 governorates. Duhok, Erbil and Sulaymaniyah are listed under the Kurdistan Region; the other 15 are under Governorates. |
| Cambodia (`KH`) | 25 | Phnom Penh (`KH-12`, the capital) and 24 provinces, including Tbong Khmum (`KH-25`, added by ISO in 2015). |
| Laos (`LA`) | 18 | Vientiane Prefecture (`LA-VT`, the capital) and 17 provinces, including Xaisomboun (`LA-XS`). |
| Bangladesh (`BD`) | 8 | The eight divisions (`BD-A` to `BD-H`), including Mymensingh (`BD-H`, added by ISO in 2016). The 64 districts are not listed. |
| Bhutan (`BT`) | 20 | The twenty districts (dzongkhags). |
| Papua New Guinea (`PG`) | 22 | Twenty provinces, the Autonomous Region of Bougainville (`PG-NSB`) and the National Capital District (`PG-NCD`). They are grouped by the four regions: Highlands (7), Islands (5), Momase (4) and Southern (6). |
| Fiji (`FJ`) | 5 | The four divisions and the dependency of Rotuma (`FJ-R`). The 14 provinces are not listed. |

The counts match the expected ones. Differences from what was assumed:

- **Iraq.** ISO 3166-2:IQ lists 18 governorates. Its last change (3 March 2022) added the Kurdistan Region as `IQ-KR` and made it the parent of `IQ-AR`, `IQ-DA` and `IQ-SU`. `IQ-KR` is a region rather than a governorate, so it appears only as the group "Kurdistan Region" and not as a place. Halabja became the 19th governorate in 2025 (voted 14 April, gazetted 5 May). ISO has no code for it yet, so the app lists it as `IQ-HA`; no flag of its own is known, so it shows the national flag.
- **Laos.** Xaisomboun is in ISO's list, giving 17 provinces and the prefecture.
- **Cambodia.** Tbong Khmum is in ISO's list, giving 24 provinces and the capital.

Grouping decisions:

- **Iran.** The regions are administrative groupings without a constitutional role. Each is labelled by its number and the city that hosts its secretariat: Region 1 (Tehran), Region 2 (Isfahan), Region 3 (Tabriz), Region 4 (Kermanshah) and Region 5 (Mashhad). Their local names are منطقه ۱ to منطقه ۵. Region 1 holds seven provinces and the others six each. Markazi is in Region 4 and Yazd in Region 5, following the 2014 decision.
- **Papua New Guinea.** Bougainville is listed with the Islands Region and the National Capital District with the Southern (Papua) Region. This follows the usual four-region grouping and avoids one-place groups.
- **Cambodia and Laos.** The capital is in its own group ("Capital", រាជធានី / ນະຄອນຫຼວງ), ahead of the provinces.

## Names

English names follow English Wikipedia and common usage. The type word is dropped where the group already gives it ("Irbid", "Dhofar", "Kirkuk", "Kampot", "Thimphu"). It is kept where it is part of the name or prevents confusion: Capital Governorate (Kuwait, Bahrain), Northern and Southern Governorate (Bahrain), Vientiane Prefecture and Vientiane Province, Central Province and Western Province (Papua New Guinea), and Fiji's Central, Eastern, Northern and Western Divisions. Other spellings:

- Bangladesh uses the official spellings that ISO also uses (Barishal, Chattogram).
- Oman uses English Wikipedia's "Al Batinah North" and "Ash Sharqiyah South" forms.
- Qatar's `QA-KH` is the municipality's full name, Al Khor and Al Thakhira.
- Iraq uses Anbar, Babylon, Qadisiyah and Saladin.
- Cambodia uses Kratié and Takéo, and Tbong Khmum as ISO spells it.
- Papua New Guinea uses Chimbu, Sandaun (ISO: West Sepik) and Oro (ISO: Northern), the names the provinces use.

Local names are stored without the type word, except where the type word is part of the usual name:

- **Arabic** for Jordan, Oman, Qatar, Kuwait and Bahrain. Two Arabic names keep the type word: محافظة العاصمة for the Capital Governorates, and المحافظة الشمالية / المحافظة الجنوبية in Bahrain. Jordan's Amman Governorate is officially محافظة العاصمة ("the Capital Governorate") and is stored as العاصمة.
- **Iraq.** Arabic for the 15 governorates outside the Kurdistan Region. The three Kurdistan Region governorates use Sorani Kurdish, the region's main official language, in the spellings that ISO and the Sorani Wikipedia use (دھۆک, ھەولێر, سلێمانی).
- **Persian** for Iran (without استان).
- **Khmer** for Cambodia (without ខេត្ត). Pailin is ប៉ៃលិន, as in ISO.
- **Lao** for Laos (without ແຂວງ). Vientiane Province keeps it (ແຂວງວຽງຈັນ) to distinguish it from the prefecture (ນະຄອນຫຼວງວຽງຈັນ). Spellings use the modern ຫຼ, and Khammouane is ຄຳມ່ວນ (the ISO-derived source data wrongly repeats Houaphanh's Lao name for `LA-KH`).
- **Bengali** for Bangladesh (without বিভাগ).
- **Dzongkha** for Bhutan, without རྫོང་ཁག. The names follow the native names in English Wikipedia's district articles, because the Dzongkha forms in the ISO-derived data are inconsistent and several look misspelled. Examples: བུམ་ཐང (ISO བྲུམ་ཐང), ཀྲོང་གསར (ISO གྲོང་གསར), གསར་སྤང (ISO ས་སྤངས), བསམ་གྲུབ་ལྗོངས་མཁར, བཀྲ་ཤིས་གཡང་རྩེ, དར་དཀར་ནང, མགར་ས. Zhemgang is stored as གཞལམ་སྒང, the form used by both the English and the Dzongkha Wikipedia.
- **Tok Pisin** for Papua New Guinea, using ISO's Tok Pisin names where they differ from the English (Simbu, Isten Hailans, Is Niu Briten, Milen Be, Pot Mosbi, Bogenvil…). Enga, Hela, Jiwaka, Manus, Madang, Morobe, Sandaun, Oro and Gulf have no separate local name.
- **Fiji** has no local names for the divisions; only the country has one (Viti).

## How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`). The flag (P41) was read from the preferred-rank statement, or else from a normal-rank statement without an end date. Iran's items carry both the pre-2020 and the current ISO codes; the current code (preferred rank) was used. Wikidata records flags only for the four Bahraini governorates and the 22 Papua New Guinean provinces.
2. The English and local-language Wikipedia infoboxes, the Commons categories of subdivision flags and Flags of the World (FOTW) were checked for every country. FOTW is the source for the current Iraqi governorate flags (Daniel Rentería, July and October 2025), Hela's 2015 flag, the Bahraini and Kuwaiti governorate flags, and Rotuma.
3. Candidate flags were compared on contact sheets with FOTW's drawings and descriptions, and the installed flags were inspected after conversion.

Each flag is Wikimedia Commons' PNG render of the linked SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette. The alpha channel is kept whenever a render is not fully opaque; here that is only anti-aliased edges. Six of the chosen files are raster PNGs and were converted the same way from the original or its 960-pixel thumbnail: Kirkuk and the Papua New Guinean flags of Enga, East Sepik, Gulf, Morobe and Oro. Artwork is unchanged.

Every file's author, source page and licence ship in `IraqFlagCredits.json` and `PapuaNewGuineaFlagCredits.json`. The other eleven collections use only their national flags, which are already credited in `WorldFlagCredits.json`.

## Notes by collection

- **Papua New Guinea.** The provincial flags as recorded on Wikidata. They were checked against FOTW's descriptions; the flags fly under each province's provincial law, as provided by the Organic Law on Provincial Governments and Local-level Governments.
  - **Long-standing files over redraws.** Where Commons also has a recent unsourced redraw of the same design, the long-standing file is used: Enga's 2011 PNG instead of a 2025 SVG, and Morobe's 2011 PNG instead of two 2025 SVGs.
  - **Oro.** The file used by English Wikipedia, whose tapa strip has the black markings that FOTW describes. Wikidata's file is a small 289-pixel image with green markings.
  - **National Capital District.** The yellow flag of the National Capital District Commission (Wikidata's preferred file), not the former "City of Port Moresby" flag.
  - **Bougainville.** The current file, with green triangles.
  - **Western Highlands.** The design with black, as on Wikidata. FOTW noted in 2012 that black parts may now be made in purple; this is unconfirmed.
  - **Hela.** The only file on Commons is the 2012 flag (a man's head with an axe and a club). FOTW reports that this was replaced in 2015 by a yellow, green and black flag with a Huli hat, a bird of paradise and five stars. No artwork of that flag exists, so Hela shows the national flag.
- **Iraq.** Governorates fly their logo on a white field, often set diagonally so that it appears upright. These flags change with the logo and are not set by law. FOTW documents current ones from photographs for most governorates. Only two have accurate artwork on Commons:
  - **Basra:** the flag with the logo introduced in November 2022. FOTW cites this Commons file.
  - **Kirkuk:** the flag with the logo adopted by the provincial council on 4 March 2025.
  The Commons files for Anbar, Babylon, Diyala, Dhi Qar, Karbala, Qadisiyah, Nineveh and Wasit show the logo upright, an older logo or a wrong background. Several are recent redraws taken from the Vexillology fan wiki. They do not match the flags that FOTW documents and are not used. Baghdad, Maysan, Najaf, Saladin and Sulaymaniyah have no Commons artwork; Sulaymaniyah's current flag is a UNESCO Creative City banner. FOTW knows no current flag for Muthanna, Duhok or Erbil; Erbil uses the Kurdistan Regional Government's symbols.
- **Bahrain.** FOTW and Commons show each governorate's logo on white. FOTW's evidence is slight ("I seem to remember…", and drawings from Vexilla Mundi), and no legal basis was found. The Commons SVGs come from a flag seller and are flawed: the Northern Governorate file carries the Southern Governorate's Arabic name, and the Capital and Southern files crop the logo's lettering. They are not treated as official flags.
- **Kuwait.** FOTW shows logo-on-white flags for Ahmadi and Mubarak Al-Kabeer, drawn from one Facebook photo each. The Commons GIFs (288 × 216 px) copy FOTW's drawings. They are not treated as established flags.
- **Qatar.** FOTW reports one sighting (2025) of a logo flag for Doha at a twinning ceremony. Municipalities have no adopted flags.
- **Jordan.** FOTW lists flags of the cities of Amman, Irbid, Karak, Salt and Zarqa. These belong to the municipalities, not the governorates, and are not shown.
- **Oman.** No province has an officially recognised flag (Whitney Smith, *Flag Bulletin* 167, 1995, summarised by FOTW).
- **Laos.** FOTW (May 2026) notes that Vientiane has not adopted an official flag; a banner with Pha That Luang is used at sports events.
- **Iran, Cambodia, Bangladesh, Bhutan.** No flags. Cambodian provinces and Bhutanese districts have seals or emblems, which are not flags.
- **Fiji.** The divisions have no flags. The only Rotuma flag on Commons is that of the short-lived 1987–88 independence declaration, which is not shown.

## National flag fallbacks

| Places | Note shown |
| --- | --- |
| Jordan: all 12 | "Jordan's governorates have no official flags; the national flag is shown." |
| Oman: all 11 | "Oman's governorates have no official flags; the national flag is shown." |
| Qatar: all 8 | "Qatar's municipalities have no official flags; the national flag is shown." |
| Kuwait: all 6 | "Kuwait's governorates have no official flags; the national flag is shown." |
| Bahrain: all 4 | "Bahrain's governorates have no official flags; the national flag is shown." |
| Iran: all 31 | "Iran's provinces have no official flags; the national flag is shown." |
| Cambodia: all 25 | "Cambodia's provinces and capital have no official flags; the national flag is shown." |
| Laos: all 18 | "The provinces of Laos and Vientiane Prefecture have no official flags; the national flag is shown." |
| Bangladesh: all 8 | "Bangladesh's divisions have no official flags; the national flag is shown." |
| Bhutan: all 20 | "Bhutan's districts have no official flags; the national flag is shown." |
| Fiji: all 5 | "Fiji's divisions and Rotuma have no official flags; the national flag is shown." |
| Iraq: Anbar, Babylon, Baghdad, Dhi Qar, Diyala, Karbala, Maysan, Najaf, Nineveh, Qadisiyah, Saladin, Wasit, Sulaymaniyah | "The national flag is shown; no accurate artwork of <Name> Governorate's flag is available." |
| Iraq: Muthanna, Duhok, Erbil | "The national flag is shown; no current flag of <Name> Governorate is known." |
| Papua New Guinea: Hela | "The national flag is shown; artwork for Hela's current provincial flag (2015) is not available." |

## Licences

The 21 Papua New Guinean files are public domain (self-released by their authors or as official insignia). The two Iraqi files are released under CC0 1.0. None requires attribution; the credits are kept as a courtesy and to make provenance reviewable.

## Files

- **Catalogs:** `jpex/JordanCatalog.swift`, `OmanCatalog.swift`, `QatarCatalog.swift`, `KuwaitCatalog.swift`, `BahrainCatalog.swift`, `IranCatalog.swift`, `IraqCatalog.swift`, `CambodiaCatalog.swift`, `LaosCatalog.swift`, `BangladeshCatalog.swift`, `BhutanCatalog.swift`, `PapuaNewGuineaCatalog.swift` and `FijiCatalog.swift`.
- **Flags:** 23 imagesets named `<cc>_flag_<code suffix>`: `iq_flag_ba` and `iq_flag_ki`, plus `pg_flag_cpk` and the other Papua New Guinean flags apart from Hela. Each has `flag.png` and the standard `Contents.json`. The 165 fallback places use the existing `world_flag_jo`, `world_flag_om`, `world_flag_qa`, `world_flag_kw`, `world_flag_bh`, `world_flag_ir`, `world_flag_iq`, `world_flag_kh`, `world_flag_la`, `world_flag_bd`, `world_flag_bt`, `world_flag_pg` and `world_flag_fj` assets.
- **Credits:** `jpex/IraqFlagCredits.json` and `jpex/PapuaNewGuineaFlagCredits.json`.
