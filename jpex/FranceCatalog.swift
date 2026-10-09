import Foundation

extension CountryCatalog {
    // INSEE Code officiel géographique, 1 January 2026: 101 departments.
    // Department IDs are stable COG codes, including Corsica and overseas departments.
    // Mayotte’s territorial authority is now 976R; its department code remains 976.
    // Source: https://www.insee.fr/fr/information/8740222
    static let france = Country(
        id: "FR",
        name: "France",
        localName: "France",
        divisionLabel: "Departments",
        groups: [
            DivisionGroup(
                id: "FR-region-84",
                name: "Auvergne-Rhône-Alpes",
                divisions: [
                    frenchDepartment("01", name: "Ain", region: "84"),
                    frenchDepartment("03", name: "Allier", region: "84"),
                    frenchDepartment("07", name: "Ardèche", region: "84"),
                    frenchDepartment("15", name: "Cantal", region: "84"),
                    frenchDepartment("26", name: "Drôme", region: "84"),
                    frenchDepartment("38", name: "Isère", region: "84"),
                    frenchDepartment("42", name: "Loire", region: "84"),
                    frenchDepartment("43", name: "Haute-Loire", region: "84"),
                    frenchDepartment("63", name: "Puy-de-Dôme", region: "84"),
                    frenchDepartment("69", name: "Rhône", region: "84"),
                    frenchDepartment("73", name: "Savoie", region: "84"),
                    frenchDepartment("74", name: "Haute-Savoie", region: "84")
                ]
            ),
            DivisionGroup(
                id: "FR-region-27",
                name: "Bourgogne-Franche-Comté",
                divisions: [
                    frenchDepartment("21", name: "Côte-d'Or", region: "27"),
                    frenchDepartment("25", name: "Doubs", region: "27"),
                    frenchDepartment("39", name: "Jura", region: "27"),
                    frenchDepartment("58", name: "Nièvre", region: "27"),
                    frenchDepartment("70", name: "Haute-Saône", region: "27"),
                    frenchDepartment("71", name: "Saône-et-Loire", region: "27"),
                    frenchDepartment("89", name: "Yonne", region: "27"),
                    frenchDepartment("90", name: "Territoire de Belfort", region: "27")
                ]
            ),
            DivisionGroup(
                id: "FR-region-53",
                name: "Bretagne",
                divisions: [
                    frenchDepartment("22", name: "Côtes-d'Armor", region: "53"),
                    frenchDepartment("29", name: "Finistère", region: "53"),
                    frenchDepartment("35", name: "Ille-et-Vilaine", region: "53"),
                    frenchDepartment("56", name: "Morbihan", region: "53")
                ]
            ),
            DivisionGroup(
                id: "FR-region-24",
                name: "Centre-Val de Loire",
                divisions: [
                    frenchDepartment("18", name: "Cher", region: "24"),
                    frenchDepartment("28", name: "Eure-et-Loir", region: "24"),
                    frenchDepartment("36", name: "Indre", region: "24"),
                    frenchDepartment("37", name: "Indre-et-Loire", region: "24"),
                    frenchDepartment("41", name: "Loir-et-Cher", region: "24"),
                    frenchDepartment("45", name: "Loiret", region: "24")
                ]
            ),
            DivisionGroup(
                id: "FR-region-94",
                name: "Corse",
                divisions: [
                    frenchDepartment("2A", name: "Corse-du-Sud", region: "94"),
                    frenchDepartment("2B", name: "Haute-Corse", region: "94")
                ]
            ),
            DivisionGroup(
                id: "FR-region-44",
                name: "Grand Est",
                divisions: [
                    frenchDepartment("08", name: "Ardennes", region: "44"),
                    frenchDepartment("10", name: "Aube", region: "44"),
                    frenchDepartment("51", name: "Marne", region: "44"),
                    frenchDepartment("52", name: "Haute-Marne", region: "44"),
                    frenchDepartment("54", name: "Meurthe-et-Moselle", region: "44"),
                    frenchDepartment("55", name: "Meuse", region: "44"),
                    frenchDepartment("57", name: "Moselle", region: "44"),
                    frenchDepartment("67", name: "Bas-Rhin", region: "44"),
                    frenchDepartment("68", name: "Haut-Rhin", region: "44"),
                    frenchDepartment("88", name: "Vosges", region: "44")
                ]
            ),
            DivisionGroup(
                id: "FR-region-32",
                name: "Hauts-de-France",
                divisions: [
                    frenchDepartment("02", name: "Aisne", region: "32"),
                    frenchDepartment("59", name: "Nord", region: "32"),
                    frenchDepartment("60", name: "Oise", region: "32"),
                    frenchDepartment("62", name: "Pas-de-Calais", region: "32"),
                    frenchDepartment("80", name: "Somme", region: "32")
                ]
            ),
            DivisionGroup(
                id: "FR-region-11",
                name: "Île-de-France",
                divisions: [
                    frenchDepartment("75", name: "Paris", region: "11"),
                    frenchDepartment("77", name: "Seine-et-Marne", region: "11"),
                    frenchDepartment("78", name: "Yvelines", region: "11"),
                    frenchDepartment("91", name: "Essonne", region: "11"),
                    frenchDepartment("92", name: "Hauts-de-Seine", region: "11"),
                    frenchDepartment("93", name: "Seine-Saint-Denis", region: "11"),
                    frenchDepartment("94", name: "Val-de-Marne", region: "11"),
                    frenchDepartment("95", name: "Val-d'Oise", region: "11")
                ]
            ),
            DivisionGroup(
                id: "FR-region-28",
                name: "Normandie",
                divisions: [
                    frenchDepartment("14", name: "Calvados", region: "28"),
                    frenchDepartment("27", name: "Eure", region: "28"),
                    frenchDepartment("50", name: "Manche", region: "28"),
                    frenchDepartment("61", name: "Orne", region: "28"),
                    frenchDepartment("76", name: "Seine-Maritime", region: "28")
                ]
            ),
            DivisionGroup(
                id: "FR-region-75",
                name: "Nouvelle-Aquitaine",
                divisions: [
                    frenchDepartment("16", name: "Charente", region: "75"),
                    frenchDepartment("17", name: "Charente-Maritime", region: "75"),
                    frenchDepartment("19", name: "Corrèze", region: "75"),
                    frenchDepartment("23", name: "Creuse", region: "75"),
                    frenchDepartment("24", name: "Dordogne", region: "75"),
                    frenchDepartment("33", name: "Gironde", region: "75"),
                    frenchDepartment("40", name: "Landes", region: "75"),
                    frenchDepartment("47", name: "Lot-et-Garonne", region: "75"),
                    frenchDepartment("64", name: "Pyrénées-Atlantiques", region: "75"),
                    frenchDepartment("79", name: "Deux-Sèvres", region: "75"),
                    frenchDepartment("86", name: "Vienne", region: "75"),
                    frenchDepartment("87", name: "Haute-Vienne", region: "75")
                ]
            ),
            DivisionGroup(
                id: "FR-region-76",
                name: "Occitanie",
                divisions: [
                    frenchDepartment("09", name: "Ariège", region: "76"),
                    frenchDepartment("11", name: "Aude", region: "76"),
                    frenchDepartment("12", name: "Aveyron", region: "76"),
                    frenchDepartment("30", name: "Gard", region: "76"),
                    frenchDepartment("31", name: "Haute-Garonne", region: "76"),
                    frenchDepartment("32", name: "Gers", region: "76"),
                    frenchDepartment("34", name: "Hérault", region: "76"),
                    frenchDepartment("46", name: "Lot", region: "76"),
                    frenchDepartment("48", name: "Lozère", region: "76"),
                    frenchDepartment("65", name: "Hautes-Pyrénées", region: "76"),
                    frenchDepartment("66", name: "Pyrénées-Orientales", region: "76"),
                    frenchDepartment("81", name: "Tarn", region: "76"),
                    frenchDepartment("82", name: "Tarn-et-Garonne", region: "76")
                ]
            ),
            DivisionGroup(
                id: "FR-region-52",
                name: "Pays de la Loire",
                divisions: [
                    frenchDepartment("44", name: "Loire-Atlantique", region: "52"),
                    frenchDepartment("49", name: "Maine-et-Loire", region: "52"),
                    frenchDepartment("53", name: "Mayenne", region: "52"),
                    frenchDepartment("72", name: "Sarthe", region: "52"),
                    frenchDepartment("85", name: "Vendée", region: "52")
                ]
            ),
            DivisionGroup(
                id: "FR-region-93",
                name: "Provence-Alpes-Côte d'Azur",
                divisions: [
                    frenchDepartment("04", name: "Alpes-de-Haute-Provence", region: "93"),
                    frenchDepartment("05", name: "Hautes-Alpes", region: "93"),
                    frenchDepartment("06", name: "Alpes-Maritimes", region: "93"),
                    frenchDepartment("13", name: "Bouches-du-Rhône", region: "93"),
                    frenchDepartment("83", name: "Var", region: "93"),
                    frenchDepartment("84", name: "Vaucluse", region: "93")
                ]
            ),
            DivisionGroup(
                id: "FR-region-01",
                name: "Guadeloupe",
                divisions: [
                    frenchDepartment("971", name: "Guadeloupe", region: "01")
                ]
            ),
            DivisionGroup(
                id: "FR-region-02",
                name: "Martinique",
                divisions: [
                    frenchDepartment("972", name: "Martinique", region: "02")
                ]
            ),
            DivisionGroup(
                id: "FR-region-03",
                name: "Guyane",
                divisions: [
                    frenchDepartment("973", name: "Guyane", region: "03")
                ]
            ),
            DivisionGroup(
                id: "FR-region-04",
                name: "La Réunion",
                divisions: [
                    frenchDepartment("974", name: "La Réunion", region: "04")
                ]
            ),
            DivisionGroup(
                id: "FR-region-06",
                name: "Mayotte",
                divisions: [
                    frenchDepartment("976", name: "Mayotte", region: "06")
                ]
            )
        ]
    )

    private static func frenchDepartment(_ code: String, name: String, region: String) -> AdministrativeDivision {
        let flag = frenchFlags[code]
        return AdministrativeDivision(
            id: "FR-\(code)",
            countryID: "FR",
            name: name,
            abbreviation: code,
            groupID: "FR-region-\(region)",
            flagAssetName: flag?.asset ?? "fr_flag",
            flagNote: flag?.note ?? "The French national tricolor is shown for this department."
        )
    }

    // Artwork licenses and sources are bundled in FranceFlagCredits.json.
    // Heraldic banners, council flags and national fallbacks are identified in each note.
    private static let frenchFlags: [String: (asset: String, note: String)] = [
        "01": ("fr_flag_01", "A heraldic flag associated with this department is shown as a local symbol."),
        "02": ("fr_flag_02", "A heraldic flag associated with this department is shown as a local symbol."),
        "03": ("fr_flag_03", "A heraldic flag associated with this department is shown as a local symbol."),
        "04": ("fr_flag_04", "A heraldic flag associated with this department is shown as a local symbol."),
        "05": ("fr_flag_05", "A heraldic flag associated with this department is shown as a local symbol."),
        "06": ("fr_flag_06", "A departmental council flag associated with this department is shown."),
        "07": ("fr_flag_07", "Heraldic banner associated with Ardèche."),
        "08": ("fr_flag_08", "Heraldic banner associated with Ardennes."),
        "09": ("fr_flag_09", "Departmental council flag associated with Ariège."),
        "10": ("fr_flag_10", "Heraldic banner associated with Aube."),
        "11": ("fr_flag_11", "Traditional flag associated with Aude."),
        "12": ("fr_flag", "The French national flag is shown for Aveyron."),
        "13": ("fr_flag_13", "Departmental council flag associated with Bouches-du-Rhône."),
        "14": ("fr_flag_14", "Departmental council flag associated with Calvados."),
        "15": ("fr_flag_15", "Heraldic banner associated with Cantal."),
        "16": ("fr_flag_16", "A heraldic flag associated with this department is shown as a local symbol."),
        "17": ("fr_flag_17", "A heraldic flag associated with this department is shown as a local symbol."),
        "18": ("fr_flag_18", "A heraldic flag associated with this department is shown as a local symbol."),
        "19": ("fr_flag_19", "A heraldic flag associated with this department is shown as a local symbol."),
        "21": ("fr_flag_21", "An unofficial heraldic flag associated with this department is shown."),
        "22": ("fr_flag_22", "Heraldic banner associated with Côtes-d’Armor."),
        "23": ("fr_flag_23", "A heraldic flag associated with this department is shown as a local symbol."),
        "24": ("fr_flag_24", "A heraldic flag associated with this department is shown as a local symbol."),
        "25": ("fr_flag", "The French national tricolor is shown for this department; a separate departmental flag is not represented."),
        "26": ("fr_flag_26", "Departmental council flag associated with Drôme."),
        "27": ("fr_flag_27", "A departmental council flag associated with this department is shown."),
        "28": ("fr_flag_28", "A heraldic flag associated with this department is shown as a local symbol."),
        "29": ("fr_flag_29", "A heraldic flag associated with this department is shown as a local symbol."),
        "2A": ("fr_flag_2a", "The Corsican flag is shared by Corse-du-Sud and Haute-Corse."),
        "2B": ("fr_flag_2b", "The Corsican flag is shared by Haute-Corse and Corse-du-Sud."),
        "30": ("fr_flag_30", "An unofficial heraldic flag associated with this department is shown."),
        "31": ("fr_flag_31", "An unofficial heraldic flag associated with this department is shown."),
        "32": ("fr_flag_32", "An unofficial heraldic flag associated with this department is shown."),
        "33": ("fr_flag_33", "A heraldic flag associated with this department is shown as a local symbol."),
        "34": ("fr_flag_34", "An unofficial heraldic flag associated with this department is shown."),
        "35": ("fr_flag_35", "An unofficial heraldic flag associated with this department is shown."),
        "36": ("fr_flag_36", "A heraldic flag associated with this department is shown as a local symbol."),
        "37": ("fr_flag_37", "An unofficial heraldic flag associated with this department is shown."),
        "38": ("fr_flag_38", "An unofficial heraldic flag associated with this department is shown."),
        "39": ("fr_flag_39", "A heraldic flag associated with this department is shown as a local symbol."),
        "40": ("fr_flag_40", "A heraldic flag associated with this department is shown as a local symbol."),
        "41": ("fr_flag_41", "A heraldic flag associated with this department is shown as a local symbol."),
        "42": ("fr_flag_42", "A heraldic flag associated with this department is shown as a local symbol."),
        "43": ("fr_flag_43", "Heraldic banner associated with Haute-Loire."),
        "44": ("fr_flag_44", "A heraldic flag associated with this department is shown as a local symbol."),
        "45": ("fr_flag_45", "A heraldic flag associated with this department is shown as a local symbol."),
        "46": ("fr_flag_46", "An unofficial heraldic flag associated with this department is shown."),
        "47": ("fr_flag_47", "A heraldic flag associated with this department is shown as a local symbol."),
        "48": ("fr_flag_48", "An unofficial heraldic flag associated with this department is shown."),
        "49": ("fr_flag_49", "A heraldic flag associated with this department is shown as a local symbol."),
        "50": ("fr_flag_50", "An unofficial heraldic flag associated with this department is shown."),
        "51": ("fr_flag_51", "Heraldic banner associated with Marne."),
        "52": ("fr_flag_52", "A heraldic flag associated with this department is shown as a local symbol."),
        "53": ("fr_flag_53", "A heraldic flag associated with this department is shown as a local symbol."),
        "54": ("fr_flag_54", "A heraldic flag associated with this department is shown as a local symbol."),
        "55": ("fr_flag_55", "Heraldic banner based on the arms of Meuse."),
        "56": ("fr_flag_56", "Heraldic banner associated with Morbihan."),
        "57": ("fr_flag_57", "Heraldic banner based on the arms of Moselle."),
        "58": ("fr_flag_58", "A heraldic flag associated with this department is shown as a local symbol."),
        "59": ("fr_flag_59", "Departmental council flag associated with Nord."),
        "60": ("fr_flag_60", "A heraldic flag associated with this department is shown as a local symbol."),
        "61": ("fr_flag_61", "A heraldic flag associated with this department is shown as a local symbol."),
        "62": ("fr_flag_62", "An unofficial heraldic flag associated with this department is shown."),
        "63": ("fr_flag_63", "A departmental council flag associated with this department is shown."),
        "64": ("fr_flag", "The French national tricolor is shown for this department; a separate departmental flag is not represented."),
        "65": ("fr_flag_65", "A departmental council flag associated with this department is shown."),
        "66": ("fr_flag_66", "A departmental council flag associated with this department is shown."),
        "67": ("fr_flag_67", "Departmental council flag associated with Bas-Rhin."),
        "68": ("fr_flag_68", "A heraldic flag associated with this department is shown as a local symbol."),
        "69": ("fr_flag_69", "Heraldic banner associated with Rhône."),
        "70": ("fr_flag_70", "A heraldic flag associated with this department is shown as a local symbol."),
        "71": ("fr_flag_71", "A departmental council flag associated with this department is shown."),
        "72": ("fr_flag_72", "Heraldic banner associated with Sarthe."),
        "73": ("fr_flag_73", "Traditional flag of Savoy, shared across the historic region."),
        "74": ("fr_flag_74", "An unofficial heraldic flag associated with this department is shown."),
        "75": ("fr_flag_75", "The blue-and-red flag of Paris."),
        "76": ("fr_flag_76", "Departmental council flag associated with Seine-Maritime."),
        "77": ("fr_flag_77", "An unofficial heraldic flag associated with this department is shown."),
        "78": ("fr_flag_78", "A heraldic flag associated with this department is shown as a local symbol."),
        "79": ("fr_flag_79", "A heraldic flag associated with this department is shown as a local symbol."),
        "80": ("fr_flag_80", "A heraldic flag associated with this department is shown as a local symbol."),
        "81": ("fr_flag_81", "A heraldic flag associated with this department is shown as a local symbol."),
        "82": ("fr_flag_82", "A heraldic flag associated with this department is shown as a local symbol."),
        "83": ("fr_flag_83", "A heraldic flag associated with this department is shown as a local symbol."),
        "84": ("fr_flag_84", "A heraldic flag associated with this department is shown as a local symbol."),
        "85": ("fr_flag_85", "A heraldic flag associated with this department is shown as a local symbol."),
        "86": ("fr_flag_86", "A heraldic flag associated with this department is shown as a local symbol."),
        "87": ("fr_flag_87", "A heraldic flag associated with this department is shown as a local symbol."),
        "88": ("fr_flag_88", "A heraldic flag associated with this department is shown as a local symbol."),
        "89": ("fr_flag_89", "A heraldic flag associated with this department is shown as a local symbol."),
        "90": ("fr_flag_90", "A heraldic flag associated with this department is shown as a local symbol."),
        "91": ("fr_flag_91", "A heraldic flag associated with this department is shown as a local symbol."),
        "92": ("fr_flag_92", "A heraldic flag associated with this department is shown as a local symbol."),
        "93": ("fr_flag", "The French national tricolor is shown for this department; a separate departmental flag is not represented."),
        "94": ("fr_flag_94", "An unofficial heraldic flag associated with this department is shown."),
        "95": ("fr_flag_95", "A heraldic flag associated with this department is shown as a local symbol."),
        "971": ("fr_flag_971", "Unofficial local flag associated with Guadeloupe. The French tricolour is the official flag."),
        "972": ("fr_flag_972", "Flag adopted by the Territorial Collectivity of Martinique in 2023."),
        "973": ("fr_flag_973", "Local flag adopted by the former General Council of French Guiana in 2010."),
        "974": ("fr_flag", "The French national flag is shown for La Réunion."),
        "976": ("fr_flag_976", "Unofficial local banner bearing Mayotte’s coat of arms. The French tricolour is the official flag.")
    ]
}
