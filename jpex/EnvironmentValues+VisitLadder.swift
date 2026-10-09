import SwiftUI

extension EnvironmentValues {
    /// The person's levels, lowest first. ContentView sets it from the saved model.
    @Entry var visitLadder: VisitLadder = .standard
}
