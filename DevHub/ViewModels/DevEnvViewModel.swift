import Foundation
import SwiftUI

@MainActor
class DevEnvViewModel: ObservableObject {
    @Published var tools: [DevTool] = DevEnvViewModel.defaultTools
    @Published var isScanning: Bool = false

    var updatableTools: [DevTool] {
        tools.filter { $0.isInstalled && $0.updateCommand != nil }
    }

    func scanAll() async {
        isScanning = true
        defer { isScanning = false }

        await withTaskGroup(of: (Int, String?, Bool).self) { group in
            for (index, tool) in tools.enumerated() {
                group.addTask {
                    do {
                        let result = try await ShellService.shared.run(tool.versionCommand, timeout: 10)
                        if result.success {
                            let version = Self.parseVersion(from: result.output, toolName: tool.name)
                            return (index, version, true)
                        } else {
                            return (index, nil, false)
                        }
                    } catch {
                        return (index, nil, false)
                    }
                }
            }

            for await (index, version, installed) in group {
                tools[index].installedVersion = version
                tools[index].isInstalled = installed
            }
        }
    }

    func update(_ tool: DevTool) async {
        guard let index = tools.firstIndex(where: { $0.id == tool.id }),
              let command = tool.updateCommand else { return }

        tools[index].isUpdating = true
        tools[index].updateError = nil

        do {
            let result = try await ShellService.shared.run(command, timeout: 300)
            if !result.success {
                tools[index].updateError = result.error.isEmpty ? "Échec de la mise à jour" : result.error
            }
        } catch {
            tools[index].updateError = error.localizedDescription
        }

        tools[index].isUpdating = false

        // Re-scan version after update
        do {
            let result = try await ShellService.shared.run(tool.versionCommand, timeout: 10)
            if result.success {
                tools[index].installedVersion = Self.parseVersion(from: result.output, toolName: tool.name)
                tools[index].isInstalled = true
            }
        } catch {}
    }

    func updateAll() async {
        for tool in tools where tool.updateCommand != nil && tool.isInstalled {
            await update(tool)
        }
    }

    // MARK: - Version Parsing

    nonisolated static func parseVersion(from output: String, toolName: String) -> String {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: "\n").first ?? trimmed

        // Match version patterns like v20.11.0, 3.12.1, 1.76.0, etc.
        let pattern = #"v?\d+\.\d+[\.\d]*"#
        if let range = firstLine.range(of: pattern, options: .regularExpression) {
            return String(firstLine[range])
        }

        // Fallback: return first line if short enough
        if firstLine.count <= 30 {
            return firstLine
        }

        return trimmed
    }

    // MARK: - Default Tools

    static let defaultTools: [DevTool] = [
        DevTool(name: "DevHub", icon: "terminal", versionCommand: "/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' /Applications/DevHub.app/Contents/Info.plist",
                updateCommand: "cd ~/Documents/Perso/DevHub && xcodebuild -project DevHub.xcodeproj -scheme DevHub -configuration Release build && mv /Applications/DevHub.app /tmp/DevHub_old.app 2>/dev/null; cp -R ~/Library/Developer/Xcode/DerivedData/DevHub-*/Build/Products/Release/DevHub.app /Applications/ && rm -rf /tmp/DevHub_old.app && open /Applications/DevHub.app", updateNote: nil),
        DevTool(name: "Node.js", icon: "circle.hexagongrid", versionCommand: "node --version",
                updateCommand: "brew upgrade node", updateNote: nil),
        DevTool(name: "npm", icon: "shippingbox", versionCommand: "npm --version",
                updateCommand: "npm install -g npm@latest", updateNote: nil),
        DevTool(name: "Yarn", icon: "link", versionCommand: "yarn --version",
                updateCommand: "brew upgrade yarn", updateNote: nil),
        DevTool(name: "pnpm", icon: "shippingbox.fill", versionCommand: "pnpm --version",
                updateCommand: "brew upgrade pnpm", updateNote: nil),
        DevTool(name: "Python", icon: "chevron.left.forwardslash.chevron.right", versionCommand: "python3 --version",
                updateCommand: "brew upgrade python", updateNote: nil),
        DevTool(name: "Ruby", icon: "diamond", versionCommand: "ruby --version",
                updateCommand: "brew upgrade ruby", updateNote: nil),
        DevTool(name: "Git", icon: "arrow.triangle.branch", versionCommand: "git --version",
                updateCommand: "brew upgrade git", updateNote: nil),
        DevTool(name: "Xcode", icon: "hammer", versionCommand: "xcodebuild -version",
                updateCommand: nil, updateNote: "App Store"),
        DevTool(name: "Homebrew", icon: "mug", versionCommand: "brew --version",
                updateCommand: "brew update", updateNote: nil),
        DevTool(name: "CocoaPods", icon: "leaf", versionCommand: "pod --version",
                updateCommand: "gem install cocoapods", updateNote: nil),
        DevTool(name: "Docker", icon: "shippingbox.and.arrow.backward", versionCommand: "docker --version",
                updateCommand: nil, updateNote: "Docker Desktop"),
        DevTool(name: "Go", icon: "hare", versionCommand: "go version",
                updateCommand: "brew upgrade go", updateNote: nil),
        DevTool(name: "Rust", icon: "gearshape.2", versionCommand: "rustc --version",
                updateCommand: "rustup update", updateNote: nil),
    ]
}
