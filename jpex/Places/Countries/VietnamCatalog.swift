import Foundation

extension CountryCatalog {
    // Vietnam's 34 provinces and centrally run cities since the merger of 1 July 2025 (Resolution
    // 202/2025/QH15), with Đồng Nai, Quảng Ninh and Bắc Ninh made cities in 2026. ISO 3166-2:VN predates the
    // merger, so each ID is the former code of the unit whose name the new one kept, such as VN-29 for
    // Quảng Ngãi, which took in Kon Tum. None has a flag; each shows the national flag. See MORE_FLAG_SOURCES_D.md.
    static let vietnam = Country(
        id: "VN",
        name: "Vietnam",
        localName: "Việt Nam",
        divisionLabel: "Provinces & cities",
        groups: [
            vietnameseGroup("cities", name: "Centrally run cities", localName: "Thành phố trực thuộc trung ương", divisions: [
                ("56", "Bắc Ninh", nil),
                ("CT", "Cần Thơ", nil),
                ("DN", "Da Nang", "Đà Nẵng"),
                ("39", "Đồng Nai", nil),
                ("HP", "Haiphong", "Hải Phòng"),
                ("HN", "Hanoi", "Hà Nội"),
                ("SG", "Ho Chi Minh City", "Thành phố Hồ Chí Minh"),
                ("26", "Huế", nil),
                ("13", "Quảng Ninh", nil),
            ]),
            vietnameseGroup("provinces", name: "Provinces", localName: "Tỉnh", divisions: [
                ("44", "An Giang", nil),
                ("59", "Cà Mau", nil),
                ("04", "Cao Bằng", nil),
                ("33", "Đắk Lắk", nil),
                ("71", "Điện Biên", nil),
                ("45", "Đồng Tháp", nil),
                ("30", "Gia Lai", nil),
                ("23", "Hà Tĩnh", nil),
                ("66", "Hưng Yên", nil),
                ("34", "Khánh Hòa", nil),
                ("01", "Lai Châu", nil),
                ("35", "Lâm Đồng", nil),
                ("09", "Lạng Sơn", nil),
                ("02", "Lào Cai", nil),
                ("22", "Nghệ An", nil),
                ("18", "Ninh Bình", nil),
                ("68", "Phú Thọ", nil),
                ("29", "Quảng Ngãi", nil),
                ("25", "Quảng Trị", nil),
                ("05", "Sơn La", nil),
                ("37", "Tây Ninh", nil),
                ("69", "Thái Nguyên", nil),
                ("21", "Thanh Hóa", nil),
                ("07", "Tuyên Quang", nil),
                ("49", "Vĩnh Long", nil),
            ]),
        ]
    )

    private static func vietnameseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "VN-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "VN-\(place.code)",
                    countryID: "VN",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "VN-\(group)",
                    flagAssetName: "world_flag_vn",
                    flagNote: "Vietnam's provinces and centrally run cities have no official flags; the national flag is shown."
                )
            }
        )
    }
}
