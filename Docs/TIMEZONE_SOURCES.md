# Time zone sources

Written on 16 October 2026 for World Time. Nothing here is fetched at runtime: every offset, change and name comes from the device's own copy of the data below, or from tables bundled in the app's code.

## Offsets and clock changes: the tz database

- **Source.** The IANA Time Zone Database (the "tz database" or "Olson database"), https://www.iana.org/time-zones, as built into iOS and read through Foundation's `TimeZone`.
- **What World Time reads from it.**
  - Each clock's offset from UTC at any moment, summer time included (`secondsFromGMT(for:)`, `daylightSavingTimeOffset(for:)`).
  - When a zone's clocks next change (`nextDaylightSavingTimeTransition(after:)`), noted on the card in the fortnight before, as "Clocks go back an hour on Sunday 25 October".
  - Each zone's identifier, such as `Asia/Taipei`, shown as written in the database.
- **Checked against the database** (16 October 2026): Samoa on UTC+13 since crossing the date line in 2011; Venezuela back on UTC−4; Kazakhstan's single time from 2024; Paris's next change on 25 October 2026.
- **Freshness.** The database is as current as the device's system; World Time never ships its own copy.

## Zone names: Unicode CLDR

- **Source.** The Unicode Common Locale Data Repository, https://cldr.unicode.org, as built into iOS and read through `TimeZone.localizedName(for:locale:)`.
- **What World Time reads from it.** Each zone's name in the person's own language, standard or summer: "China Standard Time", "Taiwan Standard Time", "Irkutsk Standard Time", "British Summer Time". A zone whose CLDR name is only an offset falls back to its generic name, such as "Bougainville Time".
- **How names group.** World Time groups every place keeping one offset by the name its zone goes by, so UTC+8 reads as China Standard Time (China, Macao), Taiwan Standard Time (Taiwan), Hong Kong Standard Time, Irkutsk Standard Time (Irkutsk Oblast and Buryatia, Russia), and so on. The person can lead each card with any of them; the choice is kept on the device.

## Abbreviations

- **Source.** A curated table in `jpex/WorldTime/ZoneClock+Names.swift` of the letters in common English use, such as JST, KST, HKT, IST, AEST and CEST.
- **Rule.** A zone shows letters only while its offset is the one those letters stand for, so a place that changes its clocks never shows the wrong ones. Where a zone has no widely used letters, or they're in doubt (Kazakhstan since it took one time in 2024), it shows its UTC offset instead.

## Official and local names

A small table in `jpex/WorldTime/ZoneClock+Names.swift` gives what a zone is officially called where it's kept, where that differs from CLDR's name, and its name in the local language. Each is as the country's timekeeper or law names it:

| Zone | Official name | Local name | Source |
|---|---|---|---|
| Asia/Taipei | National Standard Time | 國家標準時間 | National Time and Frequency Standard Laboratory, Taiwan, https://www.stdtime.gov.tw |
| Asia/Shanghai | Beijing Time | 北京时间 | National Time Service Center, Chinese Academy of Sciences, https://www.ntsc.ac.cn |
| Asia/Hong_Kong | Hong Kong Time | 香港時間 | Hong Kong Observatory, https://www.hko.gov.hk |
| Asia/Tokyo | – | 日本標準時 | National Institute of Information and Communications Technology, https://jjy.nict.go.jp |
| Asia/Seoul | – | 한국 표준시 | Korea Research Institute of Standards and Science, https://www.kriss.re.kr |
| Asia/Kolkata | Indian Standard Time | भारतीय मानक समय | CSIR-National Physical Laboratory, India, https://www.nplindia.org |
| Asia/Manila | – | Pamantayang Oras ng Pilipinas | Republic Act No. 10535, the Philippine Standard Time Act of 2013; PAGASA, https://www.pagasa.dost.gov.ph |
| Asia/Jakarta, Asia/Makassar, Asia/Jayapura | – | Waktu Indonesia Barat, Tengah, Timur | Presidential Decree No. 41 of 1987 (Keputusan Presiden Nomor 41 Tahun 1987) |
| Europe/Moscow | Moscow Time | Московское время | Federal Law No. 107-FZ of 3 June 2011, "On the Calculation of Time" |

## Which parts of a country keep which time

- **Source.** A table in `jpex/WorldTime/TimeZoneAtlas+Subdivisions.swift` assigning each ISO 3166-2 subdivision of the countries spanning several zones (the United States, Canada, Australia, Brazil, Russia, Mexico, Indonesia, Mongolia, Chile, Ecuador, Spain, Portugal and Papua New Guinea) to a tz database zone, following the zone descriptions in the database's `zone1970.tab`.
- **Rule.** A subdivision split between zones keeps the one most of its people do: Texas keeps Central time though El Paso keeps Mountain, Nunavut keeps Eastern, Idaho keeps Mountain. Subdivisions the table leaves out keep their country's own time.
- **Where it shows.** Coloured by time zone, these countries are split along their zones; with a time picked, only the parts keeping it come forward; and the card names them, as "Kept in Irkutsk Oblast and Buryatia, Russia".
- **Outlines.** The subdivisions' outlines are the app's own maps, listed in `MAP_SOURCES.md` and the files beside it.

## Time zone colours

The colouring is drawn live, after the style of printed time zone maps such as the CIA's "Time Zones of the World": six soft colours repeating round the world, a zone a half or three quarters of an hour off sitting between its neighbours' colours. No map image is bundled.

- **The sea.** Real zones don't follow the meridians, so neither does the sea's colouring: each stretch of sea wears the time of the nearest land, worked out on the device from the same outlines the map draws (a distance transform over a half-degree raster, `jpex/WorldTime/SeaZones.swift`), so the zones run out from the coasts and meet in the open ocean, bending round island groups. Only beyond reach of any land does the sea keep its fifteen-degree nautical zone, as ships do on the high seas.
- **The International Date Line.** From Natural Earth's geographic lines (public domain), https://www.naturalearthdata.com, `ne_50m_geographic_lines`, simplified to 28 points: down the 180th meridian, round Chukotka, west of the Aleutians, east round Kiribati's Line Islands, between Samoa and American Samoa, and east of Tonga and the Chatham Islands.
- **The list's key.** Each zone's card carries its hours from UTC on a token of the same colour as on the map, the zones a quarter, half or three quarters of an hour off written with fractions: +5½, +5¾, +13¾.
