import Foundation

extension CountryCatalog {
    // Iraq's 19 governorates: the 18 in ISO 3166-2:IQ plus Halabja, with Duhok, Erbil, Halabja and Sulaymaniyah
    // under the Kurdistan Region (IQ-KR, which is a region rather than a governorate, is not listed). Halabja was split
    // from Sulaymaniyah by a law passed on 14 April 2025 and in force since its publication on 5 May 2025; it has no
    // ISO 3166-2 code yet, so it uses "IQ-HA".
    // Governorate flags are the governorate logo on a white field; only Basra's and Kirkuk's current flags have accurate
    // artwork. The others show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_B.md and IraqFlagCredits.json.
    static let iraq = Country(
        id: "IQ",
        name: "Iraq",
        localName: "العراق",
        divisionLabel: "Governorates",
        groups: [
            iraqiGroup("governorates", name: "Governorates", localName: "المحافظات", divisions: [
                ("AN", "Anbar", "الأنبار"),
                ("BB", "Babylon", "بابل"),
                ("BG", "Baghdad", "بغداد"),
                ("BA", "Basra", "البصرة"),
                ("DQ", "Dhi Qar", "ذي قار"),
                ("DI", "Diyala", "ديالى"),
                ("KA", "Karbala", "كربلاء"),
                ("KI", "Kirkuk", "كركوك"),
                ("MA", "Maysan", "ميسان"),
                ("MU", "Muthanna", "المثنى"),
                ("NA", "Najaf", "النجف"),
                ("NI", "Nineveh", "نينوى"),
                ("QA", "Qadisiyah", "القادسية"),
                ("SD", "Saladin", "صلاح الدين"),
                ("WA", "Wasit", "واسط"),
            ]),
            iraqiGroup("kurdistan", name: "Kurdistan Region", localName: "هەرێمی کوردستان", divisions: [
                ("DA", "Duhok", "دھۆک"),
                ("AR", "Erbil", "ھەولێر"),
                ("HA", "Halabja", "ھەڵەبجە"),
                ("SU", "Sulaymaniyah", "سلێمانی"),
            ]),
        ]
    )

    /// Governorates shown with the national flag, and why. Governorate flags are the logo on a white field;
    /// only Basra (2022) and Kirkuk (2025) have accurate artwork of their current flags.
    private static let iraqiFlagNotes: [String: String] = [
        "AN": "The national flag is shown; no accurate artwork of Anbar Governorate's flag is available.",
        "BB": "The national flag is shown; no accurate artwork of Babylon Governorate's flag is available.",
        "BG": "The national flag is shown; no accurate artwork of Baghdad Governorate's flag is available.",
        "DQ": "The national flag is shown; no accurate artwork of Dhi Qar Governorate's flag is available.",
        "DI": "The national flag is shown; no accurate artwork of Diyala Governorate's flag is available.",
        "KA": "The national flag is shown; no accurate artwork of Karbala Governorate's flag is available.",
        "MA": "The national flag is shown; no accurate artwork of Maysan Governorate's flag is available.",
        "MU": "The national flag is shown; no current flag of Muthanna Governorate is known.",
        "NA": "The national flag is shown; no accurate artwork of Najaf Governorate's flag is available.",
        "NI": "The national flag is shown; no accurate artwork of Nineveh Governorate's flag is available.",
        "QA": "The national flag is shown; no accurate artwork of Qadisiyah Governorate's flag is available.",
        "SD": "The national flag is shown; no accurate artwork of Saladin Governorate's flag is available.",
        "WA": "The national flag is shown; no accurate artwork of Wasit Governorate's flag is available.",
        "DA": "The national flag is shown; no current flag of Duhok Governorate is known.",
        "AR": "The national flag is shown; no current flag of Erbil Governorate is known.",
        "SU": "The national flag is shown; no accurate artwork of Sulaymaniyah Governorate's flag is available.",
        "HA": "The national flag is shown; no flag of Halabja Governorate is known.",
    ]

    private static func iraqiGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "IQ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = iraqiFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "IQ-\(place.code)",
                    countryID: "IQ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "IQ-\(group)",
                    flagAssetName: flagNote == nil ? "iq_flag_\(place.code.lowercased())" : "world_flag_iq",
                    flagNote: flagNote
                )
            }
        )
    }
}
