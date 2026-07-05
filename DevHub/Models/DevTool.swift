import Foundation

struct DevTool: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let versionCommand: String
    let updateCommand: String?
    let updateNote: String?
    var installedVersion: String?
    var isInstalled: Bool = false
    var isUpdating: Bool = false
    var updateError: String?
}
