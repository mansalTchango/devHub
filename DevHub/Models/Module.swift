import SwiftUI

enum Module: String, CaseIterable, Identifiable {
    case cleaner = "Cleaner"
    case quickActions = "Quick Actions"
    case projects = "Projects"
    case processes = "Processes"
    case ports = "Ports"
    case devEnv = "Dev Environment"
    case system = "System Monitor"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cleaner: return "trash.circle"
        case .quickActions: return "bolt.circle"
        case .projects: return "folder"
        case .processes: return "terminal.fill"
        case .ports: return "network"
        case .devEnv: return "gearshape.2"
        case .system: return "gauge.with.dots.needle.bottom.50percent"
        }
    }

    var terminalName: String {
        switch self {
        case .cleaner: return "mac_cleaner"
        case .quickActions: return "quick_actions"
        case .projects: return "projects"
        case .processes: return "processes"
        case .ports: return "ports"
        case .devEnv: return "dev_env"
        case .system: return "system_monitor"
        }
    }

    var terminalCommand: String {
        switch self {
        case .cleaner: return "$ mac_cleaner --scan"
        case .quickActions: return "$ quick_actions --list"
        case .projects: return "$ projects --scan"
        case .processes: return "$ ps aux"
        case .ports: return "$ lsof -i -P | grep LISTEN"
        case .devEnv: return "$ brew list --versions"
        case .system: return "$ system_monitor --live"
        }
    }

    var description: String {
        switch self {
        case .cleaner: return "Nettoyez les caches et libérez de l'espace"
        case .quickActions: return "Actions rapides pour macOS"
        case .projects: return "Lancez et gérez vos projets"
        case .processes: return "Process lancés depuis DevHub"
        case .ports: return "Gérez les ports réseau actifs"
        case .devEnv: return "Versions et outils de développement"
        case .system: return "Moniteur système en temps réel"
        }
    }

    var color: Color {
        switch self {
        case .cleaner: return HackerColors.accentRed
        case .quickActions: return HackerColors.accentOrange
        case .projects: return HackerColors.accentBlue
        case .processes: return HackerColors.accentPurple
        case .ports: return HackerColors.accent
        case .devEnv: return Color(hex: 0x3FB950) // vert dev
        case .system: return HackerColors.accentOrange
        }
    }
}
