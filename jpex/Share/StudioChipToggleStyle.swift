import SwiftUI

/// An option above a tool's tiles, such as the levels' key, as one of its capsules, highlighted
/// while it's on.
struct StudioChipToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            configuration.label
        }
        .buttonStyle(StudioChipStyle(isOn: configuration.isOn))
        .accessibilityRemoveTraits(.isSelected)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}
