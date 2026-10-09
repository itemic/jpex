import Foundation

extension CountryCatalog {
    // South Korea's 16 first-level divisions: Seoul, five metropolitan cities, Sejong, Jeonnam-Gwangju and
    // eight provinces (Gangwon, Jeonbuk and Jeju are special self-governing provinces). IDs follow ISO 3166-2:KR.
    // South Jeolla (KR-46) and Gwangju (KR-29) merged into Jeonnam-Gwangju Special Metropolitan City on
    // 1 July 2026; it has no ISO code yet, so it uses KR-JG, and levels set on the two carry over to it.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and SouthKoreaFlagCredits.json.
    static let southKorea = Country(
        id: "KR",
        name: "South Korea",
        localName: "대한민국",
        divisionLabel: "Provinces & cities",
        groups: [
            koreanGroup("cities", name: "Special & metropolitan cities", localName: "특별시·광역시", divisions: [
                ("11", "Seoul", "서울특별시"),
                ("26", "Busan", "부산광역시"),
                ("27", "Daegu", "대구광역시"),
                ("28", "Incheon", "인천광역시"),
                ("30", "Daejeon", "대전광역시"),
                ("31", "Ulsan", "울산광역시"),
                ("50", "Sejong", "세종특별자치시"),
                ("JG", "Jeonnam-Gwangju", "전남광주통합특별시"),
            ]),
            koreanGroup("provinces", name: "Provinces", localName: "도", divisions: [
                ("41", "Gyeonggi", "경기도"),
                ("42", "Gangwon", "강원특별자치도"),
                ("43", "North Chungcheong", "충청북도"),
                ("44", "South Chungcheong", "충청남도"),
                ("45", "Jeonbuk", "전북특별자치도"),
                ("47", "North Gyeongsang", "경상북도"),
                ("48", "South Gyeongsang", "경상남도"),
                ("49", "Jeju", "제주특별자치도"),
            ]),
        ]
    )

    private static func koreanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "KR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "KR-\(place.code)",
                    countryID: "KR",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "KR-\(group)",
                    // Jeonnam-Gwangju has no flag of its own yet, so it shows the national flag.
                    flagAssetName: place.code == "JG" ? "world_flag_kr" : "kr_flag_\(place.code.lowercased())",
                    flagNote: place.code == "JG"
                        ? "Jeonnam-Gwangju Special Metropolitan City, formed in July 2026, has no flag yet; the national flag is shown."
                        : nil
                )
            }
        )
    }
}
