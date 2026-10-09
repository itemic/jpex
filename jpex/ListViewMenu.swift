import SwiftUI

/// The list's eye menu: how the list is arranged and what it shows, a tap away on the list itself
/// rather than in Settings. It stays open, so several things can be changed in one go.
struct ListViewMenu: View {
    var country: Country
    @Binding var localLanguage: Bool
    @AppStorage(RowSize.storageKey) private var rowSize = RowSize.saved
    @AppStorage(ListOrder.showsMapKey) private var showsMap = true
    @AppStorage(ListOrder.showsHeadingsKey) private var showsHeadings = true
    @AppStorage(ListOrder.countriesKey) private var countriesOrder = ListOrder.regions
    @AppStorage(ListOrder.subdivisionsKey) private var subdivisionsOrder = ListOrder.regions
    @AppStorage(DayNight.storageKey) private var showsDayNight = false

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
                Label("By \(groupName)", systemImage: listsCountries ? "globe.europe.africa" : "map")
                    .tag(ListOrder.regions)
                Label("A to Z", systemImage: "textformat.characters")
                    .tag(ListOrder.alphabetical)
            }
            .pickerStyle(.inline)
            Section {
                Toggle(
                    order.wrappedValue == .alphabetical ? "Letter Headings" : "\(groupName) Headings",
                    systemImage: "list.dash.header.rectangle", isOn: $showsHeadings.animation(.smooth))
                Picker("Row Size", systemImage: rowSize.symbolName, selection: $rowSize.animation(.smooth)) {
                    ForEach(RowSize.allCases) { size in
                        Label(size.name, systemImage: size.symbolName).tag(size)
                    }
                }
                .pickerStyle(.menu)
                Toggle("Map", systemImage: "map", isOn: $showsMap.animation(.smooth))
                // The night side of the World, shaded as it is right now. Only World maps know
                // where on Earth they are, so only lists of countries offer it.
                if listsCountries {
                    Toggle("Day & Night", systemImage: "sun.horizon", isOn: $showsDayNight)
                }
                if country.supportsLocalNames {
                    Toggle(
                        country.id == "JP" ? "Japanese Names First" : "Local Names First",
                        systemImage: "character.book.closed", isOn: $localLanguage.animation(.smooth))
                }
            }
        }
        .menuActionDismissBehavior(.disabled)
    }
}
