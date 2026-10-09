import Foundation

extension CountryCatalog {
    // Scope: 31 mainland provincial-level units and two Special Administrative Regions.
    // Identifiers follow the current alphabetic ISO 3166-2:CN subdivision codes.
    // Grouped into the seven traditional geographical regions (华北, 东北, 华东, 华中, 华南, 西南, 西北),
    // with places listed in administrative-code order. Group IDs are display data only.
    // Short names are the one-character abbreviations (简称) on mainland licence plates, so the
    // Special Administrative Regions, which issue their own plates, have none.
    // See CN_FLAG_SOURCES.md for source references and catalog scope decisions.
    static let china = Country(
        id: "CN",
        name: "China",
        localName: "中国",
        divisionLabel: "Provinces & regions",
        groups: [
            chineseRegion("north", name: "North China", localName: "华北", divisions: [
                ("BJ", "Beijing", "北京市", "京", nil),
                ("TJ", "Tianjin", "天津市", "津", nil),
                ("HE", "Hebei", "河北省", "冀", nil),
                ("SX", "Shanxi", "山西省", "晋", nil),
                ("NM", "Inner Mongolia", "内蒙古自治区", "蒙", nil),
            ]),
            chineseRegion("northeast", name: "Northeast China", localName: "东北", divisions: [
                ("LN", "Liaoning", "辽宁省", "辽", nil),
                ("JL", "Jilin", "吉林省", "吉", nil),
                ("HL", "Heilongjiang", "黑龙江省", "黑", nil),
            ]),
            chineseRegion("east", name: "East China", localName: "华东", divisions: [
                ("SH", "Shanghai", "上海市", "沪", nil),
                ("JS", "Jiangsu", "江苏省", "苏", nil),
                ("ZJ", "Zhejiang", "浙江省", "浙", nil),
                ("AH", "Anhui", "安徽省", "皖", nil),
                ("FJ", "Fujian", "福建省", "闽", nil),
                ("JX", "Jiangxi", "江西省", "赣", nil),
                ("SD", "Shandong", "山东省", "鲁", nil),
            ]),
            chineseRegion("central", name: "Central China", localName: "华中", divisions: [
                ("HA", "Henan", "河南省", "豫", nil),
                ("HB", "Hubei", "湖北省", "鄂", nil),
                ("HN", "Hunan", "湖南省", "湘", nil),
            ]),
            chineseRegion("south", name: "South China", localName: "华南", divisions: [
                ("GD", "Guangdong", "广东省", "粤", nil),
                ("GX", "Guangxi", "广西壮族自治区", "桂", nil),
                ("HI", "Hainan", "海南省", "琼", nil),
                ("HK", "Hong Kong SAR", "香港特別行政區", nil, "hk"),
                ("MO", "Macao SAR", "澳門特別行政區", nil, "mo"),
            ]),
            chineseRegion("southwest", name: "Southwest China", localName: "西南", divisions: [
                ("CQ", "Chongqing", "重庆市", "渝", nil),
                ("SC", "Sichuan", "四川省", "川", nil),
                ("GZ", "Guizhou", "贵州省", "贵", nil),
                ("YN", "Yunnan", "云南省", "云", nil),
                ("XZ", "Tibet", "西藏自治区", "藏", nil),
            ]),
            chineseRegion("northwest", name: "Northwest China", localName: "西北", divisions: [
                ("SN", "Shaanxi", "陕西省", "陕", nil),
                ("GS", "Gansu", "甘肃省", "甘", nil),
                ("QH", "Qinghai", "青海省", "青", nil),
                ("NX", "Ningxia", "宁夏回族自治区", "宁", nil),
                ("XJ", "Xinjiang", "新疆维吾尔自治区", "新", nil),
            ]),
        ]
    )

    private static func chineseRegion(
        _ region: String,
        name: String,
        localName: String,
        divisions: [(code: String, name: String, localName: String, shortName: String?, flag: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "CN-\(region)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "CN-\(place.code)",
                    countryID: "CN",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "CN-\(region)",
                    flagAssetName: place.flag.map { "cn_flag_\($0)" } ?? "cn_flag",
                    flagNote: place.flag == nil ? "The national flag of China is shown here." : nil,
                    shortName: place.shortName
                )
            }
        )
    }
}
