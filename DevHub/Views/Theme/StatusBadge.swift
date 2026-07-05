import SwiftUI

enum BadgeType {
    case ok
    case run
    case warn
    case err
    case info
    case listen
    case stopped

    var label: String {
        switch self {
        case .ok: return "OK"
        case .run: return "RUN"
        case .warn: return "WARN"
        case .err: return "ERR"
        case .info: return "INFO"
        case .listen: return "LISTEN"
        case .stopped: return "STOP"
        }
    }

    var color: Color {
        switch self {
        case .ok: return HackerColors.accent
        case .run: return HackerColors.accentBlue
        case .warn: return HackerColors.accentOrange
        case .err: return HackerColors.accentRed
        case .info: return HackerColors.accentPurple
        case .listen: return HackerColors.accentBlue
        case .stopped: return HackerColors.textSecondary
        }
    }
}

struct StatusBadge: View {
    let type: BadgeType
    var customLabel: String? = nil

    var body: some View {
        Text("[\(customLabel ?? type.label)]")
            .font(.system(.caption, design: .monospaced, weight: .bold))
            .foregroundStyle(type.color)
    }
}

#Preview {
    VStack(spacing: 8) {
        StatusBadge(type: .ok)
        StatusBadge(type: .run)
        StatusBadge(type: .warn)
        StatusBadge(type: .err)
        StatusBadge(type: .info)
        StatusBadge(type: .listen)
        StatusBadge(type: .stopped)
        StatusBadge(type: .run, customLabel: "RUNNING")
    }
    .padding()
    .background(HackerColors.background)
}
