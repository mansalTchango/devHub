import SwiftUI

struct GaugeWidget: View {
    let value: Double
    let label: String
    let detail: String
    let icon: String

    private var clampedValue: Double {
        max(0, min(100, value))
    }

    private var gaugeColor: Color {
        if clampedValue > 80 { return HackerColors.accentRed }
        if clampedValue > 60 { return HackerColors.accentOrange }
        return HackerColors.accent
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        gaugeColor.opacity(0.15),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))

                // Value ring
                Circle()
                    .trim(from: 0, to: 0.75 * clampedValue / 100)
                    .stroke(
                        gaugeColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: clampedValue)

                // Center content
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(gaugeColor)
                    Text("\(Int(clampedValue))%")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(gaugeColor)
                }
            }
            .frame(width: 100, height: 100)

            // ASCII bar
            ASCIIProgressBar(value: clampedValue, width: 15)

            Text(label)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(HackerColors.text)

            Text(detail)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
                .lineLimit(1)
        }
    }
}
