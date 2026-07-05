import Foundation
import AppKit
import SwiftTerm
import Combine

@MainActor
class ProcessManager: ObservableObject {
    static let shared = ProcessManager()

    @Published var processes: [RunningProcess] = []

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stopAll()
            }
        }
    }

    var runningCount: Int {
        processes.filter { $0.status == .running }.count
    }

    func start(command: LaunchCommand, projectName: String, projectPath: String) {
        let terminalView = EnhancedTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 400))

        let runningProcess = RunningProcess(
            projectName: projectName,
            projectPath: projectPath,
            command: command,
            terminalView: terminalView
        )

        terminalView.onScrollStateChanged = { [weak runningProcess] locked in
            Task { @MainActor in
                runningProcess?.paneState.isScrollLocked = locked
            }
        }

        let delegate = ProcessTerminalDelegate(process: runningProcess)
        terminalView.processDelegate = delegate
        objc_setAssociatedObject(terminalView, &AssociatedKeys.delegate, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        var env = ProcessInfo.processInfo.environment
        let nodeModulesBin = (projectPath as NSString).appendingPathComponent("node_modules/.bin")
        let home = NSHomeDirectory()
        let pnpmBin = "\(home)/Library/pnpm"
        if let path = env["PATH"] {
            env["PATH"] = "\(nodeModulesBin):\(pnpmBin):/usr/local/bin:/opt/homebrew/bin:" + path
        }

        // Source nvm if available so projects use the correct Node version
        let nvmInit = "[ -s \"$HOME/.nvm/nvm.sh\" ] && source \"$HOME/.nvm/nvm.sh\" && nvm use 2>/dev/null;"
        let wrappedCommand = "\(nvmInit) cd \(projectPath.shellEscaped) && \(command.command)"

        terminalView.startProcess(
            executable: "/bin/zsh",
            args: ["-l", "-c", wrappedCommand],
            environment: env.map { "\($0.key)=\($0.value)" },
            execName: command.label
        )

        processes.append(runningProcess)
    }

    func stop(id: UUID) {
        guard let process = processes.first(where: { $0.id == id }),
              process.status == .running else { return }

        // Send Ctrl+C (SIGINT) via the terminal
        let ctrlC: [UInt8] = [0x03]
        process.terminalView.send(ctrlC)

        // If still running after 3s, send EOF and mark stopped
        let processId = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self,
                  let proc = self.processes.first(where: { $0.id == processId }),
                  proc.status == .running else { return }
            // Send Ctrl+\ (SIGQUIT) as stronger signal
            let ctrlBackslash: [UInt8] = [0x1C]
            proc.terminalView.send(ctrlBackslash)
            proc.status = .stopped
        }
    }

    func restart(id: UUID) {
        guard let process = processes.first(where: { $0.id == id }) else { return }
        let command = process.command
        let projectName = process.projectName
        let projectPath = process.projectPath

        stop(id: id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.removeProcess(id: id)
            self?.start(command: command, projectName: projectName, projectPath: projectPath)
        }
    }

    func stopAll() {
        for process in processes where process.status == .running {
            let ctrlC: [UInt8] = [0x03]
            process.terminalView.send(ctrlC)
            process.status = .stopped
        }
    }

    func removeProcess(id: UUID) {
        processes.removeAll { $0.id == id && $0.status != .running }
    }

    func removeAllStopped() {
        processes.removeAll { $0.status != .running }
    }
}

// MARK: - Associated object key
private enum AssociatedKeys {
    nonisolated(unsafe) static var delegate = 0
}

// MARK: - Terminal Delegate
class ProcessTerminalDelegate: NSObject, LocalProcessTerminalViewDelegate {
    private weak var process: RunningProcess?

    init(process: RunningProcess) {
        self.process = process
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        Task { @MainActor [weak self] in
            guard let process = self?.process else { return }
            process.exitCode = exitCode
            if process.status == .running {
                process.status = (exitCode == 0) ? .finished : .errored
            }
        }
    }
}
