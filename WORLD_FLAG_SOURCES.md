# Countries collection sources

The collection contains the 249 ISO 3166-1 countries and territories, plus Kosovo and Northern Cyprus using the user-assigned XK and XC codes. WORLD-XX identifiers remain separate from subdivision visits, except for the places listed under "Shared places" below. Inclusion and geographic grouping are for travel tracking, not a statement on sovereignty.

- Country data: [flag-icons country.json](https://github.com/lipis/flag-icons/blob/main/country.json), MIT. Åland spelling, Czechia short name, Palestine short name, and Caribbean groupings were adjusted for display.
- Flag SVGs: [hampusborgos/country-flags](https://github.com/hampusborgos/country-flags), described by the repository as public-domain artwork sourced from Wikimedia Commons. Bundled as 768-pixel PNG renders made with WebKit (Nepal keeps its SVG for its transparent shape). Original proportions and artwork retained.
- Antarctica has no official flag; the supplied artwork is an unofficial design.
- Dataset downloaded 2026-10-06. All artwork is bundled for offline use. Source and license notices ship in WorldFlagCredits.json under Settings → Acknowledgements → Countries.

## Shown as "Countries"

The collection keeps the permanent ID `WORLD` but is shown as Countries. Settings → Count as countries decides which entries appear and count:

| Setting | Default | Entries |
| --- | --- | --- |
| Hong Kong & Macau | On | HK, MO |
| Taiwan | On | TW |
| UK nations | Off | Replaces GB with England, Scotland, Wales and Northern Ireland (the UK collection's GB-ENG, GB-SCT, GB-WLS and GB-NIR records) |
| Territories | On | AI, AS, AW, AX, BL, BM, BQ, CC, CK, CW, CX, EH, FK, FO, GF, GG, GI, GL, GP, GU, IM, JE, KY, MF, MP, MQ, MS, NC, NF, NU, PF, PM, PN, PR, RE, SH, SJ, SX, TC, TK, VG, VI, WF, YT |
| Antarctica & remote islands | Off | AQ, BV, GS, HM, IO, TF, UM |
| Northern Cyprus | Off | XC. While it's off, its part of the island counts as Cyprus. Rules saved before it had a switch turn it on only if they counted everywhere. |

Every other entry always counts: 193 UN members, the Holy See, Palestine and Kosovo. With the defaults, Countries lists 243 places.

## Shared places

These places appear in Countries and in a subdivision collection, and both lists show one shared status: HK and MO (China), GP, MQ, GF, RE and YT (France), AS, GU, MP, PR and VI (United States), and CX, CC, NF and HM (Australia). The shared record uses the subdivision ID. A status saved earlier under the place's WORLD-XX ID is still read until the shared record is set. See `CountryCatalog.sharedPlaceIDs` and `legacyStatusIDs`.

## Local flags

Places whose upstream artwork repeats the French or British flag use their own local flag, as listed in WorldFlagCredits.json:

| Place | Flag | Source | License |
| --- | --- | --- | --- |
| New Caledonia (NC) | Kanak flag, official alongside the tricolour since 2010 | [Flag of FLNKS.svg](https://commons.wikimedia.org/wiki/File:Flag_of_FLNKS.svg) — User:WarX | Public domain |
| Saint Pierre and Miquelon (PM) | Local flag | [Flag of Saint-Pierre and Miquelon.svg](https://commons.wikimedia.org/wiki/File:Flag_of_Saint-Pierre_and_Miquelon.svg) — André Paturel | Public domain |
| Saint Helena, Ascension and Tristan da Cunha (SH) | Flag of Saint Helena | [Flag of Saint Helena.svg](https://commons.wikimedia.org/wiki/File:Flag_of_Saint_Helena.svg) — Patricia Fidi | Public domain |
| Réunion (RE) | Lo Mahavéli (unofficial) | [Proposed flag of Réunion (VAR).svg](https://commons.wikimedia.org/wiki/File:Proposed_flag_of_R%C3%A9union_(VAR).svg) — Ch1902 | Public domain |
| Saint Martin (MF) | Local flag of the Collectivity | [Local flag of the Collectivity of Saint Martin.svg](https://commons.wikimedia.org/wiki/File:Local_flag_of_the_Collectivity_of_Saint_Martin.svg) — Collectivity of Saint-Martin, vectorised by Flagvisioner | Licence Ouverte |
| Saint Barthélemy (BL) | Local flag | [Flag of Saint Barthélemy (Local).svg](https://commons.wikimedia.org/wiki/File:Flag_of_Saint_Barth%C3%A9lemy_(Local).svg) — Germenfer | CC0 |
| Guadeloupe, Martinique, French Guiana, Mayotte (GP, MQ, GF, YT) | Same artwork as `fr_flag_971`, `972`, `973`, `976` | See FR_FLAG_SOURCES.md | Public domain |
| Northern Cyprus (XC) | Flag of the Turkish Republic of Northern Cyprus | [Flag of the Turkish Republic of Northern Cyprus.svg](https://commons.wikimedia.org/wiki/File:Flag_of_the_Turkish_Republic_of_Northern_Cyprus.svg) — Wikimedia Commons contributors | Public domain |

Downloaded 2026-10-08 as Wikimedia PNG renders, scaled to 768 pixels wide. Caribbean Netherlands (BQ), Bouvet Island, Svalbard and Jan Mayen, Heard and McDonald Islands and the US Minor Outlying Islands keep their sovereign's flag, which is the flag they fly.
