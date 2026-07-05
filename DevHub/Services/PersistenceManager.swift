import Foundation

struct DevHubData: Codable {
    var launchCommands: [String: [LaunchCommand]] = [:]
    var customActions: [StoredAction] = []
}

final class PersistenceManager {
    static let shared = PersistenceManager()

    private let directoryURL: URL
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        directoryURL = home.appendingPathComponent(".devhub")
        fileURL = directoryURL.appendingPathComponent("devhub.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()

        ensureDirectory()
    }

    // MARK: - Core

    func load() -> DevHubData {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let migrated = migrateFromUserDefaults()
            save(migrated)
            return migrated
        }

        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode(DevHubData.self, from: data) else {
            return DevHubData()
        }
        return decoded
    }

    func save(_ data: DevHubData) {
        guard let jsonData = try? encoder.encode(data) else { return }
        try? jsonData.write(to: fileURL, options: .atomic)
    }

    // MARK: - Launch Commands

    func loadLaunchCommands() -> [String: [LaunchCommand]] {
        load().launchCommands
    }

    func saveLaunchCommands(_ commands: [String: [LaunchCommand]]) {
        var data = load()
        data.launchCommands = commands
        save(data)
    }

    func updateLaunchCommands(for projectPath: String, commands: [LaunchCommand]) {
        var data = load()
        data.launchCommands[projectPath] = commands
        save(data)
    }

    // MARK: - Custom Actions

    func loadCustomActions() -> [StoredAction] {
        load().customActions
    }

    func saveCustomActions(_ actions: [StoredAction]) {
        var data = load()
        data.customActions = actions
        save(data)
    }

    // MARK: - Private

    private func ensureDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: directoryURL.path) {
            try? fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }

    private func migrateFromUserDefaults() -> DevHubData {
        var data = DevHubData()
        let defaults = UserDefaults.standard

        // Migrate launch commands
        if let raw = defaults.data(forKey: "ProjectLaunchCommands"),
           let commands = try? JSONDecoder().decode([String: [LaunchCommand]].self, from: raw) {
            data.launchCommands = commands
        }

        // Migrate custom actions
        if let raw = defaults.data(forKey: "devhub.quickactions.custom"),
           let actions = try? JSONDecoder().decode([StoredAction].self, from: raw) {
            data.customActions = actions
        }

        return data
    }
}
