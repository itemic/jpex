import Foundation

/// A group of countries the world knows by name, such as the European Union or ASEAN. Each is a
/// list of its own, drawn from Countries and sharing its statuses, on the World map zoomed to its
/// members. Memberships are as of 2026.
enum WorldGroup: String, CaseIterable, Identifiable, Sendable {
    case unitedNations, g7, g20, europeanUnion, schengen, eurozone, nato, commonwealth, asean, africanUnion
    case arabLeague, oecd, brics, gulfCooperation, opec, mercosur, caricom, efta, nordic, baltic, benelux

    var id: Self { self }

    /// Collections of groups have IDs of their own, apart from every country's.
    private static let idPrefix = "GROUP-"

    var collectionID: String { Self.idPrefix + rawValue }

    /// The group whose list has this ID, if it is one.
    init?(collectionID: String) {
        guard collectionID.hasPrefix(Self.idPrefix) else { return nil }
        self.init(rawValue: String(collectionID.dropFirst(Self.idPrefix.count)))
    }

    var name: String {
        switch self {
        case .unitedNations: "United Nations"
        case .g7: "G7"
        case .g20: "G20"
        case .europeanUnion: "European Union"
        case .schengen: "Schengen Area"
        case .eurozone: "Eurozone"
        case .nato: "NATO"
        case .commonwealth: "Commonwealth"
        case .asean: "ASEAN"
        case .africanUnion: "African Union"
        case .arabLeague: "Arab League"
        case .oecd: "OECD"
        case .brics: "BRICS"
        case .gulfCooperation: "Gulf Cooperation Council"
        case .opec: "OPEC"
        case .mercosur: "Mercosur"
        case .caricom: "CARICOM"
        case .efta: "EFTA"
        case .nordic: "Nordic Countries"
        case .baltic: "Baltic States"
        case .benelux: "Benelux"
        }
    }

    /// What the group is, in a few words, for its row in the sidebar.
    var summary: String {
        switch self {
        case .unitedNations: "Member states"
        case .g7: "Major advanced economies"
        case .g20: "The largest economies"
        case .europeanUnion: "Political and economic union"
        case .schengen: "Travel without border checks"
        case .eurozone: "Countries using the euro"
        case .nato: "North Atlantic alliance"
        case .commonwealth: "Commonwealth of Nations"
        case .asean: "Southeast Asian nations"
        case .africanUnion: "Every state in Africa"
        case .arabLeague: "League of Arab States"
        case .oecd: "Economic co-operation"
        case .brics: "Emerging economies"
        case .gulfCooperation: "Arab states of the Gulf"
        case .opec: "Oil-exporting countries"
        case .mercosur: "South American trade bloc"
        case .caricom: "Caribbean Community"
        case .efta: "European Free Trade Association"
        case .nordic: "With the Faroe Islands, Greenland and Åland"
        case .baltic: "Estonia, Latvia and Lithuania"
        case .benelux: "Belgium, the Netherlands and Luxembourg"
        }
    }

    /// Members by ISO code. The United Nations takes its members from Countries' own UN standard.
    private var memberCodes: Set<String> {
        let codes: String = switch self {
        case .unitedNations: ""
        case .g7: "CA FR DE IT JP GB US"
        case .g20: "AR AU BR CA CN FR DE IN ID IT JP KR MX RU SA ZA TR GB US"
        case .europeanUnion: "AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE"
        case .schengen: "AT BE BG HR CZ DK EE FI FR DE GR HU IT LV LT LU MT NL PL PT RO SK SI ES SE IS LI NO CH"
        case .eurozone: "AT BE BG HR CY EE FI FR DE GR IE IT LV LT LU MT NL PT SK SI ES"
        case .nato: "AL BE BG CA HR CZ DK EE FI FR DE GR HU IS IT LV LT LU ME NL MK NO PL PT RO SK SI ES SE TR GB US"
        case .commonwealth:
            "AG AU BS BD BB BZ BW BN CM CA CY DM SZ FJ GA GM GH GD GY IN JM KE KI LS MW MY MV MT MU MZ NA NR NZ NG PK "
                + "PG RW KN LC VC WS SC SL SG SB ZA LK TZ TG TO TT TV UG GB VU ZM"
        case .asean: "BN KH ID LA MY MM PH SG TH VN TL"
        case .africanUnion:
            "DZ AO BJ BW BF BI CV CM CF TD KM CG CD CI DJ EG GQ ER SZ ET GA GM GH GN GW KE LS LR LY MG MW ML MR MU MA "
                + "MZ NA NE NG RW EH ST SN SC SL SO ZA SS SD TZ TG TN UG ZM ZW"
        case .arabLeague: "DZ BH KM DJ EG IQ JO KW LB LY MR MA OM PS QA SA SO SD SY TN AE YE"
        case .oecd:
            "AU AT BE CA CL CO CR CZ DK EE FI FR DE GR HU IS IE IL IT JP KR LV LT LU MX NL NZ NO PL PT SK SI ES SE CH "
                + "TR GB US"
        case .brics: "BR RU IN CN ZA EG ET IR AE ID"
        case .gulfCooperation: "BH KW OM QA SA AE"
        case .opec: "DZ CG GQ GA IR IQ KW LY NG SA AE VE"
        case .mercosur: "AR BR PY UY BO"
        case .caricom: "AG BS BB BZ DM GD GY HT JM MS KN LC VC SR TT"
        case .efta: "IS LI NO CH"
        case .nordic: "DK FI IS NO SE FO GL AX"
        case .baltic: "EE LV LT"
        case .benelux: "BE NL LU"
        }
        return Set(codes.split(separator: " ").map(String.init))
    }

    /// The group as a list: its members from Countries, under their continents, in Countries' order.
    var collection: Country {
        let members: (AdministrativeDivision) -> Bool
        if self == .unitedNations {
            let ids = Set(
                CountryCatalog.world(applying: CountingStandard.unMembers.applied(to: CountingRules())).divisions.map(\.id))
            members = { ids.contains($0.id) }
        } else {
            let codes = memberCodes
            members = { codes.contains($0.abbreviation) }
        }
        let groups = CountryCatalog.world.groups.compactMap { group -> DivisionGroup? in
            var group = group
            group.divisions = group.divisions.filter(members)
            return group.divisions.isEmpty ? nil : group
        }
        return Country(id: collectionID, name: name, localName: name, divisionLabel: "Countries", groups: groups)
    }

    /// Every group's list, in the order the sidebar shows them.
    static let collections: [Country] = allCases.map(\.collection)
}
