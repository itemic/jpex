# Russia collection: flag sources

Retrieved 8 October 2026. All artwork is bundled for offline use. No flag was drawn, recoloured or edited for the app.

## Catalog scope

The Russia collection (`RU`, `jpex/RussiaCatalog.swift`) lists the 83 federal subjects in ISO 3166-2:RU: 21 republics, 9 krais, 46 oblasts, the federal cities of Moscow (`RU-MOW`) and Saint Petersburg (`RU-SPE`), the Jewish Autonomous Oblast and 4 autonomous okrugs. IDs are the ISO codes (`RU-<code>`), with the code suffix as the abbreviation and the national flag (`world_flag_ru`) as the collection flag.

The app follows internationally recognised boundaries. Crimea and Sevastopol are listed in the Ukraine collection (`UA-43`, `UA-40`), not here, and the Ukrainian oblasts Russia claimed in 2022 (Donetsk, Luhansk, Zaporizhzhia and Kherson) are not included. ISO 3166-2:RU itself lists only these 83 subjects.

Places are grouped by the eight federal districts, alphabetically by English name within each district. Membership is current: Buryatia and Zabaykalsky Krai have been in the Far Eastern district since 2018. Group IDs are display data only.

| Group (ID) | Local name | Places |
| --- | --- | --- |
| Central (`RU-central`) | Центральный | 18 |
| Northwestern (`RU-northwestern`) | Северо-Западный | 11 |
| Southern (`RU-southern`) | Южный | 6 (excluding Crimea and Sevastopol, see above) |
| North Caucasian (`RU-north-caucasian`) | Северо-Кавказский | 7 |
| Volga (`RU-volga`) | Приволжский | 14 |
| Ural (`RU-ural`) | Уральский | 6 |
| Siberian (`RU-siberian`) | Сибирский | 10 |
| Far Eastern (`RU-far-eastern`) | Дальневосточный | 11 |

## Names

English names follow Wikidata's English labels and English Wikipedia's article titles. Krais, oblasts and okrugs keep their type word ("Krasnodar Krai", "Moscow Oblast"), so Moscow and Moscow Oblast stay distinct. Autonomous okrugs use "Autonomous Okrug" as on English Wikipedia (Wikidata says "Autonomous District"). Republics use their short English names (Tatarstan, Chechnya, Karelia), except Komi Republic and Altai Republic, where the type is part of the usual name. Sakha is "Sakha (Yakutia)".

Local names are the official Russian names. Republics use the names in Article 65 of the Constitution, such as Республика Татарстан, Чеченская Республика, Чувашская Республика, Республика Саха (Якутия) and Республика Северная Осетия — Алания. The Constitution's repeated short forms, such as "(Адыгея)" and "— Чувашия", are left out. Two subjects use their official compound names: Ханты-Мансийский автономный округ — Югра, and Кемеровская область — Кузбасс (renamed in 2019). Their English names stay "Khanty-Mansi Autonomous Okrug" and "Kemerovo Oblast".

## How flags were chosen

1. Each ISO code was matched to its Wikidata item through the MediaWiki API (`haswbstatement:P300=<code>`). Every code matched exactly one item. The flag image (P41) came from the preferred-rank statement, or else from a normal-rank statement without an end date; deprecated statements were ignored. All 83 subjects have a flag on Wikidata.
2. Each choice was compared with the galleries in English Wikipedia's *Flags of the federal subjects of Russia* and Russian Wikipedia's *Флаги субъектов Российской Федерации*, including their adoption dates and the laws they cite.
3. Every candidate, and then every installed flag, was checked on contact sheets for historical designs, wrong colours or proportions, and blank or broken renders.

On Wikidata, 14 subjects point to files that two Commons users uploaded in 2024–2025 under names such as "(large)", "(Latest version)", "(design, Dark color)" or ", center". These are self-published redrawings, mostly CC BY-SA 4.0, and cite no source. For these subjects, the app uses the long-standing Commons files that both Wikipedia galleries use instead. Those files have the same designs and mostly cite the regional law, government website or geraldika.ru:

Amur Oblast, Kaluga Oblast, Kemerovo Oblast, Khabarovsk Krai, Komi Republic, Moscow Oblast, Murmansk Oblast, Novgorod Oblast, Penza Oblast, Primorsky Krai, Pskov Oblast, Saint Petersburg, Tula Oblast and Voronezh Oblast.

For two of these, the colours were visibly off. Tula's preferred file has a dark crimson field, but the 2005 flag law specifies red. Komi's file uses a purple-tinted blue. Wikidata's choices were kept elsewhere, including two recent files:

- **Kursk Oblast** uses "Flag of Kursk Oblast (large fix).svg". The file cites geraldika.ru and is public domain, and Commons marks the older rendering as superseded by it.
- **Belgorod Oblast** uses "New Flag of Belgorod Oblast.svg". It is the 2022 redrawing of the 2000 flag by the author of the older file, with refined arms and colours.

Each flag is Wikimedia Commons' PNG render of the linked SVG at 960 pixels wide, resized to 768 pixels on the long side and reduced to a 256-colour palette. The alpha channel is kept whenever a render is not fully opaque. In the 17 flags where this applies, only anti-aliased edges and hairline seams between stripes are transparent; there are no transparent areas. All 83 sources are SVG files. Artwork is unchanged.

## Notes

- Every subject has an official flag, so there are no national-flag fallbacks and no flag notes.
- Current designs include Altai Republic (2016), Vladimir Oblast (2017, with the hammer and sickle in the hoist stripe), Pskov Oblast (2018), Kemerovo Oblast (2020) and Penza Oblast (2022).
- Most flags are 2:3. The source files are 1:2 for Adygea, Altai Krai, Buryatia, Karachay-Cherkessia, Kurgan, Khanty-Mansi, Khakassia, Kalmykia, Sakha, North Ossetia, Tatarstan and Udmurtia, and 5:8 for Chuvashia. A few renders are a pixel or two off 2:3 because of their SVG canvases.
- North Ossetia–Alania's file has had repeated edits to its colour shades (2023–2026). The installed render is the version current on 8 October 2026: white, red and yellow stripes.

## Licences

Most files are public domain, as official symbols (PD-RU-exempt) or by their authors' release. `RussiaFlagCredits.json` names the author, source page and licence for every file. These licences require attribution:

| Licence | Files |
| --- | --- |
| CC BY-SA 3.0 | 3 (Altai Krai; Khakassia and Chukotka Autonomous Okrug, both also GFDL) |
| CC BY-SA 4.0 | 1 (Belgorod Oblast; the file is also tagged PD-RU-exempt, and attribution is given anyway) |

The remaining 79 files are public domain. The Jewish Autonomous Oblast's file is released into the public domain except in France, where its author asks for attribution; the credit names him. The public-domain credits are kept as a courtesy and to make provenance reviewable.

## Files

- Catalog: `jpex/RussiaCatalog.swift` (`CountryCatalog.russia`).
- Flags: 83 imagesets named `ru_flag_<code suffix>` (for example `ru_flag_mow`, `ru_flag_spe`, `ru_flag_ta`, `ru_flag_kda`), each with `flag.png` and the standard `Contents.json`.
- Credits: `jpex/RussiaFlagCredits.json`.
