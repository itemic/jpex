import SwiftUI

/// One page of the Atlas book, set as an atlas's page is: the region along its head, the place's
/// flag large, its name and other name, a rule, then its capitals, its codes and what the Atlas
/// knows, as on its card, and the page's number in the outer corner of its foot.
struct AtlasBookPage: View {
    var deck: LearnDeck
    var place: AdministrativeDivision
    /// The page's number, the place's position in the deck counted from one.
    var number: Int
    var localLanguage: Bool
    var facts: [MapFact]
    @ScaledMetric(relativeTo: .largeTitle) private var flagHeight: CGFloat = 84

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            runningHead
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    emblem
                        .padding(.top, 24)
                    names
                    Rectangle()
                        .fill(.primary.opacity(0.12))
                        .frame(height: 1)
                    details
                }
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            // Details running on past the foot of the page fade away there, rather than being cut
            // through, as they scroll up into view.
            .mask {
                VStack(spacing: 0) {
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 24)
                }
            }
            folio
        }
        .padding(.horizontal, 28)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AtlasBook.paper)
        .fontDesign(.rounded)
        .accessibilityElement(children: .contain)
    }

    /// Along the head of the page, as an atlas runs its section: the region the place is in, and
    /// on the other side, the collection the book is of.
    private var runningHead: some View {
        HStack(spacing: 12) {
            if let region = deck.regionName(of: place, localLanguage: localLanguage), !region.isEmpty {
                ScrollingName(text: region)
            }
            Spacer(minLength: 0)
            ScrollingName(text: deck.collection.name)
                .fixedSize()
        }
        .typeStyle(.smallEyebrow)
        .foregroundStyle(.secondary)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.primary.opacity(0.08))
                .frame(height: 1)
        }
        .accessibilityHidden(true)
    }

    /// The flag large, in its own shape, or where the place has none of its own, the code that
    /// stands in for it, as on its card.
    @ViewBuilder
    private var emblem: some View {
        if let flag = deck.flag(of: place) {
            let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
            let size = flagSize(of: flag)
            Image(flag)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
                .clipShape(shape)
                .overlay { shape.strokeBorder(.primary.opacity(0.1), lineWidth: 1) }
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                .accessibilityHidden(true)
        } else if let code = emblemCode {
            CodeBadge(code: code.code, kind: code.kind, size: 40)
                .fixedSize()
                .accessibilityHidden(true)
        }
    }

    /// The name, large and light, and beneath it its other name, each on one line, gliding to show
    /// the rest where it's long.
    private var names: some View {
        let name = place.displayName(localLanguage: localLanguage)
        let subtitle = place.subtitle(localLanguage: localLanguage)
        return VStack(alignment: .leading, spacing: 4) {
            ScrollingText {
                Text(name)
                    .typeStyle(.placeName, language: place.language(of: name))
                    .fontDesign(.default)
            }
            if let subtitle, subtitle != name {
                ScrollingText {
                    Text(subtitle)
                        .typeStyle(.placeSubtitle, language: place.language(of: subtitle))
                        .fontDesign(.default)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// The capitals first, on a line of their own, then the codes and what the Atlas knows, two
    /// to a row where they fit, in the same grid as the place's card.
    @ViewBuilder
    private var details: some View {
        let capitals = deck.capitals(of: place)
        let leading = capitals.isEmpty ? [] : [CodeGrid.Entry(capitals: capitals, isLit: false)]
        let codes = deck.codes(of: place)
            .filter { $0.kind != emblemCode?.kind }
            .map(CodeGrid.Entry.init(code:))
        if !leading.isEmpty || !codes.isEmpty || !facts.isEmpty {
            CodeGrid(leading: leading, entries: codes, trailing: facts.map(CodeGrid.Entry.init(fact:)), maxGroups: 2)
        }
    }

    /// The page's number, in the outer corner of its foot, as a book numbers its right-hand pages.
    private var folio: some View {
        HStack {
            Spacer(minLength: 0)
            Text(number, format: .number)
                .font(.footnote.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
        .accessibilityLabel("Page \(number) of \(deck.count)")
    }

    /// The flag's size: `flagHeight` tall in its own proportions, unless that would make a long
    /// flag, such as Qatar's, wider than about twice its height, when it keeps that width instead.
    private func flagSize(of flag: String) -> CGSize {
        guard let artwork = UIImage(named: flag)?.size, artwork.width > 0, artwork.height > 0 else {
            return CGSize(width: flagHeight * 1.5, height: flagHeight)
        }
        let aspect = artwork.width / artwork.height
        let width = min(flagHeight * aspect, flagHeight * 1.9)
        return CGSize(width: width, height: width / aspect)
    }

    /// The code standing in for the flag, for a place with none of its own, such as 京 for Beijing.
    private var emblemCode: (kind: MapGame.CodeKind, code: String)? {
        guard deck.flag(of: place) == nil else { return nil }
        let codes = deck.codes(of: place)
        for kind in MapGame.CodeKind.emblems {
            if let entry = codes.first(where: { $0.kind == kind }) { return entry }
        }
        return nil
    }
}
