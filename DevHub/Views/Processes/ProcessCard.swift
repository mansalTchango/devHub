import SwiftUI

struct ProcessCard: View {
    @ObservedObject var process: RunningProcess
    let isExpanded: Bool
    let onToggle: () -> Void
    let onStop: () -> Void
    let onRestart: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            // Status badge CLI style
            statusLabel

            VStack(alignment: .leading, spacing: 1) {
                Text(process.projectName)
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(HackerColors.text)
                    .lineLimit(1)

                Text(process.command.label)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(HackerColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Expand indicator
            Image(systemName: isExpanded ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle")
                .font(.caption2)
                .foregroundStyle(isExpanded ? HackerColors.accentPurple : HackerColors.textSecondary)

            // Duration style HH:mm:ss
            Text(process.formattedDuration)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
                .onReceive(timer) { _ in
                    now = Date()
                }

            // Action buttons
            HStack(spacing: 4) {
                if process.status == .running {
                    actionButton("stop.fill", color: HackerColors.accentRed, help: "Arrêter", action: onStop)
                    actionButton("arrow.counterclockwise", color: HackerColors.accentOrange, help: "Redémarrer", action: onRestart)
                } else {
                    actionButton("arrow.counterclockwise", color: HackerColors.accent, help: "Relancer", action: onRestart)
                    actionButton("xmark", color: HackerColors.textSecondary, help: "Retirer", action: onRemove)
                }
            }
        }
        .hackerCard(
            borderColor: isExpanded ? HackerColors.accentPurple.opacity(0.4) : (isHovered ? statusColor.opacity(0.3) : HackerColors.border),
            padding: 10
        )
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var statusColor: Color {
        switch process.status {
        case .running: return HackerColors.accent
        case .stopped: return HackerColors.textSecondary
        case .errored: return HackerColors.accentRed
        case .finished: return HackerColors.accentBlue
        }
    }

    private var statusLabel: some View {
        Group {
            switch process.status {
            case .running:
                StatusBadge(type: .run, customLabel: "RUNNING")
            case .stopped:
                StatusBadge(type: .stopped, customLabel: "STOPPED")
            case .errored:
                StatusBadge(type: .err, customLabel: "ERROR")
            case .finished:
                StatusBadge(type: .ok, customLabel: "DONE")
            }
        }
    }

    private func actionButton(_ icon: String, color: Color, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
