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
  @Environment(CountingPreferences.self) private var counting
  @Environment(\.visitLadder) private var ladder
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
  @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
  @State private var searchText = ""
  /// Whether the search field is open, so a new list can put it away.
  @State private var isSearching = false
  @State private var totalHeight = 0.0
  @State private var showingMap = false
  @State private var mapCardFrame: CGRect?
  @State private var listFrame: CGRect = .zero
  @State private var mapGrowsFromCard = false
  @State private var isMapCardHidden = false
  @AppStorage(RowSize.storageKey) private var rowSize = RowSize.saved
  /// Whether the map is held beside the fold rather than at the head of the list.
  @State private var isMapPinned = false
  /// A place found from the pinned map, briefly lit in the list.
  @State private var highlightedID: String?
  @State private var scrollRequest: ScrollRequest?
  /// How many times each region has been jumped to, so its header can pulse on arrival.
  @State private var regionJumps: [String: Int] = [:]
  /// Counts pinches that switched the rows to another size.
  @State private var pinches = 0
  /// The place whose quick level picker is open, outlined on the map too.
  @State private var tapbackID: String?
  @State private var tapbackSize: CGSize = .zero
  @AppStorage(MapCard.pinnedKey) private var keepsMapAtTop = false
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
  /// The place last found in the list from a tap on the map card, which another tap opens the map on.
  @State private var cardFoundID: String?

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
  private func scrolledPastTotal(map: TravelMap?, snapshot: TravelSnapshot) -> String? {
    guard map != nil, !keepsMapAtTop, isTotalScrolledAway else { return nil }
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
        searchText.isEmpty
          || [
            division.name, division.localName ?? "", division.abbreviation, group.name,
            group.localName ?? "", regionName(of: division) ?? "",
          ]
          .contains { $0.localizedStandardContains(searchText) }
      }
      return matches.isEmpty ? nil : DivisionSearchSection(group: group, divisions: matches)
    }
  }

  /// The level totals count from, kept by ID so it follows renames.
  private var minimumLevel: Binding<VisitLevel> {
    Binding(
      get: { counting.rules.minimumLevel(in: ladder) },
      set: { counting.rules.minimumLevelID = $0.id }
    )
  }

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
      let fold = measured ?? (isSearching && listMap != nil ? heldFold?.fitted(to: container.size) : nil)
      let listFrame = fold?.near ?? CGRect(origin: .zero, size: container.size)
      ZStack(alignment: .topLeading) {
        if let fold, let map = listMap {
          PinnedMapView(
            map: map, statuses: statuses, minimumStatus: counting.rules.minimumLevel(in: ladder),
            highlightedID: highlightedID ?? tapbackID, journey: journey, onSelect: reveal, onOpen: openMap,
            onFrameChange: { mapCardFrame = $0 }
          )
          .opacity(isMapCardHidden ? 0 : 1)
          .frame(width: fold.far.width, height: fold.far.height)
          .position(x: fold.far.midX, y: fold.far.midY)
          .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
        list(snapshot: snapshot, statuses: statuses, map: fold == nil ? listMap : nil, journey: journey)
          .frame(width: listFrame.width, height: listFrame.height)
          .position(x: listFrame.midX, y: listFrame.midY)
      }
      .animation(.smooth(duration: 0.5), value: fold)
      .onChange(of: fold != nil, initial: true) { _, pinned in isMapPinned = pinned }
      .onChange(of: measured, initial: true) { _, measured in
        if let measured { heldFold = measured } else if !isSearching { heldFold = nil }
      }
    }
    .background(.pageBackground)
    .animation(.smooth, value: country.id)
    .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search")
    .navigationTitle(country.listTitle)
    .modifier(TotalSubtitle(text: scrolledPastTotal(map: map, snapshot: snapshot)))
    // With the map held on the far side of the fold, a small title leaves it more of its half.
    .navigationBarTitleDisplayMode(isMapPinned ? .inline : .large)
    .toolbar {
      // The map card carries its own Map button; without the card in the list, the toolbar does.
      if map != nil, !showsMap || isMapPinned {
        ToolbarItem(placement: .primaryAction) {
          Button("Map", systemImage: "map") { openMap() }
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
          sourceFrame: mapGrowsFromCard ? mapCardFrame : nil,
          onStatusChange: onStatusChange,
          onOpenCollection: { id in
            closeMap()
            // The full-screen map has already flown there.
            onOpenCollection(id, false)
          },
          onPresent: { isMapCardHidden = mapGrowsFromCard },
          onClose: closeMap
        )
        .presentationBackground(.clear)
      }
    }
    // Only for a pinch here; switching in Settings has its own toggle.
    .sensoryFeedback(.impact(weight: .light), trigger: pinches)
    .onChange(of: country.id) {
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
    }
  }

  /// The map's flight over from the list before, while this list is arriving in its place.
  private func journey(snapshot: TravelSnapshot) -> MapJourney? {
    guard let arrival, arrival.toID == country.id, arrival.isUnderWay else { return nil }
    return MapJourney(
      arrival: arrival, collections: CountryCatalog.countries(applying: counting.rules), snapshot: snapshot,
      projection: projection, center: center)
  }

  /// Coming back to this list, brings the place just left into view and lights it up for a moment,
  /// as the list fades in.
  private func revealArrival(with scroller: ScrollViewProxy) {
    guard let arrival, arrival.toID == country.id, arrival.isUnderWay, revealedArrivalID != arrival.id,
          let id = arrival.revealedPlaceID, country.divisions.contains(where: { $0.id == id })
    else { return }
    revealedArrivalID = arrival.id
    Task { @MainActor in
      scroller.scrollTo(id, anchor: .center)
      withAnimation(.smooth) { highlightedID = id }
      try? await Task.sleep(for: .seconds(1.8))
      guard highlightedID == id else { return }
      withAnimation(.smooth(duration: 0.8)) { highlightedID = nil }
    }
  }

  /// The scrolling list of places, with the map card at its head unless the map is pinned beside it.
  /// Pinch in for compact rows and out for roomy ones.
  private func list(
    snapshot: TravelSnapshot, statuses: [String: VisitLevel], map: TravelMap?, journey: MapJourney?
  ) -> some View {
    @Bindable var counting = counting
    let regions = displayedGroups.map { regionSummary(of: $0.group, snapshot: snapshot) }
    let minimumStatus = counting.rules.minimumLevel(in: ladder)
    // Pinned, the map stays above the list; otherwise it heads the list and scrolls away with it.
    let pinnedMap = keepsMapAtTop ? map : nil
    let scrollingMap = keepsMapAtTop ? nil : map
    // Where the pinned map ends, including the strip of page beneath it, in global coordinates.
    let mapBottom = pinnedMap != nil && searchText.isEmpty ? (mapCardFrame?.maxY ?? 0) + 8 : -CGFloat.infinity
    return GeometryReader { geometry in
      // Pinned, the map starts at its full size and shrinks as the list scrolls, down to a strip.
      // The reader's width already stops short of the safe area, as the pinned card does.
      // On a short screen, such as iPhone Duo's outer display on its side, the map keeps to a share
      // of the height so the list still has room.
      let fullMapHeight = pinnedMap.map {
        min(MapCard.naturalHeight(of: $0, places: statuses.keys, width: geometry.size.width), geometry.size.height * 0.45)
      } ?? 0
      let compactMapHeight = min(150, fullMapHeight, geometry.size.height * 0.25)
      let collapse = max(fullMapHeight - compactMapHeight, 0)
      ScrollViewReader { scroller in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
            if searchText.isEmpty {
              VStack(spacing: 0) {
                if let map = scrollingMap {
                  mapCard(
                    map, statuses: statuses, snapshot: snapshot, horizontalSafeArea: geometry.safeAreaInsets,
                    journey: journey)
                } else if pinnedMap != nil {
                  // Room for the pinned map's full size, which scrolls away as the map shrinks.
                  Color.clear.frame(height: collapse)
                }
                TravelTotalView(
                  tally: snapshot.tally(of: country.divisions),
                  total: country.divisions.count,
                  horizontalSafeArea: geometry.safeAreaInsets,
                  minimumStatus: minimumLevel
                )
              }
              .onGeometryChange(for: Double.self) { $0.size.height } action: { totalHeight = $0 }
            }
            if displayedGroups.isEmpty {
              ContentUnavailableView.search(text: searchText)
                .frame(maxWidth: .infinity)
            }
            ForEach(displayedGroups) { section in
              Section {
                // Where a jump to this region lands. Pinned headers don't make reliable scroll targets.
                Color.clear
                  .frame(height: 0)
                  .id(Self.regionAnchor(section.group.id))
                ForEach(section.divisions) { division in
                  DivisionListRow(
                    division: division,
                    horizontalSafeArea: geometry.safeAreaInsets,
                    localLanguage: localLanguage,
                    size: rowSize,
                    regionName: order == .alphabetical ? regionName(of: division) : nil,
                    isHighlighted: highlightedID == division.id || tapbackID == division.id,
                    status: snapshot.status(for: division),
                    collection: CountryCatalog.collection(for: division),
                    onSelect: { openTapback(for: division) },
                    onStatusChange: { onStatusChange($0, division, country) },
                    onOpenCollection: { onOpenCollection($0, true) }
                  )
                  .anchorPreference(key: TapbackAnchorKey.self, value: .bounds) { tapbackID == division.id ? $0 : nil }
                  .id(division.id)
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
          }
          .frame(maxWidth: .infinity)
          // Rebuilt when the order changes: the lazy stack otherwise keeps some rows as they were,
          // with A to Z's region names still above them under the region headings.
          .id(order)
          .scrollTargetLayout()
        }
        .onScrollTargetVisibilityChange(idType: String.self) { visibleRows.ids = $0 }
        .onAppear { revealArrival(with: scroller) }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { listFrame = $0 }
        .contentMargins(.horizontal, 0, for: .scrollContent)
        .contentMargins(.horizontal, geometry.safeAreaInsets, for: .scrollIndicators)
        .ignoresSafeArea(.container, edges: .horizontal)
        .modifier(PinnedHeaderCap(threshold: searchText.isEmpty ? totalHeight : 0))
        .simultaneousGesture(
          MagnifyGesture(minimumScaleDelta: 0.06)
            .onEnded { value in
              // Pinching in steps down a size, and out, back up, a step at a time.
              guard value.magnification != 1,
                let size = value.magnification < 1 ? rowSize.smaller : rowSize.larger
              else { return }
              withAnimation(.smooth(duration: 0.45)) { rowSize = size }
              pinches += 1
            }
        )
        .onChange(of: scrollRequest) { _, request in
          guard let request else { return }
          isGlidingToRequest = true
          withAnimation(.smooth(duration: 0.6)) {
            scroller.scrollTo(request.id, anchor: request.anchor)
          } completion: {
            // A newer request may have taken over the glide; it ends the hold itself.
            if scrollRequest == request { isGlidingToRequest = false }
            // Arriving at a region, its header pulses and the hand feels it land.
            if let region = request.landingRegion { regionJumps[region, default: 0] += 1 }
          }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: regionJumps)
        .overlayPreferenceValue(TapbackAnchorKey.self) { anchor in
          tapbackLayer(anchor: anchor, snapshot: snapshot, clearOf: mapBottom, sides: geometry.safeAreaInsets)
        }
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
            withAnimation(.smooth(duration: 0.45)) { mapFocus = [] }
          }
        }
        // Once the total has mostly slid under the pinned map, the map carries the count.
        .onScrollGeometryChange(for: Bool.self) { [totalHeight] scroll in
          searchText.isEmpty && scroll.contentOffset.y + scroll.contentInsets.top > totalHeight - 30
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
          if let map = pinnedMap, searchText.isEmpty {
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
            .transition(.move(edge: .top).combined(with: .opacity))
          }
        }
        .id(country.id)
        // Another list fades through rather than across, so the two never show at once: this one
        // slips away quickly, then the next rises gently into its place.
        .transition(.asymmetric(
          insertion: (reduceMotion ? AnyTransition.opacity : .opacity.combined(with: .offset(y: 14)))
            .animation(.smooth(duration: 0.4).delay(0.1)),
          removal: .opacity.animation(.easeOut(duration: 0.15))))
      }
    }
  }

  private func mapCard(
    _ map: TravelMap, statuses: [String: VisitLevel], snapshot: TravelSnapshot, horizontalSafeArea: EdgeInsets,
    height: CGFloat? = nil, journey: MapJourney?
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
      // Pinned and scrolled, the total is under the map, so its count rides on the map instead.
      badge: height != nil && isTotalScrolledAway
        ? TravelTotalView(
          tally: snapshot.tally(of: country.divisions), total: country.divisions.count, horizontalSafeArea: EdgeInsets(),
          minimumStatus: minimumLevel, isBadge: true)
        : nil,
      focus: height != nil ? mapFocus : [],
      journey: journey,
      onFrameChange: { mapCardFrame = $0 },
      nudges: mapNudges,
      onOpenMap: openMap,
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

  /// Grows the shrunken pinned map back to its full size, pushing the list down with it so the
  /// rows in view stay in view, and zooms it in on those places. Tapped again, it opens full screen.
  private func expandMap() {
    let places = Set(country.divisions.map(\.id))
    // Scrolling back by as much as the map has shrunk grows it in step, as scrolling up by hand does.
    withAnimation(.smooth(duration: 0.5)) {
      scrollPosition.scrollTo(y: max(scrolledDistance - mapCollapse, 0))
      mapFocus = visibleRows.ids.filter(places.contains)
    }
  }

  /// A place tapped on the map card. The first tap finds it in the list; once it's found and in
  /// view, tapping it again opens the map.
  private func findFromCard(_ id: String) {
    if cardFoundID == id, visibleRows.ids.contains(id) {
      openMap()
    } else {
      cardFoundID = id
      reveal(id)
    }
  }

  // MARK: Quick level picker

  private func openTapback(for division: AdministrativeDivision) {
    withAnimation(.bouncy(duration: 0.4, extraBounce: 0.08)) { tapbackID = division.id }
  }

  private func closeTapback() {
    withAnimation(.smooth(duration: 0.25)) { tapbackID = nil }
  }

  /// The chosen place's quick level picker floats just above it, or below when there's more room
  /// there, and always wholly in view. Nothing dims: the picker glows instead, and a tap or a drag
  /// anywhere else puts it away. `mapBottom` is where the pinned map ends, in global coordinates,
  /// since the map draws over the top of the list and would hide the picker's head. `sides` is the
  /// room kept at the list's sides, such as for iPhone Duo's vertical bar or its outer camera,
  /// which the list's rows run under but the picker stays clear of.
  @ViewBuilder
  private func tapbackLayer(
    anchor: Anchor<CGRect>?, snapshot: TravelSnapshot, clearOf mapBottom: CGFloat, sides: EdgeInsets
  ) -> some View {
    GeometryReader { proxy in
      if let anchor, let id = tapbackID, let division = country.divisions.first(where: { $0.id == id }) {
        let row = proxy[anchor]
        let size = tapbackSize == .zero ? CGSize(width: 300, height: 80) : tapbackSize
        // The list's own side, short of its bars and the pinned map, so on a partly folded iPhone Duo
        // it stays on the near side of the fold, and on every device it is never covered or cut off.
        let top = max(proxy.safeAreaInsets.top, mapBottom - proxy.frame(in: .global).minY, 0)
        let bottom = proxy.size.height - proxy.safeAreaInsets.bottom
        let leading = max(sides.leading, proxy.safeAreaInsets.leading)
        let trailing = max(sides.trailing, proxy.safeAreaInsets.trailing)
        let room = CGRect(
          x: leading, y: top, width: max(proxy.size.width - leading - trailing, 0), height: max(bottom - top, size.height + 16)
        )
        .insetBy(dx: 8, dy: 8)
        let above = row.minY + 6 - size.height / 2
        let below = row.maxY - 6 + size.height / 2
        let fitsAbove = above - size.height / 2 >= room.minY
        let fitsBelow = below + size.height / 2 <= room.maxY
        let preferred = fitsAbove ? above : fitsBelow ? below : row.minY - room.minY > room.maxY - row.maxY ? above : below
        let y = min(max(preferred, room.minY + size.height / 2), max(room.maxY - size.height / 2, room.minY + size.height / 2))
        // Beside the row's trailing end, but never past the side bar or the camera.
        let x = min(max(min(row.maxX, room.maxX + 8) - size.width / 2 - 12, room.minX + size.width / 2), room.maxX - size.width / 2)
        ZStack(alignment: .topLeading) {
          Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: closeTapback)
            .gesture(DragGesture(minimumDistance: 6).onChanged { _ in closeTapback() })
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Close")
          let collection = CountryCatalog.collection(for: division)
          LevelTapback(
            status: snapshot.status(for: division),
            place: division,
            localLanguage: localLanguage,
            collection: collection.map { CollectionSummary(collection: $0, snapshot: snapshot, rules: counting.rules) },
            onSelect: { choose($0, for: division) },
            onOpenCollection: {
              closeTapback()
              if let collection { onOpenCollection(collection.id, true) }
            }
          )
          .frame(maxWidth: room.width)
          .onGeometryChange(for: CGSize.self) { $0.size } action: { tapbackSize = $0 }
          .position(x: x, y: y)
          // Grows from beside the row, or with Reduce Motion simply fades in.
          .transition(
            reduceMotion
              ? AnyTransition.opacity
              : .scale(scale: 0.4, anchor: y < row.midY ? .bottomTrailing : .topTrailing).combined(with: .opacity))
        }
        .accessibilityAction(.escape, closeTapback)
      }
    }
    .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: tapbackID) { _, new in new != nil }
  }

  /// Sets the level, lets the ring settle on it for a moment, then puts the picker away.
  private func choose(_ level: VisitLevel, for division: AdministrativeDivision) {
    onStatusChange(level, division, country)
    Task {
      try? await Task.sleep(for: .seconds(0.3))
      if tapbackID == division.id { closeTapback() }
    }
  }

  private static func regionAnchor(_ id: String) -> String { "region-\(id)" }

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

  /// Scrolls the list to a place tapped on the pinned map and lights it up for a moment.
  private func reveal(_ id: String) {
    if !searchText.isEmpty { searchText = "" }
    withAnimation(.smooth) { highlightedID = id }
    scrollRequest = ScrollRequest(id: id)
    Task {
      try? await Task.sleep(for: .seconds(1.8))
      guard highlightedID == id else { return }
      withAnimation(.smooth(duration: 0.8)) { highlightedID = nil }
    }
  }

  /// The full-screen map runs its own animation, growing out of the card when the card is in view.
  private func openMap() {
    // The full-screen map opens on the whole map, so the card pulls back out to match it.
    mapFocus = []
    if isMapPinned {
      mapGrowsFromCard = mapCardFrame != nil
    } else if let mapCardFrame, !listFrame.isEmpty {
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
  @State private var bursts = 0
  @State private var showingRegions = false

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
          Text(region.name)
            .typeStyle(titleStyle, language: region.language)
          Image(systemName: "chevron.down")
            .font(.footnote.weight(.bold))
            .foregroundStyle(.tertiary)
            .rotationEffect(.degrees(showingRegions ? 180 : 0))
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
          Text(region.counted, format: .number)
            .typeStyle(.count)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(region.counted)))
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
      .overlay {
        // Finishing a region with a tap throws confetti from its count.
        CelebrationBurst(trigger: bursts, colors: ladder.levels.map(\.color))
          .frame(width: 320, height: 320)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, verticalPadding)
    .padding(.leading, horizontalSafeArea.leading)
    .padding(.trailing, horizontalSafeArea.trailing)
    .background {
      Rectangle()
        .fill(.thickMaterial)
        .overlay {
          // Arriving from a jump, the header glows in its region's colour and fades back.
          color.keyframeAnimator(initialValue: 0.0, trigger: jumps) { glow, opacity in
            glow.opacity(opacity)
          } keyframes: { _ in
            CubicKeyframe(reduceMotion ? 0.18 : 0.32, duration: 0.18)
            CubicKeyframe(0, duration: 0.9)
          }
        }
    }
    .animation(.snappy, value: region.counted)
    .animation(.smooth, value: color)
    // Confetti only for a region the person has just finished, never for a count that went up
    // some other way.
    .onChange(of: celebration) { _, celebration in
      if celebration?.regionID == region.id { bursts += 1 }
    }
  }
}

private struct DivisionListRow: View {
  var division: AdministrativeDivision
  var horizontalSafeArea: EdgeInsets
  var localLanguage: Bool
  /// Compact rows are shorter, with the other-language name beside the name, so more places fit
  /// at once; extra compact ones are shorter still, in smaller type with a smaller pill.
  var size = RowSize.standard
  /// The place's region or continent, set small above its name when the list runs A to Z, or in
  /// extra compact rows, at the end of the line.
  var regionName: String? = nil
  /// Lit for a moment after the place is tapped on the pinned map.
  var isHighlighted = false
  var status: VisitLevel
  var collection: Country?
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
              // Roomy rows let a long name wrap; compact ones keep it on one line, gliding across
              // now and then to show its end rather than cutting it short.
              Group {
                if isCompact {
                  ScrollingText {
                    Text(name)
                      .typeStyle(nameStyle, language: division.language(of: name))
                  }
                } else {
                  Text(name)
                    .typeStyle(.placeName, language: division.language(of: name))
                    .fixedSize(horizontal: false, vertical: true)
                }
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
              // Long formal names, such as Hong Kong's, wrap in roomy rows and scroll in compact ones.
              Group {
                if isCompact {
                  ScrollingText {
                    Text(subtitle)
                      .typeStyle(
                        size == .extraCompact ? .extraCompactPlaceSubtitle : .compactPlaceSubtitle,
                        language: division.language(of: subtitle))
                  }
                } else {
                  Text(subtitle)
                    .typeStyle(.placeSubtitle, language: division.language(of: subtitle))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                }
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
        .accessibilityLabel(regionName.map { "\(division.name), \($0)" } ?? division.name)
        .accessibilityHint("Shows its levels.")
        VisitPillView(status: statusBinding, placeName: division.name, isSmall: size == .extraCompact)
          .fixedSize(horizontal: true, vertical: false)
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
          status.color.opacity(isHighlighted ? 0.45 : 0.2)
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
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
      }
      .clipped()
      .animation(.smooth(duration: 0.6), value: status)
      .contentShape(.contextMenuPreview, Rectangle())
      .contextMenu {
        Picker("Visit status", selection: statusBinding) {
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
}

/// A wash of colour that spreads across the row from the pill when the status changes.
private struct StatusRipple: View {
  var status: VisitLevel

  var body: some View {
    Circle()
      .fill(
        RadialGradient(
          colors: [status.color.opacity(0.5), status.color.opacity(0)], center: .center,
          startRadius: 0, endRadius: 20)
      )
      .frame(width: 40, height: 40)
      .keyframeAnimator(initialValue: RippleFrame(), trigger: status.id) { content, frame in
        content
          .scaleEffect(frame.scale)
          .opacity(frame.opacity)
      } keyframes: { _ in
        KeyframeTrack(\.scale) {
          MoveKeyframe(0.3)
          CubicKeyframe(18, duration: 0.75)
        }
        KeyframeTrack(\.opacity) {
          MoveKeyframe(1)
          CubicKeyframe(0, duration: 0.75)
        }
      }
      .allowsHitTesting(false)
  }
}

private struct RippleFrame {
  var scale = 0.3
  var opacity = 0.0
}

/// The card that lifts out of a row when you touch and hold it.
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
      VStack(spacing: 0) {
        let name = division.displayName(localLanguage: localLanguage)
        Text(name)
          .typeStyle(.placeName, language: division.language(of: name))
        if let subtitle = division.subtitle(localLanguage: localLanguage) {
          Text(subtitle)
            .typeStyle(.placeSubtitle, language: division.language(of: subtitle))
            .foregroundStyle(.secondary)
        }
      }
      .multilineTextAlignment(.center)
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

private struct DivisionSearchSection: Identifiable {
  var group: DivisionGroup
  var divisions: [AdministrativeDivision]
  var id: String { group.id }
}

/// The rows in view, kept aside from the view's state, since they change on every scroll and
/// are only read when the pinned map is tapped.
private final class VisibleRows {
  var ids: [String] = []
}

/// Asks the list to scroll to a place, even when it is the same place as last time.
private struct ScrollRequest: Equatable {
  var id: String
  var anchor: UnitPoint = .center
  /// The region a jump arrives at, whose header pulses once the list lands there.
  var landingRegion: String? = nil
  var token = UUID()
}

/// A region the person has just finished with a tap, so its header can celebrate. Counts going
/// up some other way, such as counting from a lower level, don't set it off.
struct RegionCelebration: Equatable {
  var regionID: String
  var token = UUID()
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
    collection.id == CountryCatalog.world.id || WorldGroup(collectionID: collection.id) != nil
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
