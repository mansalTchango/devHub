import SwiftUI

struct CleaningTaskCard: View {
    let task: CleaningTask
    let onClean: () -> Void

    private var isDisabled: Bool {
        task.scannedSize == 0 && task.status != .done
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: task.icon)
                .font(.title2)
                .foregroundStyle(colorForStatus)
                .frame(width: 36, height: 36)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(HackerColors.text)
                Text(task.description)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(HackerColors.textSecondary)

                if task.status == .done && task.freedSize > 0 {
                    Text("freed: \(DiskSizeCalculator.formatBytes(task.freedSize))")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundStyle(HackerColors.accent)
                }

                if case .error(let msg) = task.status {
                    Text(msg)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(HackerColors.accentRed)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Size
            Text("[\(DiskSizeCalculator.formatBytes(task.scannedSize))]")
                .font(.system(.body, design: .monospaced, weight: .semibold))
                .foregroundStyle(isDisabled ? HackerColors.textSecondary : HackerColors.text)

            // Action button / status
            Group {
                switch task.status {
                case .scanning:
                    StatusBadge(type: .run, customLabel: "SCAN")
                        .frame(width: 90)
                case .cleaning:
                    StatusBadge(type: .run, customLabel: "CLEAN")
                        .frame(width: 90)
                case .done:
                    StatusBadge(type: .ok, customLabel: "DONE")
                        .frame(width: 90)
                default:
                    Button {
                        onClean()
                    } label: {
                        Text("> clean")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                    }
                    .hackerButton(color: HackerColors.accentRed)
                    .disabled(isDisabled)
                    .frame(width: 90)
                }
            }
        }
        .hackerCard()
        .opacity(isDisabled ? 0.5 : 1.0)
        .animation(.spring(duration: 0.3), value: task.status)
    }

    private var colorForStatus: Color {
        switch task.status {
        case .idle: return HackerColors.textSecondary
        case .scanning: return HackerColors.accentBlue
        case .ready: return HackerColors.text
        case .cleaning: return HackerColors.accentOrange
        case .done: return HackerColors.accent
        case .error: return HackerColors.accentRed
        }
    }
}
