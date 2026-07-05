import Foundation
import SwiftTerm

enum ProcessStatus: String {
    case running = "En cours"
    case stopped = "Arrêté"
    case errored = "Erreur"
    case finished = "Terminé"

    var color: String {
        switch self {
        case .running: return "green"
        case .stopped: return "gray"
        case .errored: return "red"
        case .finished: return "blue"
        }
    }
}

@MainActor
class RunningProcess: Identifiable, ObservableObject {
    let id: UUID
    let projectName: String
    let projectPath: String
    let command: LaunchCommand
    let startedAt: Date
    let terminalView: EnhancedTerminalView
    let paneState = TerminalPaneState()

    @Published var status: ProcessStatus = .running
    @Published var exitCode: Int32?

    init(
        id: UUID = UUID(),
        projectName: String,
        projectPath: String,
        command: LaunchCommand,
        terminalView: EnhancedTerminalView
    ) {
        self.id = id
        self.projectName = projectName
        self.projectPath = projectPath
        self.command = command
        self.startedAt = Date()
        self.terminalView = terminalView
    }

    /// Même logique que Project.parentFolder
    var parentFolder: String {
        let scanRoots = ["/Documents/Perso/", "/Documents/vo2/"]
        for root in scanRoots {
            if let range = projectPath.range(of: root) {
                let relative = String(projectPath[range.upperBound...])
                let components = relative.split(separator: "/")
                if components.count >= 2 {
                    return String(components[0])
                }
            }
        }
        return projectName
    }

    var runningDuration: TimeInterval {
        Date().timeIntervalSince(startedAt)
    }

    var formattedDuration: String {
        let interval = Int(runningDuration)
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        if hours > 0 {
            return String(format: "%dh%02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm%02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
