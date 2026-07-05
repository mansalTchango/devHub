import Foundation

enum ShellError: LocalizedError {
    case commandNotFound(String)
    case permissionDenied(String)
    case timeout(TimeInterval)
    case executionFailed(exitCode: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .commandNotFound(let cmd):
            return "Commande introuvable : \(cmd)"
        case .permissionDenied(let detail):
            return "Permission refusée : \(detail)"
        case .timeout(let seconds):
            return "Timeout après \(Int(seconds))s"
        case .executionFailed(let code, let stderr):
            return "Échec (code \(code)) : \(stderr)"
        }
    }
}

struct ShellResult {
    let output: String
    let error: String
    let exitCode: Int32
    var success: Bool { exitCode == 0 }
}

actor ShellService {
    static let shared = ShellService()

    func run(_ command: String, timeout: TimeInterval = 30) async throws -> ShellResult {
        try await run(executable: "/bin/zsh", arguments: ["-l", "-c", command], timeout: timeout)
    }

    func run(executable: String, arguments: [String] = [], timeout: TimeInterval = 30) async throws -> ShellResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            process.environment = ProcessInfo.processInfo.environment

            let timeoutWorkItem = DispatchWorkItem {
                if process.isRunning {
                    process.terminate()
                }
            }
            DispatchQueue.global().asyncAfter(
                deadline: .now() + timeout,
                execute: timeoutWorkItem
            )

            do {
                try process.run()
            } catch {
                timeoutWorkItem.cancel()
                let message = error.localizedDescription
                if message.contains("No such file") {
                    continuation.resume(throwing: ShellError.commandNotFound(executable))
                } else if message.contains("permission") || message.contains("Permission") {
                    continuation.resume(throwing: ShellError.permissionDenied(message))
                } else {
                    continuation.resume(throwing: ShellError.commandNotFound(executable))
                }
                return
            }

            // Read pipe data BEFORE waitUntilExit to avoid deadlock
            // when output exceeds the pipe buffer size (64KB)
            let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            process.waitUntilExit()
            timeoutWorkItem.cancel()

            let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let stderr = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if process.terminationReason == .uncaughtSignal {
                continuation.resume(throwing: ShellError.timeout(timeout))
                return
            }

            let result = ShellResult(output: output, error: stderr, exitCode: process.terminationStatus)
            continuation.resume(returning: result)
        }
    }
}
