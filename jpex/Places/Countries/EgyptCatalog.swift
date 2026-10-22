import Foundation

extension CountryCatalog {
    // Egypt's 27 governorates. IDs follow ISO 3166-2:EG.
    // Governorates whose current flag has no accurate artwork show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and EgyptFlagCredits.json.
    static let egypt = Country(
        id: "EG",
        name: "Egypt",
        localName: "مصر",
        divisionLabel: "Governorates",
        groups: [
            egyptianGroup("governorates", name: "Governorates", localName: "المحافظات", divisions: [
                ("ALX", "Alexandria", "الإسكندرية"),
                ("ASN", "Aswan", "أسوان"),
                ("AST", "Asyut", "أسيوط"),
                ("BH", "Beheira", "البحيرة"),
                ("BNS", "Beni Suef", "بني سويف"),
                ("C", "Cairo", "القاهرة"),
                ("DK", "Dakahlia", "الدقهلية"),
                ("DT", "Damietta", "دمياط"),
                ("FYM", "Faiyum", "الفيوم"),
                ("GH", "Gharbia", "الغربية"),
                ("GZ", "Giza", "الجيزة"),
                ("IS", "Ismailia", "الإسماعيلية"),
                ("KFS", "Kafr El Sheikh", "كفر الشيخ"),
                ("LX", "Luxor", "الأقصر"),
                ("MT", "Matrouh", "مطروح"),
                ("MN", "Minya", "المنيا"),
                ("MNF", "Monufia", "المنوفية"),
                ("WAD", "New Valley", "الوادي الجديد"),
                ("SIN", "North Sinai", "شمال سيناء"),
                ("PTS", "Port Said", "بورسعيد"),
                ("KB", "Qalyubia", "القليوبية"),
                ("KN", "Qena", "قنا"),
                ("BA", "Red Sea", "البحر الأحمر"),
                ("SHR", "Sharqia", "الشرقية"),
                ("SHG", "Sohag", "سوهاج"),
                ("JS", "South Sinai", "جنوب سيناء"),
                ("SUZ", "Suez", "السويس"),
            ]),
        ]
    )

    /// Governorates shown with the national flag, with the reason.
    private static let egyptianFlagNotes: [String: String] = [
        "C": "The national flag is shown; no reliable artwork of Cairo Governorate's flag is available.",
        "FYM": "The national flag is shown; artwork for Faiyum's current governorate flag (2016) is not available.",
        "LX": "The national flag is shown; artwork for Luxor's current governorate flag is not available.",
        "MT": "The national flag is shown; artwork for Matrouh's current governorate flag (2016) is not available.",
        "SIN": "The national flag is shown; artwork for North Sinai's current governorate flag is not available.",
        "KB": "The national flag is shown; artwork for Qalyubia's current governorate flag (2016) is not available.",
        "SHG": "The national flag is shown; artwork for Sohag's current governorate flag (2020) is not available.",
    ]

    private static func egyptianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "EG-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = egyptianFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "EG-\(place.code)",
                    countryID: "EG",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "EG-\(group)",
                    flagAssetName: flagNote == nil ? "eg_flag_\(place.code.lowercased())" : "world_flag_eg",
                    flagNote: flagNote
                )
            }
        )
    }
}
