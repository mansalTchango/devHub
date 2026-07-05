import SwiftUI
import SwiftTerm

struct TerminalViewWrapper: NSViewRepresentable {
    let terminalView: EnhancedTerminalView
    var fontSize: CGFloat = 12

    func makeNSView(context: Context) -> EnhancedTerminalView {
        terminalView.autoresizingMask = [.width, .height]
        terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        return terminalView
    }

    func updateNSView(_ nsView: EnhancedTerminalView, context: Context) {
        let currentSize = nsView.font.pointSize
        if abs(currentSize - fontSize) > 0.5 {
            nsView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }
}
