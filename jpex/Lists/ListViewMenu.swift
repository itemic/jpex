import SwiftUI

/// The list's eye menu: how the list is arranged and what it shows, a tap away on the list itself
/// rather than in Settings. It stays open, so several things can be changed in one go.
struct ListViewMenu: View {
    var country: Country
    @Binding var localLanguage: Bool
    @AppStorage(RowSize.storageKey) private var rowSize = RowSize.saved
    @AppStorage(ListOrder.showsMapKey) private var showsMap = true
    @AppStorage(MapPosition.storageKey) private var mapPosition = MapPosition.saved
    @AppStorage(ListOrder.showsHeadingsKey) private var showsHeadings = true
    @AppStorage(ListOrder.countriesKey) private var countriesOrder = ListOrder.regions
    @AppStorage(ListOrder.subdivisionsKey) private var subdivisionsOrder = ListOrder.regions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var listsCountries: Bool { ListOrder.listsCountries(country) }

    /// Countries and subdivisions keep their own order, so switching one leaves the other be.
    private var order: Binding<ListOrder> {
        listsCountries ? $countriesOrder : $subdivisionsOrder
    }

    /// What the list groups by when it isn't A to Z: continents for countries, regions otherwise.
    private var groupName: String {
        listsCountries ? "Continent" : "Region"
    }

    var body: some View {
        Menu("View", systemImage: "eye") {
            Picker("Sort", selection: order.animation(.smooth)) {
                Label("By \(groupName.lowercased())", systemImage: listsCountries ? "globe.europe.africa" : "map")
                    .tag(ListOrder.regions)
                Label("A to Z", systemImage: "textformat.characters")
                    .tag(ListOrder.alphabetical)
            }
            .pickerStyle(.inline)
            Section {
                Toggle(
                    order.wrappedValue == .alphabetical ? "Letter headings" : "\(groupName) headings",
                    systemImage: "list.dash.header.rectangle",
                    isOn: $showsHeadings.animation(Motion.moving(Motion.layout, reduceMotion: reduceMotion)))
                // The rows change size as they do after a pinch on the list.
                Picker(
                    "Row size", systemImage: rowSize.symbolName,
                    selection: $rowSize.animation(Motion.moving(Motion.layout, reduceMotion: reduceMotion))
                ) {
                    ForEach(RowSize.allCases) { size in
                        Label(size.name, systemImage: size.symbolName).tag(size)
                    }
                }
                .pickerStyle(.menu)
                Toggle(
                    "Map", systemImage: "map",
                    isOn: $showsMap.animation(Motion.moving(Motion.layout, reduceMotion: reduceMotion)))
                // Where the map sits, which means nothing while it's hidden from the list.
                if showsMap {
                    Picker(
                        "Map position", systemImage: mapPosition.symbolName,
                        selection: $mapPosition.animation(Motion.moving(Motion.layout, reduceMotion: reduceMotion))
                    ) {
                        ForEach(MapPosition.allCases) { position in
                            Label(position.name, systemImage: position.symbolName).tag(position)
                        }
                    }
                    .pickerStyle(.menu)
                }
                if country.supportsLocalNames {
                    Toggle(
                        "Local names first",
                        systemImage: "character.book.closed", isOn: $localLanguage.animation(.smooth))
                }
            }
            // What the map shows: colours for the countries, and lines and shapes
            // over them. Only World maps know where on Earth they are, so only lists of countries
            // offer them, and only while the map is showing.
            if listsCountries, showsMap {
                Section {
                    WorldLayerControls()
                }
            }
        }
        .menuActionDismissBehavior(.disabled)
    }
}
