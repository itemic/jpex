# World formal names: sources

`jpex/WorldFormalNames.swift` adds `CountryCatalog.formalNames`: the formal (full official) name shown beneath each place's short name in the World list. Keys are ISO 3166-1 alpha-2 codes, plus the user-assigned XK for Kosovo and XC for Northern Cyprus. It has 175 names. The other 76 places are left out; they're listed below with the reason. Including a name is not a statement on sovereignty.

Checked 8 October 2026.

## Sources

### UN member states and observer states (159 names)

- **UNTERM**, the [United Nations Terminology Database](https://unterm.un.org/unterm2/en/country), gives each country's English "formal" name. Names were taken from UNTERM's own export of its country list ([download](https://conferences.unite.un.org/untermapi/api/term/downloadCountries)). The export has 197 records: the 193 member states, the two observer states (the Holy See and the State of Palestine), the Cook Islands and Niue. Where a name looked unexpected, the notes on that UNTERM record were read; they're quoted below.
- **UN Protocol and Liaison Service**, [Heads of State, Heads of Government, Ministers for Foreign Affairs](https://www.un.org/dgacm/sites/www.un.org.dgacm/files/Documents_Protocol/hspmfmlist3.pdf) (public list dated 19 September 2026). Its official titles, such as "President of the Republic of Italy", were used as a cross-check. Many countries' titles appear in French or Spanish, so this check is partial.
- **Wikipedia**, [List of sovereign states](https://en.wikipedia.org/wiki/List_of_sovereign_states), as a second cross-check. Every difference is explained under the judgement calls.

### Other places (16 names)

| Code | Formal name | Source |
| --- | --- | --- |
| TW | Republic of China (Taiwan) | The [Office of the President](https://english.president.gov.tw/) and the [Ministry of Foreign Affairs](https://www.mofa.gov.tw/en/) use this form in English |
| XK | Republic of Kosovo | Constitution of the Republic of Kosovo, art. 1: "The Republic of Kosovo is an independent, sovereign, democratic, unique and indivisible state" ([text](https://www.constituteproject.org/constitution/Kosovo_2016)) |
| XC | Turkish Republic of Northern Cyprus | Its constitution's name for the state, Kuzey Kıbrıs Türk Cumhuriyeti, in the English form its government uses |
| HK | Hong Kong Special Administrative Region of the People's Republic of China | The [Basic Law](https://www.basiclaw.gov.hk/en/basiclaw/index.html) of the Hong Kong SAR |
| MO | Macao Special Administrative Region of the People's Republic of China | The Basic Law of the Macao SAR ([text](https://www.cecc.gov/resources/legal-provisions/the-basic-law-of-the-macao-macau-special-administrative-region-of-the-prc)); the [Macao SAR Government Portal](https://www.gov.mo/en/) |
| PR | Commonwealth of Puerto Rico | Constitution of the Commonwealth of Puerto Rico, art. I §1: "The Commonwealth of Puerto Rico is hereby constituted" ([text](https://www.refworld.org/docid/3e9a9dba4.html)) |
| MP | Commonwealth of the Northern Mariana Islands | The Covenant, §101: "a self-governing commonwealth to be known as the 'Commonwealth of the Northern Mariana Islands'" ([48 U.S.C. §1801 note](https://www.govinfo.gov/content/pkg/USCODE-2022-title48/html/USCODE-2022-title48-chap17-subchapI-sec1801.htm)) |
| VI | United States Virgin Islands | The [Government of the United States Virgin Islands](https://www.vi.gov/): its seal (adopted 1991) and the Governor's letterhead |
| CX | Territory of Christmas Island | [Christmas Island Act 1958](https://legislation.gov.au/C1958A00041/asmade/1958-09-02/text/original/pdf): "the Territory" means the Territory of Christmas Island |
| CC | Territory of Cocos (Keeling) Islands | [Cocos (Keeling) Islands Act 1955](https://www.legislation.gov.au/C1955A00034): "the Territory" means the Territory of Cocos (Keeling) Islands |
| NF | Territory of Norfolk Island | [Norfolk Island Act 1979](https://www.legislation.gov.au/C2004A02035), s. 4 and Schedule 1 |
| HM | Territory of Heard Island and McDonald Islands | Heard Island and McDonald Islands Act 1953; the [Australian Antarctic Division](https://www.antarctica.gov.au/about-antarctica/australia-in-antarctica/the-territory-of-heard-island-and-mcdonald-islands/) |
| GG | Bailiwick of Guernsey | [Government House Guernsey](https://www.governmenthouse.gg/the-role-of-the-lieutenant-governor-in-the-bailiwick-of-guernsey): "The Bailiwick of Guernsey is one of three Crown Dependencies"; the States of Guernsey's Constitutional Position page |
| JE | Bailiwick of Jersey | The Government of Jersey's [Island Identity report](https://islandidentity.je/report/about-jersey/constitution-citizenship-legal-system): "The Bailiwick of Jersey is a self-governing Parliamentary Democracy" |
| PN | Pitcairn, Henderson, Ducie and Oeno Islands | [Pitcairn Constitution Order 2010](https://www.legislation.gov.uk/uksi/2010/244): "'Pitcairn' means Pitcairn, Henderson, Ducie and Oeno Islands" |
| TF | French Southern and Antarctic Lands | Terres australes et antarctiques françaises: French Constitution art. 72-3 and law no. 55-1052 of 6 August 1955. English rendering; see the judgement calls |

## Rules

- UN member states and the observer states use the UN's formal name. The Holy See is used for VA and the State of Palestine for PS. Names are current, for example Republic of Türkiye, Kingdom of Eswatini, Republic of North Macedonia, Plurinational State of Bolivia and Bolivarian Republic of Venezuela.
- All other places use their own official name in English, from their constitution, founding law or government, where one exists and differs from the short name. ISO 3166 names and any other name a place doesn't use for itself are not used, for example "Taiwan, Province of China".
- A leading "the" is dropped ("the Kingdom of Norway" becomes "Kingdom of Norway"). Official capitalisation and diacritics are kept, as in "Republic of Côte d'Ivoire" and "Commonwealth of The Bahamas".
- A place is left out when its formal name is the same as the app's short name, or differs only by "the". Places with no official name, or with a difference judged trivial, are also left out; those cases are listed below.
- Entries are sorted by code, one per line.

## Left out (76)

**UNTERM's formal name equals the short name once "the" is dropped (38).** AE United Arab Emirates, AG Antigua and Barbuda, AU Australia, BA Bosnia and Herzegovina, BB Barbados, BF Burkina Faso, BN Brunei Darussalam, BZ Belize, CA Canada, CD Democratic Republic of the Congo, CF Central African Republic, CG Republic of the Congo, CK Cook Islands, DO Dominican Republic, FM Federated States of Micronesia, GD Grenada, GE Georgia, HU Hungary, IE Ireland, IS Iceland, JM Jamaica, JP Japan, KN Saint Kitts and Nevis, LC Saint Lucia, ME Montenegro, MN Mongolia, MY Malaysia, NP Nepal, NU Niue, NZ New Zealand, RO Romania, SB Solomon Islands, TM Turkmenistan, TV Tuvalu, UA Ukraine, US United States of America, VA Holy See, VC Saint Vincent and the Grenadines.

**The official name equals the short name (20).** AI Anguilla, BM Bermuda, BV Bouvet Island, FK Falkland Islands, FO Faroe Islands, GF French Guiana, GI Gibraltar, GL Greenland, GP Guadeloupe, GS South Georgia and the South Sandwich Islands, GU Guam, IM Isle of Man, IO British Indian Ocean Territory, KY Cayman Islands, MQ Martinique, MS Montserrat, NC New Caledonia, PF French Polynesia, TC Turks and Caicos Islands, TK Tokelau.

**Judgement calls (13).** AS American Samoa, AW Aruba, AX Åland Islands, BL Saint Barthélemy, CW Curaçao, MF Saint Martin, PM Saint Pierre and Miquelon, RE Réunion, SH Saint Helena, Ascension and Tristan da Cunha, SX Sint Maarten, VG Virgin Islands (British), WF Wallis and Futuna, YT Mayotte. Each is explained below.

**No official long form (5).** AQ Antarctica, BQ Bonaire, Sint Eustatius and Saba, EH Western Sahara, SJ Svalbard and Jan Mayen, UM United States Minor Outlying Islands.

## Judgement calls

### Disputed and partly recognised places

- **Taiwan (TW): Republic of China (Taiwan).** The constitution names the state the Republic of China (中華民國). Taiwan's Office of the President and Ministry of Foreign Affairs write "Republic of China (Taiwan)" in English, so that form is used. Taiwan has not been represented at the UN since 1971 and has no UNTERM record. ISO 3166's "Taiwan, Province of China" is not used.
- **Kosovo (XK): Republic of Kosovo.** This is the name its constitution uses (art. 1). Kosovo is not a UN member, the UN refers to it under Security Council resolution 1244 (1999), and its recognition is disputed. XK is a user-assigned code.
- **Northern Cyprus (XC): Turkish Republic of Northern Cyprus.** This is the name its constitution gives the state. Only Türkiye recognises it; UN Security Council resolution 541 (1983) calls its declaration of independence legally invalid, and the island is otherwise part of the Republic of Cyprus. XC is a user-assigned code.
- **Palestine (PS): State of Palestine.** This is UNTERM's formal name for the observer state; the Protocol list writes "President of the State of Palestine".
- **Western Sahara (EH): none.** The UN lists it as a Non-Self-Governing Territory. Morocco administers most of it and the Sahrawi Arab Democratic Republic claims it, so no single official name is shared.
- **Afghanistan (AF): Islamic Republic of Afghanistan.** This is UNTERM's formal name, adopted in November 2004 according to its record. The Protocol list still titles the posts "of the Islamic Republic of Afghanistan" but names no one in them. The Taliban, in power since August 2021, style the country the "Islamic Emirate of Afghanistan", which Wikipedia uses. Only Russia has recognised that government (July 2025); the UN has not. The UN name is used per the rule. The alternative, if showing the former government's name is unwanted, is to leave AF out.
- **Myanmar (MM): Republic of the Union of Myanmar.** This has been UNTERM's formal name since 30 March 2011 and is in the Protocol list. The name is the same whichever authority is recognised, so the dispute over Myanmar's UN seat doesn't affect it. "Burma" is not used.
- **Holy See / Vatican City (VA): Holy See.** The UN observer state is the Holy See; the app's short name is Vatican City, so the Holy See is its subtitle. UNTERM notes that UN documents use "the Holy See", not "Vatican City State", except in ITU and UPU texts. The territory's own name, Vatican City State (Stato della Città del Vaticano), which Wikipedia gives as the formal name, was not used because the rule is to use the Holy See for VA.

### UN names that differ from a country's own usage or from Wikipedia

- **Italy (IT): Republic of Italy.** This is the English formal name in UNTERM (no note on the record) and in the Protocol list ("President of the Republic of Italy"). Italy's constitution names the state Repubblica Italiana, which Wikipedia renders as "Italian Republic". UNTERM's own French and Spanish formal names use that same form (la République italienne, la República Italiana); only its English one says "Republic of Italy". The UN English form is kept per the rule; change it to "Italian Republic" if Italy's own name is preferred.
- **Nauru (NR): Republic of Naoero.** Nauru renamed itself Naoero by a constitutional amendment certified on 13 May 2026. UNTERM: "Name changed from Nauru to Naoero by note verbale dated 6 July 2026. Name change in effect as of 26 June 2026." The Protocol list and Wikipedia also use "Republic of Naoero". The app's short name is now "Naoero" too.
- **Nepal (NP): left out.** UNTERM records that Nepal's formal name changed from "Federal Democratic Republic of Nepal" to "Nepal", following Nepal's note verbale of 16 November 2020, effective 14 December 2020. The Protocol list writes "President of Nepal". Wikipedia still gives the longer name.
- **Iceland (IS): left out.** UNTERM records that the official name changed from "Republic of Iceland" to "Iceland", following Iceland's communication of 12 October 2022.
- **Australia (AU): left out.** UNTERM's formal name is "Australia", and its record lists "Commonwealth of Australia" as a variant used outside the UN. The Protocol list's titles ("Prime Minister of the Commonwealth of Australia") and Wikipedia use the Constitution's name, Commonwealth of Australia. UNTERM is followed here; "Commonwealth of Australia" is the alternative.
- **Saint Kitts and Nevis (KN): left out.** UNTERM's formal name is "Saint Kitts and Nevis". Its note says the country is called the Federation of Saint Christopher and Nevis in other contexts, but not at the UN. Wikipedia gives "Federation of Saint Kitts and Nevis".
- **The Gambia (GM): Republic of The Gambia.** UNTERM writes "the Republic of the Gambia". The Protocol list writes "Republic of The Gambia", which is also the Gambian government's style and Wikipedia's. The capital "The" is kept as the official capitalisation. This is the only change made to a UNTERM name.
- **The Bahamas (BS): Commonwealth of The Bahamas.** UNTERM notes that The Bahamas' Permanent Representative confirmed the capital "T" by letter of 10 April 2025.
- **Uruguay (UY): Oriental Republic of Uruguay.** This is UNTERM's form, confirmed by Uruguay's note verbale of 19 December 2025. "Eastern Republic of Uruguay" is not used.
- **Netherlands (NL): Kingdom of the Netherlands.** This is UNTERM's formal name. After the Netherlands' request of 3 March 2023, the UN's short form also became "Netherlands (Kingdom of the)".
- **Czechia (CZ): Czech Republic.** This is UNTERM's formal name. It is a real difference from the short name, so it stays.
- **UN spellings** are kept even where the app's short name differs: Socialist Republic of Viet Nam, Lao People's Democratic Republic, and Democratic Republic of Sao Tome and Principe (without diacritics, as UNTERM writes it).
- **Names that only add "the"** are left out: CF, CD, DO, AE and US. The same applies where the app already uses the formal name: CG "Republic of the Congo", FM "Federated States of Micronesia" and BN "Brunei Darussalam".

### Territories, dependencies and special regions

- **Hong Kong and Macao** use the names in their Basic Laws. The official English spelling, "Macao", is kept even though the app's short name is "Macau".
- **United States.**
  - **PR, MP:** constitution and Covenant names, included.
  - **VI: United States Virgin Islands.** Borderline. The Revised Organic Act of 1954 ([48 U.S.C. §1541](https://www.govinfo.gov/content/pkg/USCODE-2011-title48/html/USCODE-2011-title48-chap12-subchapI-sec1541.htm)) says just "Virgin Islands". The territory's government calls itself the Government of the United States Virgin Islands, on its seal and letterhead. That spells out the app's "(U.S.)", so it is included as the place's own name.
  - **AS: left out.** The [Revised Constitution of American Samoa](https://faolex.fao.org/docs/pdf/ams72562.pdf) and the American Samoa Government use "American Samoa". "Territory of American Samoa" appears in a few statutes (for example [ASCA §1.0302](https://asbar.org/code-annotated/1-0302-motto/), the territorial motto) and is the CIA World Factbook's long form. It describes the territory's status rather than naming it, so it was not used. "Territory of American Samoa" is the alternative if wanted.
  - **GU: left out.** The Organic Act ([48 U.S.C. §1421](https://www.govinfo.gov/link/uscode/48/1421)) says the island "shall continue to be known as Guam". Guam's own code also prohibits the term "Territory" in official use ([1 GCA §420](https://col.guamcourts.gov/sites/default/files/01gc004_Q.pdf), "Affirmation of Self-Respect and Prohibition of Use of the Term 'Territory' in All Official Uses Within the Government of Guam").
  - **UM: left out.** It is an ISO grouping of separately administered islands with no official long form.
- **Australia:** each Act names its external territory "Territory of …" (CX, CC, NF, HM), so these are included.
- **United Kingdom.**
  - **GG, JE:** the Crown dependencies are bailiwicks. ISO's GG covers the whole Bailiwick of Guernsey, including Alderney and Sark. Both are included.
  - **PN:** the territory is named Pitcairn, Henderson, Ducie and Oeno Islands by its constitution, so it is included.
  - **SH: left out.** The [constitution order](https://www.legislation.gov.uk/uksi/2009/1751) names it "St Helena, Ascension and Tristan da Cunha", which differs only by "St".
  - **VG: left out.** The [Virgin Islands Constitution Order 2007](https://www.legislation.gov.uk/uksi/2007/1678) calls it "the Virgin Islands", which says less than the app's "Virgin Islands (British)".
  - **IM, AI, BM, KY, MS, TC, FK, GI, GS, IO:** official names equal the short names.
  - **IO:** the UK–Mauritius treaty signed on 22 May 2025 would end the territory once in force; this file doesn't track that.
- **Kingdom of the Netherlands.**
  - **AW, CW, SX: left out.** Their constitutions name them Aruba, Curaçao and Sint Maarten. The [English translation of Sint Maarten's constitution](https://repository.officiele-overheidspublicaties.nl/CVDR/CVDR179884/1/xml/i240624.pdf) reads "The territory of Sint Maarten consists of …". "Land Aruba", "Land Curaçao" and "Land Sint Maarten", rendered "Country of …" by Wikipedia and the CIA, name each country's public legal entity and its status in the Kingdom. Curaçao's constitution, art. 1: "Het Land Curaçao is een openbare rechtspersoon". They were treated like the French collectivité names below. Aruba's government ([gobierno.aw](https://www.gobierno.aw/en/governance-administration): "The Aruban government (The Country of Aruba)") and Sint Maarten's English law translations do use "the Country of …" for that entity. These would be the most defensible additions if wanted.
  - **BQ: left out.** Bonaire, Sint Eustatius and Saba are three public bodies of the Netherlands. "Caribbean Netherlands" is a collective term, not a formal name.
- **France.**
  - **TF: French Southern and Antarctic Lands.** Included as a judgement call. The official name, Terres australes et antarctiques françaises, exists only in French: it appears in the Constitution (art. 72-3) and the territory was created by law 55-1052. The TAAF's own website is in French only. "French Southern and Antarctic Lands" is the usual English rendering (Wikipedia, CIA, the OCTA page for the TAAF). ISO's "French Southern Territories" is not a name the territory uses for itself. ISO's TF also excludes Adélie Land, which falls under AQ. Remove the entry if only names published in English by the place's own government should count.
  - **BL, MF, PM: left out.** Their statutory names are collectivité de Saint-Barthélemy, collectivité de Saint-Martin and collectivité territoriale de Saint-Pierre-et-Miquelon (Code général des collectivités territoriales LO6211-1, LO6311-1, LO6411-1). These name the overseas collectivity, the local authority. They exist only in French and amount to a status word in front of the short name.
  - **WF: left out.** "Territoire des îles Wallis et Futuna" is left out for the same reason.
  - **YT: left out.** So is "Département de Mayotte", the name given by organic law 2010-1486.
  - **MQ, GF, GP: left out.** Martinique and French Guiana are each governed by a single collectivité territoriale (de Martinique, de Guyane). That is the local authority's name, not the place's, so they are left out like Guadeloupe.
  - **RE: left out.** The French name "La Réunion" only adds the article.
  - **PF, NC: left out.** Their official names, Polynésie française and Nouvelle-Calédonie, equal the short names.
- **Nordic countries.**
  - **AX: left out.** Åland's government calls it "Åland" ("Åland is an autonomous, demilitarised, Swedish-speaking region of Finland", [aland.ax](https://aland.ax/en/node/36)), which says less than "Åland Islands".
  - **FO, GL: left out.** The English names Faroe Islands (Føroyar) and Greenland (Kalaallit Nunaat) equal the short names.
  - **SJ: left out.** It is an ISO grouping of two separately governed Norwegian areas with no combined name.
  - **BV: left out.** Bouvetøya is Bouvet Island.
- **New Zealand's realm:** CK, NU and TK are left out. UNTERM lists the Cook Islands and Niue with formal names equal to their short names.
- **Antarctica (AQ): none.** It is governed by the Antarctic Treaty System and has no government to give it a formal name.

## Validation

The file was compiled with the model layer and a throwaway check program:

```sh
xcrun swiftc -parse-as-library -module-name Check -target "$(uname -m)-apple-macosx14.0" \
    jpex/VisitStatus.swift jpex/VisitLevel.swift jpex/VisitLadder.swift jpex/LevelColor.swift \
    jpex/Prefecture.swift jpex/AdministrativeDivision.swift jpex/Country.swift jpex/DivisionGroup.swift \
    jpex/*Catalog.swift jpex/CountingRules.swift jpex/CollectionSection.swift jpex/WorldFormalNames.swift \
    check.swift -o check && ./check jpex/WorldFormalNames.swift
```

The check confirmed the following:

- Every key is a code in `CountryCatalog.world`.
- No value equals its short name, even ignoring case, accents and a leading "the".
- No value starts with "the" or has stray whitespace.
- The source lists one `"XX": "…",` entry per line, sorted by code, with no repeated codes.

## Updating

Re-download the UNTERM export and compare it with this list. UNTERM's record notes date each change, such as Naoero (2026), Uruguay (2025), The Bahamas (2025), Iceland (2022) and Nepal (2020).
