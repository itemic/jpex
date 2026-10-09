# Time Machine — design and data spec

Time Machine is a full-screen trip through time, opened from the Places sidebar's toolbar.
The world map floats in space, on the front of a receding stack of maps like macOS Time
Machine's windows. A scrubber along the bottom runs through twelve moments in history, not to
scale. As it moves, borders retrace themselves, colours flow from one power to the next, and
little cards with flags tell what changed. Scrub past the earliest moment and keep pulling, and
the map wraps itself into a globe and the continents drift back to Pangaea.

## Eras (earliest first)

| id    | year | headline (indicative)                  |
|-------|------|----------------------------------------|
| 1815  | 1815 | After Napoleon (Congress of Vienna)    |
| 1871  | 1871 | Nations unite (Germany, Italy)         |
| 1914  | 1914 | The eve of the Great War               |
| 1923  | 1923 | Empires fall                           |
| 1939  | 1939 | On the brink (summer 1939, pre-invasion of Poland) |
| 1949  | 1949 | A world divided                        |
| 1960  | 1960 | The Year of Africa                     |
| 1976  | 1976 | Decolonisation                         |
| 1990  | 1990 | Germany reunites (after 3 Oct 1990)     |
| 1993  | 1993 | After the Soviet Union (mid-1993)       |
| 2011  | 2011 | South Sudan (after 9 Jul 2011)          |
| today | 2026 | Today                                   |

Each era is a snapshot of the world at that moment (state as of the year noted). An era's
events describe what changed since the previous (earlier) era, so scrubbing forward reads like a
story. The `today` era's events are recent changes of name or flag since 2011 (e.g. Eswatini
2018, North Macedonia 2019, Kyrgyzstan's flag 2023, Türkiye 2022).

## Units (the atoms of the map)

The map is built from **units**. Every region in `jpex/Maps/geo_WORLD.json` is a unit, named by
its id without the `WORLD-` prefix: `RU`, `FR`, `GB-ENG`, `GB-SCT`, `GB-WLS`, `GB-NIR`, `FR-973`
(French Guiana), `FR-971`, `FR-972`, `FR-974`, `FR-976`, `US-PR`, `US-GU`, `US-VI`, `US-MP`,
`US-AS`, `CN-HK`, `CN-MO`, `FI-01` (Åland), `AU-HM`, `AU-CX`, `AU-CC`, `AU-NF`, `XK` (Kosovo),
`XC` (Northern Cyprus), `EH` (Western Sahara), `PS`, `TW`, `AQ`, and so on (255 in all).

Some countries are cut into **pieces** so historical borders that don't follow today's can be
drawn. A piece id is `<COUNTRY>~<name>`. Where a country is cut, its pieces replace it as units
and together cover the whole country exactly. **Only the pieces below exist.** Assigning the bare
country code in an era applies to all its pieces; assigning a piece overrides that for the piece.

**Germany is cut by state**, so its pieces are states (or groups of states), and the
GDR/West split is expressed by assigning them:
`DE~brandenburg` (BB+BE), `DE~mecklenburg` (MV), `DE~saxony` (SN), `DE~saxonyanhalt` (ST),
`DE~thuringia` (TH), `DE~bavaria` (BY), `DE~badenwurttemberg` (BW), `DE~hesse` (HE),
`DE~rhineland` (NW), `DE~palatinate` (RP+SL), `DE~lowersaxony` (NI+HB), `DE~holstein` (SH+HH).
The GDR is `DE~brandenburg DE~mecklenburg DE~saxony DE~saxonyanhalt DE~thuringia`.

| piece | approximates | built from |
|---|---|---|
| `PL~west` | German until 1945 (Silesia, Pomerania, Lubusz, southern East Prussia) | PL-02 PL-08 PL-16 PL-32 PL-28 |
| `PL~posen` | Prussian 1815–1919, Polish after (Posen, West Prussia, Upper Silesia) | PL-30 PL-04 PL-22 PL-24 |
| `PL~galicia` | Austrian until 1918 | PL-12 PL-18 |
| `PL~congress` | Russian (Congress Poland) until 1915 | PL-10 PL-14 PL-06 PL-20 PL-26 |
| `RU~kaliningrad` | German East Prussia until 1945 | RU-KGD |
| `RU~amur` | Qing until 1858/60 (Outer Manchuria) | RU-PRI RU-AMU RU-YEV RU-KHA |
| `RU~tuva` | Qing until 1911, Tuvan People's Republic 1921–44 | RU-TY |
| `RU~sakhalin` | Karafuto (south Sakhalin) + Kurils, Japanese 1905/1875–1945 | RU-SAK south of 50°N, plus the Kurils |
| `RU~main` | the rest of Russia | remainder |
| `LT~klaipeda` | Memel territory (German until 1920, again 1939) | LT-KL |
| `LT~vilnius` | Polish 1920–39 | LT-VL |
| `LT~main` | rest of Lithuania | remainder |
| `UA~galicia` | Austrian until 1918, Polish 1919–39 | UA-46 UA-26 UA-61 |
| `UA~volhynia` | Russian until 1917, Polish 1921–39 | UA-07 UA-56 |
| `UA~bukovina` | Austrian until 1918, Romanian 1918–40 | UA-77 |
| `UA~transcarpathia` | Hungarian until 1918, Czechoslovak 1919–38, Hungarian 1939–44 | UA-21 |
| `UA~main` | rest of Ukraine | remainder |
| `BY~west` | Polish 1921–39 | BY-HR BY-BR |
| `BY~main` | rest of Belarus | remainder |
| `RO~transylvania` | Hungarian (Austria-Hungary) until 1918, incl. Banat, Crișana, Maramureș | RO-AB RO-AR RO-BH RO-BN RO-BV RO-CJ RO-CS RO-CV RO-HD RO-HR RO-MM RO-MS RO-SB RO-SJ RO-SM RO-TM |
| `RO~bukovina` | Austrian until 1918 | RO-SV |
| `RO~main` | Wallachia, Moldavia, Dobruja | remainder |
| `BG~dobruja` | Southern Dobruja, Romanian 1913–40 | BG-08 BG-19 |
| `BG~main` | rest of Bulgaria | remainder |
| `RS~vojvodina` | Hungarian (Austria-Hungary) until 1918 | the districts of Vojvodina (RS-01…RS-07) |
| `RS~main` | rest of Serbia | remainder |
| `FR~alsacelorraine` | German 1871–1918 (and annexed 1940–44) | FR-67 FR-68 FR-57 |
| `FR~savoynice` | Kingdom of Sardinia until 1860 | FR-73 FR-74 FR-06 |
| `FR~main` | rest of metropolitan France (overseas regions are separate units) | remainder |
| `IT~piedmont` | Kingdom of Sardinia's mainland | IT-21 IT-42 IT-23 |
| `IT~sardinia` | island of Sardinia | IT-88 |
| `IT~lombardy` | Austrian until 1859 | IT-25 |
| `IT~venetia` | Austrian until 1866 | IT-34 |
| `IT~friuli` | Austrian until 1866 (Udine) / 1918 (Trieste, Gorizia); treat as 1866 | IT-36 |
| `IT~trentino` | Austrian until 1918 | IT-32 |
| `IT~papal` | Papal States (Lazio until 1870; Umbria, Marche, Romagna until 1860) | IT-62 IT-55 IT-57 |
| `IT~emilia` | Parma, Modena, Romagna (approximate) | IT-45 |
| `IT~tuscany` | Grand Duchy of Tuscany | IT-52 |
| `IT~sicilies` | Kingdom of the Two Sicilies | IT-72 IT-65 IT-67 IT-75 IT-77 IT-78 IT-82 |
| `GR~old` | Kingdom of Greece 1832 | GR-I GR-J GR-H GR-G GR-L GR-69 |
| `GR~ionian` | British until 1864 | GR-F |
| `GR~thessaly` | Ottoman until 1881 | GR-E |
| `GR~north` | Ottoman until 1912–13 (Epirus, Macedonia, Thrace, N. Aegean) | GR-D GR-C GR-B GR-A GR-K |
| `GR~crete` | Ottoman until 1898/1913 | GR-M |
| `SA~hejaz` | Ottoman Hejaz, Kingdom of Hejaz 1916–25 | SA-02 SA-03 SA-07 SA-12 |
| `SA~hasa` | Ottoman al-Hasa until 1913 | SA-04 |
| `SA~nejd` | the rest | remainder |
| `CN~tibet` | de facto independent 1912–50 | CN-XZ |
| `CN~manchuria` | Manchukuo 1932–45 | CN-HL CN-JL CN-LN |
| `CN~main` | the rest of China | remainder |
| `GH~togoland` | British Togoland until 1957 | GH-TV GH-OT |
| `GH~main` | Gold Coast | remainder |
| `US~east` | the US in 1783 (east of the Mississippi, without Florida) | every state east of the Mississippi except FL, plus DC |
| `US~louisiana` | Louisiana Purchase 1803 | LA AR MO IA MN ND SD NE KS OK MT WY CO |
| `US~florida` | Spanish until 1819/21 | FL |
| `US~texas` | Mexican until 1836, Republic of Texas 1836–45 | TX |
| `US~southwest` | Mexican Cession 1848 | CA NV UT AZ NM |
| `US~oregon` | Oregon Country, US 1846 | WA OR ID |
| `US~alaska` | Russian until 1867 | AK |
| `US~hawaii` | Kingdom of Hawaii until 1898 | HI |
| `VN~north` | North Vietnam 1954–76 | north of 17°N |
| `VN~south` | South Vietnam 1954–76 | south of 17°N |
| `YE~south` | Aden / South Yemen until 1990 | lon/lat polygon of the pre-1990 South Yemen |
| `YE~north` | North Yemen | remainder |
| `SO~somaliland` | British Somaliland until 1960 | the `somaliland` disputed area in geo_WORLD |
| `SO~italian` | Italian Somaliland | remainder |
| `MA~spanish` | Spanish protectorate in the north, 1912–56 | lon/lat polygon of the Rif zone |
| `MA~main` | the rest | remainder |
| `CM~british` | British Southern Cameroons 1919–61 | lon/lat polygon of today's NW and SW regions |
| `CM~main` | the rest | remainder |

(Approximations are expected: borders are drawn from today's lines. The app says so.)

## `jpex/TimeMachineEras.json`

```jsonc
{
  "polities": {
    // id: UPPER_SNAKE, unique. Every polity used in "assign" must be defined here.
    "GB_EMPIRE": {
      "name": "British Empire",              // what a tapped place says beneath its label
      "flag": "commons:Flag_of_the_United_Kingdom.svg", // or "asset:world_flag_gb" for a flag the app has
      "color": "GB",                         // a unit code whose palette colour it takes, or a named colour
      "kind": "empire"                       // state | empire | indigenous | unclaimed | contested
    }
  },
  "eras": [
    {
      "id": "1914", "year": 1914,
      "title": "The Eve of the Great War",   // ≤ 32 characters
      "summary": "One sentence, ≤ 140 characters, on what defines the world map now.",
      // unit or piece → "POLITY" or "POLITY|Label". Label = what the place itself was called
      // (a colony, province, or constituent part), e.g. "British India". Units with the same
      // polity and label have no border between them; same polity, different label → a fine
      // dashed border; different polity → a full border.
      "assign": { "IN": "GB_EMPIRE|British India", "PL~congress": "RU_EMPIRE|Congress Poland" },
      "events": [
        {
          "year": 1912,                       // the actual year it happened
          "title": "Italy takes Libya",       // ≤ 34 characters
          "detail": "One or two plain sentences, ≤ 200 characters.",
          "at": [17.0, 27.0],                 // [lon, lat] where the card points
          "units": ["LY"],                    // units/pieces to glow
          "from": ["OTTOMAN"],                // polity ids whose flags show before the arrow (may be empty)
          "to": ["IT_KINGDOM"],               // polity ids whose flags show after it
          "kind": "annexation"                // independence | unification | partition | annexation |
                                              // dissolution | colonization | decolonization | flag |
                                              // rename | treaty | revolution
        }
      ]
    }
  ]
}
```

Rules:
- **Any unit not in an era's `assign` is itself**: an implicit polity named after today's
  country (`FR` → France, flag `world_flag_fr`, colour `FR`). Units like `GB-SCT` default to
  their parent `GB` with label "Scotland". So an era must assign every unit that was *not* its
  modern self at that time — including countries whose name or flag differed (`IR` → Persia in
  1914, `TH` → Siam, `CA` with the Red Ensign, …) — and every piece that belonged elsewhere.
- In colonial eras the metropole joins its empire's polity with its own name as the label
  (`"FR": "FR_EMPIRE|France"`), so France and French West Africa share a colour.
- Polity ids used across eras: reuse the same id for the same entity (see canonical ids below).
  A state whose flag changed between eras gets a separate id per flag (`CA_1868`, `CA`), both
  with `color: "CA"` so its colour stays put.
- `indigenous` is for lands without a state the era's map can honestly draw (e.g. much of
  inner Africa in 1815/1871): drawn as soft land without inner borders, name like
  "Independent African kingdoms and peoples". `unclaimed` is for Antarctica before claims.
  `contested` is drawn hatched (e.g. Western Sahara 1976).
- Named colours allowed for `color`: rose, coral, amber, sand, olive, sage, teal, sky, indigo,
  violet, plum, slate, rust, gold.
- Flags: `commons:<exact Wikimedia Commons file name>` of the flag *as used in that era*. Use
  `asset:world_flag_xx` only when today's flag was already in use then.
- Keep events to the 3–8 most significant per era. Prefer ones visible on a world map.

### Canonical polity ids (use these where they apply)

GB_EMPIRE, FR_EMPIRE, ES_EMPIRE, PT_EMPIRE, NL_EMPIRE, BE_EMPIRE (Belgian colonial), DE_EMPIRE
(German Empire 1871–1918), IT_KINGDOM (Kingdom of Italy incl. colonies 1861–1946), RU_EMPIRE,
OTTOMAN, AT_EMPIRE (Austrian Empire 1804–67), AT_HU (Austria-Hungary 1867–1918), QING,
ROC (Republic of China), PRC, JP_EMPIRE (Empire of Japan incl. colonies, until 1947), USSR,
YUGOSLAVIA_KINGDOM, YUGOSLAVIA (SFR), FRY (Federal Republic of Yugoslavia 1992–2003),
CZECHOSLOVAKIA, GDR, FRG (West Germany), NAZI_GERMANY, US (when it differs from today, e.g. US
with fewer stars, use US_1815 etc.), PRUSSIA, PERSIA, SIAM, ETHIOPIA_EMPIRE, MANCHUKUO,
AFRICA_INDEPENDENT.

## `jpex/TimeMachinePlates.json` (prehistory, 0–250 Ma)

```jsonc
{
  "maxMa": 250,
  "plates": [
    { "id": "AF", "name": "Africa", "units": ["DZ", "EG", ...] }
    // every unit appears in exactly one plate; pieces follow their country
  ],
  // For each plate, finite rotations taking PRESENT-day coordinates to where that land was at
  // `ma` million years ago, in one absolute frame. Keyframes in increasing ma, first ma=0 with
  // angle 0. Between keyframes the app slerps the rotation (quaternions).
  "rotations": { "AF": [ {"ma": 0, "lat": 90, "lon": 0, "angle": 0}, {"ma": 100, "lat": .., "lon": .., "angle": ..} ] },
  "emerged": { "IS": 16 },                    // unit → Ma it formed/rose; it fades out before that
  "periods": [ {"name": "Cretaceous", "start": 145, "end": 66, "color": "#7FC64E"} ],
  "labels": [ {"name": "Pangaea", "from": 250, "to": 180, "plate": "AF", "at": [lon, lat]} ],
  // label positions are in PRESENT-day coordinates on the named plate, so they ride with it
  "events": [ {"ma": 66, "title": "The asteroid", "detail": "…", "plate": "NA", "at": [-89.5, 21.4], "kind": "impact"} ]
  // kinds: impact, extinction, rift, collision, life
}
```

Rotation math (the app and any validator must agree): a point at longitude λ, latitude φ is the
unit vector v = (cos φ cos λ, cos φ sin λ, sin φ). The Euler pole (lat, lon) is the unit axis k.
The rotated point is Rodrigues' v' = v cos θ + (k × v) sin θ + k (k · v)(1 − cos θ), θ = angle in
degrees converted to radians, positive counter-clockwise looking down on the pole from outside
the Earth.

## Generated geometry: `jpex/Maps/geo_TIMEMACHINE.json`

Built by `Tools/TimeMachine/build_geometry.py` from geo_WORLD.json and the subdivision files.

```jsonc
{
  "units": [ {"id": "DE~bavaria", "country": "DE", "name": "Bavaria", "d": "M… Z", "c": [lon, lat]} ],
  // arcs: maximal runs of boundary shared by the same two units (b = null for coastline).
  "arcs": [ {"a": "DE~bavaria", "b": "AT", "d": "M…L…"} ],
  "colors": { "DE": "slate", ... }            // a named colour per country, neighbours differ
}
```
