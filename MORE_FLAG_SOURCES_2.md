# Sixteen more collections, second batch: flag sources

Retrieved 8 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

## Catalog scope

Every collection uses ISO 3166-2 codes as permanent IDs (`<country>-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_<cc>`) as the collection flag. Group IDs are `<country>-<slug>` and are display data only.

| Collection | Places | Contents and grouping |
| --- | --- | --- |
| Ireland (`IE`) | 26 | The 26 counties, grouped by province: Connacht, Leinster, Munster and Ulster (the three Ulster counties in the state). Dublin, Cork, Galway and the other counties with more than one local authority are one place each, as in ISO 3166-2:IE. |
| Sweden (`SE`) | 21 | The 21 counties (*län*), grouped by land: Götaland (9), Svealand (7) and Norrland (5). |
| Denmark (`DK`) | 5 | The five regions. |
| Finland (`FI`) | 19 | The 19 regions (*maakunnat*), including the autonomous Åland Islands (`FI-01`), which the Countries collection shares. |
| Czechia (`CZ`) | 14 | Thirteen regions and the capital, Prague (`CZ-10`). Districts are not included. |
| Croatia (`HR`) | 21 | Twenty counties and the City of Zagreb (`HR-21`). |
| Greece (`GR`) | 14 | The 13 administrative regions, and the autonomous monastic state of Mount Athos (`GR-69`) in its own group. |
| Hungary (`HU`) | 20 | Nineteen counties and the capital, Budapest (`HU-BU`). The 23 cities with county rights lie within their counties and are not listed. |
| Chile (`CL`) | 16 | The 16 regions, listed north to south from Arica y Parinacota to Magallanes, including Ñuble (2018). |
| Colombia (`CO`) | 33 | Thirty-two departments and the Capital District, Bogotá (`CO-DC`). |
| Peru (`PE`) | 26 | Twenty-four departments, the Constitutional Province of Callao and Lima Province (`PE-LMA`), which the Metropolitan Municipality of Lima governs. Lima Region (`PE-LIM`) is the rest of the department of Lima. |
| Türkiye (`TR`) | 81 | The 81 provinces, grouped by the seven geographical regions: Marmara (11), Aegean (8), Mediterranean (8), Central Anatolia (13), Black Sea (18), Eastern Anatolia (14) and Southeastern Anatolia (9). Each province is in the region that holds most of its area, as in the usual table (Wikipedia, *Geographical regions of Turkey*). |
| United Arab Emirates (`AE`) | 7 | The seven emirates. |
| Sri Lanka (`LK`) | 9 | The nine provinces. Districts are not included. |
| New Zealand (`NZ`) | 17 | Sixteen regions grouped by island (North Island 9, South Island 7), and the Chatham Islands Territory (`NZ-CIT`) in its own group. |
| South Africa (`ZA`) | 9 | The nine provinces. |

Places are alphabetical by English name within each group, ignoring accents (so Östergötland files under O and Şanlıurfa under S), except Chile, which runs north to south.

## Names

English names follow Wikidata's English labels and English Wikipedia, without type words that the group already gives: "Central Bohemian" for Central Bohemian Region, "Krapina-Zagorje" for Krapina-Zagorje County, "Stockholm" for Stockholm County. Type words stay where the name needs them: Zagreb County and the City of Zagreb, Denmark's Capital Region, Chile's Santiago Metropolitan Region, Peru's Lima Region and Lima Province, and Sri Lanka's provinces (Western Province), whose names are otherwise bare adjectives. Hungarian county names are the same in English. Turkish province names keep their Turkish letters, as English Wikipedia and ISO 3166-2 do, except Istanbul and Izmir, whose usual English spellings have no dot. Other choices: Skåne (not Scania), Vukovar-Syrmia, Western Greece, San Andrés and Providencia, Wellington (ISO 3166-2's "Greater Wellington" is the regional council's name) and North West (ISO: North-West).

Local names are stored only where they differ from the English name:

- **Ireland:** Irish names in the nominative, without *Contae*, as in the Placenames Database of Ireland (Gaillimh, Baile Átha Cliath, Dún na nGall). Laois is the same in Irish. Province names: Connachta, Laighin, An Mhumhain, Ulaidh.
- **Sweden, Denmark, Czechia, Croatia:** the full county or region names (Stockholms län; Region Hovedstaden; Středočeský kraj, Kraj Vysočina and Praha; Zagrebačka županija and Grad Zagreb).
- **Finland:** Finnish names; Swedish for the Åland Islands (Åland). Kainuu, Kanta-Häme, Kymenlaakso, Päijät-Häme, Pirkanmaa, Satakunta and Uusimaa are the same in English.
- **Greece:** Greek names without *Περιφέρεια*; Mount Athos is Άγιον Όρος.
- **Hungary:** none for places. The group of counties is *Megyék*: Act XLIX of 2026 (Magyar Közlöny no. 131, 11 September 2026), under the 17th amendment of the Fundamental Law, restored *megye* from 1 October 2026, ending the *vármegye* name used since 2023.
- **Chile, Colombia, Peru:** Spanish where it differs: Región Metropolitana de Santiago, La Araucanía, San Andrés y Providencia, Región Lima and Provincia de Lima.
- **Türkiye:** İstanbul and İzmir; region names Ege, Akdeniz, İç Anadolu, Karadeniz, Doğu Anadolu and Güneydoğu Anadolu (Marmara is the same).
- **United Arab Emirates:** Arabic names (أبو ظبي, دبي…). **Sri Lanka:** Sinhala names with පළාත (province).
- **New Zealand:** Māori names as given in the infoboxes and opening lines of the English Wikipedia region articles, checked against Wikidata: Tāmaki Makaurau, Te Tai Tokerau, Te Tairāwhiti, Te Matau-a-Māui, Te Upoko o te Ika a Māui, Waitaha, Te Tauihu-o-te-waka, Whakatū, Ōtākou, Murihiku, Te Tai o Aorere and Te Tai Poutini. Bay of Plenty, which the article does not name, uses Te Moana-a-Toi from Wikidata. Manawatū-Whanganui, Taranaki and Waikato are the same in Māori. The Chatham Islands use Rēkohu, the Moriori name, matching their group; the Māori name is Wharekauri.
- **South Africa:** none.

## How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`), and the flag image (P41) was read from the preferred-rank statement, or else from a normal-rank statement without an end date. Deprecated statements were ignored. `GR-E` also matched a duplicate Thessaly item without a flag, and `PE-CAL` matched both the Callao Region item (no flag) and the Constitutional Province of Callao item.
2. Official status and currency were checked for every collection that needed it: Spanish Wikipedia's *Anexo:Banderas de Chile* and the individual regional flag articles; *Anexo:Banderas del Perú* and the departmental infoboxes; English Wikipedia's *Flag of the United Arab Emirates*, *List of New Zealand flags*, *Flag of the City of Nelson*, *Monastic community of Mount Athos* and *Flag of the Greek Orthodox Church*; Flags of the World (Otago; Sri Lankan provinces); Hungarian Wikipedia's county list; and the Commons file pages, which cite the Finnish regional councils and, for Sweden, the National Archives.
3. Every flag was then inspected on per-country contact sheets for historical designs, coats of arms used in place of flags, wrong proportions, and blank or broken renders.

Each flag is Wikimedia Commons' PNG render of the linked SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette. The alpha channel is kept whenever a render is not fully opaque; apart from anti-aliased edges and seams, only Fejér, North Savo and Satakunta, whose flags have a cut fly, have transparent areas, and Békés's coat of arms is partly translucent in the source artwork. Seven files are raster images (PNG) rather than SVG: Ucayali and six Sri Lankan provinces; they were converted the same way from the original file. Artwork is unchanged.

Some places share one source file and so identical artwork: Cavan and Laois, Donegal and Meath, Galway and Westmeath, Longford and Wicklow, and Sharjah and Ras Al Khaimah. Dubai and Ajman have the same design from separate files.

Every file's author, source page and licence ship in `IrelandFlagCredits.json`, `SwedenFlagCredits.json`, `FinlandFlagCredits.json`, `CzechiaFlagCredits.json`, `CroatiaFlagCredits.json`, `HungaryFlagCredits.json`, `ChileFlagCredits.json`, `ColombiaFlagCredits.json`, `PeruFlagCredits.json`, `UAEFlagCredits.json`, `SriLankaFlagCredits.json` and `NewZealandFlagCredits.json`. Denmark, Greece, Türkiye and South Africa use only the national flag, which is already credited in `WorldFlagCredits.json`.

## Notes by collection

- **Ireland.** Counties have no official flags; the app shows the bicolours and tricolours in each county's GAA colours that are widely flown at matches (see *Unofficial flags and banners of arms*). Most come from one consistent 1:2 set by Walden69 (2006). Cork, Limerick and Waterford use Ricordisamoa's 2:3 files, whose colours are taken from the GAA's own county colours page. Wikidata's statements mix several sets and give Longford the file *Colours of Roscommon* (primrose and blue); Longford and Wicklow show their blue and gold instead. Kildare's colours are plain white, which would read as a blank image, so Kildare shows the national flag.
- **Sweden.** Counties have no adopted flags, but their arms are official and stand for both the county administrative board and the county. The National Archives (*Riksarkivet*), which keeps Sweden's heraldic register, notes that “Varje vapen kan användas i form av en flagga” (any coat of arms can be used as a flag), and Swedish arms are flown as banners, the shield's design filling the cloth. Wikidata records these banners as the flags of 20 counties; each county shows the banner of its arms with the note "Banner of the county's coat of arms." Värmland, which has no flag statement on Wikidata, uses the banner from the same set by Lokal_Profil. Skåne uses the banner drawn from the National Archives' emblazonment by Vladimir A. Sagerlund.
- **Finland.** Thirteen regions have a flag: Åland's official flag, and regional flags (*maakuntaliput*), most of them shown among the regional council's symbols. Eight are banners of the regional arms (South Ostrobothnia, Kainuu, Kanta-Häme, Central Finland, Pirkanmaa, Päijät-Häme, Satakunta and Uusimaa) and carry the note "Banner of the region's coat of arms." Central Ostrobothnia, North Karelia, North Savo and South Savo fly designs based on their arms. Päijät-Häme's flag is upright (3:4), as Vexilla Mundi also shows it; list rows crop it like any other flag. South Karelia, Kymenlaakso, Lapland, Ostrobothnia, North Ostrobothnia and Southwest Finland use regional pennants (*maakuntaviiri*), not flags, and show the national flag. The only Commons “flag of Ostrobothnia” is an unsourced 2025 drawing tagged as a fake SVG and was not used.
- **Czechia, Croatia, Colombia.** Official regional, county and departmental flags as recorded on Wikidata. Sisak-Moslavina and Požega-Slavonia use SVG versions of the PNG files recorded on Wikidata, with the same design. Valle del Cauca's grey border is part of its flag.
- **Hungary.** County flags as recorded on Wikidata and used in Hungarian Wikipedia's list of counties, and Budapest's flag in use since 2011. Csongrád-Csanád's artwork still carries the inscription CSONGRÁD MEGYE from before the county's 2020 renaming; no newer artwork is available. See *Names* for the 2026 change from *vármegye* back to *megye*.
- **Chile.** Seven regions have officially adopted flags: Arica y Parinacota (the regional government's official symbol), Atacama (Regional Council resolution 79, 1996), Coquimbo (2013), Valparaíso (Regional Regulation No. 2, 2000), Los Ríos (2008), Los Lagos (Regional Council agreement No. 20, 2013) and Magallanes (Regional Council resolution 42, published 1997). The other nine regions fly standards of the regional government or the former intendant — the coat of arms or a logo on a plain field — whose status Spanish Wikipedia describes as unofficial or undefined; Wikidata records those standards, but they show the national flag.
- **Peru.** Departmental flags as recorded on Wikidata and in Spanish Wikipedia's list of departmental flags. Apurímac and Callao use SVG files of the same designs as the raster files on Wikidata (Callao's design matches a 2025 photograph of the flag). Cusco shows the rainbow flag with the Sol de Echenique emblem added by Municipal Ordinance 08-2021. Lima Province shows the flag of Lima. Amazonas, Loreto and Lima Region fly their regional governments' flags, which carry the government logo; Wikidata and Spanish Wikipedia record them as the departmental flags. Moquegua shows the departmental tricolour rather than the city flag.
- **United Arab Emirates.** Abu Dhabi, Dubai, Ajman, Sharjah, Ras Al Khaimah and Umm Al Quwain use their emirate flags. Fujairah abolished its red flag in 1975 and uses the national flag; Wikidata's statement points to its 1952–1961 flag.
- **Sri Lanka.** Provincial flags were chosen by a government committee from a public contest (Flags of the World). The Western Province flag is AlexR.L.'s drawing, which shows the roundels as on the Western Provincial Council's own image (bird, lion and serpent from the hoist); the file recorded on Wikidata shows them in mirror order. North Western and Uva use SVG files and North Central a 3,264-pixel public-domain PNG of the same design as the small file on Wikidata. The other provincial flags are raster drawings between 324 and 813 pixels wide, so they are softer than the rest of the collection.
- **New Zealand.** Nelson shows its civic flag, adopted in 1987 by Nelson City Council, which is also the regional authority. The Otago flag chosen in a 2004 competition and the Chatham Islands flag designed in 1989 are unofficial, and the Wellington flag recorded on Wikidata is the city's, not the region's; these places show the national flag.
- **Greece.** The regions have no official flags. Wikidata records the Vergina Sun flag of Greek Macedonia for Central Macedonia and a logo for Western Greece; neither is the region's flag. Mount Athos customarily flies the Byzantine double-headed eagle of the Greek Orthodox Church, which English Wikipedia describes as a custom rather than a written rule; the national flag is shown.
- **Denmark, Türkiye, South Africa.** Every place shows the national flag with one shared note. The flag images that Wikidata records for the five Danish regions and six South African provinces were not used.

## National flag fallbacks

| Places | Note shown |
| --- | --- |
| Denmark: all 5 regions | "Denmark's regions have no official flags; the national flag is shown." |
| Türkiye: all 81 provinces | "Turkey's provinces have no official flags; the national flag is shown." |
| South Africa: all 9 provinces | "South Africa's provinces have no official flags; the national flag is shown." |
| Greece: the 13 regions | "Greece's regions have no official flags; the national flag is shown." |
| Greece: Mount Athos | "The national flag is shown; Mount Athos has no official flag." |
| New Zealand: 15 regions | "The national flag is shown; \<Region\> has no official flag." |
| New Zealand: Chatham Islands | "The national flag is shown; the Chatham Islands have no official flag." |
| Chile: Tarapacá, Antofagasta, Santiago Metropolitan Region, O'Higgins, Maule, Ñuble, Biobío, Araucanía, Aysén | "The national flag is shown; \<Region\> has no official flag." |
| Finland: South Karelia, Kymenlaakso, Lapland, Ostrobothnia, North Ostrobothnia, Southwest Finland | "The national flag is shown; \<Region\> has no official flag." These regions have pennants only. |
| Ireland: Kildare | "The national flag is shown; Kildare has no official flag." Its GAA colours are plain white. |
| United Arab Emirates: Fujairah | "The national flag is shown; Fujairah has used it in place of an emirate flag since 1975." |

In all, 142 places show the national flag and 196 show their own artwork.

## Unofficial flags and banners of arms

- **Ireland (25 counties):** "Unofficial flag in the county's GAA colours." The credits repeat the note.
- **Sweden (21 counties):** "Banner of the county's coat of arms."
- **Finland (8 regions):** "Banner of the region's coat of arms." Wikidata and Commons record these banners as the regions' flags.

## Licences

The credits name the author and licence for every file; these licences require attribution:

| Licence | Files |
| --- | --- |
| CC BY-SA 3.0 | 39 (Hungary 18, Colombia 7, Finland 5, Sri Lanka 5, Sweden 1, Croatia 1, Chile 1, Peru 1) |
| CC BY-SA 4.0 | 26 (Croatia 9, Peru 7, Finland 4, Chile 3, Colombia 3) |
| CC BY-SA 2.5 | 20 (Sweden) |
| CC BY 3.0 | 1 (Lima Province) |
| CC BY 4.0 | 1 (Nelson) |

One file is CC0 (Osijek-Baranja). The remaining 108 are public domain; their credits are kept as a courtesy and to make provenance reviewable.

## Files

- Catalogs: `jpex/IrelandCatalog.swift`, `SwedenCatalog.swift`, `DenmarkCatalog.swift`, `FinlandCatalog.swift`, `CzechiaCatalog.swift`, `CroatiaCatalog.swift`, `GreeceCatalog.swift`, `HungaryCatalog.swift`, `ChileCatalog.swift`, `ColombiaCatalog.swift`, `PeruCatalog.swift`, `TurkeyCatalog.swift`, `UAECatalog.swift`, `SriLankaCatalog.swift`, `NewZealandCatalog.swift` and `SouthAfricaCatalog.swift`.
- Flags: 196 imagesets named `<cc>_flag_<code suffix>` (for example `ie_flag_d`, `se_flag_ab`, `fi_flag_01`, `cz_flag_10`, `co_flag_dc`, `pe_flag_lma`, `nz_flag_nsn`), each with `flag.png` and the standard `Contents.json`. The 142 fallback places use the existing `world_flag_dk`, `world_flag_tr`, `world_flag_za`, `world_flag_gr`, `world_flag_nz`, `world_flag_cl`, `world_flag_fi`, `world_flag_ie` and `world_flag_ae` assets.
- Credits: the twelve `*FlagCredits.json` files listed above.
