import SwiftUI

enum ProjectType: String, CaseIterable, Codable {
    case node = "Node.js"
    case swift = "Swift"
    case python = "Python"
    case rust = "Rust"
    case go = "Go"
    case unknown = "Autre"

    var icon: String {
        switch self {
        case .node: return "cup.and.saucer"
        case .swift: return "swift"
        case .python: return "fossil.shell"
        case .rust: return "gearshape"
        case .go: return "hare"
        case .unknown: return "questionmark.folder"
        }
    }

    var color: Color {
        switch self {
        case .node: return .green
        case .swift: return .orange
        case .python: return .blue
        case .rust: return .brown
        case .go: return .cyan
        case .unknown: return .gray
        }
    }

    /// Fichiers marqueurs pour détecter le type de projet
    var markerFiles: [String] {
        switch self {
        case .node: return ["package.json"]
        case .swift: return ["Package.swift"]
        case .python: return ["requirements.txt", "pyproject.toml", "setup.py"]
        case .rust: return ["Cargo.toml"]
        case .go: return ["go.mod"]
        case .unknown: return []
        }
    }

    /// Patterns glob pour marqueurs (ex: *.xcodeproj)
    var markerPatterns: [String] {
        switch self {
        case .swift: return [".xcodeproj", ".xcworkspace"]
        default: return []
        }
    }
}

struct LaunchCommand: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var command: String
    var environment: LaunchEnvironment

    init(id: UUID = UUID(), label: String, command: String, environment: LaunchEnvironment) {
        self.id = id
        self.label = label
        self.command = command
        self.environment = environment
    }
}

enum LaunchEnvironment: String, CaseIterable, Codable {
    case dev = "Dev"
    case staging = "Staging"
    case prod = "Prod"
    case custom = "Custom"

    var color: Color {
        switch self {
        case .dev: return .green
        case .staging: return .yellow
        case .prod: return .red
        case .custom: return .purple
        }
    }

    var icon: String {
        switch self {
        case .dev: return "play.circle.fill"
        case .staging: return "arrow.triangle.2.circlepath.circle.fill"
        case .prod: return "flame.circle.fill"
        case .custom: return "terminal.fill"
        }
    }
}

struct Project: Identifiable {
    let id: UUID
    let name: String
    let path: String
    let type: ProjectType
    let lastModified: Date
    var gitBranch: String?
    var gitDirty: Bool = false
    var launchCommands: [LaunchCommand] = []

    init(id: UUID = UUID(), name: String, path: String, type: ProjectType, lastModified: Date,
         gitBranch: String? = nil, gitDirty: Bool = false, launchCommands: [LaunchCommand] = []) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.lastModified = lastModified
        self.gitBranch = gitBranch
        self.gitDirty = gitDirty
        self.launchCommands = launchCommands
    }

    /// Path affiché tronqué (remplace le home par ~)
    var displayPath: String {
        path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path(), with: "~")
    }

    /// Date relative (ex: "il y a 2h")
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }

    /// Section racine (Perso ou vo2)
    var section: String {
        if path.contains("/Perso/") { return "Perso" }
        if path.contains("/vo2/") { return "vo2" }
        return "Autre"
    }

    /// Sous-dossier parent (le nom du projet parent)
    /// Ex: ~/Documents/Perso/MonProjet/front → "MonProjet"
    var parentFolder: String {
        let scanRoots = ["/Documents/Perso/", "/Documents/vo2/"]
        for root in scanRoots {
            if let range = path.range(of: root) {
                let relative = String(path[range.upperBound...])
                let components = relative.split(separator: "/")
                // Si 2+ composants → le premier est le dossier parent
                if components.count >= 2 {
                    return String(components[0])
                }
            }
        }
        // Projet directement à la racine du scan path
        return ""
    }
}
