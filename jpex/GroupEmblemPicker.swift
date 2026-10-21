import SwiftUI

/// Designs a group's badge on a page of its own, the badge waving at the top as it changes: a
/// pattern from the world's flags, such as a tricolour or a Nordic cross, each of its parts in a
/// colour from a flag-maker's palette, and up to four symbols over it, each where it suits the
/// pattern unless put in a spot of the person's choosing. Shuffle deals a design at random,
/// symbol and all, to start from or keep.
struct GroupEmblemPicker: View {
    @Binding var design: GroupFlag
    /// The group's colour, for the chosen symbol's tile.
    var tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether the badge may wave by itself.
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    /// Which of the pattern's parts the palette paints.
    @State private var part = 0
    /// The symbol being changed.
    @State private var selectedSymbolID: UUID?
    /// The kind of symbol on show to choose from, by its section's title.
    @State private var category = "Shapes"
    /// Counts choices, for a tick each.
    @State private var picks = 0
    @State private var shuffles = 0
    /// When the page opened, for the flag's wave.
    @State private var start = Date.now

    /// Symbols for the groups people make, from trips to the places they've lived, by kind, with
    /// names for VoiceOver. Every one is available from iOS 18.
    static let symbolSections: [(title: String, symbols: [(name: String, symbol: String)])] = [
        ("Shapes", [
            ("Star", "star.fill"), ("Half star", "star.leadinghalf.filled"), ("Heart", "heart.fill"),
            ("Circle", "circle.fill"), ("Ring", "circle.circle.fill"), ("Half circle", "circle.lefthalf.filled"),
            ("Square", "square.fill"), ("Rectangle", "rectangle.fill"), ("Capsule", "capsule.fill"), ("Oval", "oval.fill"),
            ("Triangle", "triangle.fill"), ("Diamond", "diamond.fill"), ("Rhombus", "rhombus.fill"),
            ("Pentagon", "pentagon.fill"), ("Hexagon", "hexagon.fill"), ("Octagon", "octagon.fill"), ("Seal", "seal.fill"),
            ("Burst", "burst.fill"), ("Shield", "shield.fill"), ("Half shield", "shield.lefthalf.filled"),
            ("Sparkle", "sparkle"), ("Sparkles", "sparkles"), ("Asterisk", "asterisk"), ("Star of life", "staroflife.fill"),
            ("Plus", "plus"), ("Cross", "cross.fill"), ("Tick", "checkmark"), ("Cross mark", "xmark"),
            ("Hearts", "suit.heart.fill"), ("Clubs", "suit.club.fill"), ("Spades", "suit.spade.fill"),
            ("Diamonds", "suit.diamond.fill"), ("Rays", "rays"), ("Crescent", "moonphase.waxing.crescent"),
            ("Small sun", "sun.min.fill"), ("Grid", "square.grid.2x2.fill"), ("Hexagons", "circle.hexagongrid.fill"),
            ("Dotted cross", "circle.grid.cross.fill"), ("Arrow", "arrowshape.up.fill"), ("Pointer", "arrowtriangle.up.fill"),
            ("Star in a circle", "star.circle.fill"), ("Star in a square", "star.square.fill"),
            ("Heart in a circle", "heart.circle.fill"), ("Tick in a seal", "checkmark.seal.fill"), ("Infinity", "infinity"),
            ("Peace", "peacesign"), ("Atom", "atom"), ("Compass", "compass.drawing"), ("Heart with a bolt", "bolt.heart.fill"),
        ]),
        ("Travel", [
            ("Plane", "airplane"), ("Take-off", "airplane.departure"), ("Landing", "airplane.arrival"),
            ("Suitcase", "suitcase.rolling.fill"), ("Bag", "suitcase.fill"), ("Backpack", "backpack.fill"),
            ("Car", "car.fill"), ("Bus", "bus.fill"), ("Tram", "tram.fill"), ("Train", "train.side.front.car"),
            ("Ferry", "ferry.fill"), ("Sailboat", "sailboat.fill"), ("Bicycle", "bicycle"), ("Scooter", "scooter"),
            ("Walking", "figure.walk"), ("Hiking", "figure.hiking"), ("Map", "map.fill"), ("Pin", "mappin"),
            ("Pin on a map", "mappin.and.ellipse"), ("Location", "location.fill"), ("Signpost", "signpost.right.fill"),
            ("Road", "road.lanes"), ("Ticket", "ticket.fill"), ("Camera", "camera.fill"),
            ("Binoculars", "binoculars.fill"), ("Fuel", "fuelpump.fill"),
        ]),
        ("Places & nature", [
            ("Globe", "globe"), ("Americas", "globe.americas.fill"), ("Europe and Africa", "globe.europe.africa.fill"),
            ("Asia and Australia", "globe.asia.australia.fill"), ("Desk globe", "globe.desk.fill"), ("Flag", "flag.fill"),
            ("Crossed flags", "flag.2.crossed.fill"), ("Chequered flag", "flag.pattern.checkered"), ("House", "house.fill"),
            ("Lodge", "house.lodge.fill"), ("Building", "building.fill"), ("City", "building.2.fill"),
            ("Tent", "tent.fill"), ("Campsite", "tent.2.fill"), ("Mountains", "mountain.2.fill"),
            ("Beach", "beach.umbrella.fill"), ("Tree", "tree.fill"), ("Leaf", "leaf.fill"), ("Waves", "water.waves"),
            ("Drop", "drop.fill"), ("Snowflake", "snowflake"), ("Sun", "sun.max.fill"), ("Sunrise", "sunrise.fill"),
            ("Sunset", "sun.horizon.fill"), ("Moon", "moon.fill"), ("Moon and stars", "moon.stars.fill"),
            ("Cloud", "cloud.fill"), ("Sun and cloud", "cloud.sun.fill"), ("Rainbow", "rainbow"),
            ("Flame", "flame.fill"), ("Lightning", "bolt.fill"), ("Storm", "tropicalstorm"), ("Shell", "fossil.shell.fill"),
        ]),
        ("People & life", [
            ("Person", "person.fill"), ("Two people", "person.2.fill"),
            ("Three people", "person.3.fill"), ("Family", "figure.2.and.child.holdinghands"),
            ("Graduation cap", "graduationcap.fill"), ("Briefcase", "briefcase.fill"), ("Book", "book.fill"),
            ("Books", "books.vertical.fill"), ("Crown", "crown.fill"), ("Trophy", "trophy.fill"), ("Medal", "medal.fill"),
            ("Laurel", "laurel.leading"), ("Gift", "gift.fill"), ("Party", "party.popper.fill"), ("Balloon", "balloon.fill"),
            ("Cake", "birthday.cake.fill"), ("Music", "music.note"), ("Guitars", "guitars.fill"),
            ("Theatre", "theatermasks.fill"), ("Dancing", "figure.dance"), ("Paintbrush", "paintbrush.pointed.fill"),
            ("Palette", "paintpalette.fill"), ("Game controller", "gamecontroller.fill"), ("Medical", "cross.case.fill"),
            ("Stethoscope", "stethoscope"), ("Hammer", "hammer.fill"), ("Tools", "wrench.and.screwdriver.fill"),
        ]),
        ("Food & drink", [
            ("Food", "fork.knife"), ("Coffee", "cup.and.saucer.fill"), ("Mug", "mug.fill"), ("Wine", "wineglass.fill"),
            ("Takeaway", "takeoutbag.and.cup.and.straw.fill"), ("Carrot", "carrot.fill"),
        ]),
        ("Sport", [
            ("Football", "soccerball"), ("Basketball", "basketball.fill"), ("Tennis", "tennisball.fill"),
            ("Baseball", "baseball.fill"), ("Volleyball", "volleyball.fill"), ("Skiing", "figure.skiing.downhill"),
            ("Skis", "skis.fill"), ("Surfing", "figure.surfing"), ("Surfboard", "surfboard.fill"), ("Running", "figure.run"),
            ("Climbing", "figure.climbing"), ("Swimming", "figure.pool.swim"), ("Golf", "figure.golf"),
            ("Court", "sportscourt.fill"), ("Weights", "dumbbell.fill"),
        ]),
        ("Animals", [
            ("Paw", "pawprint.fill"), ("Bird", "bird.fill"), ("Fish", "fish.fill"), ("Tortoise", "tortoise.fill"),
            ("Hare", "hare.fill"), ("Ant", "ant.fill"), ("Ladybird", "ladybug.fill"), ("Cat", "cat.fill"),
            ("Dog", "dog.fill"), ("Lizard", "lizard.fill"), ("Teddy bear", "teddybear.fill"),
        ]),
    ]

    /// Every symbol, for finding one's name.
    static let symbols: [(name: String, symbol: String)] = symbolSections.flatMap { $0.symbols }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                preview
                section("Pattern", detail: design.pattern.name) { patterns }
                section("Colours") { colors }
                section("Symbols") { symbolEditor }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fontDesign(.rounded)
        .navigationTitle("Badge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Shuffle", systemImage: "dice.fill", action: shuffle)
                    .symbolEffect(.bounce, value: reduceMotion ? 0 : shuffles)
                    .accessibilityHint("Deals a pattern, colours and a symbol at random.")
            }
        }
        .sensoryFeedback(.selection, trigger: picks)
        .sensoryFeedback(.impact(weight: .medium), trigger: shuffles)
        .onChange(of: design.pattern) {
            part = min(part, design.pattern.colorCount - 1)
        }
        .onAppear {
            if selectedSymbolID == nil { selectedSymbolID = symbols.first?.id }
        }
    }

    // MARK: Preview

    /// The badge large, as a flag on a breeze; still with Reduce Motion, in Low Power Mode and
    /// while the app isn't in front.
    private var preview: some View {
        let emblem = GroupEmblem(symbolName: "", color: tint, flag: design)
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return TimelineView(.animation(paused: !allowsAmbientMotion)) { context in
            WorldGroupBadge(emblem: emblem)
                .frame(width: 210, height: 140)
                .clipShape(shape)
                .overlay { shape.strokeBorder(.primary.opacity(0.08), lineWidth: 0.5) }
                .layerEffect(
                    ShaderLibrary.flagWave(
                        .boundingRect, .float(Float(context.date.timeIntervalSince(start))),
                        .float(allowsAmbientMotion ? 1 : 0)),
                    maxSampleOffset: CGSize(width: 0, height: 10))
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .pop(on: picks + shuffles)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Badge")
        .accessibilityValue(spokenDesign)
    }

    /// The design in words, for VoiceOver, such as "Vertical Tricolour: blue, white and red, with a star".
    private var spokenDesign: String {
        let colors = design.usedColors.map(\.name).formatted(.list(type: .and))
        let names = symbols.map { symbol in Self.name(of: symbol.name).lowercased() }
        return "\(design.pattern.name): \(colors)" + (names.isEmpty ? "" : ", with \(names.formatted(.list(type: .and)))")
    }

    // MARK: Pattern

    /// Every pattern as a small flag in the colours chosen, two rows that scroll sideways, the
    /// chosen one ringed and named in the heading above.
    private var patterns: some View {
        ScrollViewReader { scroller in
            ScrollView(.horizontal) {
                LazyHGrid(rows: [GridItem(.fixed(34), spacing: 10), GridItem(.fixed(34), spacing: 10)], spacing: 10) {
                    ForEach(FlagPattern.allCases) { pattern in
                        let isChosen = pattern == design.pattern
                        Button {
                            withAnimation(.snappy) { design.pattern = pattern }
                            picks += 1
                        } label: {
                            FlagPatternView(flag: GroupFlag(pattern: pattern, colors: design.colors))
                                .frame(width: 45, height: 30)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .strokeBorder(.primary.opacity(0.12), lineWidth: 0.5)
                                }
                                .padding(2)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(.primary, lineWidth: isChosen ? 2 : 0)
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PillButtonStyle())
                        .id(pattern)
                        .accessibilityLabel(pattern.name)
                        .accessibilityAddTraits(isChosen ? .isSelected : [])
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .bleedsToEdges()
            .onAppear { scroller.scrollTo(design.pattern, anchor: .center) }
            .onChange(of: design.pattern) { _, pattern in
                withAnimation(Motion.travelling(.smooth, reduceMotion: reduceMotion)) {
                    scroller.scrollTo(pattern, anchor: .center)
                }
            }
        }
    }

    // MARK: Colours

    /// A chip for each part of the pattern, such as Field and Cross, in its colour: the palette
    /// beneath paints the one chosen. Swap moves every colour along a part.
    private var colors: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(Array(design.pattern.partNames.enumerated()), id: \.offset) { index, name in
                            partChip(index: index, name: name)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .mask(StripFade(leading: 0))
                if design.pattern.colorCount > 1 {
                    Button("Swap colours", systemImage: "arrow.left.arrow.right", action: rotateColors)
                        .labelStyle(.iconOnly)
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .accessibilityHint("Moves each colour on to the next part.")
                }
            }
            palette(chosen: design.color(at: part)) { color in
                guard design.colors.indices.contains(part) else { return }
                design.colors[part] = color
            }
        }
    }

    private func partChip(index: Int, name: String) -> some View {
        let isChosen = index == part
        return Button {
            withAnimation(.snappy) { part = index }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(design.color(at: index).color)
                    .overlay { Circle().strokeBorder(.primary.opacity(0.2), lineWidth: 0.5) }
                    .frame(width: 18, height: 18)
                Text(name)
                    .font(.subheadline.weight(isChosen ? .semibold : .regular))
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .frame(minHeight: 36)
            .background(isChosen ? AnyShapeStyle(.primary.opacity(0.1)) : AnyShapeStyle(.clear), in: Capsule())
            .overlay {
                Capsule().strokeBorder(isChosen ? AnyShapeStyle(.primary) : AnyShapeStyle(.quaternary), lineWidth: isChosen ? 1.5 : 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel(name)
        .accessibilityValue(design.color(at: index).name)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    /// The flag-maker's palette as swatches, the chosen one ringed.
    private func palette(chosen: FlagColor, choose: @escaping (FlagColor) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 8)], spacing: 10) {
            ForEach(FlagColor.allCases) { color in
                let isChosen = color == chosen
                Button {
                    withAnimation(Motion.moving(Motion.hop, reduceMotion: reduceMotion)) { choose(color) }
                    picks += 1
                } label: {
                    Circle()
                        .fill(color.color)
                        .overlay { Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 0.5) }
                        .padding(isChosen ? 5 : 2)
                        .overlay { Circle().strokeBorder(.primary, lineWidth: isChosen ? 2 : 0) }
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(PillButtonStyle())
                .accessibilityLabel(color.name)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
        }
    }

    /// Moves every colour the pattern paints on to the next part, the last coming round to the first.
    private func rotateColors() {
        let count = design.pattern.colorCount
        let used = design.usedColors
        withAnimation(.snappy) {
            for index in 0..<count { design.colors[(index + 1) % count] = used[index] }
        }
        picks += 1
    }

    // MARK: Symbols

    /// The most symbols one flag carries.
    static let maximumSymbols = 4

    private var symbols: [FlagSymbol] {
        design.symbols ?? []
    }

    private var selectedIndex: Int? {
        symbols.firstIndex { $0.id == selectedSymbolID } ?? (symbols.isEmpty ? nil : 0)
    }

    /// A symbol's name, for VoiceOver.
    static func name(of symbol: String) -> String {
        symbols.first { $0.symbol == symbol }?.name ?? "Symbol"
    }

    /// The title of the section a symbol is in.
    static func section(containing symbol: String) -> String? {
        symbolSections.first { $0.symbols.contains { $0.symbol == symbol } }?.title
    }

    /// A chip for each symbol, to choose which to change, and one to add another. Under them, for
    /// the one chosen: where it sits, which symbol it is, and its colour, each kept to a line or two.
    private var symbolEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            symbolChips
            if let index = selectedIndex {
                let symbol = symbols[index]
                HStack(alignment: .center, spacing: 16) {
                    spotPicker(for: symbol)
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            setArea(nil, for: symbol)
                        } label: {
                            Label("Auto", systemImage: "wand.and.sparkles")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(symbol.area == nil ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                                .padding(.horizontal, 12)
                                .frame(minHeight: 36)
                                .background {
                                    if symbol.area == nil {
                                        Capsule().fill(tint.gradient)
                                    } else {
                                        Capsule().fill(.fill.tertiary)
                                    }
                                }
                                .contentShape(Capsule())
                        }
                        .buttonStyle(PillButtonStyle())
                        .accessibilityHint("Puts the symbol wherever suits the pattern.")
                        .accessibilityAddTraits(symbol.area == nil ? .isSelected : [])
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            removeSymbol(symbol)
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                }
                categoryTabs
                // One slot the strips trade places in, so the colours beneath hold still while a
                // new kind of symbol comes in, and a tick for each kind chosen.
                ZStack {
                    symbolStrip(for: symbol)
                }
                .frame(height: 100)
                .animation(.swap(reduceMotion: reduceMotion), value: category)
                .sensoryFeedback(.selection, trigger: category)
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(FlagColor.allCases) { color in
                            swatch(color, isChosen: color == symbol.color) {
                                updateSymbol(symbol) { $0.color = color }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .bleedsToEdges()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Symbol colour")
            }
        }
    }

    /// Each symbol as a small chip, the one being changed filled, then a chip to add another.
    private var symbolChips: some View {
        HStack(spacing: 8) {
            ForEach(symbols) { symbol in
                let isChosen = symbol.id == symbols[selectedIndex ?? 0].id
                Button {
                    withAnimation(.snappy) { selectedSymbolID = symbol.id }
                    if let section = Self.section(containing: symbol.name) { category = section }
                } label: {
                    Image(systemName: symbol.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isChosen ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: reduceMotion ? "" : symbol.name)
                        .frame(width: 44, height: 44)
                        .background {
                            if isChosen {
                                Circle().fill(tint.gradient)
                            } else {
                                Circle().fill(.fill.tertiary)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(PillButtonStyle())
                .accessibilityLabel(Self.name(of: symbol.name))
                .accessibilityAddTraits(isChosen ? .isSelected : [])
                .transition(.arrive(reduceMotion: reduceMotion))
            }
            if symbols.count < Self.maximumSymbols {
                Button(action: addSymbol) {
                    Label(symbols.isEmpty ? "Add symbol" : "Add", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .overlay { Capsule().strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])) }
                        .contentShape(Capsule())
                }
                .buttonStyle(PillButtonStyle())
                .accessibilityLabel("Add symbol")
            }
        }
    }

    /// The flag small, with its nine spots to tap: the symbol being changed moves to the one tapped.
    /// Its spot is ringed, with a wand while it's left to the pattern.
    private func spotPicker(for symbol: FlagSymbol) -> some View {
        let area = design.placements.first { $0.symbol.id == symbol.id }?.area ?? .centre
        return WorldGroupBadge(emblem: GroupEmblem(symbolName: "", color: tint, flag: design))
            .frame(width: 132, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(.primary.opacity(0.12), lineWidth: 0.5) }
            .overlay {
                GeometryReader { proxy in
                    ForEach(FlagArea.allCases) { spot in
                        let anchor = design.anchor(of: spot)
                        let isChosen = spot == area
                        Button {
                            setArea(spot, for: symbol)
                        } label: {
                            Circle()
                                .strokeBorder(.white, lineWidth: isChosen ? 2.5 : 1)
                                .background(Circle().fill(.black.opacity(isChosen ? 0.25 : 0.12)))
                                .frame(width: isChosen ? 26 : 12, height: isChosen ? 26 : 12)
                                .shadow(color: .black.opacity(0.3), radius: 1)
                                .frame(width: 30, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .position(x: anchor.x * proxy.size.width, y: anchor.y * proxy.size.height)
                        .accessibilityLabel(spot.name)
                        .accessibilityAddTraits(isChosen ? .isSelected : [])
                    }
                }
            }
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Where the symbol sits")
    }

    /// Every kind of symbol as a tab, the one on show filled.
    private var categoryTabs: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(Self.symbolSections, id: \.title) { section in
                    let isChosen = section.title == category
                    Button {
                        withAnimation(.snappy) { category = section.title }
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(isChosen ? .semibold : .regular))
                            .foregroundStyle(isChosen ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 32)
                            .background(isChosen ? AnyShapeStyle(.primary.opacity(0.1)) : AnyShapeStyle(.clear), in: Capsule())
                            .contentShape(Capsule())
                            .scaleEffect(isChosen && !reduceMotion ? 1.06 : 1)
                            .animation(.bouncy, value: isChosen)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isChosen ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .bleedsToEdges()
    }

    /// The symbols of the kind on show, two rows that scroll sideways, softening out of focus as
    /// the next kind comes into it, or with Reduce Motion, cross-fading.
    private func symbolStrip(for symbol: FlagSymbol) -> some View {
        let choices = Self.symbolSections.first { $0.title == category }?.symbols ?? []
        return ScrollView(.horizontal) {
            LazyHGrid(rows: [GridItem(.fixed(44), spacing: 8), GridItem(.fixed(44), spacing: 8)], spacing: 8) {
                ForEach(choices, id: \.symbol) { choice in
                    let isChosen = choice.symbol == symbol.name
                    Button {
                        updateSymbol(symbol) { $0.name = choice.symbol }
                    } label: {
                        Image(systemName: choice.symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isChosen ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                            .frame(width: 44, height: 44)
                            .background {
                                if isChosen {
                                    Circle().fill(tint.gradient)
                                } else {
                                    Circle().fill(.fill.tertiary)
                                }
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(PillButtonStyle())
                    .accessibilityLabel(choice.name)
                    .accessibilityAddTraits(isChosen ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .bleedsToEdges()
        .frame(height: 100)
        .id(category)
        .transition(.slotSwap(reduceMotion: reduceMotion))
    }

    /// One colour from the palette, ringed while it's chosen, the ring moving as the palette's does.
    private func swatch(_ color: FlagColor, isChosen: Bool, choose: @escaping () -> Void) -> some View {
        Button {
            withAnimation(Motion.moving(Motion.hop, reduceMotion: reduceMotion)) { choose() }
            picks += 1
        } label: {
            Circle()
                .fill(color.color)
                .overlay { Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 0.5) }
                .padding(isChosen ? 5 : 2)
                .overlay { Circle().strokeBorder(.primary, lineWidth: isChosen ? 2 : 0) }
                .frame(width: 38, height: 38)
                .animation(Motion.moving(Motion.hop, reduceMotion: reduceMotion), value: isChosen)
                .contentShape(Circle())
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel(color.name)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    private func updateSymbol(_ symbol: FlagSymbol, change: (inout FlagSymbol) -> Void) {
        var list = symbols
        guard let index = list.firstIndex(where: { $0.id == symbol.id }) else { return }
        change(&list[index])
        withAnimation(.snappy) { design.symbols = list }
        picks += 1
    }

    /// Moves a symbol to a spot, or with nil, leaves it to the pattern; its colour follows to stand out there.
    private func setArea(_ area: FlagArea?, for symbol: FlagSymbol) {
        var moved = design
        guard var list = moved.symbols, let index = list.firstIndex(where: { $0.id == symbol.id }) else { return }
        list[index].area = area
        moved.symbols = list
        if let spot = moved.placements.first(where: { $0.symbol.id == symbol.id })?.area,
           symbol.color == design.contrastingColor(at: design.placements.first { $0.symbol.id == symbol.id }?.area ?? .centre) {
            list[index].color = moved.contrastingColor(at: spot)
            moved.symbols = list
        }
        withAnimation(.snappy) { design = moved }
        picks += 1
    }

    /// Adds a star where it suits the pattern best, chosen to change at once.
    private func addSymbol() {
        var updated = design
        let added = updated.addSymbol(named: "star.fill")
        withAnimation(.snappy) { design = updated }
        selectedSymbolID = added.id
        category = "Shapes"
        picks += 1
    }

    private func removeSymbol(_ symbol: FlagSymbol) {
        let list = symbols.filter { $0.id != symbol.id }
        withAnimation(.snappy) { design.symbols = list }
        selectedSymbolID = list.first?.id
        picks += 1
    }

    // MARK: Parts

    /// A part of the page under its heading, with what's chosen in it beside the heading, if given.
    private func section<Content: View>(
        _ title: String, detail: String? = nil, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .typeStyle(.eyebrow)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                if let detail {
                    Text(detail)
                        .font(.footnote.weight(.semibold))
                        .contentTransition(.interpolate)
                        .animation(.snappy, value: detail)
                }
            }
            content()
        }
    }

    /// A pattern, colours and a symbol at random.
    private func shuffle() {
        let flag = GroupFlag.random(symbols: Self.symbols.map(\.symbol))
        withAnimation(.bouncy) { design = flag }
        part = 0
        selectedSymbolID = flag.symbols?.first?.id
        if let name = flag.symbols?.first?.name, let section = Self.section(containing: name) { category = section }
        shuffles += 1
    }
}

private extension View {
    /// A sideways strip running past the page's margins to the screen's edges, fading softly where
    /// it carries on, rather than stopping short at the margin.
    func bleedsToEdges() -> some View {
        contentMargins(.horizontal, 20, for: .scrollContent)
            .padding(.horizontal, -20)
            .mask(StripFade())
    }
}

/// A mask fading a strip out at its ends, so what scrolls on goes softly rather than being cut.
private struct StripFade: View {
    var leading: CGFloat = 16
    var trailing: CGFloat = 16

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: leading)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: trailing)
        }
        // Room above and below for a chosen item's ring and its pop.
        .padding(.vertical, -12)
    }
}
