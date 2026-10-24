import SwiftUI

/// An option beneath the share screen's card as one of its tiles, highlighted while it's on.
struct StudioTileToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            configuration.label
                .labelStyle(StudioTileLabelStyle(isOn: configuration.isOn))
        }
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}
