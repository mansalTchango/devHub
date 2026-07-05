import SwiftUI

@MainActor
class TerminalPaneState: ObservableObject {
    @Published var isScrollLocked = false
    @Published var isSearchVisible = false
    @Published var searchText = ""
    @Published var fontSize: CGFloat = 12
}
