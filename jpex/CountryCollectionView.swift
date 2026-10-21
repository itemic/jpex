import SwiftUI

struct CountryCollectionView: View {
  var country: Country
  var saveModel: SaveModel
  @Binding var localLanguage: Bool
  /// How this list came to take the place of the one before, for its map to fly over from that
  /// one's and, coming back, for the place just left to come into view.
  var arrival: CollectionArrival? = nil
  /// Sets a place's level, along with the collection it was set in.
  var onStatusChange: (VisitLevel, AdministrativeDivision, Country) -> Void
  /// Opens another collection in place of this one, such as Japan's prefectures from Countries,
  /// and whether the map should fly there, which it doesn't once it has already flown full screen.
  var onOpenCollection: (_ id: String, _ fliesMap: Bool) -> Void = { _, _ in }
  /// Shows the same country at another level in place of this one, such as France's departments
  /// instead of its regions.
  var onSwitchLevel: (_ id: String) -> Void = { _ in }
  /// Opens one level of a country's places in place of this list, as chosen, such as France's
  /// departments from France in the World, its map flying over from this one's.
  var onOpenLevel: (_ id: String) -> Void = { _ in }
  /// Shows the same country at another level, at a section of it, such as Île-de-France's
  /// departments from Île-de-France among the regions.
  var onShowInLevel: (_ id: String, _ sectionID: String, _ placeID: String) -> Void = { _, _, _ in }
  /// A place in this list to bring into view, such as one found by searching from the sidebar.
  var revealedPlace: RevealedPlace? = nil
  /// Opens the list a place found in another list is in, with the place brought into view.
  var onOpenPlace: (_ placeID: String, _ collectionID: String) -> Void = { _, _ in }
  /// Told where this list's map is on screen, for the welcome's World to land on.
  var mapLocation: ListMapLocation? = nil
  /// Learn asked for from elsewhere, such as the quiz lobby: where it's for this list, its full map
  /// opens in Learn.
  var learnRequest: LearnDeck.Request? = nil
  @Environment(CountingPreferences.self) private var counting
  @Environment(\.visitLadder) private var ladder
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.breaksOutOntoScreen) private var breaksOutOntoScreen
  @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
  @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
  @State private var searchText = ""
  /// The search without spaces at either end, so a stray space doesn't count as searching.
  private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }
  /// Whether the search field is open, so a new list can put it away.
  @State private var isSearching = false
  @State private var totalHeight = 0.0
  @State private var showingMap = false
  /// Where the full map opens in Learn, rather than on the person's travels.
  @State private var learnStart: LearnDeck.Request?
  /// Where the map is on screen, kept in state only while it's pinned to the top, where the headers
  /// beneath move with it; otherwise kept aside, so the map scrolling with the list doesn't redraw
  /// the whole list at every frame. Either way `cardFrame` has it, for the full map to grow from.
  @State private var mapCardFrame: CGRect?
  @State private var cardFrame = CardFrame()
  /// The map's flight over from the list before, built once for each arrival rather than at every pass.
  @State private var journeys = JourneyCache()
  @State private var listFrame: CGRect = .zero
  @State private var mapGrowsFromCard = false
  @State private var isMapCardHidden = false
  @AppStorage(RowSize.storageKey) private var rowSize = RowSize.saved
  /// Whether the map is held beside the fold rather than at the head of the list.
  @State private var isMapPinned = false
  /// A place found from the map, or brought back into view, lit in the list until it settles back.
  @State private var highlightedID: String?
  /// Counts each place lit, so only the latest settles itself back.
  @State private var lightings = 0
  /// How many times the list has landed on each place found, so that place's row can flourish
  /// as it arrives, and the hand feel it land.
  @State private var placeArrivals: [String: Int] = [:]
  @State private var scrollRequest: ScrollRequest?
  /// How many times each region has been jumped to, so its header can pulse on arrival.
  @State private var regionJumps: [String: Int] = [:]
  /// Counts pinches that switched the rows to another size.
  @State private var pinches = 0
  /// The place whose quick level picker is open, outlined on the map too.
  @State private var tapbackID: String?
  @State private var tapbackSize: CGSize = .zero
  @AppStorage(MapPosition.storageKey) private var mapPosition = MapPosition.saved
  @AppStorage(ListOrder.showsMapKey) private var showsMap = true
  @AppStorage(ListOrder.countriesKey) private var countriesOrder = ListOrder.regions
  @AppStorage(ListOrder.subdivisionsKey) private var subdivisionsOrder = ListOrder.regions
  @AppStorage(ListOrder.showsHeadingsKey) private var showsHeadings = true
  @AppStorage(JapanExMapping.storageKey) private var japanExMapping = JapanExMapping()
  /// How far the pinned map has shrunk from its full size as the list scrolls.
  @State private var mapCollapse: CGFloat = 0
  /// While the list glides to a place or region on its own, the pinned map keeps its size.
  @State private var isGlidingToRequest = false
  /// The fold as last measured without the keyboard in the way, held while searching.
  @State private var heldFold: FoldRegions?
  /// The page's height as last seen without searching, so the keyboard shortening it can't set
  /// the map beside the list.
  @State private var unsearchedHeight: CGFloat?
  /// Where the list is scrolled, so a tap on the shrunken pinned map can scroll back to grow it.
  @State private var scrollPosition = ScrollPosition()
  /// How far the list is scrolled from its top, as last seen.
  @State private var scrolledDistance: CGFloat = 0
  /// The places the pinned map zooms in close to while it's grown back over the list.
  @State private var mapFocus: [String] = []
  /// Whether the list has scrolled its total away, so the count rides on the pinned map instead.
  @State private var isTotalScrolledAway = false
  /// How many times the list has been pulled down past its top, which spins or bounces the map.
  @State private var mapNudges = 0
  @State private var visibleRows = VisibleRows()
  /// The arrival whose place to come back to has been brought into view.
  @State private var revealedArrivalID: UUID?
  /// The arrival whose place to come back to waits for the map to fly back out before the list
  /// glides down to it; cleared when another list takes this one's place.
  @State private var pendingFind: UUID?
  /// The place last found in the list from a tap on the map card, which another tap opens the map on.
  @State private var cardFoundID: String?
  /// The place the full map opens on, already picked, when it was opened by tapping that place again.
  @State private var mapSelection: String?
  /// The layer the full map opens on, such as Time zones chosen from the Map button's menu, rather
  /// than the person's travels.
  @State private var mapLayer: MapLayer?

  /// Whether the map is held above the list rather than scrolling away with it, as chosen in its
  /// View menu.
  private var keepsMapAtTop: Bool { mapPosition.isPinned }

  /// How this list is arranged, as chosen in its View menu: countries and subdivisions are set apart.
  private var order: ListOrder {
    ListOrder.listsCountries(country) ? countriesOrder : subdivisionsOrder
  }

  /// The list's sections: its own regions, or, A to Z, one section for each first letter.
  private var arrangedGroups: [DivisionGroup] {
    guard order == .alphabetical else { return country.groups }
    let named = country.divisions.map { ($0, $0.displayName(localLanguage: localLanguage)) }
      .sorted { $0.1.localizedStandardCompare($1.1) == .orderedAscending }
    var groups: [DivisionGroup] = []
    for (division, name) in named {
      let letter = String(name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).prefix(1))
        .uppercased()
      if groups.last?.name == letter {
        groups[groups.count - 1].divisions.append(division)
      } else {
        groups.append(DivisionGroup(id: "\(country.id)-letter-\(letter)", name: letter, localName: nil, divisions: [division]))
      }
    }
    return groups
  }

  /// The total, once it has scrolled away with the map card, so it's always in sight. Measured by
  /// how far the list has scrolled, so it holds wherever the bars sit, as on iPhone Duo's side bar.
  /// Beside the fold, the pinned map carries the count instead.
  private func scrolledPastTotal(map: TravelMap?, snapshot: TravelSnapshot) -> String? {
    guard map != nil, !keepsMapAtTop, !isMapPinned, isTotalScrolledAway else { return nil }
    let counted = snapshot.count(in: country.divisions, counting: counting.rules)
    return "\(counted.formatted()) of \(country.divisions.count.formatted()) \(country.divisionLabel.lowercased())"
  }

  /// A place's own region or continent, shown on its row when the list runs A to Z.
  private func regionName(of division: AdministrativeDivision) -> String? {
    country.groups.first { $0.id == division.groupID }?.displayName(localLanguage: localLanguage)
  }

  private var displayedGroups: [DivisionSearchSection] {
    arrangedGroups.compactMap { group in
      let matches = group.divisions.filter { division in
        query.isEmpty
          || [
            division.name, division.localName ?? "", division.abbreviation, group.name,
            group.localName ?? "", regionName(of: division) ?? "",
          ]
          .contains { $0.localizedStandardContains(query) }
      }
      return matches.isEmpty ? nil : DivisionSearchSection(group: group, divisions: matches)
    }
  }

  /// Places in other lists matching the search, such as Kyoto searched for from the World, found
  /// a moment after typing pauses rather than at every keystroke and every redraw.
  @State private var elsewhere: [PlaceSearch.Result] = []
  /// Whether the last search to finish found nothing, in this list or any other, so No results
  /// waits for the whole search rather than flashing up before places from other lists arrive.
  @State private var foundNothing = false

  var body: some View {
    let snapshot = saveModel.snapshot()
    let statuses = Dictionary(uniqueKeysWithValues: country.divisions.map { ($0.id, snapshot.status(for: $0)) })
    let map = TravelMap.named(country.id, projection: projection, center: center)
    // Show Map off in Settings hides the map in the list; the full map stays a tap away.
    let listMap = showsMap ? map : nil
    let journey = journey(snapshot: snapshot)
    GeometryReader { container in
      // Partly folded, the map stays on the far side of the fold and the list scrolls on the near side.
      // While searching, the keyboard can leave too little room below the fold to count as split,
      // so the last fold is held, shortened to the room left, rather than unpinning the map.
      // A map squeezed into a sliver beside the fold helps no one, so it pins only with room to show.
      let measured = (listMap == nil ? nil : FoldRegions(in: container))
        .flatMap { $0.far.width >= 200 && $0.far.height >= 200 ? $0 : nil }
      // While searching, the page is judged at the height it had before the keyboard came up, so
      // typing never throws the map from the list's head to its side, nor the rows out of their
      // columns, nor back.
      let pageHeight = isSearching ? max(unsearchedHeight ?? 0, container.size.height) : container.size.height
      // A real fold comes first; otherwise a page much wider than tall, and wide enough for both,
      // such as a phone on its side or iPad in landscape, sets the map beside the list as the fold
      // would.
      let sideBySide = listMap == nil ? nil : Self.sideBySide(
        in: CGSize(width: container.size.width, height: pageHeight)
      )?.fitted(to: container.size)
      let fold = measured ?? (isSearching && listMap != nil ? heldFold?.fitted(to: container.size) : nil) ?? sideBySide
      let listFrame = fold?.near ?? CGRect(origin: .zero, size: container.size)
      ZStack(alignment: .topLeading) {
        if let fold, let map = listMap {
          PinnedMapView(
            map: map, statuses: statuses, minimumStatus: counting.rules.minimumLevel(in: ladder),
            highlightedID: highlightedID ?? tapbackID, journey: journey,
            // Once the list's total scrolls away on the near side, its count rides on the map.
            badge: isTotalScrolledAway
              ? TravelTotalView(
                tally: snapshot.tally(of: country.divisions), total: country.divisions.count,
                horizontalSafeArea: EdgeInsets(), minimumStatus: counting.rules.minimumLevel(in: ladder), isBadge: true)
              : nil,
            // Taps work as on the list's own card: a place is found in the list, then opens the map.
            onSelect: findFromCard, onOpen: { openMap() },
            onFrameChange: noteMapFrame
          )
          .opacity(isMapCardHidden ? 0 : 1)
          .frame(width: fold.far.width, height: fold.far.height)
          .position(x: fold.far.midX, y: fold.far.midY)
          // Settles in from a touch smaller as the page opens out; with Reduce Motion, only fades.
          .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
        }
        list(
          snapshot: snapshot, statuses: statuses, map: fold == nil ? listMap : nil, journey: journey,
          pageHeight: fold == nil ? pageHeight : listFrame.height, isBesideMap: fold != nil
        )
          .frame(width: listFrame.width, height: listFrame.height)
          .position(x: listFrame.midX, y: listFrame.midY)
      }
      // The map and the list take their new places together; with Reduce Motion, in a short ease.
      .animation(Motion.moving(.smooth(duration: 0.5), reduceMotion: reduceMotion), value: fold)
      .onChange(of: fold != nil, initial: true) { _, pinned in isMapPinned = pinned }
      .onChange(of: measured, initial: true) { _, measured in
        if let measured { heldFold = measured } else if !isSearching { heldFold = nil }
      }
      .onChange(of: container.size.height, initial: true) { _, height in
        if !isSearching { unsearchedHeight = height }
      }
      .onChange(of: isSearching) { _, searching in
        if !searching { unsearchedHeight = container.size.height }
      }
    }
    // Places rising here break out over the screen only while the list is in front, never from
    // beneath the full map.
    .environment(\.breaksOutOntoScreen, breaksOutOntoScreen && !showingMap)
    // The map is part of the page, so its ripple runs on down the list, each row lifting as it passes.
    .environment(\.spreadsRipplesAcrossScreen, true)
    .background(.pageBackground)
    .animation(.smooth, value: country.id)
    .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search \(country.listTitle)")
    .task(id: SearchKey(query: query, listID: country.id)) {
      // Places found elsewhere settle in and out beneath the list's own rather than blinking.
      let settle = Motion.moving(.snappy(duration: 0.3), reduceMotion: reduceMotion)
      guard !query.isEmpty else {
        if !elsewhere.isEmpty || foundNothing {
          withAnimation(settle) {
            elsewhere = []
            foundNothing = false
          }
        }
        return
      }
      try? await Task.sleep(for: .milliseconds(120))
      guard !Task.isCancelled else { return }
      let found = PlaceSearch.results(for: query, in: CountryCatalog.countries(applying: counting.rules), excluding: country)
      // No results fades in only once nothing has turned up anywhere. Typing on from there, it
      // stays put rather than blinking out at each letter; places found again fade it away.
      withAnimation(settle) {
        elsewhere = found
        foundNothing = found.isEmpty && displayedGroups.isEmpty
      }
    }
    .navigationTitle(country.listTitle)
    .modifier(TotalSubtitle(text: scrolledPastTotal(map: map, snapshot: snapshot)))
    // With the map held on the far side of the fold, a small title leaves it more of its half; with
    // it pinned to the top of the list, a large one would sit hidden behind it, so the title keeps
    // to the bar there too.
    .navigationBarTitleDisplayMode(isMapPinned || (keepsMapAtTop && showsMap && map != nil) ? .inline : .large)
    .toolbar {
      // Once the list scrolls and its title is small, or beside the fold, the title opens the same
      // menu of levels as the cards beside the total. Inside the toolbar rather than wrapped around
      // the page, so moving between a country with levels, such as France, and one without leaves
      // the page itself standing: the new list fades through as any other does, and nothing in it
      // starts over.
      let levels = CountryCatalog.levels(of: country)
      if levels.count > 1 {
        ToolbarTitleMenu {
          LevelPicker(levels: levels, currentID: country.id, onSwitch: onSwitchLevel)
        }
      }
      // The way to the full map, wherever the list has one: a tap opens it, and touching and holding
      // offers the Atlas, time zones and the map's other layers to open it on instead. Every map can
      // open in the Atlas; the World's, and a group of countries', on Time zones and the facts too,
      // as the full map's own layer chooser offers there.
      if map != nil {
        ToolbarItem(placement: .primaryAction) {
          MapMenuButton(
            layers: MapMenuButton.layers(listsCountries: ListOrder.listsCountries(country)),
            onOpen: { openMap() }, onOpenLayer: { openMap(on: $0) })
        }
      }
      // JapanEx knows only the original levels; others show as the person maps them in Levels.
      if country.id == CountryCatalog.japan.id {
        // Tucked into the overflow menu, so the toolbar stays short on iPhone Duo's side bar.
        ToolbarItem(placement: .secondaryAction) {
          Link(destination: JapanEx.link(for: snapshot, mapping: japanExMapping)) {
            Label("Open in JapanEx", systemImage: "globe.asia.australia")
          }
        }
      }
      // How the list is arranged and what it shows, including local names first.
      ToolbarItem(placement: .primaryAction) {
        ListViewMenu(country: country, localLanguage: $localLanguage)
      }
    }
    .fullScreenCover(isPresented: $showingMap) {
      if let map {
        MapScreen(
          collection: country,
          map: map,
          saveModel: saveModel,
          sourceFrame: mapGrowsFromCard ? cardFrame.rect : nil,
          onStatusChange: onStatusChange,
          onOpenCollection: { id in
            closeMap()
            // The full-screen map has already flown there.
            onOpenCollection(id, false)
          },
          onPresent: { isMapCardHidden = mapGrowsFromCard },
          onClose: closeMap,
          learning: learnStart,
          selecting: mapSelection,
          startingLayer: mapLayer
        )
        .presentationBackground(.clear)
      }
    }
    // Only for a pinch here; switching in Settings has its own toggle.
    .sensoryFeedback(.impact(weight: .light), trigger: pinches)
    // Switching a country's level, such as France from its regions to its departments, ticks.
    .sensoryFeedback(.selection, trigger: country.id) { old, new in
      guard let old = CountryCatalog.country(id: old), let new = CountryCatalog.country(id: new) else { return false }
      return old.countryListID == new.countryListID
    }
    .onChange(of: learnRequest, initial: true) { _, request in
      guard let request, request.collectionID == country.id, map != nil else { return }
      // A moment for the list to settle in, and whatever it came from to go, before the map opens.
      Task {
        try? await Task.sleep(for: .milliseconds(350))
        guard country.id == request.collectionID, !showingMap else { return }
        learnStart = request
        openMap()
      }
    }
    .onChange(of: revealedPlace) { _, place in
      guard let place, country.divisions.contains(where: { $0.id == place.id }) else { return }
      reveal(place.id)
    }
    .onChange(of: mapPosition) { _, position in
      // The map takes up its new place to match where the list is scrolled: whole at full size, or
      // as shrunk as the list has scrolled, so no rows are left beneath it.
      mapCollapse = position == .pinned ? scrolledDistance : 0
      mapFocus = []
    }
    .onChange(of: country.id) {
      // A find still waiting on the map belongs to the list before, unless it's this list's own.
      if pendingFind != arrival?.id { pendingFind = nil }
      tapbackID = nil
      searchText = ""
      isSearching = false
      highlightedID = nil
      mapCollapse = 0
      mapFocus = []
      // The new list starts at its top, not where the last one was scrolled to.
      scrollPosition = ScrollPosition()
      scrolledDistance = 0
      closeMap()
      // Nothing is pushed, so VoiceOver is told the screen has changed, to start again from its title.
      AccessibilityNotification.ScreenChanged(nil).post()
    }
  }

  /// The map's flight over from the list before, while this list is arriving in its place.
  private func journey(snapshot: TravelSnapshot) -> MapJourney? {
    guard let arrival, arrival.toID == country.id, arrival.isUnderWay else { return nil }
    return journeys.journey(for: arrival) {
      MapJourney(
        arrival: arrival, collections: CountryCatalog.countries(applying: counting.rules), snapshot: snapshot,
        projection: projection, center: center)
    }
  }

  /// Coming back to this list, brings the place just left into view and lights it up, as a place
  /// found from the map is, flourishing once the list has faded in. Arriving at a section, such as
  /// a region's departments, goes to its header, which pulses as it does after a jump.
  ///
  /// Where the map heads the list and flies back out of the place just left, the list waits at its
  /// top for the flight to be seen: fly, then find. Once the map has pulled back out, the list
  /// glides down to the place, lit, and flourishes as it lands, unless the person has started
  /// scrolling by then or gone on to another list. With the map pinned at the top or beside the
  /// list, always in sight, or with Reduce Motion, where the map doesn't fly, the place comes into
  /// view at once. `flight` is the journey the list's own map card is playing, if any: back out to
  /// the World it's found once the map has pulled out; on into another country, once it has landed.
  private func revealArrival(with scroller: ScrollViewProxy, flight: MapJourney?) {
    guard let arrival, arrival.toID == country.id, arrival.isUnderWay, revealedArrivalID != arrival.id,
          let id = arrival.revealedPlaceID
    else { return }
    if country.groups.contains(where: { $0.id == id }) {
      revealedArrivalID = arrival.id
      // Diving in from a region, the map plays first, then the list glides down to its places.
      let delay = arrival.fromPlaceID != nil && !reduceMotion ? MapJourney.regionDiveDuration : 0
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(delay))
        jump(to: id)
      }
      return
    }
    guard country.divisions.contains(where: { $0.id == id }) else { return }
    revealedArrivalID = arrival.id
    if let flight, !keepsMapAtTop, !isMapPinned, !reduceMotion {
      pendingFind = arrival.id
      let flown = flight.destination == nil ? MapJourney.departureDuration : flight.duration
      let wait = flown - Date.now.timeIntervalSince(arrival.date)
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(max(wait, 0)))
        // Only if this is still the list it came back to, and the person hasn't moved it themselves.
        guard pendingFind == arrival.id, scrolledDistance < 8 else { return }
        pendingFind = nil
        reveal(id)
      }
      return
    }
    Task { @MainActor in
      scroller.scrollTo(id, anchor: .center)
      light(id, for: Self.listFadeIn + Self.foundHold)
      // The list rises into place before the row flourishes, so the flourish is seen.
      try? await Task.sleep(for: Self.listFadeIn)
      land(on: id)
    }
  }

  /// The scrolling list of places, with the map card at its head unless the map is pinned beside it.
  /// Pinch in for compact rows and out for roomy ones. `pageHeight` is how tall the list's page is
  /// taken to be when choosing whether its rows go in columns: its height before the keyboard came
  /// up, while searching, so typing never rearranges them. `isBesideMap` says the map is pinned
  /// beside the list, across a fold or a wide page, which gives the list's foot more room.
  private func list(
    snapshot: TravelSnapshot, statuses: [String: VisitLevel], map: TravelMap?, journey: MapJourney?,
    pageHeight: CGFloat, isBesideMap: Bool = false
  ) -> some View {
    @Bindable var counting = counting
    // Worked out once for the whole pass: arranging A to Z sorts every place.
    let groups = displayedGroups
    let regions = groups.map { regionSummary(of: $0.group, snapshot: snapshot) }
    let minimumStatus = counting.rules.minimumLevel(in: ladder)
    // Pinned, the map stays above the list; otherwise it heads the list and scrolls away with it.
    let pinnedMap = keepsMapAtTop ? map : nil
    let scrollingMap = keepsMapAtTop ? nil : map
    // Where the pinned map ends, including the strip of page beneath it, in global coordinates.
    let mapBottom = pinnedMap != nil && query.isEmpty ? (mapCardFrame?.maxY ?? 0) + 8 : -CGFloat.infinity
    // How far the list rises as it comes in, the way it came: none while its map is flying over.
    let journeyPlays = journey != nil && showsMap
    let rise = journeyPlays ? 0 : (arrival.flatMap { $0.toID == country.id ? $0.kind : nil } ?? .into).rise
    return GeometryReader { geometry in
      // Pinned, the map starts at its full size and shrinks as the list scrolls, down to a strip,
      // unless it's pinned at full size, when it holds that size with the list scrolling beneath it.
      // The reader's width already stops short of the safe area, as the pinned card does.
      // On a short screen, such as iPhone Duo's outer display on its side, the map keeps to a share
      // of the height so the list still has room.
      // The card's tallest grows with the page, so the World is a good size on a tall iPad page
      // rather than a strip, yet leaves a phone on its side room for the list.
      let cardMaxHeight = Self.cardMaxHeight(forHeight: geometry.size.height)
      let fullMapHeight = pinnedMap.map {
        min(
          MapCard.naturalHeight(of: $0, places: statuses.keys, width: geometry.size.width, maxHeight: cardMaxHeight),
          geometry.size.height * 0.45)
      } ?? 0
      // A page with room to spare, such as iPad's, sets its places in columns, so each pill stays
      // close to its name; a short one, such as a phone on its side, keeps to one place a row.
      let columns = Self.rowColumns(for: CGSize(width: geometry.size.width, height: pageHeight))
      // In columns, the rows keep clear of the page's sides together, rather than each on its own.
      let rowSafeArea = columns == nil ? geometry.safeAreaInsets : EdgeInsets()
      // Pinned at full size, the map never shrinks, so there's no strip for it to shrink to.
      let compactMapHeight = mapPosition == .pinnedFullSize
        ? fullMapHeight : min(150, fullMapHeight, geometry.size.height * 0.25)
      let collapse = max(fullMapHeight - compactMapHeight, 0)
      ScrollViewReader { scroller in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
            if query.isEmpty {
              VStack(spacing: 0) {
                if let map = scrollingMap {
                  mapCard(
                    map, statuses: statuses, snapshot: snapshot, horizontalSafeArea: geometry.safeAreaInsets,
                    maxHeight: cardMaxHeight, journey: journey)
                } else if pinnedMap != nil {
                  // Room for the pinned map's full size, which scrolls away as the map shrinks.
                  Color.clear.frame(height: collapse)
                }
                // A country listed at more than one level, such as France, names the level its total
                // counts, with each other level as a small card beside it to switch to.
                let levels = CountryCatalog.levels(of: country)
                // So does one with lists of its places' own subdivisions, such as Australia's states
                // with their local government areas, its places' card opening a menu of the places.
                TravelTotalView(
                  tally: snapshot.tally(of: country.divisions),
                  total: country.divisions.count,
                  horizontalSafeArea: geometry.safeAreaInsets,
                  minimumStatus: minimumStatus,
                  label: levels.count > 1 ? country.divisionLabel : SubdivisionLevels.label(of: country),
                  shortLabel: levels.count > 1 ? nil : SubdivisionLevels.shortLabel(of: country),
                  labelMap: levels.count > 1 || SubdivisionLevels.label(of: country) != nil ? TravelMap.named(country.id) : nil,
                  labelStatuses: levels.count > 1 || SubdivisionLevels.label(of: country) != nil ? statuses : [:],
                  // France keeps Regions before Departments; a place's own list keeps its country's
                  // places first, such as States & territories before Tasmania's LGAs.
                  labelPosition: levels.count > 1
                    ? levels.firstIndex { $0.id == country.id } ?? 0 : (country.parentPlace == nil ? 0 : 1),
                  otherLevels: levels.filter { $0.id != country.id }.map { level in
                    LevelSwitch(
                      id: level.id, title: level.divisionLabel,
                      counted: snapshot.count(in: level.divisions, counting: counting.rules), total: level.divisions.count,
                      map: TravelMap.named(level.id),
                      statuses: Dictionary(level.divisions.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first },
                      action: { onSwitchLevel(level.id) })
                  } + SubdivisionLevels.switches(
                    for: country, snapshot: snapshot, rules: counting.rules,
                    onOpen: { onOpenCollection($0, true) }, onSwitch: onSwitchLevel)
                )
                .feelsRipples()
                // A country's coasts aren't listed here, where the page is for browsing its places;
                // they're on the World's Coasts layer and in each country's Atlas card.
                // A group missing members hidden from the World says how many, so its count
                // isn't taken for the whole group.
                if country.hiddenCount > 0 {
                  HiddenStatesNote(count: country.hiddenCount)
                    .padding(.horizontal, 16 + geometry.safeAreaInsets.leading)
                    .padding(.bottom, 10)
                }
              }
              .onGeometryChange(for: Double.self) { $0.size.height } action: { totalHeight = $0 }
            }
            if foundNothing, groups.isEmpty, elsewhere.isEmpty {
              ContentUnavailableView.search(text: searchText)
                .frame(maxWidth: .infinity)
                .transition(.opacity)
            }
            ForEach(groups) { section in
              Section {
                // Where a jump to this region lands. Pinned headers don't make reliable scroll targets.
                Color.clear
                  .frame(height: 0)
                  .id(Self.regionAnchor(section.group.id))
                RowColumns(columns: columns, horizontalSafeArea: geometry.safeAreaInsets) {
                  ForEach(section.divisions) { division in
                    DivisionListRow(
                      division: division,
                      horizontalSafeArea: rowSafeArea,
                      localLanguage: localLanguage,
                      size: rowSize,
                      regionName: order == .alphabetical ? regionName(of: division) : nil,
                      isHighlighted: tapbackID == division.id,
                      isFound: highlightedID == division.id,
                      arrivals: placeArrivals[division.id, default: 0],
                      status: snapshot.status(for: division),
                      collection: CountryCatalog.collection(for: division),
                      isShowingLevels: tapbackID == division.id,
                      onSelect: { openTapback(for: division) },
                      onStatusChange: { onStatusChange($0, division, country) },
                      onOpenCollection: { onOpenCollection($0, true) }
                    )
                    .anchorPreference(key: TapbackAnchorKey.self, value: .bounds) { tapbackID == division.id ? $0 : nil }
                    .id(division.id)
                    // Set in columns, a row isn't one of the list's own scroll targets, so it says
                    // for itself when it comes into view, for the shrunk map to zoom in on.
                    .modifier(GridRowVisibility(id: division.id, rows: visibleRows, isTracking: columns != nil))
                  }
                }
              } header: {
                if showsHeadings, let region = regions.first(where: { $0.id == section.group.id }) {
                  DivisionListHeader(
                    horizontalSafeArea: geometry.safeAreaInsets,
                    region: region,
                    regions: regions,
                    minimumStatus: minimumStatus,
                    size: rowSize,
                    jumps: regionJumps[region.id, default: 0],
                    onJump: jump(to:)
                  )
                  // Headers pin just beneath the shrunken map; while it grows back over the list,
                  // the pinned header is pushed down to stay clear of it.
                  .visualEffect { [mapBottom] header, proxy in
                    header.offset(y: max(0, mapBottom - proxy.frame(in: .global).minY))
                  }
                }
              }
            }
            // Matches from every other list, so a place can be found and marked from anywhere.
            if !elsewhere.isEmpty {
              Section {
                // In columns on a wide page, as the list's own places are.
                RowColumns(columns: columns, horizontalSafeArea: geometry.safeAreaInsets) {
                  ForEach(elsewhere) { result in
                    DivisionListRow(
                      division: result.place,
                      horizontalSafeArea: rowSafeArea,
                      localLanguage: localLanguage,
                      size: rowSize,
                      regionName: result.locationName,
                      status: snapshot.status(for: result.place),
                      collection: CountryCatalog.collection(for: result.place),
                      selectHint: "Opens it in its list.",
                      opensLevelsAtTop: false,
                      onSelect: { onOpenPlace(result.place.id, result.collection.id) },
                      onStatusChange: { onStatusChange($0, result.place, result.collection) },
                      onOpenCollection: { onOpenCollection($0, true) }
                    )
                  }
                }
              } header: {
                ElsewhereHeader(count: elsewhere.count, horizontalSafeArea: geometry.safeAreaInsets, size: rowSize)
              }
            }
          }
          .frame(maxWidth: .infinity)
          // Rebuilt when the order changes: the lazy stack otherwise keeps some rows as they were,
          // with A to Z's region names still above them under the region headings.
          .id(order)
          // The old order slips away at once and the new one fades up in its place, so the two
          // are never seen together, one over the other.
          .transition(.asymmetric(
            insertion: .opacity.animation(.smooth(duration: 0.3).delay(0.1)),
            removal: .opacity.animation(.easeOut(duration: 0.12))))
          .scrollTargetLayout()
        }
        .onScrollTargetVisibilityChange(idType: String.self) { visibleRows.ids = $0 }
        .onAppear { revealArrival(with: scroller, flight: scrollingMap == nil ? nil : journey) }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { listFrame = $0 }
        .contentMargins(.horizontal, 0, for: .scrollContent)
        // A little room beneath the last row, so its flag's wash and a found row's glow end clear of
        // the page's foot rather than pressed against it; more on a big page in columns, or beside
        // the map, where the rows sit in open space. The pinned map's shrinking below reads the
        // scroll's insets, this margin among them, so it still ends at the list's true end.
        .contentMargins(.bottom, columns != nil || isBesideMap ? 24 : 12, for: .scrollContent)
        .contentMargins(.horizontal, geometry.safeAreaInsets, for: .scrollIndicators)
        .ignoresSafeArea(.container, edges: .horizontal)
        .modifier(PinnedHeaderCap(threshold: query.isEmpty ? totalHeight : 0))
        // Pinching in steps down a size, and out, back up, a step at a time, the rows following
        // the fingers a little as they pinch.
        .modifier(PinchToResize(canShrink: rowSize.smaller != nil, canGrow: rowSize.larger != nil) { isIn in
          guard let size = isIn ? rowSize.smaller : rowSize.larger else { return }
          withAnimation(Motion.moving(Motion.layout, reduceMotion: reduceMotion)) { rowSize = size }
          pinches += 1
        })
        .onChange(of: scrollRequest) { _, request in
          guard let request else { return }
          isGlidingToRequest = true
          // With Reduce Motion the list is simply there, rather than gliding.
          withAnimation(Motion.travelling(.smooth(duration: Self.glideDuration), reduceMotion: reduceMotion)) {
            scroller.scrollTo(request.id, anchor: request.anchor)
          } completion: {
            // A newer request may have taken over the glide; it ends the hold itself.
            if scrollRequest == request { isGlidingToRequest = false }
            // Arriving at a region, its header pulses and the hand feels it land.
            if let region = request.landingRegion { regionJumps[region, default: 0] += 1 }
            // Arriving at a place found from the map, its row flourishes, unless another has been
            // found since.
            if let place = request.landingPlace { land(on: place) }
          }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: regionJumps)
        // A softer touch as the list lands on a place, after the tick of finding it on the map.
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: placeArrivals)
        .scrollPosition($scrollPosition)
        // The pinned map shrinks as the list scrolls down and grows as it scrolls back up, from
        // wherever it is, moving with the list so the rows stay just beneath it. It can't shrink
        // further than the list has scrolled, which keeps it at full size at the top. The pinned
        // section header is pushed down to stay clear of it. Bounces past either end don't count.
        .onScrollGeometryChange(for: CGFloat.self) { scroll in
          let end = scroll.contentSize.height + scroll.contentInsets.top + scroll.contentInsets.bottom
            - scroll.containerSize.height
          return min(max(scroll.contentOffset.y + scroll.contentInsets.top, 0), max(end, 0))
        } action: { old, new in
          scrolledDistance = new
          // Gliding to a place found from the map, the map holds its size; it still can't be
          // smaller than the list has scrolled, so it's whole at the top.
          mapCollapse = isGlidingToRequest
            ? min(mapCollapse, collapse, new)
            : min(max(mapCollapse + new - old, 0), collapse, new)
          // Shrinking again pulls a zoomed-in map back out to the whole map.
          if new > old, mapCollapse > 4, !mapFocus.isEmpty {
            withAnimation(Motion.travelling(Motion.layout, reduceMotion: reduceMotion)) { mapFocus = [] }
          }
        }
        // Once the total has mostly slid under the pinned map, the map carries the count.
        .onScrollGeometryChange(for: Bool.self) { [totalHeight] scroll in
          query.isEmpty && scroll.contentOffset.y + scroll.contentInsets.top > totalHeight - 30
        } action: { _, away in
          isTotalScrolledAway = away
        }
        // Pulled well down past its top, the list gives the map a playful nudge.
        .onScrollGeometryChange(for: Bool.self) { scroll in
          scroll.contentOffset.y + scroll.contentInsets.top < -70
        } action: { wasPulled, isPulled in
          if isPulled, !wasPulled { mapNudges += 1 }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
          if let map = pinnedMap, query.isEmpty {
            // The inset keeps the compact height, so section headers pin just beneath the strip,
            // and the map draws taller over the room above the list while it's scrolled to the top.
            // The inset already sits inside the safe area, such as clear of iPhone Duo's side bar,
            // so the card needs no extra room at its sides: pinned, it matches the unpinned card.
            mapCard(
              map, statuses: statuses, snapshot: snapshot, horizontalSafeArea: EdgeInsets(),
              height: fullMapHeight - min(mapCollapse, collapse), journey: journey
            )
            .background(.pageBackground)
            .frame(height: compactMapHeight + 8, alignment: .top)
            .zIndex(1)
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
          }
        }
        // Over the pinned map too, so a picker that rises over it, where there's no room beneath it,
        // isn't covered by it.
        .overlayPreferenceValue(TapbackAnchorKey.self) { anchor in
          tapbackLayer(
            anchor: anchor, snapshot: snapshot, clearOf: mapBottom, sides: geometry.safeAreaInsets,
            rowTrailingInset: rowSafeArea.trailing)
        }
        // Starting a search, the map and the total step aside together as the matches close up
        // beneath them, and clearing it they come back, rather than vanishing in a single frame.
        .animation(Motion.moving(.smooth(duration: 0.35), reduceMotion: reduceMotion), value: query.isEmpty)
        .id(country.id)
        // Another list fades through rather than across, so the two never show at once: this one
        // slips away quickly, then the next comes gently into its place, the way it came. Further
        // in, it rises from below; back out, it settles from above; across to another level of
        // the same country, it only fades, the page holding still. While the map flies, the flight
        // is the motion, so the list only fades; with Reduce Motion too.
        .transition(.asymmetric(
          insertion: (reduceMotion || rise == 0 ? AnyTransition.opacity : .opacity.combined(with: .offset(y: rise)))
            .animation(Motion.pageIn),
          removal: .opacity.animation(Motion.pageOut)))
      }
    }
  }

  private func mapCard(
    _ map: TravelMap, statuses: [String: VisitLevel], snapshot: TravelSnapshot, horizontalSafeArea: EdgeInsets,
    height: CGFloat? = nil, maxHeight: CGFloat = MapCard.maximumHeight, journey: MapJourney?
  ) -> some View {
    MapCard(
      map: map,
      statuses: statuses,
      minimumStatus: counting.rules.minimumLevel(in: ladder),
      counted: snapshot.count(in: country.divisions, counting: counting.rules),
      horizontalSafeArea: horizontalSafeArea,
      isHidden: isMapCardHidden,
      selection: tapbackID ?? highlightedID,
      height: height,
      maxHeight: maxHeight,
      // Pinned and scrolled, the total is under the map, so its count rides on the map instead.
      badge: height != nil && isTotalScrolledAway
        ? TravelTotalView(
          tally: snapshot.tally(of: country.divisions), total: country.divisions.count, horizontalSafeArea: EdgeInsets(),
          minimumStatus: counting.rules.minimumLevel(in: ladder), isBadge: true)
        : nil,
      focus: height != nil ? mapFocus : [],
      journey: journey,
      onFrameChange: noteMapFrame,
      nudges: mapNudges,
      onSelect: { id in
        // Shrunk to a strip, the first tap grows the map back; once it's grown, taps find places.
        if height != nil, mapCollapse > 0.5 {
          expandMap()
        } else {
          findFromCard(id)
        }
      }
    ) {
      if height != nil, mapCollapse > 0.5 {
        expandMap()
      } else {
        openMap()
      }
    }
  }

  private func noteMapFrame(_ frame: CGRect) {
    cardFrame.rect = frame
    if keepsMapAtTop, mapCardFrame != frame { mapCardFrame = frame }
    mapLocation?.note(frame, in: country.id)
  }

  /// Grows the shrunken pinned map back to its full size, pushing the list down with it so the
  /// rows in view stay in view, and zooms it in on those places. Tapped again, it opens full screen.
  private func expandMap() {
    let places = Set(country.divisions.map(\.id))
    // Scrolling back by as much as the map has shrunk grows it in step, as scrolling up by hand does.
    // With Reduce Motion it's simply grown, zoomed in, with no glide.
    withAnimation(Motion.travelling(.smooth(duration: 0.5), reduceMotion: reduceMotion)) {
      scrollPosition.scrollTo(y: max(scrolledDistance - mapCollapse, 0))
      mapFocus = visibleRows.all.filter(places.contains)
    }
  }

  /// A place tapped on the map card, or on the map beside the list. The first tap finds it in the
  /// list; once it's found and in view, tapping it again opens the map on it, already picked.
  private func findFromCard(_ id: String) {
    if cardFoundID == id, visibleRows.contains(id) {
      openMap(selecting: id)
    } else {
      cardFoundID = id
      reveal(id)
    }
  }

  /// The tallest the list's map card grows for a list this tall: a fair share of the page, never
  /// less than a phone's card nor more than suits even a large iPad.
  static func cardMaxHeight(forHeight height: CGFloat) -> CGFloat {
    min(max(height * 0.42, 150), 520)
  }

  /// The columns a page this size sets its places in, or nil for one place to a row. Columns only
  /// come where there's real room for them: on a page tall enough not to be a phone, or iPhone
  /// Duo's outer display, on its side, where rows side by side crowd a short page, and wide enough
  /// for every column to be as roomy as a phone's own row. So iPad sets its places two or more
  /// abreast, each pill close to its name, while every phone, iPhone Duo's outer display, and any
  /// short or narrow window keeps to one place a row.
  static func rowColumns(for size: CGSize) -> [GridItem]? {
    guard size.height >= columnsMinimumHeight, size.width >= columnMinimumWidth * 2 else { return nil }
    return [GridItem(.adaptive(minimum: columnMinimumWidth, maximum: 520), spacing: 0)]
  }

  /// The narrowest a column of places may be: about a phone's own row, with room for a name beside
  /// its pill. iPad mini held upright, 744 points across, just fits two; the largest iPad fits two
  /// roomy ones rather than three cramped ones.
  static let columnMinimumWidth: CGFloat = 370

  /// The shortest page that sets its places in columns. A phone on its side, or iPhone Duo's outer
  /// display on its side, leaves the list well under it, about 340 to 450 points beneath the bars;
  /// iPad leaves 600 or more even in landscape, so the line falls clear of both.
  static let columnsMinimumHeight: CGFloat = 500

  /// The narrowest page that sets its map beside its list. Narrower, the two would squeeze each
  /// other: iPhone Duo's outer display on its side is under 680 points across before its bar of
  /// controls, which would leave a sliver of map and rows narrower than any phone's, so there the
  /// map heads the list and the rows take the page's whole width, as on iPhone SE on its side.
  /// Every other phone on its side is wider, from about 710 points between its sides' insets.
  static let sideBySideMinimumWidth: CGFloat = 700

  /// The map beside the list on a page much wider than tall, as a partly folded iPhone Duo holds
  /// it: the map on the leading side, the list beside it with between 380 and 520 points of its
  /// own, as roomy as a phone held upright. Nil where the page isn't wide enough for both, at
  /// least `sideBySideMinimumWidth`, so the map heads the list instead.
  static func sideBySide(in size: CGSize) -> FoldRegions? {
    guard size.height > 1, size.width >= sideBySideMinimumWidth, size.width > size.height * 1.35 else { return nil }
    let listWidth = min(max(size.width * 0.55, 380), 520)
    let mapWidth = size.width - listWidth
    guard mapWidth >= 300 else { return nil }
    return FoldRegions(
      far: CGRect(x: 0, y: 0, width: mapWidth, height: size.height),
      near: CGRect(x: mapWidth, y: 0, width: listWidth, height: size.height),
      isAcross: false)
  }

  // MARK: Quick level picker

  private func openTapback(for division: AdministrativeDivision) {
    withAnimation(LevelTapback.opening) { tapbackID = division.id }
  }

  private func closeTapback() {
    withAnimation(LevelTapback.closing) { tapbackID = nil }
  }

  /// The chosen place's quick level picker floats just above it, or below when there's more room
  /// there, and always wholly in view, pointing at the row's pill as the map's points at its place.
  /// Nothing dims: the picker glows instead, and a tap or a drag
  /// anywhere else puts it away. `mapBottom` is where the pinned map ends, in global coordinates,
  /// since the map draws over the top of the list and would hide the picker's head. `sides` is the
  /// room kept at the list's sides, such as for iPhone Duo's vertical bar or its outer camera,
  /// which the list's rows run under but the picker stays clear of. `rowTrailingInset` is the room
  /// the row itself keeps at its trailing end, short of which its pill sits: the page's side for a
  /// full-width row, none for a row in columns.
  @ViewBuilder
  private func tapbackLayer(
    anchor: Anchor<CGRect>?, snapshot: TravelSnapshot, clearOf mapBottom: CGFloat, sides: EdgeInsets,
    rowTrailingInset: CGFloat
  ) -> some View {
    GeometryReader { proxy in
      if let anchor, let id = tapbackID, let division = country.divisions.first(where: { $0.id == id }) {
        let row = proxy[anchor]
        let size = tapbackSize == .zero ? CGSize(width: 300, height: 80) : tapbackSize
        // The list's own side, short of its bars and the pinned map, so on a partly folded iPhone Duo
        // it stays on the near side of the fold, and on every device it is never covered or cut off.
        // This view already stops short of the navigation bar above and of the bottom bar below, with
        // its search field and Undo, so only the pinned map, which draws over the head of the list,
        // is kept clear of here; the bars' insets counted again would squeeze the room to nothing,
        // or push the picker out from under the map beneath the search field.
        // Where it can't fit whole above or below the row clear of the pinned map, as with France's
        // regions beneath a pinned map on iPhone, it rises over the map instead, the map being only
        // the head of the page, rather than scrolling its rows.
        let bottom = proxy.size.height
        let clearOfMap = max(mapBottom - proxy.frame(in: .global).minY, 0)
        let fitsClearOfMap = size.height <= row.minY + 6 - (clearOfMap + 8)
          || size.height <= bottom - 8 - (row.maxY - 6)
        let top = fitsClearOfMap ? clearOfMap : 0
        let leading = max(sides.leading, proxy.safeAreaInsets.leading)
        let trailing = max(sides.trailing, proxy.safeAreaInsets.trailing)
        let room = CGRect(
          x: leading, y: top, width: max(proxy.size.width - leading - trailing, 0), height: max(bottom - top, 16)
        )
        .insetBy(dx: 8, dy: 8)
        // Above the row where it fits, otherwise below. Too tall for either, it takes the roomier
        // side and scrolls what's beneath its badges rather than running off the screen; with no
        // room worth the name on either side, as on a short screen, it rests over the row.
        let spaceAbove = row.minY + 6 - room.minY
        let spaceBelow = room.maxY - (row.maxY - 6)
        let isAbove = size.height <= spaceAbove || (size.height > spaceBelow && spaceAbove >= spaceBelow)
        let space = isAbove ? spaceAbove : spaceBelow
        let maxHeight = space >= LevelTapback.minimumHeight ? space : max(room.height, LevelTapback.minimumHeight)
        let shown = min(size.height, maxHeight)
        let preferred = isAbove ? row.minY + 6 - shown / 2 : row.maxY - 6 + shown / 2
        let y = min(max(preferred, room.minY + shown / 2), max(room.maxY - shown / 2, room.minY + shown / 2))
        // Beside the row's trailing end, but never past the side bar or the camera.
        let x = min(max(min(row.maxX, room.maxX + 8) - size.width / 2 - 12, room.minX + size.width / 2), room.maxX - size.width / 2)
        // Aimed at the pill at the row's trailing end; the shape keeps the point clear of its corners.
        let pointer = CalloutPointer(
          x: row.maxX - rowTrailingInset - 54 - (x - size.width / 2), pointsDown: isAbove)
        ZStack(alignment: .topLeading) {
          Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: closeTapback)
            .gesture(DragGesture(minimumDistance: 6).onChanged { _ in closeTapback() })
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Close")
          let collection = CountryCatalog.collection(for: division)
          let smaller = smallerPlaces(of: division)
          LevelTapback(
            status: snapshot.status(for: division),
            place: division,
            localLanguage: localLanguage,
            // Every level its places are listed at, such as France's regions and its departments,
            // or a region's own places at its country's other levels, such as Île-de-France's departments.
            collections: (collection.map(CountryCatalog.levels(of:)) ?? smaller.map(\.places)).map {
              CollectionSummary(collection: $0, snapshot: snapshot, rules: counting.rules)
            },
            pointer: pointer,
            maxHeight: maxHeight,
            // The row's pill is beneath the picker, so a level chosen here rises from the picker.
            floatsChosenBadge: true,
            onSelect: { choose($0, for: division) },
            onOpenCollection: { id in
              closeTapback()
              if collection == nil, let section = smaller.first(where: { $0.places.id == id })?.sectionID {
                onShowInLevel(id, section, division.id)
              } else {
                onOpenLevel(id)
              }
            }
          )
          // Measured as the picker itself comes out, not the frame holding it, which takes all the
          // room it's given, so the pointer and the picker's place are worked out from its own width.
          .onGeometryChange(for: CGSize.self) { $0.size } action: { tapbackSize = $0 }
          .frame(maxWidth: room.width)
          .position(x: x, y: y)
          // Grows out of its point, as the map's does.
          .transition(
            LevelTapback.transition(
              from: UnitPoint(x: pointer.x / max(size.width, 1), y: pointer.pointsDown ? 1 : 0),
              reduceMotion: reduceMotion))
          // Escape on a keyboard puts the picker away, as VoiceOver's escape does.
          Button("Close", action: closeTapback)
            .keyboardShortcut(.cancelAction)
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        }
        // While it's out, VoiceOver stays in the picker rather than wandering into the list beneath.
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, closeTapback)
      }
    }
    .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: tapbackID) { _, new in new != nil }
  }

  /// Sets the level, lets the ring settle on it for a moment, then puts the picker away.
  private func choose(_ level: VisitLevel, for division: AdministrativeDivision) {
    onStatusChange(level, division, country)
    Task {
      try? await Task.sleep(for: LevelTapback.settleDelay)
      if tapbackID == division.id { closeTapback() }
    }
  }

  private static func regionAnchor(_ id: String) -> String { "region-\(id)" }

  /// A place's own places at its country's other levels, such as Île-de-France's departments, each
  /// as a list of just those places, under that level's ID, with the section holding them there.
  private func smallerPlaces(of place: AdministrativeDivision) -> [(places: Country, sectionID: String)] {
    CountryCatalog.levels(of: country).filter { $0.id != country.id }.compactMap { level in
      guard let section = level.groups.first(where: { $0.divisions.contains { $0.parentID == place.id } }) else {
        return nil
      }
      var places = level
      places.groups = [section]
      places.groups[0].divisions = section.divisions.filter { $0.parentID == place.id }
      return (places, section.id)
    }
  }

  private func regionSummary(of group: DivisionGroup, snapshot: TravelSnapshot) -> RegionSummary {
    let name = group.displayName(localLanguage: localLanguage)
    return RegionSummary(
      id: group.id,
      name: name,
      language: localLanguage && group.localName == name ? PlaceTypesetting.language(forCode: country.id) : nil,
      counted: snapshot.count(in: group.divisions, counting: counting.rules),
      total: group.divisions.count,
      tally: snapshot.tally(of: group.divisions),
      strongest: snapshot.strongestStatus(in: group.divisions)
    )
  }

  /// Glides the list to a region chosen from a header, then makes its header pulse as it lands.
  /// The list keeps room for the region's pinned header above its first place by itself.
  private func jump(to id: String) {
    scrollRequest = ScrollRequest(id: Self.regionAnchor(id), anchor: .top, landingRegion: id)
  }

  /// How long the list takes to glide to a place or a region.
  private static let glideDuration = 0.6

  /// How long a place found stays lit once the list has landed on it: long enough to be found at a
  /// glance, after the eye has come down from the map, before it settles back.
  private static let foundHold = Duration.seconds(2.8)

  /// How long a list coming back into place takes to rise in, before the place it brings back
  /// into view flourishes.
  private static let listFadeIn = Duration.seconds(0.45)

  /// Scrolls the list to a place tapped on the map, or found from the sidebar. The place lights up
  /// at once, so the eye can follow it as the list glides, flourishes as the list lands on it, and
  /// stays lit long enough to be found before settling calmly back.
  private func reveal(_ id: String) {
    if !searchText.isEmpty { searchText = "" }
    light(id, for: .seconds(Self.glideDuration) + Self.foundHold)
    scrollRequest = ScrollRequest(id: id, landingPlace: id)
  }

  /// Lights a place in the list, then lets it settle back after `duration`, slowly, unless another
  /// place, or this one again, has been lit since. It settles back even if the list never quite
  /// lands on it, as when a newer glide takes over.
  private func light(_ id: String, for duration: Duration) {
    lightings += 1
    let lighting = lightings
    withAnimation(.smooth(duration: 0.3)) { highlightedID = id }
    Task { @MainActor in
      try? await Task.sleep(for: duration)
      guard lightings == lighting else { return }
      withAnimation(Motion.afterglow) { highlightedID = nil }
    }
  }

  /// The list has landed on a place it was taken to: if the place is still the one lit, its row
  /// flourishes and the hand feels it land.
  private func land(on id: String) {
    guard highlightedID == id else { return }
    placeArrivals[id, default: 0] += 1
  }

  /// The full-screen map runs its own animation, growing out of the card when the card is in view.
  /// Opened by tapping a place found in the list again, it opens with that place picked; from the
  /// Map button's menu, on the layer chosen. Otherwise it opens on the person's travels.
  private func openMap(selecting placeID: String? = nil, on layer: MapLayer? = nil) {
    mapSelection = placeID
    mapLayer = layer
    // The full-screen map opens on the whole map, so the card pulls back out to match it.
    mapFocus = []
    if isMapPinned {
      mapGrowsFromCard = cardFrame.rect != nil
    } else if let mapCardFrame = cardFrame.rect, !listFrame.isEmpty {
      mapGrowsFromCard = mapCardFrame.intersection(listFrame).height >= mapCardFrame.height * 0.6
    } else {
      mapGrowsFromCard = false
    }
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) { showingMap = true }
  }

  private func closeMap() {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      isMapCardHidden = false
      showingMap = false
    }
    learnStart = nil
    mapSelection = nil
    mapLayer = nil
    cardFoundID = nil
  }
}

/// A section's rows, one to a line, or on a wide page in columns, so on iPad a place's pill sits
/// beside its name rather than across the page. In columns, the page's sides are kept clear around
/// the whole grid, since only the outer columns meet them. Each row keeps its own ID and anchor
/// either way, so jumps, finding a place and the quick level picker all land on the right one.
private struct RowColumns<Content: View>: View {
  var columns: [GridItem]?
  var horizontalSafeArea: EdgeInsets
  @ViewBuilder var content: Content

  var body: some View {
    if let columns {
      LazyVGrid(columns: columns, spacing: 0) {
        content
      }
      .padding(.leading, horizontalSafeArea.leading)
      .padding(.trailing, horizontalSafeArea.trailing)
    } else {
      content
    }
  }
}

/// A region's name, its count, and a bar stacked from its places' levels, strongest first.
/// Tap the name to jump to any region; the header pulses as the list arrives at it.
private struct DivisionListHeader: View {
  var horizontalSafeArea: EdgeInsets
  var region: RegionSummary
  var regions: [RegionSummary]
  var minimumStatus: VisitLevel
  var size = RowSize.standard
  /// Changes each time the list jumps to this region.
  var jumps: Int
  var onJump: (String) -> Void
  @Environment(\.visitLadder) private var ladder
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.regionCelebration) private var celebration
  @Environment(\.breaksOutOntoScreen) private var breaksOutOntoScreen
  /// Where the count is on screen, for a finished region's confetti to burst from.
  @State private var countFrame = ScreenFrame()
  @State private var showingRegions = false
  /// Counts the times the person has finished this region, each lighting the header in its colour.
  @State private var celebrations = 0

  private var color: Color { region.strongest.color }

  private var titleStyle: TypeStyle {
    switch size {
    case .standard: .sectionTitle
    case .compact: .compactSectionTitle
    case .extraCompact: .extraCompactSectionTitle
    }
  }

  private var verticalPadding: CGFloat {
    switch size {
    case .standard: 16
    case .compact: 9
    case .extraCompact: 6
    }
  }

  var body: some View {
    HStack {
      Button {
        showingRegions = true
      } label: {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          // A long region, such as Yorkshire and the Humber, keeps to one line and glides.
          ScrollingText {
            Text(region.name)
              .typeStyle(titleStyle, language: region.language)
          }
          Image(systemName: "chevron.down")
            .font(.footnote.weight(.bold))
            .foregroundStyle(.tertiary)
            .rotationEffect(.degrees(showingRegions ? 180 : 0))
            // Turns over as the regions open and back as they close; with Reduce Motion, flips.
            .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: showingRegions)
        }
        .pop(on: jumps)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(.isHeader)
      .accessibilityHint("Shows every region to jump to.")
      .popover(isPresented: $showingRegions, arrowEdge: .top) {
        RegionJumpView(regions: regions, currentID: region.id, minimumStatus: minimumStatus) { id in
          showingRegions = false
          onJump(id)
        }
        .presentationCompactAdaptation(.popover)
      }
      Spacer()
      // The smallest headers set the bar beside the count rather than beneath it.
      let tally = size == .extraCompact
        ? AnyLayout(HStackLayout(spacing: 8))
        : AnyLayout(VStackLayout(alignment: .trailing, spacing: size.isCompact ? 3 : 4))
      tally {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
          // Pops as a place in the region comes to count, so a tap in a row reaches its total.
          Text(region.counted, format: .number)
            .typeStyle(.count)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(region.counted)))
            .pop(onRiseOf: region.counted)
          Text("/ \(region.total.formatted())")
            .typeStyle(.countTotal)
            .foregroundStyle(.secondary)
        }
        StatusTallyBar(tally: region.tally, total: region.total, minimumStatus: minimumStatus)
          .frame(width: 60, height: 6)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(region.counted) of \(region.total) places counted")
      .accessibilityValue(StatusTallyBar.breakdown(of: region.tally, in: ladder))
      .trackingScreenFrame(countFrame)
    }
    // Only the words and count ride the wave; the header's background holds still.
    .feelsRipples()
    .padding(.horizontal)
    .padding(.vertical, verticalPadding)
    .padding(.leading, horizontalSafeArea.leading)
    .padding(.trailing, horizontalSafeArea.trailing)
    .background {
      Rectangle()
        .fill(.thickMaterial)
        .overlay {
          // Arriving from a jump, or finished, the header glows in its region's colour and fades
          // back, with Reduce Motion too, where it's the whole of a finished region's celebration.
          color.keyframeAnimator(initialValue: 0.0, trigger: [jumps, celebrations]) { glow, opacity in
            glow.opacity(opacity)
          } keyframes: { _ in
            CubicKeyframe(reduceMotion ? 0.18 : 0.32, duration: 0.18)
            CubicKeyframe(0, duration: 0.9)
          }
        }
    }
    .animation(Motion.count, value: region.counted)
    .animation(Motion.recolour, value: color)
    // Confetti only for a region the person has just finished, never for a count that went up
    // some other way. Finishing it with a tap lights the header and throws confetti from its
    // count, out across the list; with Reduce Motion, the light alone.
    .onChange(of: celebration) { _, celebration in
      guard celebration?.regionID == region.id else { return }
      celebrations += 1
      guard breaksOutOntoScreen, !reduceMotion, let origin = countFrame.center else { return }
      ToastCenter.shared.burst(from: origin, colors: ladder.levels.map(\.color))
    }
  }
}

struct DivisionListRow: View {
  var division: AdministrativeDivision
  var horizontalSafeArea: EdgeInsets
  var localLanguage: Bool
  /// Compact rows are shorter, with the other-language name beside the name, so more places fit
  /// at once; extra compact ones are shorter still, in smaller type with a smaller pill.
  var size = RowSize.standard
  /// The place's region or continent, set small above its name when the list runs A to Z, or in
  /// extra compact rows, at the end of the line.
  var regionName: String? = nil
  /// Lit while the place's quick level picker is open.
  var isHighlighted = false
  /// Lit, unmistakably, while the place is one just found from the map or brought back into view:
  /// its level's colour lies across the whole row, with a bar of it shining at the leading edge.
  var isFound = false
  /// Counts each time the list lands on the place, found: the bar flares, a gleam runs along the
  /// row to its pill, and the name and pill lift a little and settle.
  var arrivals = 0
  var status: VisitLevel
  var collection: Country?
  /// What a tap on the name does, for VoiceOver.
  var selectHint = "Shows its levels."
  /// Whether a tap on the pill at the highest level does what a tap on the name does: show every
  /// level. Holding the row does the same; without it, a hold shows a menu of every level instead.
  var opensLevelsAtTop = true
  /// Whether the row's quick level picker is open.
  var isShowingLevels = false
  var onSelect: () -> Void
  var onStatusChange: (VisitLevel) -> Void
  var onOpenCollection: (String) -> Void
  @Environment(\.visitLadder) private var ladder
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.colorSchemeContrast) private var contrast
  @ScaledMetric(relativeTo: .title) private var titleSize = 32
  @ScaledMetric(relativeTo: .title2) private var compactTitleSize = 22
  @ScaledMetric(relativeTo: .body) private var extraCompactTitleSize = 17

  /// How long a touch is held before it brings up every level, a little quicker than a menu.
  static let holdDuration = 0.4

  private var isCompact: Bool { size.isCompact }

  /// Whether everything sits on one line, the region too, as in extra compact rows at most text sizes.
  private var isOneLine: Bool { size == .extraCompact && !dynamicTypeSize.isAccessibilitySize }

  private var nameStyle: TypeStyle {
    switch size {
    case .standard: .placeName
    case .compact: .compactPlaceName
    case .extraCompact: .extraCompactPlaceName
    }
  }

  private var subtitleStyle: TypeStyle {
    switch size {
    case .standard: .placeSubtitle
    case .compact: .compactPlaceSubtitle
    case .extraCompact: .extraCompactPlaceSubtitle
    }
  }

  private var badgeSize: CGFloat {
    switch size {
    case .standard: titleSize
    case .compact: compactTitleSize
    case .extraCompact: extraCompactTitleSize
    }
  }

  private var verticalPadding: CGFloat {
    switch size {
    case .standard: 16
    case .compact: 2
    case .extraCompact: 0
    }
  }

  private var statusBinding: Binding<VisitLevel> {
    Binding(get: { status }, set: onStatusChange)
  }

  var body: some View {
    let isStill = reduceMotion
    let layout =
      dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
      : AnyLayout(HStackLayout(spacing: 12))
    layout {
        Button(action: onSelect) {
          let names = isCompact && !dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: -2))
          VStack(alignment: .leading, spacing: isCompact ? 0 : 2) {
          if let regionName, !isOneLine {
            regionLabel(regionName)
          }
          names {
            let name = division.displayName(localLanguage: localLanguage)
            HStack(alignment: .firstTextBaseline, spacing: isCompact ? 6 : 10) {
              // A long name, such as Saint Helena, Ascension and Tristan da Cunha's, keeps to one
              // line, gliding across now and then to show its end, or when held, or with Reduce
              // Motion dissolving there, never wrapping onto several or cut short.
              ScrollingText {
                Text(name)
                  .typeStyle(nameStyle, language: division.language(of: name))
              }
              .foregroundStyle(
                status == .never ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary)
              )
              .layoutPriority(1)
              if let shortName = division.shortName {
                // China's one-character short name, as on its licence plates.
                LicencePlateBadge(
                  shortName: shortName, size: badgeSize * 0.85,
                  isDimmed: status == .never)
              }
            }
            if let subtitle = division.subtitle(localLanguage: localLanguage) {
              // Long formal names, such as Hong Kong's, stay on one line, gliding across now and
              // then to show their end rather than wrapping.
              ScrollingText {
                Text(subtitle)
                  .typeStyle(subtitleStyle, language: division.language(of: subtitle))
              }
              .foregroundStyle(
                status == .never ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.secondary)
              )
            }
            if let regionName, isOneLine {
              regionLabel(regionName)
            }
          }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Touching and holding brings up the same picker as a tap, rather than a menu of its own.
        .simultaneousGesture(
          LongPressGesture(minimumDuration: Self.holdDuration).onEnded { _ in onSelect() }, isEnabled: opensLevelsAtTop)
        .accessibilityLabel(regionName.map { "\(division.name), \($0)" } ?? division.name)
        .accessibilityHint(selectHint)
        VisitPillView(
          status: statusBinding, placeName: division.name, isSmall: size == .extraCompact,
          // At the top, a tap shows every level, as a tap on the name does, and so does a hold;
          // rows that leave the list don't.
          onTopTap: opensLevelsAtTop ? onSelect : nil,
          onHold: opensLevelsAtTop ? onSelect : nil,
          isShowingLevels: isShowingLevels)
          .fixedSize(horizontal: true, vertical: false)
      }
      // The name and pill ride a ripple from the map as it passes; the row's colour holds still.
      .feelsRipples()
      // As the list lands on the place, found, they lift a little to meet the eye, then settle.
      .keyframeAnimator(initialValue: 0.0, trigger: arrivals) { content, lift in
        content.offset(y: -lift)
      } keyframes: { _ in
        CubicKeyframe(isStill ? 0 : 3, duration: 0.16)
        SpringKeyframe(0, duration: 0.7, spring: .bouncy(extraBounce: 0.3))
      }
      .padding(.horizontal)
      .padding(.vertical, verticalPadding)
      .padding(.leading, horizontalSafeArea.leading)
      .padding(.trailing, horizontalSafeArea.trailing)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        // The flag fills 300 points of width, so it is far taller than the row. Keep it inside
        // the row's bounds and out of hit testing, or it covers the row above and swallows taps.
        ZStack {
          // Found, the row's colour lies evenly across it, under its name as well as its pill.
          status.color.opacity(isFound ? foundWash : 0)
          status.color.opacity(isHighlighted || isFound ? 0.45 : 0.2)
            .mask(
              LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing))
          Color.clear
            .overlay(alignment: .leading) {
              Image(division.flagAssetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 300 + horizontalSafeArea.leading)
                .grayscale(status == .never ? 1 : 0)
                .mask(
                  LinearGradient(
                    colors: [.black.opacity(flagWash.opacity), .clear], startPoint: .leading,
                    endPoint: .trailing))
                .blendMode(flagWash.blendMode)
            }
            .clipped()
          if !reduceMotion {
            StatusRipple(status: status)
              .frame(maxWidth: .infinity, alignment: .trailing)
              .padding(.trailing, horizontalSafeArea.trailing + 36)
          }
          if isFound {
            FoundLight(
              color: status.color, arrivals: arrivals, leadingInset: horizontalSafeArea.leading,
              barInset: size == .standard ? 10 : 5)
              .transition(.opacity)
          }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
      }
      .clipped()
      .animation(Motion.recolour, value: status)
      .modifier(
        LevelMenu(
          isEnabled: !opensLevelsAtTop, division: division, status: statusBinding, collection: collection,
          localLanguage: localLanguage, onOpenCollection: onOpenCollection))
      .scrollTransition { content, phase in
        // Rows slip quietly under the header and settle gently as they arrive from below.
        content
          .opacity(phase.isIdentity ? 1 : phase.value < 0 ? 0.35 : 0.55)
          .scaleEffect(phase.value > 0 && !isStill ? 0.97 : 1, anchor: .top)
      }
  }

  /// The place's region or continent, as the list runs A to Z.
  private func regionLabel(_ regionName: String) -> some View {
    ScrollingText {
      Text(regionName)
        .typeStyle(.smallEyebrow)
        .foregroundStyle(status == .never ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.secondary))
    }
  }

  /// The flag behind the name. In light mode it multiplies, so its white falls away and its
  /// colours tint the row like ink; in dark mode it screens, so its colours glow instead of
  /// muddying. Increase Contrast keeps it faint behind the text.
  private var flagWash: (opacity: Double, blendMode: BlendMode) {
    let faint = contrast == .increased
    return colorScheme == .dark
      ? (faint ? 0.16 : 0.4, .screen)
      : (faint ? 0.16 : 0.34, .multiply)
  }

  /// How strongly a found row's colour lies evenly across it: a little more on a dark page, where
  /// a faint colour sinks into the dark, and more again with Increase Contrast.
  private var foundWash: Double {
    (colorScheme == .dark ? 0.24 : 0.18) + (contrast == .increased ? 0.08 : 0)
  }
}

/// Heads the places found in other lists while searching, in the same style as a region's header.
private struct ElsewhereHeader: View {
  var count: Int
  var horizontalSafeArea: EdgeInsets
  var size = RowSize.standard

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text("Elsewhere")
        .typeStyle(size == .standard ? .sectionTitle : size == .compact ? .compactSectionTitle : .extraCompactSectionTitle)
        .accessibilityAddTraits(.isHeader)
      Spacer()
      Text(count, format: .number)
        .typeStyle(.count)
        .foregroundStyle(.secondary)
        .contentTransition(.numericText(value: Double(count)))
        .accessibilityLabel("^[\(count) place](inflect: true)")
    }
    .padding(.horizontal)
    .padding(.vertical, size == .standard ? 16 : size == .compact ? 9 : 6)
    .padding(.leading, horizontalSafeArea.leading)
    .padding(.trailing, horizontalSafeArea.trailing)
    .background(.thickMaterial)
  }
}

/// A wash of colour that spreads across the row from the pill when the status changes: right
/// across the row for a rise, and only a little way, more faintly, for a fall, which is no less a
/// change but nothing to celebrate.
private struct StatusRipple: View {
  var status: VisitLevel
  @Environment(\.visitLadder) private var ladder
  /// Counts each change of level, and whether the latest was a fall.
  @State private var wave = Wave()

  var body: some View {
    let isFall = wave.isFall
    Circle()
      .fill(
        RadialGradient(
          colors: [status.color.opacity(0.5), status.color.opacity(0)], center: .center,
          startRadius: 0, endRadius: 20)
      )
      .frame(width: 40, height: 40)
      .keyframeAnimator(initialValue: RippleFrame(), trigger: wave) { content, frame in
        content
          .scaleEffect(frame.scale)
          .opacity(frame.opacity)
      } keyframes: { _ in
        KeyframeTrack(\.scale) {
          MoveKeyframe(0.3)
          CubicKeyframe(isFall ? 6 : 18, duration: isFall ? 0.5 : 0.75)
        }
        KeyframeTrack(\.opacity) {
          MoveKeyframe(isFall ? 0.6 : 1)
          CubicKeyframe(0, duration: isFall ? 0.5 : 0.75)
        }
      }
      .onChange(of: status) { old, new in
        guard old.id != new.id else { return }
        wave = Wave(count: wave.count + 1, isFall: ladder.rank(of: new) < ladder.rank(of: old))
      }
      .allowsHitTesting(false)
  }

  private struct Wave: Equatable {
    var count = 0
    var isFall = false
  }
}

private struct RippleFrame {
  var scale = 0.3
  var opacity = 0.0
}

/// What sets a row found from the map apart from its neighbours, over its colour and flag: a bar of
/// its level's colour shining at the row's leading edge for as long as it's found. Each time the
/// list lands on the place, the bar flares and a gleam of light runs along the row to its pill.
/// Where the display has HDR headroom, the bar's halo and the gleam shine brighter than the page
/// around them; elsewhere they keep to the colour itself, which reads as plainly on a light page as
/// on a dark one. With Reduce Motion there's no gleam and no flare: the bar simply shines, steady,
/// until the row settles back.
private struct FoundLight: View {
  var color: Color
  /// Counts each time the list lands on the place.
  var arrivals: Int
  /// Room at the row's leading side, such as beneath iPhone Duo's side bar, which the bar keeps
  /// clear of.
  var leadingInset: CGFloat
  /// How far the bar keeps from the row's top and bottom.
  var barInset: CGFloat
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    // With Reduce Motion, a landing plays at nothing, so the bar holds steady.
    let strength = reduceMotion ? 0.0 : 1.0
    // The animator view rather than the modifier, so the frames are drawn on the main actor, where
    // the gleam and the bar are built.
    KeyframeAnimator(initialValue: Landing(), trigger: arrivals) { landing in
      ZStack(alignment: .leading) {
        if landing.gleam > 0 {
          gleam(at: landing.sweep, strength: landing.gleam)
        }
        bar(flare: landing.flare)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    } keyframes: { _ in
      KeyframeTrack(\.flare) {
        CubicKeyframe(strength, duration: 0.16)
        CubicKeyframe(0, duration: 1.1)
      }
      KeyframeTrack(\.sweep) {
        MoveKeyframe(0)
        CubicKeyframe(1, duration: 0.9)
      }
      KeyframeTrack(\.gleam) {
        LinearKeyframe(strength, duration: 0.12)
        LinearKeyframe(strength, duration: 0.56)
        CubicKeyframe(0, duration: 0.22)
      }
    }
    // HDR colours shine past the page's white only where the views drawing them allow it.
    .allowedDynamicRange(.high)
  }

  /// The bar, over a halo of its colour that flares as the list lands. On a light page the bar
  /// keeps to the colour itself, so it stands out from the page; on a dark one it shines a little
  /// brighter, as the halo does on either.
  private func bar(flare: Double) -> some View {
    let lift = colorScheme == .dark ? 0.5 : 0
    return Capsule()
      .fill(color.glowing(by: lift + flare))
      .frame(width: 4 + 1.5 * flare)
      .background {
        Capsule()
          .fill(color.glowing(by: 1 + flare))
          .blur(radius: 4 + 5 * flare)
          .opacity(0.6 + 0.4 * flare)
      }
      .padding(.vertical, barInset)
      .padding(.leading, leadingInset + 6)
  }

  /// A soft band of light in the level's colour, `sweep` of the way along the row, from just
  /// before its leading edge to just past its trailing one.
  private func gleam(at sweep: CGFloat, strength: Double) -> some View {
    GeometryReader { proxy in
      let band = min(max(proxy.size.width * 0.4, 140), 300)
      let light = color.glowing(by: 1.5)
      LinearGradient(
        colors: [light.opacity(0), light.opacity(0.6), light.opacity(0)],
        startPoint: .leading, endPoint: .trailing
      )
      .frame(width: band)
      .offset(x: (proxy.size.width + band) * sweep - band)
      .opacity(strength)
    }
  }

  private struct Landing {
    /// How far the bar has flared, from nothing at rest to 1 at its brightest.
    var flare = 0.0
    /// How far along the row the gleam has run.
    var sweep: CGFloat = 0
    /// How strongly the gleam shows.
    var gleam = 0.0
  }
}

/// A menu of every level on a touch and hold, for a place found from another list, whose own quick
/// picker lives in that list. Everywhere else a hold brings up the same picker as a tap.
private struct LevelMenu: ViewModifier {
  var isEnabled: Bool
  var division: AdministrativeDivision
  @Binding var status: VisitLevel
  var collection: Country?
  var localLanguage: Bool
  var onOpenCollection: (String) -> Void
  @Environment(\.visitLadder) private var ladder

  func body(content: Content) -> some View {
    if isEnabled {
      content
        .contentShape(.contextMenuPreview, Rectangle())
        .contextMenu {
          Picker("Visit status", selection: $status) {
            ForEach(ladder.allLevels) { item in
              Label(item.name, systemImage: item.symbolName).tag(item)
            }
          }
          .pickerStyle(.inline)
          if let collection {
            Button(collection.divisionLabel, systemImage: "list.bullet") {
              onOpenCollection(collection.id)
            }
          }
        } preview: {
          FlagPreview(division: division, status: status, localLanguage: localLanguage)
        }
    } else {
      content
    }
  }
}

/// The card that lifts out of a row found from another list when you touch and hold it.
private struct FlagPreview: View {
  var division: AdministrativeDivision
  var status: VisitLevel
  var localLanguage: Bool

  var body: some View {
    VStack(spacing: 14) {
      Image(division.flagAssetName)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: 260, maxHeight: 170)
        .clipShape(.rect(cornerRadius: 6))
        .grayscale(status == .never ? 1 : 0)
      // Each on one line, gliding where it's long, never wrapping.
      VStack(spacing: 0) {
        let name = division.displayName(localLanguage: localLanguage)
        ScrollingText {
          Text(name)
            .typeStyle(.placeName, language: division.language(of: name))
        }
        if let subtitle = division.subtitle(localLanguage: localLanguage) {
          ScrollingText {
            Text(subtitle)
              .typeStyle(.placeSubtitle, language: division.language(of: subtitle))
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: 300)
      VisitPillLabel(status: status)
    }
    .padding(24)
  }
}

/// Once a section header pins, fills the strip the rows scroll under above it, such as the
/// camera area on iPhone Duo, so rows never show cut off against the top edge of the screen.
/// The strip is the list's own top inset, so the cap matches it on every device and pose.
private struct PinnedHeaderCap: ViewModifier {
  /// How far the list scrolls before the first header pins.
  var threshold: Double
  @State private var cap = Cap()

  func body(content: Content) -> some View {
    let threshold = threshold
    content
      .onScrollGeometryChange(for: Cap.self) { geometry in
        Cap(
          height: max(geometry.contentInsets.top, 0),
          isShown: geometry.contentOffset.y + geometry.contentInsets.top > threshold + 0.5)
      } action: { _, new in
        cap = new
      }
      .overlay(alignment: .top) {
        VStack(spacing: 0) {
          Rectangle()
            .fill(.thickMaterial)
            .frame(height: cap.height)
          Spacer(minLength: 0)
        }
        .ignoresSafeArea(.container, edges: .top)
        .opacity(cap.isShown ? 1 : 0)
        .animation(.easeOut(duration: 0.15), value: cap.isShown)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
      }
  }

  private struct Cap: Equatable {
    var height = 0.0
    var isShown = false
  }
}

/// Pinching the list to change its rows' size. While the fingers pinch, the list in view follows
/// them a little, from the top of the page, shrinking as they close and growing as they open, so
/// the pinch is felt to take hold; once they lift, the rows change size and the list settles back
/// as they do. Only the way the rows can still go follows: at the smallest size, pinching in
/// holds still. With Reduce Motion the list holds still and simply changes size.
///
/// A modifier of its own, so only it is redrawn at every step of the pinch, not the whole list.
private struct PinchToResize: ViewModifier {
  var canShrink: Bool
  var canGrow: Bool
  /// Called as the fingers lift, with whether they pinched in.
  var onPinch: (_ isIn: Bool) -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @GestureState(resetTransaction: Transaction(animation: Motion.layout)) private var pinch: CGFloat = 1

  func body(content: Content) -> some View {
    let follow = min(max(pinch, canShrink ? 0.95 : 1), canGrow ? 1.05 : 1)
    content
      .scaleEffect(reduceMotion ? 1 : follow, anchor: .top)
      .simultaneousGesture(
        MagnifyGesture(minimumScaleDelta: 0.06)
          .updating($pinch) { value, pinch, _ in pinch = value.magnification }
          .onEnded { value in
            guard value.magnification != 1 else { return }
            onPinch(value.magnification < 1)
          }
      )
  }
}

/// What the places found elsewhere depend on: the search, and the list searched from.
private struct SearchKey: Equatable {
  var query: String
  var listID: String
}

private struct DivisionSearchSection: Identifiable {
  var group: DivisionGroup
  var divisions: [AdministrativeDivision]
  var id: String { group.id }
}

/// Where the list's map is on screen, kept aside from the view's state, since it moves on every
/// scroll and is only read when the map opens full screen.
private final class CardFrame {
  var rect: CGRect?
}

/// The map's flight from the list before, kept for the arrival it was built for.
private final class JourneyCache {
  private var arrivalID: UUID?
  private var journey: MapJourney?

  func journey(for arrival: CollectionArrival, build: () -> MapJourney?) -> MapJourney? {
    if arrivalID == arrival.id { return journey }
    arrivalID = arrival.id
    journey = build()
    return journey
  }
}

/// The rows in view, kept aside from the view's state, since they change on every scroll and
/// are only read when the pinned map is tapped.
private final class VisibleRows {
  /// The list's own scroll targets in view: rows one to a line, and regions' anchors.
  var ids: [String] = []
  /// Rows set in columns that are in view, which each report for themselves, since rows inside
  /// a grid aren't among the list's own scroll targets.
  var gridIDs: Set<String> = []

  /// Every row in view, one to a line or in columns, in list order where the list says it.
  var all: [String] {
    gridIDs.isEmpty ? ids : ids + gridIDs.filter { !ids.contains($0) }.sorted()
  }

  func contains(_ id: String) -> Bool {
    gridIDs.contains(id) || ids.contains(id)
  }
}

/// A row set in columns noting when at least half of it is in view, and when it leaves, in the
/// list's `VisibleRows`. Rows one to a line are reported by the list itself, so they skip it.
private struct GridRowVisibility: ViewModifier {
  var id: String
  var rows: VisibleRows
  var isTracking: Bool

  func body(content: Content) -> some View {
    if isTracking {
      content
        .onScrollVisibilityChange(threshold: 0.5) { isVisible in
          if isVisible { rows.gridIDs.insert(id) } else { rows.gridIDs.remove(id) }
        }
        // A row rebuilt or taken away, as when the order changes, is no longer in view.
        .onDisappear { rows.gridIDs.remove(id) }
    } else {
      // Back to one place a row, the list reports it again, so any note from the columns goes.
      content
        .onAppear { rows.gridIDs.remove(id) }
    }
  }
}

/// Asks the list to scroll to a place, even when it is the same place as last time.
private struct ScrollRequest: Equatable {
  var id: String
  var anchor: UnitPoint = .center
  /// The region a jump arrives at, whose header pulses once the list lands there.
  var landingRegion: String? = nil
  /// The place found from the map that the list is gliding to, whose row flourishes as it lands.
  var landingPlace: String? = nil
  var token = UUID()
}

/// A region the person has just finished with a tap, so its header can celebrate. Counts going
/// up some other way, such as counting from a lower level, don't set it off.
struct RegionCelebration: Equatable {
  var regionID: String
  var token = UUID()
  /// When the region was finished, for telling whether the place that finished it has lifted off.
  var date = Date.now
}

extension EnvironmentValues {
  @Entry var regionCelebration: RegionCelebration? = nil
}

/// How a list is arranged: in its continents or regions, or every place A to Z.
enum ListOrder: String, CaseIterable, Identifiable {
  case regions, alphabetical

  var id: Self { self }

  static let countriesKey = "countriesOrder"
  static let subdivisionsKey = "subdivisionsOrder"
  /// Whether lists show their map above them.
  static let showsMapKey = "listsShowMap"
  /// Whether lists head each region, continent or letter with its name, count and bar.
  static let showsHeadingsKey = "listsShowHeadings"

  /// Whether a collection lists countries, which keep an order of their own apart from subdivisions'.
  static func listsCountries(_ collection: Country) -> Bool {
    collection.id == CountryCatalog.world.id || collection.isGroupOfCountries
  }
}

/// A country's levels to choose between, such as Regions and Departments, from the list's title.
private struct LevelPicker: View {
  var levels: [Country]
  var currentID: String
  var onSwitch: (String) -> Void

  var body: some View {
    Picker("Level", selection: Binding(get: { currentID }, set: onSwitch)) {
      ForEach(levels) { level in
        Text(level.divisionLabel).tag(level.id)
      }
    }
  }
}

/// A subtitle under the list's title, where the system shows one.
private struct TotalSubtitle: ViewModifier {
  var text: String?

  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.navigationSubtitle(text ?? "")
    } else {
      content
    }
  }
}

/// Beneath a group's total, how many of its members are hidden from the World, and so aren't
/// listed or counted here, such as "2 states hidden".
private struct HiddenStatesNote: View {
  var count: Int

  var body: some View {
    Label(count == 1 ? "1 state hidden" : "\(count) states hidden", systemImage: "eye.slash")
      .font(.footnote.weight(.medium))
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityLabel(count == 1 ? "1 member state hidden from the World" : "\(count) member states hidden from the World")
  }
}
