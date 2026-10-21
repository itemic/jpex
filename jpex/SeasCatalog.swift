import Foundation

extension CountryCatalog {
    // The world's oceans and seas as the IHO's limits of oceans and seas divide them, through
    // Marine Regions' sea areas, with the Caspian and the Dead Sea as inland seas; see
    // SEA_SOURCES.md. Each sea's ID is made from its name and stays put whatever it's called.
    // Seas have no flags, so every one wears the same wash of water.
    static let seas = Country(
        id: "SEAS",
        name: "Seas",
        localName: "Seas",
        divisionLabel: "Seas",
        groups: [
            seaGroup("pacific", name: "Pacific Ocean", seas: [
                ("arafura-sea", "Arafura Sea"),
                ("bali-sea", "Bali Sea"),
                ("banda-sea", "Banda Sea"),
                ("bering-sea", "Bering Sea"),
                ("bismarck-sea", "Bismarck Sea"),
                ("celebes-sea", "Celebes Sea"),
                ("coastal-waters-of-southeast-alaska-and-british-columbia", "Coastal Waters of Southeast Alaska and British Columbia"),
                ("coral-sea", "Coral Sea"),
                ("east-china-sea", "East China Sea"),
                ("flores-sea", "Flores Sea"),
                ("gulf-of-alaska", "Gulf of Alaska"),
                ("gulf-of-bone", "Gulf of Bone"),
                ("gulf-of-california", "Gulf of California"),
                ("gulf-of-thailand", "Gulf of Thailand"),
                ("gulf-of-tomini", "Gulf of Tomini"),
                ("halmahera-sea", "Halmahera Sea"),
                ("java-sea", "Java Sea"),
                ("makassar-strait", "Makassar Strait"),
                ("molucca-sea", "Molucca Sea"),
                ("north-pacific-ocean", "North Pacific Ocean"),
                ("philippine-sea", "Philippine Sea"),
                ("savu-sea", "Savu Sea"),
                ("japan-sea", "Sea of Japan"),
                ("sea-of-okhotsk", "Sea of Okhotsk"),
                ("seram-sea", "Seram Sea"),
                ("seto-inland-sea", "Seto Inland Sea"),
                ("singapore-strait", "Singapore Strait"),
                ("solomon-sea", "Solomon Sea"),
                ("south-china-sea", "South China Sea"),
                ("south-pacific-ocean", "South Pacific Ocean"),
                ("sulu-sea", "Sulu Sea"),
                ("tasman-sea", "Tasman Sea"),
                ("yellow-sea", "Yellow Sea"),
            ]),
            seaGroup("atlantic", name: "Atlantic Ocean", seas: [
                ("baltic-sea", "Baltic Sea"),
                ("bay-of-biscay", "Bay of Biscay"),
                ("bay-of-fundy", "Bay of Fundy"),
                ("bristol-channel", "Bristol Channel"),
                ("caribbean-sea", "Caribbean Sea"),
                ("celtic-sea", "Celtic Sea"),
                ("davis-strait", "Davis Strait"),
                ("english-channel", "English Channel"),
                ("gulf-of-bothnia", "Gulf of Bothnia"),
                ("gulf-of-finland", "Gulf of Finland"),
                ("gulf-of-guinea", "Gulf of Guinea"),
                ("gulf-of-mexico", "Gulf of Mexico"),
                ("gulf-of-riga", "Gulf of Riga"),
                ("gulf-of-st-lawrence", "Gulf of St. Lawrence"),
                ("inner-seas-off-the-west-coast-of-scotland", "Inner Seas off the West Coast of Scotland"),
                ("irish-sea", "Irish Sea"),
                ("kattegat", "Kattegat"),
                ("labrador-sea", "Labrador Sea"),
                ("north-atlantic-ocean", "North Atlantic Ocean"),
                ("north-sea", "North Sea"),
                ("norwegian-sea", "Norwegian Sea"),
                ("rio-de-la-plata", "Río de la Plata"),
                ("skagerrak", "Skagerrak"),
                ("south-atlantic-ocean", "South Atlantic Ocean"),
            ]),
            seaGroup("mediterranean", name: "Mediterranean and Black Sea", seas: [
                ("adriatic-sea", "Adriatic Sea"),
                ("aegean-sea", "Aegean Sea"),
                ("alboran-sea", "Alboran Sea"),
                ("balearic-sea", "Balearic Sea"),
                ("black-sea", "Black Sea"),
                ("mediterranean-eastern-basin", "Eastern Mediterranean"),
                ("ionian-sea", "Ionian Sea"),
                ("ligurian-sea", "Ligurian Sea"),
                ("sea-of-azov", "Sea of Azov"),
                ("sea-of-marmara", "Sea of Marmara"),
                ("strait-of-gibraltar", "Strait of Gibraltar"),
                ("tyrrhenian-sea", "Tyrrhenian Sea"),
                ("mediterranean-western-basin", "Western Mediterranean"),
            ]),
            seaGroup("indian", name: "Indian Ocean", seas: [
                ("andaman-sea", "Andaman Sea"),
                ("arabian-sea", "Arabian Sea"),
                ("bass-strait", "Bass Strait"),
                ("bay-of-bengal", "Bay of Bengal"),
                ("great-australian-bight", "Great Australian Bight"),
                ("gulf-of-aden", "Gulf of Aden"),
                ("gulf-of-aqaba", "Gulf of Aqaba"),
                ("gulf-of-oman", "Gulf of Oman"),
                ("gulf-of-suez", "Gulf of Suez"),
                ("indian-ocean", "Indian Ocean"),
                ("laccadive-sea", "Laccadive Sea"),
                ("mozambique-channel", "Mozambique Channel"),
                ("persian-gulf", "Persian Gulf"),
                ("red-sea", "Red Sea"),
                ("strait-of-malacca", "Strait of Malacca"),
                ("timor-sea", "Timor Sea"),
            ]),
            seaGroup("southern", name: "Southern Ocean", seas: [
                ("southern-ocean", "Southern Ocean"),
            ]),
            seaGroup("arctic", name: "Arctic Ocean", seas: [
                ("arctic-ocean", "Arctic Ocean"),
                ("baffin-bay", "Baffin Bay"),
                ("barents-sea", "Barents Sea"),
                ("beaufort-sea", "Beaufort Sea"),
                ("chukchi-sea", "Chukchi Sea"),
                ("east-siberian-sea", "East Siberian Sea"),
                ("greenland-sea", "Greenland Sea"),
                ("hudson-bay", "Hudson Bay"),
                ("hudson-strait", "Hudson Strait"),
                ("kara-sea", "Kara Sea"),
                ("laptev-sea", "Laptev Sea"),
                ("lincoln-sea", "Lincoln Sea"),
                ("northwestern-passages", "Northwestern Passages"),
                ("white-sea", "White Sea"),
            ]),
            seaGroup("inland", name: "Inland seas", seas: [
                ("caspian-sea", "Caspian Sea"),
                ("dead-sea", "Dead Sea"),
            ]),
        ]
    )

    /// Seas known by more than one name, with every name, the IHO's first. Other names belong to
    /// the countries that use them, such as the East Sea, as South Korea calls the Sea of Japan.
    static let seasWithOtherNames: [(id: String, names: [String])] = [
        ("SEAS-japan-sea", ["Sea of Japan", "East Sea"]),
        ("SEAS-yellow-sea", ["Yellow Sea", "West Sea"]),
        ("SEAS-south-china-sea", ["South China Sea", "West Philippine Sea", "East Sea"]),
        ("SEAS-persian-gulf", ["Persian Gulf", "Arabian Gulf"]),
        ("SEAS-gulf-of-mexico", ["Gulf of Mexico", "Gulf of America"]),
    ]

    /// The seas, each called by the name the person chose, in their oceans alphabetically.
    static func seas(applying rules: CountingRules) -> Country {
        guard !rules.seaNames.isEmpty else { return seas }
        var collection = seas
        for index in collection.groups.indices {
            collection.groups[index].divisions = collection.groups[index].divisions
                .map { sea in
                    var sea = sea
                    if let name = rules.seaNames[sea.id],
                       seasWithOtherNames.contains(where: { $0.id == sea.id && $0.names.contains(name) }) {
                        sea.name = name
                    }
                    return sea
                }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return collection
    }

    private static func seaGroup(_ group: String, name: String, seas: [(id: String, name: String)]) -> DivisionGroup {
        DivisionGroup(
            id: "SEAS-ocean-\(group)",
            name: name,
            divisions: seas
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                .map { sea in
                    AdministrativeDivision(
                        id: "SEAS-\(sea.id)",
                        countryID: "SEAS",
                        name: sea.name,
                        abbreviation: sea.id,
                        groupID: "SEAS-ocean-\(group)",
                        flagAssetName: "world_flag_seas"
                    )
                }
        )
    }
}
