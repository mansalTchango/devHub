import Foundation

enum ActionCategory: String, CaseIterable, Codable {
    case system = "Système"
    case dev = "Développement"
    case cleanup = "Nettoyage"
    case custom = "Custom"
}

enum ActionStatus: Equatable {
    case idle
    case running
    case success
    case error(String)
}

struct QuickAction: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let command: String
    let needsSudo: Bool
    let needsInput: Bool
    let inputPlaceholder: String?
    let category: ActionCategory
    let isCustom: Bool
    var status: ActionStatus = .idle

    static let allActions: [QuickAction] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path()
        return [
            // Système
            QuickAction(
                id: UUID(), name: "Flush DNS", icon: "network.badge.shield.half.filled",
                command: "dscacheutil -flushcache && killall -HUP mDNSResponder",
                needsSudo: true, needsInput: false, inputPlaceholder: nil,
                category: .system, isCustom: false
            ),
            QuickAction(
                id: UUID(), name: "Restart Dock", icon: "dock.rectangle",
                command: "killall Dock",
                needsSudo: false, needsInput: false, inputPlaceholder: nil,
                category: .system, isCustom: false
            ),
            QuickAction(
                id: UUID(), name: "Purge RAM", icon: "memorychip",
                command: "purge",
                needsSudo: true, needsInput: false, inputPlaceholder: nil,
                category: .system, isCustom: false
            ),
            QuickAction(
                id: UUID(), name: "Restart Finder", icon: "folder.badge.gearshape",
                command: "killall Finder",
                needsSudo: false, needsInput: false, inputPlaceholder: nil,
                category: .system, isCustom: false
            ),
            QuickAction(
                id: UUID(), name: "Restart Audio", icon: "speaker.wave.3",
                command: "killall coreaudiod",
                needsSudo: true, needsInput: false, inputPlaceholder: nil,
                category: .system, isCustom: false
            ),
            // Développement
            QuickAction(
                id: UUID(), name: "Kill Port", icon: "network",
                command: "lsof -ti:{input} | xargs kill -9",
                needsSudo: false, needsInput: true, inputPlaceholder: "Numéro de port (ex: 3000)",
                category: .dev, isCustom: false
            ),
            QuickAction(
                id: UUID(), name: "Kill Xcode", icon: "hammer",
                command: "killall Xcode",
                needsSudo: false, needsInput: false, inputPlaceholder: nil,
                category: .dev, isCustom: false
            ),
            QuickAction(
                id: UUID(), name: "Rebuild Spotlight", icon: "magnifyingglass",
                command: "mdutil -E /",
                needsSudo: true, needsInput: false, inputPlaceholder: nil,
                category: .dev, isCustom: false
            ),
            // Nettoyage
            QuickAction(
                id: UUID(), name: "Vider Corbeille", icon: "trash",
                command: "rm -rf ~/.Trash/*",
                needsSudo: false, needsInput: false, inputPlaceholder: nil,
                category: .cleanup, isCustom: false
            ),
            QuickAction(
                id: UUID(), name: "Clear Downloads 30j+", icon: "arrow.down.circle",
                command: "find \(home)/Downloads -mtime +30 -maxdepth 1 -delete",
                needsSudo: false, needsInput: false, inputPlaceholder: nil,
                category: .cleanup, isCustom: false
            ),
        ]
    }()
}

// MARK: - Persistance UserDefaults pour actions custom

struct StoredAction: Codable {
    let id: UUID
    let name: String
    let icon: String
    let command: String
    let needsSudo: Bool

    func toQuickAction() -> QuickAction {
        QuickAction(
            id: id, name: name, icon: icon, command: command,
            needsSudo: needsSudo, needsInput: false, inputPlaceholder: nil,
            category: .custom, isCustom: true
        )
    }

    static func from(_ action: QuickAction) -> StoredAction {
        StoredAction(id: action.id, name: action.name, icon: action.icon,
                     command: action.command, needsSudo: action.needsSudo)
    }
}

enum CustomActionsStorage {
    static func load() -> [QuickAction] {
        PersistenceManager.shared.loadCustomActions().map { $0.toQuickAction() }
    }

    static func save(_ actions: [QuickAction]) {
        let stored = actions.filter(\.isCustom).map(StoredAction.from)
        PersistenceManager.shared.saveCustomActions(stored)
    }
}
