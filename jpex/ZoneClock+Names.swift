import Foundation

extension ZoneClock {
    /// How a clock's offset from UTC is written: "UTC+9", "UTC+5:30", "UTC−3", or for UTC itself
    /// "UTC±0", so every one reads alike.
    static func utcName(offset: Int) -> String {
        "UTC" + utcOffsetName(offset: offset)
    }

    /// The offset alone, as it follows "UTC": "+9", "+5:30", "−3" or "±0", for World Time to set in
    /// the time's own colour on the map.
    static func utcOffsetName(offset: Int) -> String {
        guard offset != 0 else { return "±0" }
        let hours = abs(offset) / 3600
        let minutes = abs(offset) % 3600 / 60
        let sign = offset > 0 ? "+" : "−"
        return minutes == 0 ? "\(sign)\(hours)" : "\(sign)\(hours):\(String(format: "%02d", minutes))"
    }

    /// The clock's offset from UTC at a moment, written as "UTC+9".
    func utcName(at date: Date) -> String {
        Self.utcName(offset: offset(at: date))
    }

    /// The zone's own name at a moment, such as "Japan Standard Time" or "British Summer Time",
    /// from the Unicode CLDR names built into the system. A zone the system has no such name for,
    /// such as Bougainville's, goes by its place's: "Bougainville Time"; one without even that, by
    /// its offset, "UTC+11".
    func name(at date: Date) -> String {
        let style: NSTimeZone.NameStyle = timeZone.isDaylightSavingTime(for: date) ? .daylightSaving : .standard
        for style in [style, .generic] {
            if let name = timeZone.localizedName(for: style, locale: .current), !name.hasPrefix("GMT"), !name.hasPrefix("UTC") {
                return name
            }
        }
        return utcName(at: date)
    }

    /// What the zone is officially called where it's kept, where that differs from the system's
    /// own name for it, such as National Standard Time for Taiwan's.
    var officialName: String? {
        ZoneOfficialNames.table[timeZone.identifier]?.english
    }

    /// The zone's name in the language of the place keeping it, such as 國家標準時間 for Taiwan's
    /// or Waktu Indonesia Barat for western Indonesia's.
    var localName: String? {
        ZoneOfficialNames.table[timeZone.identifier]?.local
    }

    /// The letters the zone goes by at a moment, such as JST, CEST or AEDT, where it's widely known
    /// by any. Each is kept only while the clock's offset is the one those letters stand for, so a
    /// place that changes its clocks never shows the wrong ones.
    func abbreviation(at date: Date) -> String? {
        let offset = offset(at: date)
        if let known = ZoneAbbreviations.table[timeZone.identifier] {
            return known.first { $0.offset == offset }?.letters
        }
        // A zone the table doesn't know, such as the device set to Melbourne, may still have letters
        // of the system's own; offsets written out don't count.
        let system = timeZone.abbreviation(for: date) ?? ""
        return system.isEmpty || system.hasPrefix("GMT") || system.hasPrefix("UTC") || !system.allSatisfy(\.isLetter) ? nil : system
    }
}

/// The letters zones are widely known by, with the offset each stands for. Where a zone's letters
/// are in doubt, such as Kazakhstan's since it took one time, it has none, and shows its offset.
private enum ZoneAbbreviations {
    static let table: [String: [(letters: String, offset: Int)]] = entries.mapValues { entry in
        entry.components(separatedBy: ";").compactMap { part in
            let pieces = part.split(separator: " ")
            guard pieces.count == 2, let hours = Double(pieces[1]) else { return nil }
            return (String(pieces[0]), Int((hours * 3600).rounded()))
        }
    }

    /// By zone: its letters and offsets in hours, standard time first, separated by ";".
    private static let entries: [String: String] = {
        var entries: [String: String] = [:]
        func add(_ value: String, _ zones: String) {
            for zone in zones.split(separator: " ") { entries[String(zone)] = value }
        }
        // North America
        add("EST -5;EDT -4", """
            America/New_York America/Toronto America/Nassau America/Port-au-Prince America/Grand_Turk \
            America/Detroit America/Indiana/Indianapolis America/Kentucky/Louisville America/Montreal
            """)
        add("CST -6;CDT -5", "America/Chicago America/Winnipeg America/Indiana/Knox America/Menominee")
        add("MST -7;MDT -6", "America/Denver America/Edmonton America/Boise America/Ciudad_Juarez")
        add("PST -8;PDT -7", "America/Los_Angeles America/Vancouver America/Tijuana")
        add("MST -7", "America/Phoenix America/Whitehorse America/Mazatlan America/Hermosillo America/Dawson_Creek")
        add("AKST -9;AKDT -8", "America/Anchorage America/Juneau America/Sitka America/Nome")
        add("HST -10;HDT -9", "America/Adak")
        add("HST -10", "Pacific/Honolulu")
        add("AST -4;ADT -3", "America/Halifax America/Thule Atlantic/Bermuda America/Glace_Bay America/Moncton")
        add("NST -3.5;NDT -2.5", "America/St_Johns")
        add("CST -6", """
            America/Regina America/Mexico_City America/Guatemala America/Belize America/El_Salvador \
            America/Tegucigalpa America/Managua America/Costa_Rica America/Merida America/Monterrey
            """)
        add("EST -5", "America/Cancun America/Jamaica America/Cayman America/Panama")
        add("CST -5;CDT -4", "America/Havana")
        add("AST -4", """
            America/Puerto_Rico America/Santo_Domingo America/Anguilla America/Antigua America/Aruba \
            America/Barbados America/Kralendijk America/Curacao America/Dominica America/Grenada \
            America/Guadeloupe America/Martinique America/Montserrat America/St_Barthelemy America/St_Kitts \
            America/St_Lucia America/Marigot America/St_Vincent America/Lower_Princes America/Tortola \
            America/St_Thomas America/Port_of_Spain
            """)
        add("PMST -3;PMDT -2", "America/Miquelon")
        add("WGT -2;WGST -1", "America/Nuuk America/Godthab")
        add("GMT 0", "America/Danmarkshavn")
        // South America
        add("ART -3", "America/Argentina/Buenos_Aires America/Buenos_Aires America/Argentina/Cordoba")
        add("BOT -4", "America/La_Paz")
        add("BRT -3", "America/Sao_Paulo America/Fortaleza America/Recife America/Bahia America/Belem")
        add("AMT -4", "America/Manaus America/Cuiaba America/Campo_Grande America/Porto_Velho America/Boa_Vista")
        add("ACT -5", "America/Rio_Branco America/Eirunepe")
        add("FNT -2", "America/Noronha")
        add("CLT -4;CLST -3", "America/Santiago")
        add("EAST -6;EASST -5", "Pacific/Easter")
        add("COT -5", "America/Bogota")
        add("ECT -5", "America/Guayaquil")
        add("GALT -6", "Pacific/Galapagos")
        add("FKST -3", "Atlantic/Stanley")
        add("GFT -3", "America/Cayenne")
        add("GYT -4", "America/Guyana")
        add("PET -5", "America/Lima")
        add("SRT -3", "America/Paramaribo")
        add("UYT -3", "America/Montevideo")
        add("VET -4", "America/Caracas")
        // Europe
        add("GMT 0;BST 1", "Europe/London Europe/Guernsey Europe/Jersey Europe/Isle_of_Man")
        add("GMT 0;IST 1", "Europe/Dublin")
        add("WET 0;WEST 1", "Europe/Lisbon Atlantic/Canary Atlantic/Faroe Atlantic/Madeira")
        add("AZOT -1;AZOST 0", "Atlantic/Azores")
        add("GMT 0", "Atlantic/Reykjavik")
        add("CET 1;CEST 2", """
            Europe/Paris Europe/Berlin Europe/Madrid Europe/Rome Europe/Vienna Europe/Brussels \
            Europe/Amsterdam Europe/Luxembourg Europe/Zurich Europe/Vaduz Europe/Monaco Europe/Andorra \
            Europe/San_Marino Europe/Vatican Europe/Malta Europe/Prague Europe/Bratislava Europe/Budapest \
            Europe/Warsaw Europe/Copenhagen Europe/Oslo Europe/Stockholm Europe/Belgrade Europe/Zagreb \
            Europe/Ljubljana Europe/Sarajevo Europe/Podgorica Europe/Skopje Europe/Tirane Europe/Gibraltar \
            Arctic/Longyearbyen Europe/Busingen Africa/Ceuta
            """)
        add("CET 1", "Africa/Algiers Africa/Tunis")
        add("EET 2;EEST 3", """
            Europe/Helsinki Europe/Tallinn Europe/Riga Europe/Vilnius Europe/Kyiv Europe/Kiev \
            Europe/Chisinau Europe/Bucharest Europe/Sofia Europe/Athens Europe/Mariehamn Asia/Nicosia \
            Asia/Famagusta Asia/Beirut Africa/Cairo Asia/Hebron Asia/Gaza
            """)
        add("EET 2", "Africa/Tripoli Europe/Kaliningrad")
        add("MSK 3", "Europe/Moscow Europe/Simferopol Europe/Volgograd")
        add("TRT 3", "Europe/Istanbul")
        add("SAMT 4", "Europe/Samara")
        // Africa
        add("WAT 1", """
            Africa/Lagos Africa/Luanda Africa/Porto-Novo Africa/Douala Africa/Bangui Africa/Ndjamena \
            Africa/Kinshasa Africa/Malabo Africa/Libreville Africa/Niamey Africa/Brazzaville
            """)
        add("CAT 2", """
            Africa/Gaborone Africa/Bujumbura Africa/Lubumbashi Africa/Blantyre Africa/Maputo Africa/Kigali \
            Africa/Lusaka Africa/Harare Africa/Khartoum Africa/Juba Africa/Windhoek
            """)
        add("EAT 3", """
            Africa/Nairobi Africa/Addis_Ababa Africa/Asmara Africa/Djibouti Africa/Mogadishu \
            Africa/Dar_es_Salaam Africa/Kampala Indian/Comoro Indian/Antananarivo Indian/Mayotte
            """)
        add("SAST 2", "Africa/Johannesburg Africa/Maseru Africa/Mbabane")
        add("GMT 0", """
            Africa/Abidjan Africa/Accra Africa/Bamako Africa/Banjul Africa/Bissau Africa/Conakry \
            Africa/Dakar Africa/Freetown Africa/Lome Africa/Monrovia Africa/Nouakchott Africa/Ouagadougou \
            Africa/Sao_Tome Atlantic/St_Helena
            """)
        add("CVT -1", "Atlantic/Cape_Verde")
        add("MUT 4", "Indian/Mauritius")
        add("SCT 4", "Indian/Mahe")
        add("RET 4", "Indian/Reunion")
        add("TFT 5", "Indian/Kerguelen")
        // Asia
        add("JST 9", "Asia/Tokyo")
        add("KST 9", "Asia/Seoul Asia/Pyongyang")
        add("CST 8", "Asia/Shanghai Asia/Macau Asia/Taipei")
        add("HKT 8", "Asia/Hong_Kong")
        add("ULAT 8", "Asia/Ulaanbaatar")
        add("HOVT 7", "Asia/Hovd")
        add("SGT 8", "Asia/Singapore")
        add("MYT 8", "Asia/Kuala_Lumpur Asia/Kuching")
        add("BNT 8", "Asia/Brunei")
        add("PHT 8", "Asia/Manila")
        add("WIB 7", "Asia/Jakarta Asia/Pontianak")
        add("WITA 8", "Asia/Makassar")
        add("WIT 9", "Asia/Jayapura")
        add("TLT 9", "Asia/Dili")
        add("ICT 7", "Asia/Bangkok Asia/Ho_Chi_Minh Asia/Saigon Asia/Phnom_Penh Asia/Vientiane")
        add("MMT 6.5", "Asia/Yangon Asia/Rangoon")
        add("BST 6", "Asia/Dhaka")
        add("BTT 6", "Asia/Thimphu")
        add("NPT 5.75", "Asia/Kathmandu Asia/Katmandu")
        add("IST 5.5", "Asia/Kolkata Asia/Calcutta")
        add("SLST 5.5", "Asia/Colombo")
        add("MVT 5", "Indian/Maldives")
        add("PKT 5", "Asia/Karachi")
        add("AFT 4.5", "Asia/Kabul")
        add("IRST 3.5", "Asia/Tehran")
        add("GST 4", "Asia/Dubai Asia/Muscat")
        add("AST 3", "Asia/Riyadh Asia/Baghdad Asia/Kuwait Asia/Bahrain Asia/Qatar Asia/Aden")
        add("IST 2;IDT 3", "Asia/Jerusalem")
        add("AZT 4", "Asia/Baku")
        add("GET 4", "Asia/Tbilisi")
        add("AMT 4", "Asia/Yerevan")
        add("UZT 5", "Asia/Tashkent Asia/Samarkand")
        add("TJT 5", "Asia/Dushanbe")
        add("TMT 5", "Asia/Ashgabat")
        add("KGT 6", "Asia/Bishkek")
        add("YEKT 5", "Asia/Yekaterinburg")
        add("OMST 6", "Asia/Omsk")
        add("NOVT 7", "Asia/Novosibirsk")
        add("KRAT 7", "Asia/Krasnoyarsk")
        add("IRKT 8", "Asia/Irkutsk")
        add("YAKT 9", "Asia/Yakutsk")
        add("VLAT 10", "Asia/Vladivostok")
        add("MAGT 11", "Asia/Magadan")
        add("PETT 12", "Asia/Kamchatka")
        add("IOT 6", "Indian/Chagos")
        add("CXT 7", "Indian/Christmas")
        add("CCT 6.5", "Indian/Cocos")
        // Oceania
        add("AEST 10;AEDT 11", "Australia/Sydney Australia/Melbourne Australia/Hobart Australia/Canberra Australia/ACT")
        add("AEST 10", "Australia/Brisbane Australia/Lindeman")
        add("ACST 9.5;ACDT 10.5", "Australia/Adelaide Australia/Broken_Hill")
        add("ACST 9.5", "Australia/Darwin")
        add("AWST 8", "Australia/Perth")
        add("ACWST 8.75", "Australia/Eucla")
        add("LHST 10.5;LHDT 11", "Australia/Lord_Howe")
        add("NZST 12;NZDT 13", "Pacific/Auckland")
        add("CHAST 12.75;CHADT 13.75", "Pacific/Chatham")
        add("FJT 12;FJST 13", "Pacific/Fiji")
        add("TOT 13", "Pacific/Tongatapu")
        add("WST 13", "Pacific/Apia")
        add("SST -11", "Pacific/Pago_Pago Pacific/Midway")
        add("NUT -11", "Pacific/Niue")
        add("CKT -10", "Pacific/Rarotonga")
        add("TAHT -10", "Pacific/Tahiti")
        add("MART -9.5", "Pacific/Marquesas")
        add("GAMT -9", "Pacific/Gambier")
        add("ChST 10", "Pacific/Guam Pacific/Saipan")
        add("PGT 10", "Pacific/Port_Moresby")
        add("SBT 11", "Pacific/Guadalcanal")
        add("VUT 11", "Pacific/Efate")
        add("NCT 11", "Pacific/Noumea")
        add("NFT 11;NFDT 12", "Pacific/Norfolk")
        add("NRT 12", "Pacific/Nauru")
        add("TVT 12", "Pacific/Funafuti")
        add("MHT 12", "Pacific/Majuro Pacific/Kwajalein")
        add("WAKT 12", "Pacific/Wake")
        add("WFT 12", "Pacific/Wallis")
        add("GILT 12", "Pacific/Tarawa")
        add("PHOT 13", "Pacific/Kanton")
        add("LINT 14", "Pacific/Kiritimati")
        add("TKT 13", "Pacific/Fakaofo")
        add("PWT 9", "Pacific/Palau")
        add("PONT 11", "Pacific/Pohnpei")
        add("CHUT 10", "Pacific/Chuuk")
        return entries
    }()
}

/// Zones' official names where they're kept, as their governments' timekeepers publish them, for
/// the few whose names there differ from the system's or whose own languages name them. Sources
/// are listed in TIMEZONE_SOURCES.md.
private enum ZoneOfficialNames {
    static let table: [String: (english: String?, local: String?)] = [
        "Asia/Taipei": ("National Standard Time", "國家標準時間"),
        "Asia/Shanghai": ("Beijing Time", "北京时间"),
        "Asia/Hong_Kong": ("Hong Kong Time", "香港時間"),
        "Asia/Tokyo": (nil, "日本標準時"),
        "Asia/Seoul": (nil, "한국 표준시"),
        "Asia/Kolkata": ("Indian Standard Time", "भारतीय मानक समय"),
        "Asia/Manila": (nil, "Pamantayang Oras ng Pilipinas"),
        "Asia/Jakarta": (nil, "Waktu Indonesia Barat"),
        "Asia/Makassar": (nil, "Waktu Indonesia Tengah"),
        "Asia/Jayapura": (nil, "Waktu Indonesia Timur"),
        "Europe/Moscow": ("Moscow Time", "Московское время"),
    ]
}
