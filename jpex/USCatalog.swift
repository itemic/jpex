import Foundation

extension CountryCatalog {
    // Fifty states, the federal district, and the five inhabited U.S. territories.
    // The Minor Outlying Islands remain available in the World catalog.
    // Source: https://www.usa.gov/state-governments
    static let unitedStates = Country(
        id: "US",
        name: "United States",
        localName: "United States",
        divisionLabel: "States & territories",
        groups: [
            DivisionGroup(
                id: "US-states",
                name: "States",
                divisions: [
                    americanDivision("AL", name: "Alabama", group: "states", flag: "us_flag_al"),
                    americanDivision("AK", name: "Alaska", group: "states", flag: "us_flag_ak"),
                    americanDivision("AZ", name: "Arizona", group: "states", flag: "us_flag_az"),
                    americanDivision("AR", name: "Arkansas", group: "states", flag: "us_flag_ar"),
                    americanDivision("CA", name: "California", group: "states", flag: "us_flag_ca"),
                    americanDivision("CO", name: "Colorado", group: "states", flag: "us_flag_co"),
                    americanDivision("CT", name: "Connecticut", group: "states", flag: "us_flag_ct"),
                    americanDivision("DE", name: "Delaware", group: "states", flag: "us_flag_de"),
                    americanDivision("FL", name: "Florida", group: "states", flag: "us_flag_fl"),
                    americanDivision("GA", name: "Georgia", group: "states", flag: "us_flag_ga"),
                    americanDivision("HI", name: "Hawaii", group: "states", flag: "us_flag_hi"),
                    americanDivision("ID", name: "Idaho", group: "states", flag: "us_flag_id"),
                    americanDivision("IL", name: "Illinois", group: "states", flag: "us_flag_il"),
                    americanDivision("IN", name: "Indiana", group: "states", flag: "us_flag_in"),
                    americanDivision("IA", name: "Iowa", group: "states", flag: "us_flag_ia"),
                    americanDivision("KS", name: "Kansas", group: "states", flag: "us_flag_ks"),
                    americanDivision("KY", name: "Kentucky", group: "states", flag: "us_flag_ky"),
                    americanDivision("LA", name: "Louisiana", group: "states", flag: "us_flag_la"),
                    americanDivision("ME", name: "Maine", group: "states", flag: "us_flag_me"),
                    americanDivision("MD", name: "Maryland", group: "states", flag: "us_flag_md"),
                    americanDivision("MA", name: "Massachusetts", group: "states", flag: "us_flag_ma"),
                    americanDivision("MI", name: "Michigan", group: "states", flag: "us_flag_mi"),
                    americanDivision("MN", name: "Minnesota", group: "states", flag: "us_flag_mn"),
                    americanDivision("MS", name: "Mississippi", group: "states", flag: "us_flag_ms"),
                    americanDivision("MO", name: "Missouri", group: "states", flag: "us_flag_mo"),
                    americanDivision("MT", name: "Montana", group: "states", flag: "us_flag_mt"),
                    americanDivision("NE", name: "Nebraska", group: "states", flag: "us_flag_ne"),
                    americanDivision("NV", name: "Nevada", group: "states", flag: "us_flag_nv"),
                    americanDivision("NH", name: "New Hampshire", group: "states", flag: "us_flag_nh"),
                    americanDivision("NJ", name: "New Jersey", group: "states", flag: "us_flag_nj"),
                    americanDivision("NM", name: "New Mexico", group: "states", flag: "us_flag_nm"),
                    americanDivision("NY", name: "New York", group: "states", flag: "us_flag_ny"),
                    americanDivision("NC", name: "North Carolina", group: "states", flag: "us_flag_nc"),
                    americanDivision("ND", name: "North Dakota", group: "states", flag: "us_flag_nd"),
                    americanDivision("OH", name: "Ohio", group: "states", flag: "us_flag_oh"),
                    americanDivision("OK", name: "Oklahoma", group: "states", flag: "us_flag_ok"),
                    americanDivision("OR", name: "Oregon", group: "states", flag: "us_flag_or"),
                    americanDivision("PA", name: "Pennsylvania", group: "states", flag: "us_flag_pa"),
                    americanDivision("RI", name: "Rhode Island", group: "states", flag: "us_flag_ri"),
                    americanDivision("SC", name: "South Carolina", group: "states", flag: "us_flag_sc"),
                    americanDivision("SD", name: "South Dakota", group: "states", flag: "us_flag_sd"),
                    americanDivision("TN", name: "Tennessee", group: "states", flag: "us_flag_tn"),
                    americanDivision("TX", name: "Texas", group: "states", flag: "us_flag_tx"),
                    americanDivision("UT", name: "Utah", group: "states", flag: "us_flag_ut"),
                    americanDivision("VT", name: "Vermont", group: "states", flag: "us_flag_vt"),
                    americanDivision("VA", name: "Virginia", group: "states", flag: "us_flag_va"),
                    americanDivision("WA", name: "Washington", group: "states", flag: "us_flag_wa"),
                    americanDivision("WV", name: "West Virginia", group: "states", flag: "us_flag_wv"),
                    americanDivision("WI", name: "Wisconsin", group: "states", flag: "us_flag_wi"),
                    americanDivision("WY", name: "Wyoming", group: "states", flag: "us_flag_wy")
                ]
            ),
            DivisionGroup(
                id: "US-federal",
                name: "Federal district",
                divisions: [
                    americanDivision("DC", name: "District of Columbia", group: "federal", flag: "us_flag_dc")
                ]
            ),
            DivisionGroup(
                id: "US-territories",
                name: "Inhabited territories",
                divisions: [
                    americanDivision("AS", name: "American Samoa", group: "territories", flag: "world_flag_as"),
                    americanDivision("GU", name: "Guam", group: "territories", flag: "world_flag_gu"),
                    americanDivision("MP", name: "Northern Mariana Islands", group: "territories", flag: "world_flag_mp"),
                    americanDivision("PR", name: "Puerto Rico", group: "territories", flag: "world_flag_pr"),
                    americanDivision("VI", name: "U.S. Virgin Islands", group: "territories", flag: "world_flag_vi")
                ]
            )
        ]
    )

    private static func americanDivision(_ code: String, name: String, group: String, flag: String) -> AdministrativeDivision {
        let flagNote: String?
        switch code {
        case "MN": flagNote = "The state flag adopted on May 11, 2024 is shown."
        case "MS": flagNote = "The New Magnolia state flag adopted in 2021 is shown."
        case "UT": flagNote = "The state flag introduced on March 9, 2024 is shown."
        default: flagNote = nil
        }
        return AdministrativeDivision(
            id: "US-\(code)",
            countryID: "US",
            name: name,
            abbreviation: code,
            groupID: "US-\(group)",
            flagAssetName: flag,
            flagNote: flagNote
        )
    }
}
