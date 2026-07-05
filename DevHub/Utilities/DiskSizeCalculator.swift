import Foundation

struct DiskSizeCalculator {
    /// Calcule taille d'un dossier en bytes
    static func sizeOfDirectory(at path: String) async -> UInt64 {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fileManager = FileManager.default
                var isDir: ObjCBool = false

                guard fileManager.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
                    continuation.resume(returning: 0)
                    return
                }

                var totalSize: UInt64 = 0
                guard let enumerator = fileManager.enumerator(
                    at: URL(fileURLWithPath: path),
                    includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    continuation.resume(returning: 0)
                    return
                }

                for case let fileURL as URL in enumerator {
                    guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                          resourceValues.isRegularFile == true,
                          let fileSize = resourceValues.fileSize else {
                        continue
                    }
                    totalSize += UInt64(fileSize)
                }

                continuation.resume(returning: totalSize)
            }
        }
    }

    /// Formate bytes en string lisible (ex: "39.2 Go")
    static func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1.0 {
            return String(format: "%.1f Go", gb)
        }
        let mb = Double(bytes) / 1_048_576
        if mb >= 1.0 {
            return String(format: "%.1f Mo", mb)
        }
        let kb = Double(bytes) / 1_024
        return String(format: "%.0f Ko", kb)
    }

    /// Vérifie si un dossier existe
    static func directoryExists(at path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}
