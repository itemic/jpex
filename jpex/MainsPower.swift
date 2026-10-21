import SwiftUI

/// The mains electricity a place's sockets give: the kinds of plug they take and their voltage and
/// frequency. Sources are in LAYER_SOURCES.md.
struct MainsPower {
    /// The kinds of plug its sockets take, its own national socket first, which the map colours it
    /// by: Germany's F rather than the Europlug, C, which fits nearly every round-pin socket.
    var plugs: [PlugType]
    var volts: [Int]
    var hertz: [Int]

    /// A place's mains, by its ISO 3166 code, or nil where nobody lives, such as Antarctica.
    static func of(_ code: String) -> MainsPower? {
        table[code]
    }

    var voltage: MainsVoltage {
        if volts.allSatisfy({ $0 < 150 }) { return .low }
        if volts.allSatisfy({ $0 >= 150 }) { return .high }
        return .both
    }

    /// The kinds of plug, such as "Types A and B".
    var plugSummary: String {
        let types = plugs.map(\.rawValue).formatted(.list(type: .and))
        return "\(plugs.count == 1 ? "Type" : "Types") \(types)"
    }

    /// The voltage and frequency, such as "100 V, 50 or 60 Hz".
    var powerSummary: String {
        let volts = volts.map { $0.formatted() }.formatted(.list(type: .or))
        let hertz = hertz.map { $0.formatted() }.formatted(.list(type: .or))
        return "\(volts) V, \(hertz) Hz"
    }

    /// The IEC lists a place's plugs alphabetically, so where C comes first, the national socket
    /// is the one after it, such as France's E. The table puts any other national socket first
    /// by hand, such as China's I and Italy's L.
    private init(_ plugs: [PlugType], _ volts: [Int], _ hertz: [Int]) {
        var plugs = plugs
        if plugs.count > 1, plugs[0] == .c { plugs.swapAt(0, 1) }
        self.plugs = plugs
        self.volts = volts
        self.hertz = hertz
    }

    private static let table: [String: MainsPower] = [
        "AD": MainsPower([.c, .f], [230], [50]),
        "AE": MainsPower([.g, .m], [230], [50]),
        "AF": MainsPower([.c, .f], [220], [50]),
        "AG": MainsPower([.a, .b], [230], [60]),
        "AI": MainsPower([.a], [110], [60]),
        "AL": MainsPower([.c, .f], [230], [50]),
        "AM": MainsPower([.c, .f], [230], [50]),
        "AO": MainsPower([.c], [220], [50]),
        "AR": MainsPower([.i], [220], [50]),
        "AS": MainsPower([.a, .b, .f, .i], [120], [60]),
        "AT": MainsPower([.c, .f], [230], [50]),
        "AU": MainsPower([.i], [230], [50]),
        "AW": MainsPower([.a, .b, .f], [127], [60]),
        "AX": MainsPower([.c, .f], [230], [50]),
        "AZ": MainsPower([.c, .f], [220], [50]),
        "BA": MainsPower([.c, .f], [230], [50]),
        "BB": MainsPower([.a, .b], [115], [50]),
        "BD": MainsPower([.c, .d, .g, .k], [220], [50]),
        "BE": MainsPower([.c, .e], [230], [50]),
        "BF": MainsPower([.c, .e], [220], [50]),
        "BG": MainsPower([.c, .f], [230], [50]),
        "BH": MainsPower([.g], [230], [50]),
        "BI": MainsPower([.c, .e], [220], [50]),
        "BJ": MainsPower([.c, .e], [220], [50]),
        "BL": MainsPower([.c, .e], [230], [60]),  // 60 Hz, unlike mainland France
        "BM": MainsPower([.a, .b], [120], [60]),
        "BN": MainsPower([.g], [240], [50]),
        "BO": MainsPower([.a, .c], [230, 115], [50]),
        "BQ": MainsPower([.a, .b], [127, 110], [50, 60]),  // Bonaire runs at 50 Hz; Saba and Sint Eustatius at 60 Hz
        "BR": MainsPower([.c, .n], [127, 220], [60]),  // 127 V or 220 V depending on the state or city
        "BS": MainsPower([.a, .b], [120], [60]),
        "BT": MainsPower([.d, .c, .f, .g, .m], [230], [50]),
        "BW": MainsPower([.d, .g, .m], [230], [50]),
        "BY": MainsPower([.c, .f], [220], [50]),
        "BZ": MainsPower([.a, .b, .g], [110, 220], [60]),
        "CA": MainsPower([.a, .b], [120], [60]),
        "CC": MainsPower([.i], [240], [50]),
        "CD": MainsPower([.c, .d, .e], [220], [50]),
        "CF": MainsPower([.c, .e], [220], [50]),
        "CG": MainsPower([.c, .e], [230], [50]),
        "CH": MainsPower([.c, .j], [230], [50]),
        "CI": MainsPower([.c, .e], [230], [50]),
        "CK": MainsPower([.i], [240], [50]),
        "CL": MainsPower([.c, .l], [220], [50]),
        "CM": MainsPower([.c, .e], [220], [50]),
        "CN": MainsPower([.i, .a], [220], [50]),
        "CO": MainsPower([.a, .b], [110], [60]),
        "CR": MainsPower([.a, .b], [120], [60]),
        "CU": MainsPower([.a, .b], [110], [60]),
        "CV": MainsPower([.c, .f], [220], [50]),
        "CW": MainsPower([.a, .b, .f], [127], [50]),
        "CX": MainsPower([.i], [240], [50]),
        "CY": MainsPower([.g], [240], [50]),
        "CZ": MainsPower([.c, .e], [230], [50]),
        "DE": MainsPower([.c, .f], [230], [50]),
        "DJ": MainsPower([.c, .e], [220], [50]),
        "DK": MainsPower([.k, .c, .e, .f], [230], [50]),
        "DM": MainsPower([.g, .d], [230], [50]),
        "DO": MainsPower([.a, .b], [110], [60]),
        "DZ": MainsPower([.c, .f], [230], [50]),
        "EC": MainsPower([.a, .b], [120], [60]),
        "EE": MainsPower([.c, .f], [230], [50]),
        "EG": MainsPower([.c, .f], [220], [50]),
        "EH": MainsPower([.c, .e], [220], [50]),
        "ER": MainsPower([.c, .l], [230], [50]),
        "ES": MainsPower([.c, .f], [230], [50]),
        "ET": MainsPower([.c, .f, .l], [220], [50]),
        "FI": MainsPower([.c, .f], [230], [50]),
        "FJ": MainsPower([.i], [240], [50]),
        "FK": MainsPower([.g], [240], [50]),
        "FM": MainsPower([.a, .b], [120], [60]),
        "FO": MainsPower([.k, .c, .e, .f], [230], [50]),
        "FR": MainsPower([.c, .e], [230], [50]),
        "GA": MainsPower([.c], [220], [50]),
        "GB": MainsPower([.g], [230], [50]),
        "GD": MainsPower([.g], [230], [50]),
        "GE": MainsPower([.c, .f], [220], [50]),
        "GF": MainsPower([.c, .d, .e], [220], [50]),
        "GG": MainsPower([.g], [230], [50]),
        "GH": MainsPower([.g, .d], [230], [50]),
        "GI": MainsPower([.g, .c], [240], [50]),
        "GL": MainsPower([.k, .c, .e, .f], [230], [50]),
        "GM": MainsPower([.g], [230], [50]),
        "GN": MainsPower([.c, .f, .k], [220], [50]),
        "GP": MainsPower([.c, .d, .e], [230], [50]),
        "GQ": MainsPower([.c, .e], [220], [50]),
        "GR": MainsPower([.c, .f], [230], [50]),
        "GT": MainsPower([.a, .b], [120], [60]),
        "GU": MainsPower([.a, .b], [110], [60]),
        "GW": MainsPower([.c], [220], [50]),
        "GY": MainsPower([.a, .b, .d, .g], [240], [60]),
        "HK": MainsPower([.g, .d], [220], [50]),
        "HN": MainsPower([.a, .b], [110], [60]),
        "HR": MainsPower([.c, .f], [230], [50]),
        "HT": MainsPower([.a, .b], [110], [60]),
        "HU": MainsPower([.c, .f], [230], [50]),
        "ID": MainsPower([.c, .f], [230], [50]),
        "IE": MainsPower([.g], [230], [50]),
        "IL": MainsPower([.h, .c], [230], [50]),
        "IM": MainsPower([.g, .c], [240], [50]),
        "IN": MainsPower([.d, .m, .c], [230], [50]),
        "IQ": MainsPower([.g, .c, .d], [230], [50]),
        "IR": MainsPower([.c, .f], [220], [50]),
        "IS": MainsPower([.c, .f], [230], [50]),
        "IT": MainsPower([.l, .c, .f], [230], [50]),
        "JE": MainsPower([.g], [230], [50]),
        "JM": MainsPower([.a, .b], [110], [50]),
        "JO": MainsPower([.c, .f, .g, .b, .d, .j], [230], [50]),
        "JP": MainsPower([.a, .b], [100], [50, 60]),  // 50 Hz in the east, 60 Hz in the west
        "KE": MainsPower([.g], [240], [50]),
        "KG": MainsPower([.c, .f], [220], [50]),
        "KH": MainsPower([.a, .c, .g], [230], [50]),
        "KI": MainsPower([.i], [240], [50]),
        "KM": MainsPower([.c, .e], [220], [50]),
        "KN": MainsPower([.a, .b, .g, .d], [230], [60]),
        "KP": MainsPower([.a, .c, .f], [220, 110], [50, 60]),
        "KR": MainsPower([.c, .f], [220], [60]),
        "KW": MainsPower([.g, .c, .m], [240], [50]),
        "KY": MainsPower([.a, .b], [120], [60]),
        "KZ": MainsPower([.c, .f], [220], [50]),
        "LA": MainsPower([.a, .b, .c, .e, .f], [230], [50]),
        "LB": MainsPower([.c, .a, .b, .d, .g], [220], [50]),
        "LC": MainsPower([.g], [240], [50]),
        "LI": MainsPower([.c, .j], [230], [50]),
        "LK": MainsPower([.g, .d, .m], [230], [50]),
        "LR": MainsPower([.a, .b, .c, .e, .f], [120, 220], [50, 60]),  // Mix of 120 V and 220 V supplies; the national grid runs at 50 Hz
        "LS": MainsPower([.m], [220], [50]),
        "LT": MainsPower([.c, .f], [220], [50]),
        "LU": MainsPower([.c, .f], [230], [50]),
        "LV": MainsPower([.c, .f], [230], [50]),
        "LY": MainsPower([.c, .d, .f, .l], [230, 127], [50]),
        "MA": MainsPower([.c, .e], [220, 127], [50]),
        "MC": MainsPower([.c, .d, .e, .f], [230], [50]),
        "MD": MainsPower([.c, .f], [220], [50]),
        "ME": MainsPower([.c, .f], [230], [50]),
        "MF": MainsPower([.c, .e], [220], [60]),  // 60 Hz, unlike mainland France
        "MG": MainsPower([.c, .e, .d, .j, .k], [220, 127], [50]),
        "MH": MainsPower([.a, .b], [120], [60]),
        "MK": MainsPower([.c, .f], [230], [50]),
        "ML": MainsPower([.c, .e], [220], [50]),
        "MM": MainsPower([.c, .d, .f, .g], [230], [50]),
        "MN": MainsPower([.c, .e], [220], [50]),
        "MO": MainsPower([.g, .d, .m, .f], [220], [50]),
        "MP": MainsPower([.a, .b], [120], [60]),
        "MQ": MainsPower([.c, .d, .e], [220], [50]),
        "MR": MainsPower([.c], [220], [50]),
        "MS": MainsPower([.a, .b], [230], [60]),
        "MT": MainsPower([.g], [230], [50]),
        "MU": MainsPower([.c, .g], [230], [50]),
        "MV": MainsPower([.g, .c, .d, .j, .k, .l], [230], [50]),
        "MW": MainsPower([.g], [230], [50]),
        "MX": MainsPower([.a, .b], [127], [60]),
        "MY": MainsPower([.g, .a, .c, .m], [240], [50]),
        "MZ": MainsPower([.c, .f, .m], [220], [50]),
        "NA": MainsPower([.m, .d], [220], [50]),
        "NC": MainsPower([.c, .f], [220], [50]),
        "NE": MainsPower([.a, .b, .c, .d, .e, .f], [220], [50]),
        "NF": MainsPower([.i], [240], [50]),
        "NG": MainsPower([.g, .d], [230], [50]),
        "NI": MainsPower([.a, .b], [120], [60]),
        "NL": MainsPower([.c, .f], [230], [50]),
        "NO": MainsPower([.c, .f], [230], [50]),
        "NP": MainsPower([.c, .d, .m], [230], [50]),
        "NR": MainsPower([.i], [240], [50]),
        "NU": MainsPower([.i], [230], [50]),
        "NZ": MainsPower([.i], [230], [50]),
        "OM": MainsPower([.g], [240], [50]),
        "PA": MainsPower([.a, .b], [110], [60]),
        "PE": MainsPower([.a, .b, .c], [220], [60]),
        "PF": MainsPower([.c, .e], [220], [60, 50]),  // 60 Hz on Tahiti and most islands; 50 Hz on a few, including the Marquesas
        "PG": MainsPower([.i], [240], [50]),
        "PH": MainsPower([.a, .b, .c], [230], [60]),
        "PK": MainsPower([.d, .c, .g, .m], [230], [50]),
        "PL": MainsPower([.c, .e], [230], [50]),
        "PM": MainsPower([.c, .e], [230], [50]),
        "PN": MainsPower([.i], [230], [50]),
        "PR": MainsPower([.a, .b], [120], [60]),
        "PS": MainsPower([.h, .c], [230], [50]),
        "PT": MainsPower([.c, .f], [230], [50]),
        "PW": MainsPower([.a, .b], [120], [60]),
        "PY": MainsPower([.c], [220], [50]),
        "QA": MainsPower([.g], [240], [50]),
        "RE": MainsPower([.e], [220], [50]),
        "RO": MainsPower([.c, .f], [230], [50]),
        "RS": MainsPower([.c, .f], [230], [50]),
        "RU": MainsPower([.c, .f], [220], [50]),
        "RW": MainsPower([.c, .e, .f, .g], [230], [50]),
        "SA": MainsPower([.g], [220, 230], [60]),
        "SB": MainsPower([.i, .g], [220], [50]),
        "SC": MainsPower([.g], [240], [50]),
        "SD": MainsPower([.c, .d], [230], [50]),
        "SE": MainsPower([.c, .f], [230], [50]),
        "SG": MainsPower([.g, .c, .m], [230], [50]),
        "SH": MainsPower([.g], [240], [50]),
        "SI": MainsPower([.c, .f], [230], [50]),
        "SJ": MainsPower([.c, .f], [230], [50]),
        "SK": MainsPower([.c, .e], [230], [50]),
        "SL": MainsPower([.g, .d], [230], [50]),
        "SM": MainsPower([.l, .c, .f], [230], [50]),
        "SN": MainsPower([.c, .d, .e, .k], [230], [50]),
        "SO": MainsPower([.c], [220], [50]),
        "SR": MainsPower([.c, .f], [127], [60]),
        "SS": MainsPower([.c, .d, .g], [230], [50]),
        "ST": MainsPower([.c, .f], [220], [50]),
        "SV": MainsPower([.a, .b], [115], [60]),
        "SX": MainsPower([.a, .b], [120], [60]),
        "SY": MainsPower([.c, .e, .l], [220], [50]),
        "SZ": MainsPower([.m], [230], [50]),
        "TC": MainsPower([.a, .b], [120], [60]),
        "TD": MainsPower([.c, .d, .e, .f], [220], [50]),
        "TG": MainsPower([.c], [220], [50]),
        "TH": MainsPower([.o, .a, .b, .c, .f], [220], [50]),
        "TJ": MainsPower([.c, .f, .i], [220], [50]),
        "TK": MainsPower([.i], [230], [50]),
        "TL": MainsPower([.c, .e, .f, .i], [220], [50]),
        "TM": MainsPower([.b, .c, .f], [220], [50]),
        "TN": MainsPower([.c, .e], [230], [50]),
        "TO": MainsPower([.i], [240], [50]),
        "TR": MainsPower([.c, .f], [220], [50]),
        "TT": MainsPower([.a, .b], [115], [60]),
        "TV": MainsPower([.i], [220], [50]),
        "TW": MainsPower([.a, .b], [110], [60]),
        "TZ": MainsPower([.g, .d], [230], [50]),
        "UA": MainsPower([.c, .f], [220], [50]),
        "UG": MainsPower([.g], [240], [50]),
        "US": MainsPower([.a, .b], [120], [60]),
        "UY": MainsPower([.c, .f, .l], [230], [50]),
        "UZ": MainsPower([.c, .i], [220], [50]),
        "VA": MainsPower([.l, .c, .f], [230], [50]),
        "VC": MainsPower([.g, .a, .c, .e, .i, .k], [230], [50]),
        "VE": MainsPower([.a, .b], [120], [60]),
        "VG": MainsPower([.a, .b], [110], [60]),
        "VI": MainsPower([.a, .b], [110], [60]),
        "VN": MainsPower([.a, .b, .c], [220], [50]),
        "VU": MainsPower([.i, .c, .g], [220], [50]),
        "WF": MainsPower([.c, .e], [230], [50]),
        "WS": MainsPower([.i], [230], [50]),
        "XC": MainsPower([.g], [230], [50]),
        "XK": MainsPower([.c, .f], [230], [50]),
        "YE": MainsPower([.g, .d, .m], [240], [50]),
        "YT": MainsPower([.c, .e], [230], [50]),
        "ZA": MainsPower([.m, .n, .c], [230], [50]),
        "ZM": MainsPower([.g, .c, .d], [230], [50]),
        "ZW": MainsPower([.g, .d], [220], [50]),
    ]
}

/// Whether a place's sockets give about 110 volts, as across most of the Americas and in Japan,
/// or about 230, as nearly everywhere else, or each in different parts of the country.
enum MainsVoltage: String, CaseIterable {
    case low, high, both

    var name: String {
        switch self {
        case .low: "100–127 V"
        case .high: "220–240 V"
        case .both: "Both"
        }
    }

    var key: MapKey {
        MapKey(id: rawValue, name: name, color: color, spokenName: spokenName)
    }

    private var spokenName: String {
        switch self {
        case .low: "100 to 127 volts"
        case .high: "220 to 240 volts"
        case .both: "Both voltages"
        }
    }

    /// Warmer the higher it is.
    private var color: Color {
        switch self {
        case .low: LevelColor.yellow.color
        case .high: LevelColor.red.color
        case .both: LevelColor.orange.color
        }
    }
}
