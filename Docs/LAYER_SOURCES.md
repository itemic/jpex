# World map layer sources

Written on 16 October 2026 for the World map's layers: driving side, plugs, voltage, the Equator and tropics, and antipodes. Nothing is fetched at runtime. The tables live in `jpex/Atlas/DrivingSide.swift` and `jpex/Atlas/MainsPower.swift`; everything else is worked out on the device.

## Summary

- **Plugs, voltage and frequency** cover 244 places, from the IEC's World Plugs list, plus utilities and regulators for places it leaves out. Seven places with no permanent population have none: AQ, BV, HM, GS, TF, UM, IO.
- **Driving side** covers every place on the World map. Two broad sources agree on every code they both cover, and doubtful cases were checked against government or legal sources. AQ, BV, GS, HM, IO, TF, TK and UM have no public roads or no one to drive on them.
- **The IEC's World Plugs list** (https://www.iec.ch/world-plugs) couldn't be reached on 16 October 2026: iec.ch returned a bot check to every request, and Wikipedia's "Mains electricity by country" records the guide as retired in September 2026. The data comes from the Wayback Machine's last good capture, of 16 August 2026, which lists 216 locations: https://web.archive.org/web/20260816170935/https://www.iec.ch/world-plugs. Cite that dated archive in any credit, not the live URL.

## How the map colours plugs

The IEC lists each place's plug letters alphabetically, so the order doesn't say which is most common. The map colours each country by its own national socket and lists every letter in its callout. Bringing a letter forward from the full map's legend lights every country whose sockets take it.

- **Where a place lists C first** with other letters after it, it's coloured by the next one, because C, the Europlug, fits nearly every round-pin socket: Germany is F, France is E, Switzerland is J, Brazil is N.
- **Set by hand:**
  - China is I, not A.
  - Thailand is O, its national standard, not A.
  - Denmark, Greenland and the Faroe Islands are K, not E.
  - Italy, San Marino and the Vatican are L, not F.
- **Moved first by the research**, where a standards body or other source supports it, such as Ghana's G and India's D (see "Plugs reordered" below).

Voltages are grouped as 100–127 V, 220–240 V, or both where a place has each in different parts, such as Brazil by state.

## Equator, tropics and polar circles

- **The Earth's tilt** is taken as 23° 26′ 09″ (23.4358°) for late 2026, from the IAU 2006 precession model. It sets the tropics at ±23.4358° and the polar circles at ±66.5642°.
- **The tilt shrinks** by about 0.47″ a year, a few metres of latitude, far too little to show on the map.

## Antipodes

- **No outside data.** Antipodes are worked out on the device from the World map's own outlines (see MAP_SOURCES.md). Each point moves half way round the Earth, and as far south of the Equator as it was north.
- **The callout's "Antipodes: …"** samples a 16 × 16 grid of points across the tapped country's largest piece of land, so places across the date line, such as Fiji, aren't stretched round the World. It names the country most of them land in, as long as that's at least a tenth of them. Otherwise it says the antipodes are open sea.

## Sources by field

### `plugs`, `volts`, `hertz`

**Primary source: the IEC World Plugs list (archive of 16 Aug 2026).** 215 codes use it directly. Three of those have a value replaced (ID, IL, MF; see "Judgement calls").

- The IEC's "Saint Martin" entry is mapped to MF.
- The IEC's obsolete "Netherlands Antilles" entry (127 V / 220 V, 50 Hz, A/B/C/F) is not used for any code.

**The IEC doesn't rank plug letters.** It lists them alphabetically. I moved a letter to the front only where a source names it as the national standard or the most common socket. Everywhere else the IEC's alphabetical order is kept, so don't read the order as a ranking. The changes are under "Judgement calls".

**Fallback sources** cover the 36 codes the IEC list doesn't. They're listed per code below. Where several were available, I preferred the utility's terms of supply, then a regulator or government page, then the archived CIA World Factbook "Travel Facts". The Factbook itself closed on 4 Feb 2026; I used Wayback copies from 2023 to 2024.

**Cross-checks used:**
- Wikipedia "Mains electricity by country", rev. 1379647853 (11 Oct 2026). Its table was itself built mostly from the IEC data.
- WorldStandards.eu "Plug, socket & voltage by country", updated 7 Sep 2025.
- CIA Factbook Travel Facts, 38 places, captured 2023 to 2024.

### `drives`

1. **Two broad sources agree on every code they both cover:**
   - Wikipedia "Left- and right-hand traffic", rev. 1379274791 (9 Oct 2026), table "Worldwide distribution by country". A territory with no row of its own takes its parent country's row.
   - WorldStandards.eu "List of left- & right-driving countries", updated 23 Jan 2026.
2. **The archived CIA Factbook "Road Driving Side"** agreed on all 37 places I fetched.
3. **Doubtful cases were checked against official sources:**
   - **Samoa, left since 7 Sep 2009:** Road Transport Reform Act 2008 (paclii.org) and Government of Canada (GAC) travel advice.
   - **Hong Kong, left:** HK Government LegCo reply, 10 Apr 2024.
   - **Macao, left:** DSAT page on the Hong Kong–Zhuhai–Macao Bridge.
   - **Gibraltar, right:** visitgibraltar.gi and the Control of Traffic Regulations.
   - **Falklands, Cyprus and Malta, left:** GAC.
   - **Northern Cyprus, left:** TRNC Public Information Office. On 20 Aug 2025 the ministry denied any plan to switch.
   - **US Virgin Islands, left:** National Park Service.
   - **British Virgin Islands, left:** FCDO.
   - **Guyana and Suriname, left:** GAC.
   - **Saint Helena, left:** Road Traffic Regulations 1985, reg. 75.
   - **Svalbard, right:** Norway's Road Traffic Act, applied on Svalbard by regulation 1993-11-10-1018.
   - **Kiribati, Tuvalu, Nauru, Cook Islands, Niue, Anguilla, Montserrat, Cayman, Turks and Caicos, Bermuda: left.** GAC.
   - **Christmas Island, left:** Parks Australia.
   - **Japan including Okinawa, left:** Road Traffic Act art. 17; Okinawa switched on 30 Jul 1978.
   - **Rwanda, right:** Law No. 014/2026 of 6 Mar 2026, art. 4, still says right.
   - **Burundi, right:** no change announced; only non-government sources state the side.
4. **No country changed sides, or set a date to, between 2020 and Oct 2026.**

## Fallback codes (not in the IEC list)

| Code | Values used | Source |
|---|---|---|
| AQ, BV, HM, GS, TF | all null | No permanent population. GS has about 1 km of track between King Edward Point and Grytviken. TF has about 4.5 km of road at Port-aux-Français. |
| UM | all null | No permanent population. Wake Island has a keep-right rule, 32 CFR 935.131 (verified), which is kept in the note. |
| IO | all null | No permanent population. The BIOT Road Traffic Ordinance 1998 s.25 says "vehicles shall keep to the right hand side" (verified in the PDF at biot.gov.io); this is kept in the note. Base power is 60 Hz, but outlet voltage and plugs couldn't be confirmed. The UK–Mauritius Chagos treaty (signed 22 May 2025) was not in force as of Oct 2026. |
| AX | C/F, 230 V, 50 Hz, right | Follows Finland (Kraftnät Åland grid, tied to Sweden). Travel sources: ArrivalGuides, ANWB. Driving: Åland's own Vägtrafiklag (2023:108), modelled on Finland's. |
| CC | I, 240 V, 50 Hz, left | Power from the Australian government's Indian Ocean Territories Power Service. A visitor page says "240V AC 50 cycles, three pin plug". |
| CX | I, 240 V, 50 Hz, left | Parks Australia FAQ: "220 – 240v 50Hz". Plug type from travel guides. |
| NF | I, 240 V, 50 Hz, left | Norfolk Island Electricity Supply Regulations 1986: "415/240 volts", 50 Hz. The Factbook says 230 V. |
| NU | I, 230 V, 50 Hz, left | CIA Factbook (Aug 2024) and WorldStandards. |
| TK | I, 230 V, 50 Hz, drives null | Tokelau government energy page (240 V, older); solar mini-grid design "nominal 230V 50 Hz". GAC: "no paved roads and no motor vehicles", so drives is null. WorldStandards says left. |
| PN | I, 230 V, 50 Hz, left | Visit Pitcairn: "230-240 Volts", Australia/NZ plug. Left by convention: there are only a few concrete roads and quad bikes, and no official traffic statement was found. |
| SH | G, 240 V, 50 Hz, left | Travel guides (TTG: "240V… British three-pin"). WorldStandards says 230 V. Ascension and Tristan are assumed to be the same. |
| GG | G, 230 V, 50 Hz, left | Follows Jersey and the UK at 230 V. Visit Guernsey says "240 volts (50 hertz)"; see "Judgement calls". |
| JE | G, 230 V, 50 Hz, left | Jersey Electricity tariff, 1 Jan 2025: "LOW VOLTAGE (230/400 VOLTS)". |
| SJ | C/F, 230 V, 50 Hz, right | Follows Norway (travel sources); driving per lovdata regulation 1993-11-10-1018. |
| MP | A/B, 120 V, 60 Hz, right | CNMI Administrative Code §50-10-210 and §50-10-220 (60 Hz, 120/240 V). |
| MH | A/B, 120 V, 60 Hz, right | Marshalls Energy Company via the WFP Logistics Cluster ("120V 60Hz"), and the Factbook. |
| ML | C/E, 220 V, 50 Hz, right | Embassy of Mali in Japan ("220 volts AC, 50 Hz"), and the Factbook. |
| MV | G/C/D/J/K/L, 230 V, 50 Hz, left | Maldives Energy Authority draft installation regulations (2013): 230 V, and at least one BS 1363 (G) socket per room. The other letters come from the Factbook. |
| SS | C/D/G, 230 V, 50 Hz, right | The Factbook gives C, D; WorldStandards says G is most common. Low confidence. |
| PS | H/C, 230 V, 50 Hz, right | Same grid as Israel (Israel Electric supply). WorldStandards: "types C and H are the official standards". |
| VA | C/F/L, 230 V, 50 Hz, right | Factbook (Holy See, Feb 2024), on the Italian grid. |
| XK | C/F, 230 V, 50 Hz, right | Factbook (May 2024); regulator ERO (0.4 kV low voltage); WorldStandards. |
| XC | G, 230 V, 50 Hz, left | Eastern Mediterranean University: "between 220 and 240 volts", BS 1363. No KIB-TEK page was found. |
| EH | C/E, 220 V, 50 Hz, right | Follows Morocco (Moroccan-administered area). Nothing was found for the Sahrawi-held zone. |
| BL | C/E, 230 V, 60 Hz, right | EDF terms of sale for overseas customers (2017), art. 11-1: "50 Hertz (60 Hertz pour Saint-Martin et Saint Barthélemy)". Volts and plugs from the Factbook. |
| SX | A/B, 120 V, 60 Hz, right | GEBE conditions for connection: "60 cycles per second", "nominally 120 Volt". The Factbook's "110 V / 50 Hz" is contradicted by GEBE. |
| CW | A/B/F, 127 V, 50 Hz, right | Aqualectra general conditions, art. 11: "approximately 50 Hertz", "127 or 110 Volts". Plugs from Wikipedia; the Factbook gives A, B. |
| BQ | A/B, 127/110 V, 50/60 Hz, right | WEB Bonaire terms 2024 (50 Hz, 127 or 110 V); STUCO on Sint Eustatius ("127/220 Volt, 60Hz"); Saba at 110 V, 60 Hz from travel sources only. Bonaire has most of the population, so its values come first. |
| PF | C/E, 220 V, 60/50 Hz, right | Regulator CRE's 2012 Polynesia report: "220 – 380 V, sous 60 Hz". EDT concession reports; Moana Roa primer (some islands, e.g. the Marquesas and Hao, are 50 Hz). The Factbook lists C, D, E at 60 Hz. |
| WF | C/E, 230 V, 50 Hz, right | WorldStandards only; nothing found from EEWF. Low confidence. |
| PM | C/E, 230 V, 50 Hz, right | Wikipedia and the tourism office. 50 Hz is inferred, because EDF names only Saint-Martin and Saint-Barthélemy as 60 Hz exceptions. A legacy 127/220 V network was still being converted in 2015 to 2019. |
| YT | C/E, 230 V, 50 Hz, right | Électricité de Mayotte terms of sale (2023): "La tension nominale est de 230 V". Plugs from WorldStandards. |

## Judgement calls and disagreements

### Values changed from the IEC
- **ID:** IEC gives 220 V / 110 V; now [230].
  - Standard SPLN 1:1995 converted the supply to 230/400 V by 2003, and no 110 V public supply remains.
  - The Factbook (230 V) and Wikipedia (230/400 V, citing SPLN 1:1995 and Permen ESDM 04/2009) agree.
- **IL:** IEC gives H; now [H, C].
  - The IEC's own Type H description says H sockets are shaped to take Type C plugs.
  - Wikipedia and WorldStandards list C and H. This also keeps IL consistent with PS.
- **MF:** IEC "Saint Martin" gives 120 V / 220 V, 60 Hz, C/F; now 220 V, 60 Hz, C/E.
  - The 120 V belongs to the Dutch side, which GEBE supplies.
  - French Saint-Martin uses French E sockets (Factbook, Wikipedia).
  - EDF confirms 60 Hz.

### Plugs reordered (IEC letters kept, main type moved first)
- **GH, NG, SL, TZ, ZW, DM:** G before D.
  - Ghana Standards Authority made Type G mandatory from 1 Jan 2019.
  - For the rest, WorldStandards says G is official.
- **ZM:** G, C, D. Zambian standard ZS 558 (SI 120 of 2006).
- **KW:** G, C, M. **IQ:** G, C, D. **YE:** G, D, M. All from WorldStandards.
- **IN:** D, M, C. BIS standard IS 1293:2019 covers D and M; BIS has restricted C plugs since 2015.
- **PK:** D, C, G, M. **BT:** D, C, F, G, M. **NA:** M, D. All from WorldStandards.
- **ZA:** M, N, C. M is the de facto standard; wiring code SANS 10142-1 has required an N outlet at new socket points since 2018.
- **JO:** C, F, G, B, D, J. **MG:** C, E, D, J, K. **VC:** G first. **KN:** A, B, G, D. All from WorldStandards.
- **SB:** I, G. **VU:** I, C, G. WorldStandards says I is official; it also says G is never used in the Solomons, which contradicts the IEC. G is kept but put last.
- **HK, MY, SG:** G first. Wikipedia: "Type G is most common", and the IEC's Type G text names these places.
- **MO:** G, D, M, F. The Factbook lists G only.
- **LB:** C first. Wikipedia: "Type C sockets are the most frequent".
- **LK:** G, D, M. Wikipedia: only Type G may be made or imported since Aug 2017.
- **GI, IM:** G before C. Both use UK practice; the Factbook lists only G for Gibraltar.
- **Not reordered, for lack of evidence:** BD, BW (sources conflict on M vs G), MU, MM, SD, RW, UZ, TJ.

### Voltages reordered (dominant first)
- **MA:** 220, 127.
- **MG:** 220, 127. The regulator ORE and JIRAMA refer to the legacy level as 110 V, not 127 V.
- **LY:** 230, 127.
- **BO:** 230, 115. 115 V is found in parts of La Paz and Viacha.
- **Kept in IEC order:** BZ (110 V / 220 V split-phase), BR (127 V / 220 V by state), SA (220 V / 230 V while it moves to 230/400 V), KP and LR.

### Kept as the IEC has them, though other sources disagree
- **KP:** IEC gives 220 V / 110 V, 50 Hz / 60 Hz, A/C/F. The Factbook and Wikipedia give 220 V, 50 Hz, C/F. Nobody has a primary source.
- **LR:** IEC gives 120 V / 220 V, 50 Hz / 60 Hz, A/B/C/E/F.
  - The regulator LERC's Grid Code (Nov 2022) sets the national grid at 50 Hz, and its mini-grid code at 230 V.
  - The Factbook says 60 Hz, and some private plants still run at 60 Hz. The note says so.
- **RW:** IEC gives C/E/F/G; the Factbook (2024) gives C/J. Type G is official under RS EAS 495; C is the most common in practice.
- **IEC voltages that differ from current national standards:**
  - IEC says 220 V for some countries whose standards are now 230 V: RU, UA, TR, KZ, BY, MD, LT, TV (the Factbook says 230 V for TV).
  - IEC says 240 V for some that are now 230 V: CY (the Factbook says 230 V), GI, IM, MY, KI, TO.
  - IEC says 110 V for some whose nominal is 120 V: CO, HN, PA, DO, HT.
  - All kept as the IEC states them.
- **Other Factbook differences, all kept as the IEC has them:**
  - SR: the Factbook adds A/B and 220 V.
  - GY: it adds 120 V.
  - VC: it gives A/B/G and 110 V / 230 V; Petit St Vincent runs at 110 V, 60 Hz.
  - HK: it gives G only.
- **AS:** the IEC lists A/B/F/I, but a Wikipedia editor reporting a visit in Oct 2026 found only A/B. Kept as the IEC has it.
- **NC:** the IEC says C/F. The territory's tourism site says E/F in English and "identical to French" in French. Kept as the IEC has it.

### Fallback calls
- **No permanent population** means all fields are null: AQ, BV, HM, GS, TF, UM, IO.
  - The real keep-right rules on Wake Island and Diego Garcia are in the notes.
  - Wikipedia lists GS as left-hand traffic, but its note is copied from the Falklands. There is no road network or traffic law, so GS is null.
- **TK:** drives is null because there are no motor vehicles (GAC), although WorldStandards says left.
- **PN:** left, by convention only.
- **GG:** 230 V, not Visit Guernsey's 240 V, to match the Jersey utility and the UK.
- **SH:** 240 V from travel guides; WorldStandards says 230 V.
- **NF:** 240 V from the 1986 regulations; the Factbook says 230 V.
- **CC, CX:** 240 V. That is the figure on the Cocos visitor page and the top of Parks Australia's 220–240 V range for Christmas Island; the IEC's Australia entry is 230 V.
- **XC:** 230 V, while CY keeps the IEC's 240 V. The two are separate grids and the sources give a 220 to 240 V range.
- **SX:** GEBE's 120 V / 60 Hz is used over the Factbook's 110 V / 50 Hz.
- **SS:** C/D from the Factbook plus G from WorldStandards. Low confidence.
- **WF:** WorldStandards only. Low confidence.
- **BQ:** the values combine the three islands; see the note.
