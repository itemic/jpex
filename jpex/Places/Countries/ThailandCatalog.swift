import Foundation

extension CountryCatalog {
    // Thailand's 76 provinces and Bangkok, in six geographic regions. IDs follow ISO 3166-2:TH;
    // Pattaya (TH-S) lies within Chon Buri and is not listed separately.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and ThailandFlagCredits.json.
    static let thailand = Country(
        id: "TH",
        name: "Thailand",
        localName: "ประเทศไทย",
        divisionLabel: "Provinces",
        groups: [
            thaiRegion("northern", name: "Northern", localName: "ภาคเหนือ", divisions: [
                ("50", "Chiang Mai", "เชียงใหม่"),
                ("57", "Chiang Rai", "เชียงราย"),
                ("52", "Lampang", "ลำปาง"),
                ("51", "Lamphun", "ลำพูน"),
                ("58", "Mae Hong Son", "แม่ฮ่องสอน"),
                ("55", "Nan", "น่าน"),
                ("56", "Phayao", "พะเยา"),
                ("54", "Phrae", "แพร่"),
                ("53", "Uttaradit", "อุตรดิตถ์"),
            ]),
            thaiRegion("northeastern", name: "Northeastern", localName: "ภาคตะวันออกเฉียงเหนือ", divisions: [
                ("37", "Amnat Charoen", "อำนาจเจริญ"),
                ("38", "Bueng Kan", "บึงกาฬ"),
                ("31", "Buriram", "บุรีรัมย์"),
                ("36", "Chaiyaphum", "ชัยภูมิ"),
                ("46", "Kalasin", "กาฬสินธุ์"),
                ("40", "Khon Kaen", "ขอนแก่น"),
                ("42", "Loei", "เลย"),
                ("44", "Maha Sarakham", "มหาสารคาม"),
                ("49", "Mukdahan", "มุกดาหาร"),
                ("48", "Nakhon Phanom", "นครพนม"),
                ("30", "Nakhon Ratchasima", "นครราชสีมา"),
                ("39", "Nong Bua Lamphu", "หนองบัวลำภู"),
                ("43", "Nong Khai", "หนองคาย"),
                ("45", "Roi Et", "ร้อยเอ็ด"),
                ("47", "Sakon Nakhon", "สกลนคร"),
                ("33", "Si Sa Ket", "ศรีสะเกษ"),
                ("32", "Surin", "สุรินทร์"),
                ("34", "Ubon Ratchathani", "อุบลราชธานี"),
                ("41", "Udon Thani", "อุดรธานี"),
                ("35", "Yasothon", "ยโสธร"),
            ]),
            thaiRegion("central", name: "Central", localName: "ภาคกลาง", divisions: [
                ("10", "Bangkok", "กรุงเทพมหานคร"),
                ("15", "Ang Thong", "อ่างทอง"),
                ("18", "Chai Nat", "ชัยนาท"),
                ("62", "Kamphaeng Phet", "กำแพงเพชร"),
                ("16", "Lopburi", "ลพบุรี"),
                ("26", "Nakhon Nayok", "นครนายก"),
                ("73", "Nakhon Pathom", "นครปฐม"),
                ("60", "Nakhon Sawan", "นครสวรรค์"),
                ("12", "Nonthaburi", "นนทบุรี"),
                ("13", "Pathum Thani", "ปทุมธานี"),
                ("67", "Phetchabun", "เพชรบูรณ์"),
                ("66", "Phichit", "พิจิตร"),
                ("65", "Phitsanulok", "พิษณุโลก"),
                ("14", "Phra Nakhon Si Ayutthaya", "พระนครศรีอยุธยา"),
                ("11", "Samut Prakan", "สมุทรปราการ"),
                ("74", "Samut Sakhon", "สมุทรสาคร"),
                ("75", "Samut Songkhram", "สมุทรสงคราม"),
                ("19", "Saraburi", "สระบุรี"),
                ("17", "Sing Buri", "สิงห์บุรี"),
                ("64", "Sukhothai", "สุโขทัย"),
                ("72", "Suphan Buri", "สุพรรณบุรี"),
                ("61", "Uthai Thani", "อุทัยธานี"),
            ]),
            thaiRegion("eastern", name: "Eastern", localName: "ภาคตะวันออก", divisions: [
                ("24", "Chachoengsao", "ฉะเชิงเทรา"),
                ("22", "Chanthaburi", "จันทบุรี"),
                ("20", "Chon Buri", "ชลบุรี"),
                ("25", "Prachin Buri", "ปราจีนบุรี"),
                ("21", "Rayong", "ระยอง"),
                ("27", "Sa Kaeo", "สระแก้ว"),
                ("23", "Trat", "ตราด"),
            ]),
            thaiRegion("western", name: "Western", localName: "ภาคตะวันตก", divisions: [
                ("71", "Kanchanaburi", "กาญจนบุรี"),
                ("76", "Phetchaburi", "เพชรบุรี"),
                ("77", "Prachuap Khiri Khan", "ประจวบคีรีขันธ์"),
                ("70", "Ratchaburi", "ราชบุรี"),
                ("63", "Tak", "ตาก"),
            ]),
            thaiRegion("southern", name: "Southern", localName: "ภาคใต้", divisions: [
                ("86", "Chumphon", "ชุมพร"),
                ("81", "Krabi", "กระบี่"),
                ("80", "Nakhon Si Thammarat", "นครศรีธรรมราช"),
                ("96", "Narathiwat", "นราธิวาส"),
                ("94", "Pattani", "ปัตตานี"),
                ("82", "Phang Nga", "พังงา"),
                ("93", "Phatthalung", "พัทลุง"),
                ("83", "Phuket", "ภูเก็ต"),
                ("85", "Ranong", "ระนอง"),
                ("91", "Satun", "สตูล"),
                ("90", "Songkhla", "สงขลา"),
                ("84", "Surat Thani", "สุราษฎร์ธานี"),
                ("92", "Trang", "ตรัง"),
                ("95", "Yala", "ยะลา"),
            ]),
        ]
    )

    /// Provinces shown with the national flag, with the reason.
    private static let thaiProvinceFlagNotes: [String: String] = [
        // Lopburi's provincial seal, and so its flag, changed by announcement of 20 August 2026;
        // no artwork of the new flag is available yet.
        "16": "The national flag is shown; artwork for Lopburi's new 2026 provincial flag is not available yet.",
    ]

    private static func thaiRegion(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "TH-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = thaiProvinceFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "TH-\(place.code)",
                    countryID: "TH",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "TH-\(group)",
                    flagAssetName: flagNote == nil ? "th_flag_\(place.code)" : "world_flag_th",
                    flagNote: flagNote
                )
            }
        )
    }
}
