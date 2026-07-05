import AppKit
import SwiftTerm

class EnhancedTerminalView: LocalProcessTerminalView {
    var isScrollLocked = false
    var onScrollStateChanged: ((Bool) -> Void)?

    override func dataReceived(slice: ArraySlice<UInt8>) {
        if isScrollLocked {
            let saved = scrollPosition
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            super.dataReceived(slice: slice)
            scroll(toPosition: saved)
            CATransaction.commit()
        } else {
            super.dataReceived(slice: slice)
        }
    }

    override func scrolled(source: TerminalView, position: Double) {
        super.scrolled(source: source, position: position)
        let wasLocked = isScrollLocked
        isScrollLocked = position < 0.999
        if wasLocked != isScrollLocked {
            onScrollStateChanged?(isScrollLocked)
        }
    }

    func scrollToBottom() {
        isScrollLocked = false
        scroll(toPosition: 1.0)
        onScrollStateChanged?(false)
    }

    func clearBuffer() {
        let bytes = Array("\u{1b}[2J\u{1b}[H\u{1b}[3J".utf8)
        feed(byteArray: ArraySlice(bytes))
    }

    func copyAllOutput() {
        selectAll(self)
        copy(self)
    }
}
