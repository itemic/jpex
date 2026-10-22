import Foundation

extension CountryCatalog {
    // Scotland's 32 council areas, Wales's 22 principal areas and Northern Ireland's 11 districts, a
    // list for each opened from its row on the United Kingdom's list, or on the World's when it lists
    // the UK's nations. IDs follow ISO 3166-2:GB. Local names are the standard Scottish Gaelic forms,
    // the official Welsh names, and the Irish names the five Northern Irish councils with one use
    // officially; names spelled the same are left out. Wales is grouped by its four regions. Council
    // flags aren't included: each place shows its nation's flag, or for Northern Ireland the Union
    // Flag. Maps: ONS, May 2026; see MAP_SOURCES_D.md.
    static let britishCouncilLists: [Country] = [
        subdivisionList(
            of: "GB-SCT", in: unitedKingdom, label: "Council areas",
            groups: [
                (slug: "councils", name: "Council areas", localName: nil, places: [
                    ("ABE", "Aberdeen", "Obar Dheathain"),
                    ("ABD", "Aberdeenshire", "Siorrachd Obar Dheathain"),
                    ("ANS", "Angus", "Aonghas"),
                    ("AGB", "Argyll and Bute", "Earra-Ghàidheal is Bòd"),
                    ("CLK", "Clackmannanshire", "Siorrachd Chlach Mhanann"),
                    ("DGY", "Dumfries and Galloway", "Dùn Phris is Gall-Ghàidhealaibh"),
                    ("DND", "Dundee", "Dùn Dè"),
                    ("EAY", "East Ayrshire", "Siorrachd Àir an Ear"),
                    ("EDU", "East Dunbartonshire", "Siorrachd Dhùn Breatann an Ear"),
                    ("ELN", "East Lothian", "Lodainn an Ear"),
                    ("ERW", "East Renfrewshire", "Siorrachd Rinn Friù an Ear"),
                    ("EDH", "Edinburgh", "Dùn Èideann"),
                    ("FAL", "Falkirk", "An Eaglais Bhreac"),
                    ("FIF", "Fife", "Fìobha"),
                    ("GLG", "Glasgow", "Glaschu"),
                    ("HLD", "Highland", "A' Ghàidhealtachd"),
                    ("IVC", "Inverclyde", "Inbhir Chluaidh"),
                    ("MLN", "Midlothian", "Lodainn Mheadhanach"),
                    ("MRY", "Moray", "Moireibh"),
                    ("ELS", "Na h-Eileanan Siar", nil),
                    ("NAY", "North Ayrshire", "Siorrachd Àir a Tuath"),
                    ("NLK", "North Lanarkshire", "Siorrachd Lannraig a Tuath"),
                    ("ORK", "Orkney Islands", "Arcaibh"),
                    ("PKN", "Perth and Kinross", "Peairt is Ceann Rois"),
                    ("RFW", "Renfrewshire", "Siorrachd Rinn Friù"),
                    ("SCB", "Scottish Borders", "Crìochan na h-Alba"),
                    ("ZET", "Shetland Islands", "Sealtainn"),
                    ("SAY", "South Ayrshire", "Siorrachd Àir a Deas"),
                    ("SLK", "South Lanarkshire", "Siorrachd Lannraig a Deas"),
                    ("STG", "Stirling", "Sruighlea"),
                    ("WDU", "West Dunbartonshire", "Siorrachd Dhùn Breatann an Iar"),
                    ("WLN", "West Lothian", "Lodainn an Iar"),
                ]),
            ],
            flagNote: "The flag of Scotland is shown; council flags aren't included."),
        subdivisionList(
            of: "GB-WLS", in: unitedKingdom, label: "Principal areas",
            groups: [
                (slug: "north", name: "North Wales", localName: nil, places: [
                    ("CWY", "Conwy", nil),
                    ("DEN", "Denbighshire", "Sir Ddinbych"),
                    ("FLN", "Flintshire", "Sir y Fflint"),
                    ("GWN", "Gwynedd", nil),
                    ("AGY", "Isle of Anglesey", "Ynys Môn"),
                    ("WRX", "Wrexham", "Wrecsam"),
                ]),
                (slug: "mid", name: "Mid Wales", localName: nil, places: [
                    ("CGN", "Ceredigion", nil),
                    ("POW", "Powys", nil),
                ]),
                (slug: "south-west", name: "South West Wales", localName: nil, places: [
                    ("CMN", "Carmarthenshire", "Sir Gaerfyrddin"),
                    ("NTL", "Neath Port Talbot", "Castell-nedd Port Talbot"),
                    ("PEM", "Pembrokeshire", "Sir Benfro"),
                    ("SWA", "Swansea", "Abertawe"),
                ]),
                (slug: "south-east", name: "South East Wales", localName: nil, places: [
                    ("BGW", "Blaenau Gwent", nil),
                    ("BGE", "Bridgend", "Pen-y-bont ar Ogwr"),
                    ("CAY", "Caerphilly", "Caerffili"),
                    ("CRF", "Cardiff", "Caerdydd"),
                    ("MTY", "Merthyr Tydfil", "Merthyr Tudful"),
                    ("MON", "Monmouthshire", "Sir Fynwy"),
                    ("NWP", "Newport", "Casnewydd"),
                    ("RCT", "Rhondda Cynon Taf", nil),
                    ("TOF", "Torfaen", nil),
                    ("VGL", "Vale of Glamorgan", "Bro Morgannwg"),
                ]),
            ],
            flagNote: "The flag of Wales is shown; council flags aren't included."),
        subdivisionList(
            of: "GB-NIR", in: unitedKingdom, label: "Districts",
            groups: [
                (slug: "districts", name: "Districts", localName: nil, places: [
                    ("ANN", "Antrim and Newtownabbey", nil),
                    ("AND", "Ards and North Down", nil),
                    ("ABC", "Armagh City, Banbridge and Craigavon", nil),
                    ("BFS", "Belfast", "Béal Feirste"),
                    ("CCG", "Causeway Coast and Glens", nil),
                    ("DRS", "Derry City and Strabane", "Cathair Dhoire agus an Srath Bán"),
                    ("FMO", "Fermanagh and Omagh", "Fear Manach agus an Ómaigh"),
                    ("LBC", "Lisburn and Castlereagh", nil),
                    ("MEA", "Mid and East Antrim", nil),
                    ("MUL", "Mid Ulster", "Lár Uladh"),
                    ("NMD", "Newry, Mourne and Down", "An tIúr, Múrn agus an Dún"),
                ]),
            ],
            flagNote: "The Union Flag is shown; council flags aren't included."),
    ]
}
