import Foundation

enum CleaningTaskStatus: Equatable {
    case idle
    case scanning
    case ready
    case cleaning
    case done
    case error(String)
}

struct CleaningTask: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let command: String
    let targetPaths: [String]
    var status: CleaningTaskStatus = .idle
    var scannedSize: UInt64 = 0
    var freedSize: UInt64 = 0

    static let allTasks: [CleaningTask] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path()
        return [
            CleaningTask(
                id: UUID(),
                name: "Xcode DerivedData",
                description: "Fichiers de build Xcode",
                icon: "hammer",
                command: "rm -rf \(home)/Library/Developer/Xcode/DerivedData/*",
                targetPaths: ["\(home)/Library/Developer/Xcode/DerivedData"]
            ),
            CleaningTask(
                id: UUID(),
                name: "Simulateurs",
                description: "Simulateurs obsolètes",
                icon: "iphone",
                command: "xcrun simctl delete unavailable",
                targetPaths: []
            ),
            CleaningTask(
                id: UUID(),
                name: "iOS DeviceSupport",
                description: "Fichiers de support iOS",
                icon: "internaldrive",
                command: "rm -rf \(home)/Library/Developer/Xcode/iOS\\ DeviceSupport/*",
                targetPaths: ["\(home)/Library/Developer/Xcode/iOS DeviceSupport"]
            ),
            CleaningTask(
                id: UUID(),
                name: "Cache Yarn",
                description: "Cache du gestionnaire de paquets Yarn",
                icon: "shippingbox",
                command: "yarn cache clean",
                targetPaths: ["\(home)/Library/Caches/Yarn"]
            ),
            CleaningTask(
                id: UUID(),
                name: "Cache Arc",
                description: "Cache du navigateur Arc",
                icon: "globe",
                command: "rm -rf \(home)/Library/Caches/Arc/*",
                targetPaths: ["\(home)/Library/Caches/Arc"]
            ),
            CleaningTask(
                id: UUID(),
                name: "Cache CocoaPods",
                description: "Cache du gestionnaire CocoaPods",
                icon: "leaf",
                command: "pod cache clean --all",
                targetPaths: ["\(home)/Library/Caches/CocoaPods"]
            ),
            CleaningTask(
                id: UUID(),
                name: "Caches misc",
                description: "Cypress, Playwright, TypeScript",
                icon: "trash",
                command: "rm -rf \(home)/Library/Caches/Cypress \(home)/Library/Caches/ms-playwright \(home)/Library/Caches/typescript",
                targetPaths: [
                    "\(home)/Library/Caches/Cypress",
                    "\(home)/Library/Caches/ms-playwright",
                    "\(home)/Library/Caches/typescript"
                ]
            )
        ]
    }()
}
