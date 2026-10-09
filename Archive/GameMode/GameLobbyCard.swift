import SwiftUI

/// Where Game Mode starts: how well do you know the place, a big candy tile for each way to play
/// with your best score on it, and which places to play and how many. A tap on a tile starts.
struct GameLobbyCard: View {
    @Bindable var game: MapGame
    var localLanguage: Bool
    var onPlay: (MapGameMode) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            tiles
            options
        }
        .padding(18)
        .fontDesign(.rounded)
    }

    private var header: some View {
        HStack(spacing: 12) {
            badge
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("How well do you know \(game.collection.id == CountryCatalog.world.id ? "the world" : game.collection.name)?")
                    .font(.title3.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(game.places.count) \(game.collection.divisionLabel.lowercased()) to name and find")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var badge: some View {
        if let flag = game.collection.flagAssetName {
            Image(flag)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 32)
                .clipShape(.rect(cornerRadius: 5))
                .overlay { RoundedRectangle(cornerRadius: 5).strokeBorder(.primary.opacity(0.12), lineWidth: 0.5) }
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        } else {
            Image(systemName: MapCenter.current.globeSymbolName)
                .font(.system(size: 34))
                .foregroundStyle(MapGameMode.nameIt.color.gradient)
        }
    }

    /// A tile for each way to play, side by side, or stacked at the largest text sizes.
    private var tiles: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
        return layout {
            ForEach(MapGameMode.allCases) { mode in
                Button {
                    onPlay(mode)
                } label: {
                    tileLabel(for: mode)
                }
                .buttonStyle(CandyButtonStyle(
                    color: mode.color, pattern: .candyStripes, shape: RoundedRectangle(cornerRadius: 24, style: .continuous)))
                .accessibilityLabel(mode.name)
                .accessibilityValue(game.best(for: mode).map { "Best score \($0)" } ?? "")
                .accessibilityHint(mode.summary(placeNoun: game.collection.placeNoun))
            }
        }
    }

    private func tileLabel(for mode: MapGameMode) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top) {
                Image(systemName: mode.symbolName)
                    .font(.title.weight(.semibold))
                Spacer(minLength: 4)
                if let best = game.best(for: mode) {
                    Label(best.formatted(), systemImage: "trophy.fill")
                        .font(.caption.weight(.heavy))
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 12)
            Text(mode.name)
                .font(.title2.weight(.heavy))
            Text(mode.summary(placeNoun: game.collection.placeNoun))
                .font(.footnote.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
    }

    /// Which places to play, and how many of them.
    private var options: some View {
        HStack(spacing: 8) {
            if !game.scopes.isEmpty {
                Menu {
                    Picker("Places", selection: $game.scopeID) {
                        Label("Everywhere", systemImage: "globe").tag(String?.none)
                        ForEach(game.scopes) { group in
                            Text(group.displayName(localLanguage: localLanguage)).tag(String?.some(group.id))
                        }
                    }
                } label: {
                    optionLabel(
                        game.scope?.displayName(localLanguage: localLanguage) ?? "Everywhere", systemImage: "mappin.and.ellipse")
                }
                .accessibilityLabel("Places")
                .accessibilityValue(game.scope?.name ?? "Everywhere")
            }
            let available = game.scopedPlaces.count
            if available > 10 {
                Menu {
                    Picker("How many", selection: $game.length) {
                        Text("10 places").tag(MapGameLength.ten)
                        Text("All \(available)").tag(MapGameLength.every)
                    }
                } label: {
                    optionLabel(game.length == .ten ? "10 places" : "All \(available)", systemImage: "list.number")
                }
                .accessibilityLabel("How many")
                .accessibilityValue(game.length == .ten ? "10 places" : "All \(available) places")
            } else {
                Text("^[\(available) place](inflect: true)")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .font(.subheadline.weight(.semibold))
        .buttonStyle(CandyButtonStyle(color: .secondary, isLit: false))
    }

    private func optionLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(title)
                .lineLimit(1)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
