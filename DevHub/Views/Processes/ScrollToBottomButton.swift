import SwiftUI

struct ScrollToBottomButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down.to.line")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.green)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .shadow(color: .green.opacity(0.3), radius: 4)
        .help("Retour en bas (auto-scroll)")
        .transition(.scale.combined(with: .opacity))
    }
}
