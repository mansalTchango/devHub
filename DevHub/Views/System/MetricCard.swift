import SwiftUI

struct MetricCard: View {
    let value: Double
    let label: String
    let detail: String
    let icon: String
    let isAlert: Bool

    var body: some View {
        VStack(spacing: 12) {
            GaugeWidget(
                value: value,
                label: label,
                detail: detail,
                icon: icon
            )

            if isAlert {
                Text("[!!! \(label) > \(label == "BATTERY" ? "LOW" : "\(Int(value))%") !!!]")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(HackerColors.accentRed)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(HackerColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(alertBorderColor, lineWidth: isAlert ? 2 : 1)
        )
        .modifier(PulseModifier(isActive: isAlert))
    }

    private var alertBorderColor: Color {
        if isAlert {
            return value > 90 ? HackerColors.accentRed : HackerColors.accentOrange
        }
        return HackerColors.border
    }
}

private struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive && isPulsing ? 0.85 : 1.0)
            .animation(
                isActive
                    ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onChange(of: isActive) { _, newValue in
                isPulsing = newValue
            }
            .onAppear {
                if isActive { isPulsing = true }
            }
    }
}
