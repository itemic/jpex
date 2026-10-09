# China catalog and flag sources

Verified on 6 October 2026.

## Administrative scope

`ChinaCatalog.swift` includes 33 administered provincial-level units: 22 mainland provinces, five autonomous regions, four direct-administered municipalities, and Hong Kong and Macao as Special Administrative Regions. The National Bureau of Statistics [mainland regional list](https://www.stats.gov.cn/english/PressRelease/202105/t20210510_1817188.html) identifies the 31 mainland units. The [State Council Information Office administrative-division list](https://english.scio.gov.cn/m/chinafacts/2017-04/17/content_40632751.htm) identifies the administrative categories and the two SARs.

Taiwan is outside this catalog of PRC-administered areas. The ISO `CN-TW` claimed-subdivision entry is therefore not included; Taiwan can be tracked through its separate `TW` country-level entry. This is an administrative-scope choice, not a statement resolving territorial claims. No territorial-claim geometry is used by this catalog.

Permanent record IDs use the alphabetic ISO 3166-2:CN subdivision codes. The [ISO Online Browsing Platform](https://www.iso.org/obp/ui/#iso:code:3166:CN) is the canonical code reference; the current code-to-name associations were cross-checked against the [Unicode CLDR subdivision registry](https://github.com/unicode-org/cldr/blob/main/common/subdivisions/en.xml) and the [ISO code change history](https://en.wikipedia.org/wiki/ISO_3166-2:CN). In particular, `HI` means Hainan, `HA` Henan, `HE` Hebei, `HL` Heilongjiang, `SN` Shaanxi, and `SX` Shanxi. Existing identifiers must not change when display names or catalog ordering change.

| Group | Subdivision codes |
| --- | --- |
| Provinces (22) | AH, FJ, GS, GD, GZ, HI, HE, HL, HA, HB, HN, JS, JX, JL, LN, QH, SN, SD, SX, SC, YN, ZJ |
| Autonomous regions (5) | GX, NM, NX, XZ, XJ |
| Municipalities (4) | BJ, CQ, SH, TJ |
| Special administrative regions (2) | HK, MO |

Names use familiar English labels with Chinese local names. Mainland local names are simplified Chinese; the two SAR local names use their traditional Chinese spelling. Tibet is the English display name for subdivision `CN-XZ` (Xizang).

## Artwork

The mainland entries use the national flag, with an explicit note in each entry's details. Historical, separatist, unofficial, or invented provincial emblems are not substituted for it. Hong Kong and Macao use their official regional flags. All three SVG files are downloaded original artwork, unmodified, bundled locally and available offline.

| Asset | Source | Artist / file attribution | License |
| --- | --- | --- | --- |
| `cn_flag` | [People's Republic of China flag](https://commons.wikimedia.org/wiki/File:Flag_of_the_People%27s_Republic_of_China.svg) | Zeng Liansong; Wikimedia Commons contributors | Public domain, as documented on the source page |
| `cn_flag_hk` | [Hong Kong flag](https://commons.wikimedia.org/wiki/File:Flag_of_Hong_Kong.svg) | Tao Ho; Open Clip Art, Alkari, Mike Rohsopht and Wikimedia Commons contributors | Public domain, as documented on the source page |
| `cn_flag_mo` | [Macao flag](https://commons.wikimedia.org/wiki/File:Flag_of_Macau.svg) | Wikimedia Commons contributors; see file history | Public domain, as documented on the source page |

The [Hong Kong Government Protocol Division specifications](https://www.protocol.gov.hk/en/flags-emblems-anthem.html) verify the national and Hong Kong regional designs. The [Macao SAR Government flag specifications](https://www.gov.mo/zh-hant/apm-info-page/funcionamento-e-procedimento-administrativos/bandeiras-e-emblemas-nacionais-e-regionais/) verify the Macao regional design. The same artwork provenance is bundled in `ChinaFlagCredits.json` for the app's Acknowledgements screen.

The catalog uses full official flags as source artwork. Row-background crops and fades are presentation effects; the complete flag remains available in the subdivision details.
