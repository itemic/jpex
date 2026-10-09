import SwiftUI

/// A whole number that counts through every value on its way when it changes inside an animation,
/// like a score adding up.
struct RollingNumber: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(Int(value.rounded()), format: .number)
    }
}
