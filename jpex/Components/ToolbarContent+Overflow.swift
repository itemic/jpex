import SwiftUI

extension ToolbarContent {
    /// Kept in view after the others as room runs short, such as in iPhone Duo's side bar on its
    /// short outer display, where items go into the overflow menu from the foot of the bar up.
    @ToolbarContentBuilder
    func overflowsLast() -> some ToolbarContent {
        if #available(iOS 27.0, *) {
            visibilityPriority(.high)
        } else {
            self
        }
    }

    /// The first to go into the overflow menu as room runs short, for something also found elsewhere.
    @ToolbarContentBuilder
    func overflowsFirst() -> some ToolbarContent {
        if #available(iOS 27.0, *) {
            visibilityPriority(.low)
        } else {
            self
        }
    }
}
