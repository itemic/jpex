import Foundation

extension CountryCatalog {
    // Vientiane Prefecture and the 17 provinces of Laos, including Xaisomboun (re-established in 2013).
    // IDs follow ISO 3166-2:LA. None has an official flag, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let laos = Country(
        id: "LA",
        name: "Laos",
        localName: "ລາວ",
        divisionLabel: "Provinces",
        groups: [
            laoGroup("capital", name: "Capital", localName: "ນະຄອນຫຼວງ", divisions: [
                ("VT", "Vientiane Prefecture", "ນະຄອນຫຼວງວຽງຈັນ"),
            ]),
            laoGroup("provinces", name: "Provinces", localName: "ແຂວງ", divisions: [
                ("AT", "Attapeu", "ອັດຕະປື"),
                ("BK", "Bokeo", "ບໍ່ແກ້ວ"),
                ("BL", "Bolikhamsai", "ບໍລິຄຳໄຊ"),
                ("CH", "Champasak", "ຈຳປາສັກ"),
                ("HO", "Houaphanh", "ຫົວພັນ"),
                ("KH", "Khammouane", "ຄຳມ່ວນ"),
                ("LM", "Luang Namtha", "ຫຼວງນໍ້າທາ"),
                ("LP", "Luang Prabang", "ຫຼວງພະບາງ"),
                ("OU", "Oudomxay", "ອຸດົມໄຊ"),
                ("PH", "Phongsaly", "ຜົ້ງສາລີ"),
                ("XA", "Sainyabuli", "ໄຊຍະບູລີ"),
                ("SL", "Salavan", "ສາລະວັນ"),
                ("SV", "Savannakhet", "ສະຫວັນນະເຂດ"),
                ("XE", "Sekong", "ເຊກອງ"),
                ("VI", "Vientiane Province", "ແຂວງວຽງຈັນ"),
                ("XS", "Xaisomboun", "ໄຊສົມບູນ"),
                ("XI", "Xiangkhouang", "ຊຽງຂວາງ"),
            ]),
        ]
    )

    private static func laoGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "LA-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "LA-\(place.code)",
                    countryID: "LA",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "LA-\(group)",
                    flagAssetName: "world_flag_la",
                    flagNote: "The provinces of Laos and Vientiane Prefecture have no official flags; the national flag is shown."
                )
            }
        )
    }
}
