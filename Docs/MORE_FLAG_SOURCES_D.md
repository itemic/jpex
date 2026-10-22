# Batch D: flag sources

Retrieved 16 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app. The sections below were researched separately for each group of countries and follow the method of `MORE_FLAG_SOURCES_A.md`: Wikidata P41, the English and local Wikipedias, Wikimedia Commons, Flags of the World and official sources, with every candidate file's source and licence traced. Each bundled flag is Commons' PNG render of the source SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette; raster originals were converted the same way and never enlarged.

Places without a flag of their own here show their national flag, with a note saying why. Most of this batch's subdivisions have no official flags.

Turkmenistan, Andorra, Liechtenstein and San Marino were researched too (their sections below), but are not in the app yet: no openly licensed boundary data of adequate accuracy was found for their maps (see `MAP_SOURCES_D.md`). Their catalog data and flags are kept in `/private/tmp/jpex-admin2/research/A/` for when they are added.

| Collection | Places | Own flags | Credits |
| --- | --- | --- | --- |
| Vietnam (`VN`) | 34 | 0 | – |
| Afghanistan (`AF`) | 34 | 0 | – |
| Brunei Darussalam (`BN`) | 4 | 0 | – |
| Myanmar (`MM`) | 15 | 14 | `MyanmarFlagCredits.json` |
| Pakistan (`PK`) | 7 | 1 | `PakistanFlagCredits.json` |
| Lebanon (`LB`) | 8 | 0 | – |
| Georgia (`GE`) | 12 | 2 | `GeorgiaFlagCredits.json` |
| Tajikistan (`TJ`) | 5 | 0 | – |
| Moldova (`MD`) | 37 | 34 | `MoldovaFlagCredits.json` |
| Zambia (`ZM`) | 10 | 0 | – |
| Zimbabwe (`ZW`) | 10 | 0 | – |
| Mozambique (`MZ`) | 11 | 0 | – |
| Cameroon (`CM`) | 10 | 0 | – |
| Botswana (`BW`) | 16 | 0 | – |
| Nicaragua (`NI`) | 17 | 2 | `NicaraguaFlagCredits.json` |
| Haiti (`HT`) | 10 | 0 | – |
| Trinidad and Tobago (`TT`) | 15 | 0 | – |
| Guyana (`GY`) | 10 | 0 | – |
| Suriname (`SR`) | 10 | 0 | – |
| Belize (`BZ`) | 6 | 0 | – |
| Samoa (`WS`) | 11 | 0 | – |
| Vanuatu (`VU`) | 6 | 3 | `VanuatuFlagCredits.json` |
| Tonga (`TO`) | 5 | 0 | – |
| Solomon Islands (`SB`) | 10 | 8 | `SolomonIslandsFlagCredits.json` |
| **24 collections** | **313** | **64** | |

## Second-level lists

The lists of a place's own subdivisions (Tasmania's and the Northern Territory's local government areas; Scotland's, Wales's and Northern Ireland's councils; Spain's provinces by community) bundle no flags. Many councils and provinces have flags or arms, but checking each one's status and artwork is left for later. Each place shows its parent's flag, already bundled and credited, with a note:

| Lists | Note shown |
| --- | --- |
| Tasmania | "The flag of Tasmania is shown; council flags aren't included." |
| Northern Territory | "The flag of the Northern Territory is shown; council flags aren't included." |
| Scotland, Wales | "The flag of Scotland (Wales) is shown; council flags aren't included." |
| Northern Ireland | "The Union Flag is shown; council flags aren't included." (Northern Ireland has no official flag of its own) |
| Spain's ten communities | "The flag of <community> is shown; provincial flags aren't included." |

The quiz's flag questions skip places that share their flag with others, so these lists aren't asked by flag.

## Vietnam, Pakistan, Afghanistan, Brunei, Myanmar and Lebanon

Retrieved 16 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

### Catalog scope

Every collection uses ISO 3166-2 codes as permanent IDs (`<country>-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_<cc>`) as the collection flag. Group IDs are `<country>-<slug>` and are display data only. The code lists were checked against the change history of each ISO 3166-2 entry (as summarised on English Wikipedia, cross-checked with the iso3166-updates dataset of August 2026) and against Wikidata (P300).

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| Vietnam (`VN`) | 34 | The provincial-level units in force since 1 July 2025: nine centrally run cities (thành phố trực thuộc trung ương) and 25 provinces (tỉnh), each in its own group. |
| Pakistan (`PK`) | 7 | The four provinces, and Azad Kashmir (`PK-JK`), Gilgit-Baltistan (`PK-GB`) and Islamabad Capital Territory (`PK-IS`) as territories. |
| Afghanistan (`AF`) | 34 | The 34 provinces. |
| Brunei Darussalam (`BN`) | 4 | The four districts. |
| Myanmar (`MM`) | 15 | The seven regions (`MM-01` to `MM-07`), seven states (`MM-11` to `MM-17`) and Nay Pyi Taw Union Territory (`MM-18`), in three groups as in the 2008 Constitution. |
| Lebanon (`LB`) | 8 | The eight governorates, including Akkar and Baalbek-Hermel (2003; governors since 2014). |

Scope decisions and differences from ISO:

- **Vietnam.** National Assembly Resolution 202/2025/QH15 (12 June 2025; new local governments from 1 July 2025) merged 52 of the 63 provinces and cities into 23 units and kept 11 unchanged, leaving 34. Every merger joined whole provinces, and each new unit kept the name of one unit it absorbed. ISO 3166-2:VN has not been updated: it still lists 58 provinces and five municipalities (last change 24 November 2020). Each unit therefore uses the former ISO code of the unit whose name it kept: `VN-29` for Quảng Ngãi (which absorbed Kon Tum, `VN-28`), `VN-SG` for Ho Chi Minh City (with Bình Dương and Bà Rịa–Vũng Tàu), and so on. Wikidata does the same: the 34 continuing items keep their codes and the 29 absorbed units carry dissolution dates. `VN.json` maps all 63 former codes to the new IDs (`oldToNew`). Three provinces have since become centrally run cities on their existing territory: Đồng Nai (30 April 2026), Quảng Ninh (1 September 2026, Resolution 36/2026/QH16) and Bắc Ninh (20 September 2026); Huế had become one on 1 January 2025 (formerly Thừa Thiên-Huế, `VN-26`). These four keep numeric province codes; the other five cities keep ISO's letter codes (`VN-CT`, `VN-DN`, `VN-HN`, `VN-HP`, `VN-SG`). Further upgrades (Khánh Hòa, Ninh Bình, Hưng Yên, targeted for 2027–2030) would change only the group.
- **Pakistan.** The Federally Administered Tribal Areas (`PK-TA`) merged into Khyber Pakhtunkhwa under the 25th Amendment (31 May 2018); ISO deleted the code on 22 November 2019. Listing Azad Kashmir and Gilgit-Baltistan follows ISO, which classes them as Pakistan-administered areas, and is not a statement on the status of Kashmir. Proposals for new provinces were under debate in September and October 2026, but no bill had been tabled.
- **Lebanon.** Keserwan-Jbeil is not listed. Law 50 of 7 September 2017 created a governorate of Keserwan al-Futuh and Jbeil (seat Jounieh), and Decree 6810 of 7 August 2020 added it to the table of administrative divisions, but it has never operated: the staffing decrees are still pending (An-Nahar, 11 October 2026), no governor is in office (the 2020 appointee was challenged before the State Council, resigned, and became Director-General of Labour on 8 October 2026), the Ministry of Interior's 2025 election results list Keserwan and Jbeil under Mount Lebanon, and the Central Administration of Statistics reports eight governorates. ISO has no code for it. If it starts operating, it would be `LB-KJ`, built from the two districts, and Mount Lebanon would keep Baabda, Matn, Chouf and Aley.
- **Myanmar, Afghanistan, Brunei.** Current ISO lists, unchanged. No state, region, province or district was created or changed through October 2026.

### Names

English names follow English Wikipedia, without type words that the group or label already gives ("Sagaing" for Sagaing Region, "Kachin" for Kachin State, "Balkh" for Balkh Province, "Belait" for Belait District, "Akkar" for Akkar Governorate). The type word is kept in Islamabad Capital Territory, and in Lebanon's North Governorate and South Governorate, whose names are bare directions. Other choices:

- **Vietnam:** English Wikipedia's titles, which keep Vietnamese letters for most provinces and some cities (Huế, Cần Thơ, Đồng Nai, Quảng Ninh, Bắc Ninh, Khánh Hòa) and use the English forms Hanoi, Ho Chi Minh City, Haiphong and Da Nang.
- **Afghanistan:** Daikundi, Juzjan and Sar-e-Pol (ISO: Dāykundī, Jowzjān, Sar-e Pul) and Maidan Wardak, as on English Wikipedia.
- **Pakistan:** Azad Kashmir, English Wikipedia's title for Azad Jammu and Kashmir.
- **Myanmar:** Nay Pyi Taw for `MM-18`, the spelling of ISO and of the English Wikipedia article (renamed from Naypyidaw Union Territory in August 2026).
- **Brunei:** Brunei–Muara, with English Wikipedia's en dash; the collection is named Brunei Darussalam to match the Countries list.

Local names are stored only where they differ from the English name:

- **Vietnam:** Vietnamese, without tỉnh or thành phố: Hà Nội, Hải Phòng, Đà Nẵng, and Thành phố Hồ Chí Minh, the city's official name (Hồ Chí Minh alone is the person). The other 30 names are the same as the English. Groups: Thành phố trực thuộc trung ương and Tỉnh.
- **Pakistan:** Urdu (پنجاب، سندھ، خیبر پختونخوا، بلوچستان، گلگت بلتستان), with the official آزاد جموں و کشمیر for Azad Kashmir and اسلام آباد وفاقی دارالحکومت علاقہ for the capital territory. Groups: صوبے and علاقے.
- **Afghanistan:** Pashto, which the app already uses to set Afghanistan's local names (Pashto and Dari are both official). Spellings are those of the Pashto service of Bakhtar News Agency, the state news agency, checked name by name against its site: Pashto letters where Pashto uses them (کونړ، لوګر، ننګرهار، سمنګان، میدان وردګ، دایکنډي، پنجشېر), the Pashto forms کندهار and کندز (Dari قندهار, قندوز), روزګان for Uruzgan, and ي only for a final /i/ (غزني). Group: ولایتونه.
- **Brunei:** Malay in Latin script; only Brunei dan Muara differs. Group: Daerah.
- **Myanmar:** Burmese with the type word (စစ်ကိုင်းတိုင်းဒေသကြီး, ကချင်ပြည်နယ်, နေပြည်တော် ပြည်ထောင်စုနယ်မြေ), because it is part of the usual name and the bare forms mean the town or the people. Spellings follow Burmese Wikipedia; Shan is ရှမ်း, as on the Shan State Government Office. Groups: တိုင်းဒေသကြီးများ, ပြည်နယ်များ and ပြည်ထောင်စုနယ်မြေ.
- **Lebanon:** Arabic without محافظة (عكار، بعلبك الهرمل، بيروت، البقاع، جبل لبنان، النبطية), except محافظة الشمال and محافظة الجنوب. Group: المحافظات.

### How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`). The flag (P41) was read from the preferred-rank statement, or else from a normal-rank statement without an end date; deprecated statements were ignored. Wikidata records flags for all 15 Myanmar units, five Pakistani units (Punjab, Sindh, Khyber Pakhtunkhwa, Balochistan, Azad Kashmir) and Beirut, and none for Vietnam, Afghanistan, Brunei or the other Lebanese governorates.
2. These were compared with the English and local-language Wikipedia infoboxes, English Wikipedia's *List of Burmese flags* and its talk page, and the Commons categories of subdivision flags. Status and design were checked against Flags of the World (FOTW: the Myanmar state and region pages, the Pakistani province pages updated in 2025–26, and Beirut), legal texts (the Azad Jammu and Kashmir State Flag Act, 1975; Lebanon's Law 50/2017 and Decree 6810/2020), the governments' own websites, and photographs of flags in official use: the state and region flags hung along Pyay Road in Yangon for Independence Day 2023 (Commons photographs), the Shan, Kayah and Kayin state government buildings, and Associated Press of Pakistan photographs of the provincial governments.
3. A flag is shown only if the subdivision's government adopted it or clearly uses it as its flag, and only if the artwork shows the current design. Every chosen flag was inspected on contact sheets, before and after conversion, beside the official images and photographs.

Each flag is Wikimedia Commons' PNG render of the linked SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette. All 15 are fully opaque, so no alpha channel is kept. Nay Pyi Taw's render (960 × 641 from a 3:2 SVG) had one fully transparent row at the bottom from thumbnail rounding; that row was trimmed. Bago's file is a raster PNG (2560 × 1705) and was converted the same way from the original. Artwork is unchanged.

Every file's author, source page and licence ship in `MMFlagCredits.json` (14 files) and `PKFlagCredits.json` (1 file). Vietnam, Afghanistan, Brunei and Lebanon use only their national flags, which are already credited in `WorldFlagCredits.json`.

### Notes by collection

- **Myanmar (14 of 15).** Two flags were adopted by the state or region Hluttaw: Mon (golden hamsa on red, 8 June 2018) and Sagaing (30 September 2019, designed by Khine Zar Mon). The others are flown by the state and region governments without published adoption, and most regions have changed theirs at least once since 2010, so each was matched to current evidence:
  - **Chin, Kayin:** the flags on the state governments' own websites (Chin's blue–red–green flag with a hornbill and nine white stars; Kayin's deep blue–white–red flag with a white star, which the government draws at 9:5 and Commons at 2:1). The two-hornbill flag on Commons is the Chin State Hluttaw's. Kayin's design is also recorded by FOTW as a Karenni flag, but the Kayin State government uses it.
  - **Bago:** the flag on the Bago Region Government's website (image of March 2025): a golden hamsa above the name on blue. Commons files this design as a former flag; Wikidata's white-disc design is not used by the region government, and an older banner with the pre-2010 name was still hung in 2023.
  - **Mandalay:** the red flag with the region emblem (2010 to the present, seen again in the 2023 display); Wikidata's light blue version was a variant flown in 2021–22.
  - **Ayeyarwady, Magway, Yangon, Nay Pyi Taw:** the flags introduced around 2021–22 with the government seals, as flown at the 2022 and 2023 parades and shown by FOTW and the Yangon Region Government. Ayeyarwady's field appears in both light and darker blue; the light blue file is used.
  - **Kachin, Kayah, Rakhine, Shan:** long-standing state flags seen in the 2023 display or on government buildings (the Shan flag on the Shan State Government Office and Hluttaw, 2019; Kayah's on the Kayah State Government Office, 2019). Kayah shows the current redraw with the large kinnara that the 2023 flags have; Shan uses the darker green of the flags in use rather than the national flag's shades.
  - **Tanintharyi:** the region flies a red–blue–green flag with a white star and a naga, but the only Commons drawing mirrors the naga of the flag on the region government's website, so the national flag is shown.
- **Pakistan (1 of 7).** Azad Kashmir shows the state flag of the Azad Jammu and Kashmir State Flag Act, 1975 (green with a saffron canton, crescent and star, four white stripes). The provincial governments and Gilgit-Baltistan fly green flags with their emblems, but the current designs have no free artwork: Punjab's and Gilgit-Baltistan's emblems are now gold, and Khyber Pakhtunkhwa's and Balochistan's are in colour (FOTW 2025–26; APP photographs), while every Commons file shows an older white emblem. Sindh's white-emblem flag is known only from a 2005 FOTW drawing (English Wikipedia's 2005 adoption date is that drawing's date), so its current form could not be verified. Islamabad Capital Territory has no flag; the green flag with an emblem is the Islamabad Metropolitan Corporation's, and the Commons "Proposed Flag of Islamabad Capital Territory" is a 2004 private proposal.
- **Lebanon.** The governorates have no flags. Beirut Governorate is coextensive with the City of Beirut, whose municipal flag is light blue with the city arms (FOTW, from a 2010 photograph); the Commons files show the arms on white, which FOTW lists as erroneous or former, so the national flag is shown.
- **Vietnam.** Provinces and centrally run cities use logos (biểu trưng), not flags. FOTW records only unofficial flags sold by a flag maker for Hanoi, Ho Chi Minh City, Da Nang, Haiphong and Cần Thơ (and a football-club flag for Haiphong); Wikidata records none.
- **Afghanistan.** FOTW lists no provincial flags; the flags it shows for Kabul, Herat and other cities belong to the municipalities. (The app's `world_flag_af` is the black–red–green tricolour of the former Islamic Republic.)
- **Brunei.** The districts have no flags; FOTW lists none.

### National flag fallbacks

| Places | Note shown |
| --- | --- |
| Vietnam: all 34 | "Vietnam's provinces and centrally run cities have no official flags; the national flag is shown." |
| Afghanistan: all 34 | "Afghanistan's provinces have no official flags; the national flag is shown." |
| Brunei: all 4 | "Brunei's districts have no official flags; the national flag is shown." |
| Lebanon: 7 governorates | "Lebanon's governorates have no official flags; the national flag is shown." |
| Lebanon: Beirut | "The national flag is shown; no accurate artwork of the City of Beirut's flag is available." |
| Pakistan: Punjab, Khyber Pakhtunkhwa, Balochistan, Gilgit-Baltistan | "The national flag is shown; no accurate artwork of <Name>'s current flag is available." |
| Pakistan: Sindh | "The national flag is shown; Sindh's current flag could not be verified." |
| Pakistan: Islamabad Capital Territory | "The national flag is shown; Islamabad Capital Territory has no official flag." |
| Myanmar: Tanintharyi | "The national flag is shown; no accurate artwork of Tanintharyi Region's flag is available." |

### Licences

Fifteen files. Public domain 8 (Bago, Chin, Kachin, Kayah, Kayin, Mon and Rakhine; Azad Kashmir), CC0 1.0 3 (Ayeyarwady, Mandalay, Yangon), CC BY-SA 4.0 3 (Magway, Sagaing, Nay Pyi Taw) and CC BY-SA 2.5 1 (Shan). The CC BY-SA files require attribution, which the credits files give.

### Files

- Data: `VN.json`, `PK.json`, `AF.json`, `BN.json`, `MM.json`, `LB.json` (`VN.json` includes `oldToNew`).
- Flags: 15 files named `<cc>_flag_<code suffix>`: `mm_flag_01` to `mm_flag_07` except `mm_flag_05`, `mm_flag_11` to `mm_flag_18`, and `pk_flag_jk`. The 87 fallback places use the existing `world_flag_vn`, `world_flag_pk`, `world_flag_af`, `world_flag_bn`, `world_flag_mm` and `world_flag_lb` assets.
- Credits: `MMFlagCredits.json` and `PKFlagCredits.json` (in the app, `MyanmarFlagCredits.json` and `PakistanFlagCredits.json`, following the existing naming).

## Georgia, Tajikistan and Moldova (and Turkmenistan, Andorra, Liechtenstein and San Marino, not yet added)

Retrieved 16 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

### Catalog scope

Every collection uses ISO 3166-2 codes as permanent IDs (`<country>-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_<cc>`) as the collection flag. Group IDs are `<country>-<slug>` and are display data only. The code lists were checked against the change history of each ISO 3166-2 entry (as summarised on English Wikipedia), the Debian iso-codes data (October 2025) and Wikidata (P300); all seven match, and no change was found through October 2026.

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| Georgia (`GE`) | 12 | Nine regions (mkhare), the autonomous republics of Abkhazia (`GE-AB`) and Adjara (`GE-AJ`), and the capital, Tbilisi (`GE-TB`), each kind in its own group. |
| Tajikistan (`TJ`) | 5 | Regions: Khatlon, Sughd and the Districts under Central Government Jurisdiction (`TJ-RA`); the autonomous region of Gorno-Badakhshan (`TJ-GB`); the capital, Dushanbe (`TJ-DU`). |
| Turkmenistan (`TM`) | 6 | The five regions (welaýatlar) and the capital, Ashgabat (`TM-S`). |
| Moldova (`MD`) | 37 | The 32 districts (raioane), the municipalities of Bălți, Bender and Chișinău, and the autonomous territorial units of Gagauzia (`MD-GA`) and Transnistria (`MD-SN`). |
| Andorra (`AD`) | 7 | The seven parishes (parròquies), `AD-02` to `AD-08`. |
| Liechtenstein (`LI`) | 11 | The eleven municipalities (Gemeinden), `LI-01` to `LI-11`. |
| San Marino (`SM`) | 9 | The nine castelli, `SM-01` to `SM-09`. |

Scope decisions and differences from the current ISO list:

- **Listed de jure.** Abkhazia (`GE-AB`) is Georgia's Autonomous Republic of Abkhazia, whose territory has been held by the self-declared Republic of Abkhazia since 1993; the World list does not list Abkhazia separately. Transnistria (`MD-SN`, in Moldovan law the administrative-territorial units of the left bank of the Dniester, an autonomous territorial unit with special legal status under Law 173/2005) and Bender (`MD-BD`) are held by the unrecognised Pridnestrovian Moldavian Republic; both are listed. South Ossetia is not an ISO 3166-2 subdivision; Georgian law assigns its territory to the surrounding regions, so it is not listed.
- **Turkmenistan: Arkadag is not included.** The new city became the administrative centre of Ahal Region on 20 December 2022 as a city with the rights of a district, and the Law on the City of Arkadag (23 March 2023) made it a "city of state significance". It is not a first-level unit: its court and prosecutor's office are those "of the city of Arkadag of Ahal velayat", Wikidata places it in Ahal Region, and neither ISO 3166-2 nor Wikidata gives it a code. It stays part of Ahal (`TM-A`), unlike Ashgabat, a city with the rights of a velayat.
- **Tajikistan.** `TJ-RA` is a region-level group of nine districts and four towns around Dushanbe governed directly by the central government; it is grouped with the regions, as English Wikipedia lists it.
- **Moldova.** Dubăsari District (`MD-DU`) covers the villages under Moldovan administration; the town of Dubăsari is in Transnistria.
- **Georgia, Andorra, Liechtenstein, San Marino.** Current ISO lists, unchanged. San Marino's `SM-07` was renamed "Città di San Marino" in 2020.

### Names

English names follow English Wikipedia, without type words that the group or label already gives ("Guria" for the Guria region, "Khatlon" for Khatlon Region, "Ahal" for Ahal Region, "Anenii Noi" for Anenii Noi District). Article-title punctuation is kept: Samtskhe–Javakheti and Escaldes–Engordany take an en dash, as North Ossetia–Alania does in the Russia collection. The type word is kept where it is part of the name or prevents confusion: the Districts under Central Government Jurisdiction (English Wikipedia's article title; also translated "Districts of Republican Subordination") and the City of San Marino. Abkhazia and Adjara drop "Autonomous Republic of"; Gorno-Badakhshan uses English Wikipedia's short form (ISO: Kŭhistoni Badakhshon); Moldova's `MD-SN` is Transnistria; Bender is the official name (historically Tighina). Moldovan names keep the Romanian diacritics (Căușeni, Șoldănești, Ștefan Vodă) and Turkmen names their letters (Daşoguz).

Local names:

- **Georgia:** Georgian without the word for region (გურია, as ISO's reference names), აფხაზეთი, აჭარა, თბილისი.
- **Tajikistan:** Tajik Cyrillic with вилояти (Вилояти Хатлон, Вилояти Мухтори Кӯҳистони Бадахшон), Ноҳияҳои тобеи ҷумҳурӣ, Душанбе.
- **Turkmenistan:** Turkmen Latin with welaýaty (Ahal welaýaty), Aşgabat.
- **Moldova:** Romanian names are identical to the English ones except Găgăuzia and Stînga Nistrului (ISO's form for Transnistria).
- **Andorra, Liechtenstein:** Catalan and German names are identical. **San Marino:** Città di San Marino; the other castelli are identical.

Group local names: მხარეები, ავტონომიური რესპუბლიკები, დედაქალაქი; Вилоятҳо, Вилояти мухтор, Пойтахт; Welaýatlar, Paýtagt; Raioane, Municipii, Unități teritoriale autonome; Parròquies; Gemeinden; Castelli. Collection local names: საქართველო, Тоҷикистон, Türkmenistan, Moldova, Andorra, Liechtenstein, San Marino.

### How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`; all 87 matched, `AD-07` twice: the parish rather than the city was used). The flag (P41) was read from the preferred statement, or else from a normal statement without an end date; deprecated statements were ignored.
2. These were compared with the flags in the English and local-language Wikipedia infoboxes (Georgian, Tajik, Turkmen, Romanian, Catalan, German, Italian, plus Russian, Spanish and French where useful) and with the Commons categories of subdivision flags. Status and design were checked against Flags of the World (FOTW), which has a page for every Moldovan district, Liechtenstein municipality, Andorran parish and San Marino castello, and against official sources: Moldovan presidential decrees and National Heraldry Commission decisions (as published in Monitorul Oficial and collected by the Russian Centre of Vexillology and Heraldry, heraldicum.ru), San Marino's Decree 40/1997 and Delegated Decree 98/2023, and the Tbilisi city hall's symbols page.
3. A flag is shown only if the subdivision's own government adopted it, or clearly uses it as its flag, and only in its current design. Proposals, logo flags without official status, reconstructions and superseded designs are not shown. Every chosen flag was inspected on contact sheets, before and after conversion, side by side with FOTW's drawings.

Each flag is Wikimedia Commons' PNG render of the SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette (median cut, no dithering). The alpha channel is kept whenever a render is not fully opaque (13 files, only at anti-aliased edges and stripe seams); opaque pixels stay fully opaque. Three renders had one fully transparent row or frame from thumbnail rounding (Cantemir, Cimișlia, Orhei); it was trimmed. Nine of the chosen files are raster images and were converted the same way from the original file: Bălți (3001 px, reduced) and eight small Moldovan district files that were not enlarged: Căușeni (448 px), Ialoveni and Ocnița (225 px), Drochia, Fălești, Nisporeni, Șoldănești and Ștefan Vodă (195 px). Where an SVG and a raster of the same design exist, the SVG is used. Balzers' file was recoloured on Commons in June 2026 ("CH palette"); Commons' render of its original 2009 version is used, so that Balzers matches the identical flag of Gamprin and the other ten files by the same author. Artwork is unchanged.

Every file's author, source page and licence ship in `GeorgiaFlagCredits.json` (`GEFlagCredits.json` here), `MoldovaFlagCredits.json` (`MDFlagCredits.json`) and `LiechtensteinFlagCredits.json` (`LIFlagCredits.json`). Tajikistan, Turkmenistan, Andorra and San Marino use only their national flags, which are already credited in `WorldFlagCredits.json`.

### Notes by collection

- **Georgia (2 of 12).** Adjara shows the flag set by the Supreme Council of Adjara's law of 20 July 2004 (seven blue and white stripes, the Georgian flag in the canton over three stripes, as FOTW describes it). Tbilisi shows the city flag published by the city hall (white, a blue cross fimbriated gold, the city arms on red, seven gold stars), which the Commons file matches. The nine regions have no flags: FOTW lists none, no Wikipedia shows one, and Commons has only files titled "Fictional flag of …". The Autonomous Republic of Abkhazia has adopted no flag; its government uses Georgia's flag (English Wikipedia, citing the government's site, and Georgian Wikipedia). Wikidata's P41 for `GE-AB`, File:Flag of Abkhazia (GE).svg, is the State Council of Heraldry's 2013 proposal (labelled a proposal on FOTW and Commons); the flag of the self-declared Republic of Abkhazia is not used either.
- **Tajikistan.** No official flags. FOTW states that Gorno-Badakhshan has no flag other than the national one; the only Commons "Flag of Gorno-Badakhshan" is tagged fictitious. Dushanbe has arms but no flag.
- **Turkmenistan.** No official flags; FOTW's regional page shows only city emblems, and the Russian Wikipedia's "flag" of Ashgabat is a logo.
- **Moldova (34 of 37).** District flags were adopted by the district councils and approved by the National Heraldry Commission (2004–2021); they were entered in the General Armorial (published in Monitorul Oficial on 6 March 2015; for Soroca, heraldicum.ru cites Commission decision 304-IV.01 of 23 December 2014) or registered by presidential decree (Basarabeasca, Cimișlia, Dondușeni and Telenești 2015; Glodeni 2016; Cantemir, Criuleni and Orhei 2017; Florești 2019; Taraclia 2021). Current designs are used where a district replaced its flag: Cantemir (swan, 2016), Criuleni (chimney on a red wedge, 2017; the Russian Wikipedia's file is the 2009 flag), Orhei (white with a red cross and the new arms, 2017; the 2004 lime-green flag is not used), Glodeni (the aurochs head in yellow, as registered in 2016), Florești (2019) and Taraclia (2021). Căușeni is shown in the district council's own rendering, the only adequate file. Bălți shows the flag adopted in 2006, Chișinău the updated flag of 2019 (three yellow stripes, arms without crown; registered by Decree 1475-VIII of 2 March 2020, replacing the 1998 flag), and Gagauzia the flag of its law of 31 October 1995. Briceni District had no flag of its own (FOTW) until Decree 721-X of 7 August 2026 registered one (red, two yellow swords in saltire, a cross crosslet, a white book and apple blossoms); no artwork exists yet, so it shows the national flag. The town of Briceni's chequered flag, shown for the district on English Wikipedia, is not used. Bender's city flag (yellow over black, with the restored 1826 arms) was adopted on 25 September 2003 by the city council under Transnistrian administration; to stay de jure it is not shown. Transnistria has no flag as a Moldovan unit, and the Pridnestrovian state flag is not used. Several 2025 Commons redraws (by GaelVector and AlmePond) were compared with the decrees and FOTW before use; they match.
- **Andorra.** No parish has an official flag. Each comú flies a white flag with its logo or emblem and name (FOTW, from 2023 photos), but no adoption of these logo flags was found, so, as with logo flags in earlier batches, all seven show the national flag. Free artwork exists only for Andorra la Vella's (File:Logo flag of Andorra la Vella.svg); it is not used. The blue-yellow-red "Hypothetical flag of …" files on Wikidata and the Wikipedias are FOTW reconstructions from 2009 that FOTW now marks as non-existent.
- **Liechtenstein (11 of 11).** Municipal colours were granted with the arms by princely decree (Triesen's use is regulated by a 2015 municipal regulation). The flags are shown in the vertical hanging form actually flown (1:4), as on Wikidata, the English and German Wikipedias and FOTW, whose contributor documented them in 2009. FOTW notes that the horizontal striped versions on Commons are not used in reality; landscape forms in use are banners of the arms (Eschen, Mauren, Schaan, Triesen, Triesenberg, Vaduz) and Planken's white-over-green flag with a star, and of these only Triesen's has accurate free artwork.
- **San Marino.** Castello flags (white over azure, the castello's arms in the centre and its name along the hoist) were authorised by Decree no. 40 of 28 March 1997. Delegated Decree no. 98 of 27 June 2023 (ratified 14 September 2023), which sets the castelli's official arms and their gonfaloni, repealed it and defines no flag; castelli display the national flag beside their gonfalone. All nine show the national flag, as with Osun State's repealed flag law. The 2025 Commons redraws of the 1997 flags used by Wikidata and English Wikipedia are not used.

### National flag fallbacks

| Places | Note shown |
| --- | --- |
| Georgia: 9 regions | "The national flag is shown; <Name> has no official flag." |
| Georgia: Abkhazia | "The national flag is shown; the Autonomous Republic of Abkhazia has no official flag." |
| Tajikistan: all 5 | "Tajikistan's regions and capital have no official flags; the national flag is shown." |
| Turkmenistan: all 6 | "Turkmenistan's regions and capital have no official flags; the national flag is shown." |
| Moldova: Briceni | "The national flag is shown; no artwork of Briceni District's flag (adopted in 2026) is available." |
| Moldova: Bender | "The national flag is shown; Bender's flag (2003) was adopted under the Transnistrian administration, which Moldova does not recognise." |
| Moldova: Transnistria | "The national flag is shown; Transnistria has no official flag as a territorial unit of Moldova." |
| Andorra: all 7 parishes | "Andorra's parishes have no official flags; the national flag is shown." |
| San Marino: all 9 castelli | "San Marino's castelli have had no official flags since 2023; the national flag is shown." |

### Licences

Most files are public domain, usually as official symbols (PD-MD-exempt, PD-GE-exempt, PD-Flag-Liechtenstein). The credits name the author and licence for every file; these licences require attribution:

| Licence | Files |
| --- | --- |
| CC BY-SA 3.0 | 2 (Tbilisi; Hîncești, which reuses Asqueladd's CC BY-SA 3.0 drawing of the bow and arrow) |
| CC BY-SA 4.0 | 1 (Soroca, which carries both a public-domain tag and the uploader's CC BY-SA 4.0 licence) |
| CC BY-SA 2.5 | 1 (Gagauzia, likewise dual-tagged) |

The remaining 43 are public domain. Leova, Taraclia and Telenești were drawn after district-council images that a Commons uploader tagged CC BY-SA 4.0; the drawings themselves are tagged only as Moldovan official symbols, so they are credited as public domain.

### Files

- Catalog data: `GE.json`, `TJ.json`, `TM.json`, `MD.json`, `AD.json`, `LI.json`, `SM.json`.
- Flags: 47 PNGs named `<cc>_flag_<code suffix>` (for example `ge_flag_aj`, `md_flag_cu`, `li_flag_01`). The 40 fallback places use the existing `world_flag_ge`, `world_flag_tj`, `world_flag_tm`, `world_flag_md`, `world_flag_ad` and `world_flag_sm` assets. `flags/alternates/` holds two unused renders: Andorra la Vella's logo flag and Triesen's landscape banner of the arms (File:Flag of Triesen Liechtenstein-boa2.svg, Mevsfotw, public domain).
- Credits: `GEFlagCredits.json`, `MDFlagCredits.json`, `LIFlagCredits.json` (the other four are empty arrays).

## Zambia, Zimbabwe, Mozambique, Cameroon and Botswana

Retrieved 16 October 2026. No place in these five collections has freely licensed, accurate artwork of an official flag, so every place shows its national flag with a note. No subdivision artwork is bundled and no credits file is needed. No flag was drawn, recoloured or edited for the app.

### Catalog scope

Every collection uses ISO 3166-2 codes as permanent IDs (`<country>-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_<cc>`) as the collection flag. Group IDs are `<country>-<slug>` and are display data only. The code lists were checked against the change history of each ISO 3166-2 entry (ISO Online Browsing Platform, as summarised on English Wikipedia and in the iso3166-updates change log, current to August 2026) and against the Debian iso-codes list. All 57 codes match the expected counts, and each matches exactly one Wikidata item by P300.

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| Zambia (`ZM`) | 10 | The ten provinces, including Muchinga (`ZM-10`, announced in 2011 and added by ISO in 2014). |
| Zimbabwe (`ZW`) | 10 | The eight provinces, and the metropolitan provinces of Bulawayo (`ZW-BU`) and Harare (`ZW-HA`) in a group of their own. |
| Mozambique (`MZ`) | 11 | The ten provinces, and the capital, Maputo (`MZ-MPM`), a city with provincial status, in a group of its own. Maputo Province is `MZ-L`. |
| Cameroon (`CM`) | 10 | The ten regions. |
| Botswana (`BW`) | 16 | The ten districts, and the two cities and four towns that are administrative districts of their own (Francistown, Gaborone, Jwaneng, Lobatse, Selebi-Phikwe, Sowa Town) in a second group. |

Scope decisions and differences from current law:

- **Botswana.** ISO 3166-2:BW has not changed since 29 October 2014 (Chobe restored, the cities and towns added; a code-source correction followed in 2020). Local government was reorganised in 2022–23: the former sub-district councils became full district councils (for example Serowe, Palapye, Mahalapye, Tutume, Boteti, Bobirwa and Tonota in Central District; Kanye, Goodhope, Mabutsane and Moshupa in Southern District). The government's directory of local authorities (October 2026) lists 26 district councils besides the 2 city and 4 town councils, and has no council for the whole of Central, Southern or Kgalagadi District, but it still files every council under the ten districts and the urban areas. ISO, that directory and Statistics Botswana's census districts all still use the ten districts, so the collection keeps them. More district councils are under consultation (the minister named Okavango West, Kweneng South, Nata, Tswapong and Mmadinare in February 2026). If ISO ever replaces the districts with the councils, this collection will need rework. Orapa, a separate census district that English Wikipedia counts as a town, has no town council and no ISO code, and is not listed.
- **Zimbabwe.** Section 267 of the 2013 Constitution names Bulawayo and Harare as metropolitan provinces; they form their own group. Harare Metropolitan Province is larger than the City of Harare: it also contains Chitungwiza, Epworth and Ruwa. Bulawayo Metropolitan Province covers the City of Bulawayo. A ZANU-PF conference resolution of October 2024 asked the government to replace the colonial-era province names (Manicaland, the Mashonalands, the Matabelelands); no new names have been proposed or enacted.
- **Mozambique.** The City of Maputo has provincial status and is listed in a Capital group, as in the Belarus and Armenia collections. The 2018 decentralisation (elected provincial governors and assemblies, state secretaries) left the provinces unchanged.
- **Zambia, Cameroon.** Current ISO lists, unchanged. Zambia's 2025 constitutional amendment and the 70 new constituencies of April 2026 concern Parliament only; calls for an eleventh "Kafue" province were not taken up. Cameroon's provinces became regions in 2008, and the Northwest and Southwest have had a special status since December 2019; the territorial administration ministry's December 2025 call for proposals concerns new departments and arrondissements, not regions.

### Names

English names follow English Wikipedia, without type words that the group or label already gives ("Copperbelt" for Copperbelt Province, "Manicaland" for Manicaland Province, "Kweneng" for Kweneng District). The type word is kept for Maputo Province (beside the city of Maputo) and for Sowa Town, the name used by ISO, Statistics Botswana and the Sowa Town Council (English Wikipedia's article is "Sowa"). Where ISO spells a name differently, English Wikipedia's form is used: Zambezia (ISO lists the Portuguese Zambézia), Adamawa (ISO's English list keeps Adamaoua), Northwest and Southwest in Cameroon (ISO and the English text of Cameroon's constitution write North-West and South-West; English Wikipedia gives these as alternatives), North-East, North-West and South-East in Botswana (ISO dropped the hyphens in 2014), and Selebi-Phikwe (ISO: Selibe Phikwe). Zambia's North-Western keeps its hyphen in both.

Local names:

- **Zambia, Zimbabwe, Botswana:** English is the official language (in Zimbabwe, the language of administration among 16 official languages), so no local names are given. The collections' local names are Zambia, Zimbabwe and Botswana.
- **Mozambique:** Portuguese where it differs: Zambézia and Província de Maputo; the other provinces and Maputo are spelled the same. The collection's local name is Moçambique and the provinces group's is Províncias.
- **Cameroon** (as integrated: the English-speaking Northwest and Southwest have no French local name in the app, so the local-language view keeps their own names; the other eight show the French forms below). English and French are both official nationwide, and French is the majority administrative language, so the French name is given wherever it differs, for all ten regions, as the Canada collection does: Adamaoua, Est, Extrême-Nord, Nord, Nord-Ouest, Ouest, Sud and Sud-Ouest (Centre and Littoral are the same). The collection's local name is Cameroun and the group's is Régions.

### How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`; all 57 codes matched once). Only three items have a flag (P41): Maputo, Gaborone and Francistown. `ZW-BU` and `ZW-HA` match the province items, which have none; the separate city items for Bulawayo and Harare carry the city flags.
2. These were compared with the flags in the English Wikipedia infoboxes (and the French ones for Cameroon, the Portuguese ones for Mozambique) and with the Commons categories of subdivision and municipal flags. Status was checked against Flags of the World (FOTW), which has no provincial or regional flag for Zambia, Zimbabwe, Mozambique or Cameroon and only municipal and council flags for Botswana, and against government websites and news reports.
3. Every candidate file's source and upload history was traced. Files copied from non-free sources were rejected even where Commons tags them as free, and neither Mozambican nor Botswana copyright law has an exemption for official emblems that would make such copies public domain. The comparison sheets (Botswana Commons files against Vexilla Mundi and FOTW, the versions of the Maputo file, and the rejected candidates) were inspected before deciding.

Had a flag qualified, it would have been processed as in the earlier batches (Commons' PNG render of the SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette). No file reached that step.

Zambia, Zimbabwe, Mozambique, Cameroon and Botswana use only their national flags, which are already credited in `WorldFlagCredits.json`.

### Notes by collection

- **Zambia.** The provinces are administered by provincial ministers and have no flags. The Commons category "Flags of provinces of Zambia" holds only own-work designs uploaded in 2022 (by Here37 and 7bdIa9, with a Copperbelt variant by Ethelium), which Commons itself tags as special or fictional flags; they are not used.
- **Zimbabwe.** The provinces have no flags. The City of Harare (flag adopted after the city was renamed in 1982) and the City of Bulawayo (flag adopted after its 1943 grant of arms) have official municipal flags, and Commons has free artwork of both (`Flag of Harare.svg`, `Flag of Bulawayo.svg`, public domain). They are not used, because the places in this collection are the metropolitan provinces, which are headed by Ministers of State for Provincial Affairs and Devolution, not by the city councils; this follows Sofia City Province in Bulgaria. Harare Metropolitan Province also includes Chitungwiza, Epworth and Ruwa, which have councils of their own (Chitungwiza also has its own flag). The 2025 Commons upload "Flag of Manicaland.jpg" is the flag of the City of Mutare, taken from a site that names it so.
- **Mozambique.** The provinces have no flags; "Bandeira Cabo Delgado.png" (2008, own work, unsourced) resembles the flag of Tanzania and is not used. The City of Maputo has an official municipal flag (the municipal emblem on a light green field with a yellow fimbriation and a dark green border, per FOTW). Its only Commons file, "Flag of Maputo.png", was overwritten in 2022 first with FOTW's 2016 drawing by Jens Pattke (pixel-identical at 324 pixels) and then with a 1,620-pixel enlargement of it, both still under the original 2006 uploader's own-work licence; the 2006 drawing itself is inaccurate (bright greens, a thin yellow line instead of the broad yellow fimbriation, and a small, low-resolution emblem). With no freely licensed artwork, Maputo shows the national flag.
- **Cameroon.** No regional flag was found on FOTW, Wikidata, the English or French Wikipedia, or Commons. The regional councils elected since 2020 use logos (for example the round seal in the West Regional Council's visual identity charter, published in 2021). Ambazonian separatist flags are not regional flags.
- **Botswana.** FOTW documents council flags for Gaborone (light blue with the city arms, flown at the Civic Centre in 2001), Francistown, Jwaneng, Lobatse and Selebi-Phikwe, but none has free artwork. The five Commons files for Francistown, Jwaneng, Lobatse, Selebi Phikwe and Sowa Town (uploaded in 2024 as CC0 and credited to FOTW contributors) are byte-identical copies of Vexilla Mundi's images, which that site allows only on non-commercial websites. "Flag of Gaborone.svg" (2023, tagged PD-Botswana with the city council as source) is an automatic trace of Vexilla Mundi's Gaborone image: its canvas is that image's 540 × 360 pixels and its render matches it almost pixel for pixel. Wikidata records the Francistown and Gaborone files and English Wikipedia's infoboxes show all six; none is used. For the districts, FOTW reported in 2024 a yellow Kgatleng District Council flag and a white Ghanzi flag with the council emblem, without artwork; Vexilla Mundi's other district "flags" are council logos on plain fields (Ghanzi's still carries a toll-free telephone number) with no evidence of use. Sowa Town's flag is known only from Vexilla Mundi.

### National flag fallbacks

| Places | Note shown |
| --- | --- |
| Zambia: all 10 provinces | "Zambia's provinces have no official flags; the national flag is shown." |
| Zimbabwe: 8 provinces | "The national flag is shown; <Name> Province has no official flag." |
| Zimbabwe: Bulawayo, Harare | "The national flag is shown; <Name> Metropolitan Province has no official flag." (the city flags belong to the city councils) |
| Mozambique: 10 provinces | "Mozambique's provinces have no official flags; the national flag is shown." |
| Mozambique: Maputo | "The national flag is shown; no freely licensed artwork of Maputo's flag is available." |
| Cameroon: all 10 regions | "Cameroon's regions have no official flags; the national flag is shown." |
| Botswana: Central, Chobe, Kgalagadi, Kweneng, North-East, North-West, South-East, Southern | "The national flag is shown; <Name> District has no documented flag in use." |
| Botswana: Ghanzi, Kgatleng | "The national flag is shown; no artwork of the <Name> District Council's flag is available." |
| Botswana: Francistown, Gaborone, Jwaneng, Lobatse, Selebi-Phikwe | "The national flag is shown; no freely licensed artwork of <Name>'s flag is available." |
| Botswana: Sowa Town | "The national flag is shown; Sowa Town has no documented flag in use." |

### Licences

No subdivision artwork is bundled, so there is nothing to credit beyond the national flags in `WorldFlagCredits.json`.

### Files

- Catalogs (to be written): `jpex/Places/Countries/ZambiaCatalog.swift` (`zambia`), `ZimbabweCatalog.swift` (`zimbabwe`), `MozambiqueCatalog.swift` (`mozambique`), `CameroonCatalog.swift` (`cameroon`) and `BotswanaCatalog.swift` (`botswana`).
- Flags: none. All 57 places use the existing `world_flag_zm`, `world_flag_zw`, `world_flag_mz`, `world_flag_cm` and `world_flag_bw` assets.
- Credits: none.

## Nicaragua, Haiti, Trinidad and Tobago, Guyana, Suriname, Belize, Samoa, Vanuatu, Tonga and Solomon Islands

Retrieved 16 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

### Catalog scope

Every collection uses ISO 3166-2 codes as permanent IDs (`<country>-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_<cc>`) as the collection flag. Group IDs are `<country>-<slug>` and are display data only. The code lists were checked against the change history of each ISO 3166-2 entry (as summarised on English Wikipedia), Debian's iso-codes data (updated October 2025) and the iso3166-updates dataset (maintained to 2026). All ten match the expected counts, and every code matched exactly one Wikidata item through `haswbstatement:P300`.

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| Nicaragua (`NI`) | 17 | The 15 departments and the two autonomous regions, North Caribbean Coast (`NI-AN`) and South Caribbean Coast (`NI-AS`), each kind in its own group. |
| Haiti (`HT`) | 10 | The ten departments, including Nippes (`HT-NI`, added by ISO in 2007). |
| Trinidad and Tobago (`TT`) | 15 | The 14 municipal corporations of Trinidad, grouped as the Municipal Corporations Act does: cities (2), boroughs (5) and regional corporations (7), and Tobago (`TT-TOB`) on its own. |
| Guyana (`GY`) | 10 | The ten administrative regions. |
| Suriname (`SR`) | 10 | The ten districts. |
| Belize (`BZ`) | 6 | The six districts. |
| Samoa (`WS`) | 11 | The eleven districts (itūmālō). |
| Vanuatu (`VU`) | 6 | The six provinces. |
| Tonga (`TO`) | 5 | The five divisions (`TO-01` to `TO-05`). |
| Solomon Islands (`SB`) | 10 | The nine provinces and the Capital Territory, Honiara (`SB-CT`), in a group of its own. |

Scope decisions and differences from the current ISO list:

- **Trinidad and Tobago.** Diego Martin (`TT-DMN`) and Siparia (`TT-SIP`) have been boroughs since 20 June 2023 (Act No. 6 of 2023, which turned the two regional municipalities into the Borough of Diego Martin and the Borough of Siparia). ISO still calls both "region"; they are grouped with the boroughs, with their ISO codes as IDs. The Municipal Corporations (Amendment) Bill 2026, introduced on 7 October 2026, would make Chaguanas a city, create boroughs at Barataria, Couva, St. Augustine and Sangre Grande and rename two regional corporations; it is not law yet. Tobago's self-government amendment failed in December 2024.
- **Nicaragua.** Wikidata's items for the two regions also carry the codes `NI-CN` and `NI-CS` (normal rank), and a Spanish copy of the ISO table uses them, but ISO has kept `NI-AN` and `NI-AS` since renaming the regions Costa Caribe Norte and Costa Caribe Sur in 2018. The 2025 constitutional reform did not change the departments, and the proposed department of Zelaya Central has not been created.
- **Solomon Islands.** ISO added Choiseul (`SB-CH`) and Rennell and Bellona (`SB-RB`) only in 2007, years after they were split off Western and Central provinces; `SB-CT` is the Capital Territory, not Central Province (`SB-CE`).
- **Guyana.** Venezuela claims the land west of the Essequibo River (its "Guayana Esequiba"). The regions are listed as ISO lists them, as the Venezuela collection already omits Guayana Esequiba.
- **Haiti, Suriname, Belize, Samoa, Vanuatu, Tonga.** Current ISO lists, unchanged; no reform was found through October 2026. Haiti's 2025 draft constitution would replace departmental delegates with governors, with no reported change to the departments, and had not been adopted.

### Names

English names follow English Wikipedia, without the type word the group or label gives ("Boaco" for Boaco Department, "North Caribbean Coast" for the North Caribbean Coast Autonomous Region, "Cayo" for Cayo District). The type word is kept for Belize District (beside the country and Belize City) and for Central Province and Western Province in the Solomon Islands (as for Papua New Guinea). Other choices:

- **Haiti:** English Wikipedia titles the departments with their French names, so these are the English names (Nord-Ouest, Sud-Est, Grand'Anse; ISO has spelled `HT-GA` Grande’Anse since 2015).
- **Trinidad and Tobago:** English Wikipedia's en dashes (Couva–Tabaquite–Talparo, Mayaro–Rio Claro, Penal–Debe, San Juan–Laventille, Tunapuna–Piarco); Guyana keeps the plain hyphens of its article titles (Barima-Waini).
- **Samoa and Tonga:** the ʻokina as in English Wikipedia (Aʻana, Faʻasaleleaga, Gagaʻifomauga, Satupaʻitea, Vaʻa-o-Fonoti, ʻEua, Haʻapai, Vavaʻu), where ISO uses an ASCII apostrophe. Tonga's `TO-03` is Niua Islands, English Wikipedia's article for the division (ISO: Niuas).
- **Solomon Islands:** the Capital Territory is Honiara (English Wikipedia's "Capital Territory (Solomon Islands)" redirects there).

Local names are stored only where they differ from the English name:

- **Nicaragua:** Spanish. The department names are the same; the regions are Costa Caribe Norte and Costa Caribe Sur (ISO's names). Groups: Departamentos, Regiones autónomas.
- **Haiti:** Haitian Creole throughout (Latibonit, Sant, Grandans, Nip, Nò, Nòdès, Nòdwès, Lwès, Sid, Sidès; Ayiti; Depatman), as listed by ISO. French and Creole are both official and ISO gives both, but the English names are already the French forms, so French local names would all be empty. Creole is the only form that adds information, as with Montenegro's Cyrillic in batch A.
- **Vanuatu:** the French forms Pénama, Shéfa and Taféa, which ISO gives as the official names (English Wikipedia and Bislama write them without accents).
- **Tonga:** Ongo Niua for the Niua Islands, the name used by English Wikipedia's list of divisions and by the Tonga Statistics Department's census tables.
- **Samoa:** the names are Samoan already; the collection and group are Sāmoa and Itūmālō. **Suriname:** the Dutch names are the same; the group is Distrikten.
- **Trinidad and Tobago, Guyana, Belize, Solomon Islands:** English is the official language; no local names. Country local names: Nicaragua, Ayiti, Sāmoa; the others as in English.

### How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`; all 100 codes matched once). The flag (P41) was read from the preferred statement, or else from a normal statement without an end date. Wikidata records flags for the six Vanuatu provinces, all ten Solomon Islands entries, Arima, Nickerie, both Nicaraguan regions and 13 Nicaraguan departments.
2. These were compared with the flags in the English and local-language Wikipedia infoboxes and with the Commons categories of subdivision flags. Status was then checked against Flags of the World (FOTW), Vexilla Mundi, Marc de Haeck's flag site, official gazettes, government websites and archived pages, and news photographs. A flag is shown only if the subdivision's own government adopted it or clearly uses it as its flag. Flags of capital cities, proposals and fan designs are not shown.
3. The artwork had to show the current design and carry a free licence. Where it does not, the national flag is shown with a note. Every candidate was inspected on contact sheets beside FOTW's drawings and, where available, photographs (Malaita 2024, Torba 2015, Malampa 2014, Tafea 2018, the Solomon Islands Broadcasting Corporation's 2010 images of all ten Solomon Islands flags), and the installed flags were inspected after conversion.

Each flag is Wikimedia Commons' PNG render of the SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette. The alpha channel is kept whenever a render is not fully opaque; here that is four files, all only at the edges (a partly covered last row from thumbnail rounding for South Caribbean Coast, Malampa and Tafea, which also has anti-aliased side edges; stray transparent pixels near the left edge of the Honiara source, nearly opaque after resizing). Malaita's render had one fully transparent row at the bottom (960×481 from a 2:1 SVG), which was trimmed. Five of the chosen files are raster PNGs by Juergen Krause (Choiseul, Isabel, Makira-Ulawa, Western Province and Honiara, 2436 to 2596 pixels wide) and were converted the same way from the original file. Artwork is unchanged.

Every file's author, source page and licence ship in `NIFlagCredits.json`, `VUFlagCredits.json` and `SBFlagCredits.json` (to be renamed `NicaraguaFlagCredits.json`, `VanuatuFlagCredits.json` and `SolomonIslandsFlagCredits.json` in the app). Haiti, Trinidad and Tobago, Guyana, Suriname, Belize, Samoa and Tonga use only their national flags, which are already credited in `WorldFlagCredits.json`.

### Notes by collection

- **Nicaragua (2 of 17).** The North Caribbean Coast's flag was created by Resolution 11-29-11-2002 of the Regional Autonomous Council of the Atlántico Norte (La Gaceta No. 19, 28 January 2003): three equal horizontal stripes of brown, green and blue with the map of the region in the centre bearing the regional arms, proportion 3:5. Wikidata's SVG follows that description; its map is smaller than in the image the region published in 2004, which the resolution does not fix, and the arms still read "Región Autónoma del Atlántico Norte", the name before 2016. The South Caribbean Coast's flag (red hoist triangle; blue, white and green; six gold stars) has no adopting resolution that could be found, but the regional council used it: FOTW recorded it in 2009 on the regional government's server and with the council's logo on the presidency's Caribbean Coast Development Council website. The departments have no government of their own and no law gives them flags. Their Commons and Wikidata flags (mostly 2010 own-work SVGs, also in English Wikipedia's infoboxes) are those of the departmental capitals: Jinotepe's for Carazo, Juigalpa's for Chontales, Somoto's for Madriz, the city flags or arms of Managua, León, Masaya, Matagalpa, Nueva Segovia and Rivas, and Jinotega's municipal flag; the tricolours for Boaco, Chinandega, Estelí and Granada have no documented adoption.
- **Trinidad and Tobago.** Every municipal corporation flies a flag with its emblem (FOTW, with photographs of all fourteen at the Ministry of Rural Development and Local Government's 2017 orientation seminar), and the Tobago House of Assembly flies a light-blue flag with its seal. None has freely licensed artwork. The five Commons PNGs of 2022 (Arima, Chaguanas, Couva–Tabaquite–Talparo, Diego Martin, Mayaro–Rio Claro), one of them on Wikidata, are tagged {{Wrong license}} because they copy the corporations' emblems. "Flag of Tobago" on Commons is the flag of a 1977 independence movement, and "Bandera de la isla de Tobago" is a 2022 proposal.
- **Vanuatu (3 of 6).** The provincial governments fly their flags at their offices and provincial days (Michel Lupant's survey in *Gaceta de Banderas* 110, Daily Post photographs of 2013–2015, a 2018 photograph on Commons; Vexilla Mundi and de Haeck have the same designs). Shown: Malampa (Wikidata's SVG as redrawn in 2022 after de Haeck; FOTW notes variants with smaller symbols and four-pointed stars), Shefa, and Tafea (Wikidata's SVG, drawn from the 2018 photograph; the older light-blue files with white stars are superseded). Penama's Commons files have white stars, where FOTW, Vexilla Mundi and de Haeck show yellow ones; Commons has only Sanma's nine-star flag, which has had twelve stars since 2013; Torba's only file has a dark blue field and a different emblem centred over the stripes, while a 2015 photograph at the provincial headquarters, Vexilla Mundi and de Haeck show light blue with the emblem in the lower yellow field. These three show the national flag. The Commons descriptions of the Malampa and Torba PNGs are swapped.
- **Solomon Islands (8 of 10).** The provincial governments use their flags (Ministry of Provincial Government publications, provincial days, the Solomon Games); the Solomon Islands Broadcasting Corporation's 2010 election pages showed all ten, and Krause's 2011 drawings follow them. Malaita shows its current flag without the national flag in the canton, flown with the Prime Minister at the province's Second Appointed Day on 15 August 2024 (Island Sun photograph); the earlier flag with the canton is superseded, which settles the "fact disputed" tags on both Commons files. Choiseul's bird faces the hoist on Commons and in some 2023 photographs, the fly in others; Rennell and Bellona's team carried a variant at the 2023 Games while the established flag hung over the podium. Honiara shows the Honiara City Council's flag (its seal on white), as on the 2010 broadcaster pages and matching the council's current logo; Wikidata and English Wikipedia show a "City of Honiara / National Capital" version known only from an unsourced 2010 FOTW drawing, which is not used. Central Province's Commons files all show an emblem with a masked figure and a turtle, which FOTW calls a wrong report (the 2013 provincial policy statement shows six six-pointed stars and an emblem with a shield, spears and the letters C and P). Guadalcanal's provincial government uses a brown flag with a black-and-white emblem (newsletters, 2023 Games, its Facebook page in 2024); Commons has only the older olive-green version with a coloured emblem. Both show the national flag.
- **Guyana.** In 2017 the Ministry of Communities put sample regional flags to the regional councils for consultation; none was adopted, and nothing more was heard of the project after 2019. FOTW shows them as flag concepts, and the one Commons copy (Barima-Waini) is not used.
- **Suriname.** Districts are run by commissioners of the Ministry of Regional Development and have no adopted flags. FOTW records a Commewijne concept (2004, awaiting approval, no later news), a "District Para" logo banner reported as a proposal (2009), Wanica logo flags on social media, and a Nickerie flag known only from a local website; the Commons Nickerie files (on Wikidata) are not used.
- **Haiti, Belize, Samoa, Tonga.** No official subdivision flags. Haiti: FOTW and Commons have only commune flags (Cap-Haïtien, Delmas, Les Cayes, Pétion-Ville and others). Belize: the districts have no governments; the flags on Commons and FOTW belong to the city and town councils. Tonga: FOTW's only entry is a flag for the island of Niuafoʻou taken from a fan wiki.

### National flag fallbacks

| Places | Note shown |
| --- | --- |
| Haiti: all 10 departments | "Haiti's departments have no official flags; the national flag is shown." |
| Guyana: all 10 regions | "Guyana's regions have no official flags; the national flag is shown." |
| Suriname: all 10 districts | "Suriname's districts have no official flags; the national flag is shown." |
| Belize: all 6 districts | "Belize's districts have no official flags; the national flag is shown." |
| Samoa: all 11 districts | "Samoa's districts have no official flags; the national flag is shown." |
| Tonga: all 5 divisions | "Tonga's divisions have no official flags; the national flag is shown." |
| Nicaragua: 15 departments | "The national flag is shown; <Name> Department has no official flag." |
| Trinidad and Tobago: 14 municipal corporations | "The national flag is shown; no freely licensed artwork of <Name>'s flag is available." |
| Trinidad and Tobago: Tobago | "The national flag is shown; no freely licensed artwork of the Tobago House of Assembly's flag is available." |
| Vanuatu: Penama, Torba | "The national flag is shown; no accurate artwork of <Name>'s flag is available." |
| Vanuatu: Sanma | "The national flag is shown; artwork for Sanma's current flag (2013) is not available." |
| Solomon Islands: Central Province | "The national flag is shown; no accurate artwork of Central Province's flag is available." |
| Solomon Islands: Guadalcanal | "The national flag is shown; no accurate artwork of Guadalcanal Province's current flag is available." |

### Licences

13 files. Public domain 6 (South Caribbean Coast and the five Solomon Islands rasters by Juergen Krause), CC0 2 (Tafea, Temotu), CC BY-SA 3.0 4 (North Caribbean Coast, Malampa, Shefa, Rennell and Bellona) and CC BY-SA 4.0 1 (Malaita). The CC BY-SA files require attribution, which the credits files give. The North Caribbean Coast file is dual-licensed CC BY-SA 3.0 and GFDL and is credited under CC BY-SA 3.0.

### Files

- **Catalogs (to be written):** `NicaraguaCatalog.swift` (`nicaragua`), `HaitiCatalog.swift` (`haiti`), `TrinidadAndTobagoCatalog.swift` (`trinidadAndTobago`), `GuyanaCatalog.swift` (`guyana`), `SurinameCatalog.swift` (`suriname`), `BelizeCatalog.swift` (`belize`), `SamoaCatalog.swift` (`samoa`), `VanuatuCatalog.swift` (`vanuatu`), `TongaCatalog.swift` (`tonga`) and `SolomonIslandsCatalog.swift` (`solomonIslands`).
- **Flags:** 13 imagesets named `<cc>_flag_<code suffix>`: `ni_flag_an`, `ni_flag_as`, `vu_flag_map`, `vu_flag_see`, `vu_flag_tae`, `sb_flag_ch`, `sb_flag_ct`, `sb_flag_is`, `sb_flag_mk`, `sb_flag_ml`, `sb_flag_rb`, `sb_flag_te` and `sb_flag_we`, each with `flag.png` and the standard `Contents.json`. The 87 fallback places use the existing `world_flag_ni`, `world_flag_ht`, `world_flag_tt`, `world_flag_gy`, `world_flag_sr`, `world_flag_bz`, `world_flag_ws`, `world_flag_vu`, `world_flag_to` and `world_flag_sb` assets.
- **Credits:** the three `*FlagCredits.json` files listed above.
