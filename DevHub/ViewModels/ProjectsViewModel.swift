import Foundation
import SwiftUI

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var searchText = ""
    @Published var filterType: ProjectType? = nil
    @Published var isScanning = false

    private static var cachedProjects: [Project]?

    init() {
        if let cached = Self.cachedProjects {
            // Recharger les launch commands depuis le JSON
            let savedCommands = PersistenceManager.shared.loadLaunchCommands()
            var updated = cached
            for i in updated.indices {
                if let commands = savedCommands[updated[i].path] {
                    updated[i].launchCommands = commands
                }
            }
            projects = updated
            Self.cachedProjects = updated
        }
    }

    private let scanPaths = [
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Perso").path(),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/vo2").path()
    ]

    private let ignoredDirectories: Set<String> = [
        "node_modules", ".git", "build", "DerivedData", "venv",
        ".venv", "__pycache__", "dist", ".next", ".nuxt", "target",
        "Pods", ".build", ".swiftpm"
    ]

    private let maxDepth = 3

    private let persistence = PersistenceManager.shared

    // MARK: - Computed

    var filteredProjects: [Project] {
        var result = projects
        if let filter = filterType {
            result = result.filter { $0.type == filter }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    /// Groupement 2 niveaux : section (Perso/vo2) → sous-dossier parent → projets
    /// Trié par projet le plus récent dans chaque sous-groupe
    var sectionedProjects: [ProjectSection] {
        let bySection = Dictionary(grouping: filteredProjects) { $0.section }
        return bySection.sorted { $0.key < $1.key }.map { section, projects in
            let byParent = Dictionary(grouping: projects) { $0.parentFolder }
            let subgroups = byParent.map { parent, projs in
                ProjectSubgroup(name: parent, projects: projs.sorted { $0.lastModified > $1.lastModified })
            }
            .sorted {
                // Projets sans dossier (nom vide) à la fin
                if $0.name.isEmpty { return false }
                if $1.name.isEmpty { return true }
                return ($0.projects.first?.lastModified ?? .distantPast) > ($1.projects.first?.lastModified ?? .distantPast)
            }
            return ProjectSection(name: section, subgroups: subgroups)
        }
    }

    // MARK: - Scan

    func scan() async {
        isScanning = true
        var found: [Project] = []

        for scanPath in scanPaths {
            await scanDirectory(path: scanPath, depth: 0, results: &found)
        }

        // Charger les launch commands sauvegardées
        let savedCommands = loadLaunchCommands()
        for i in found.indices {
            if let commands = savedCommands[found[i].path] {
                found[i].launchCommands = commands
            }
        }

        // Tri par dernière modification
        found.sort { $0.lastModified > $1.lastModified }
        projects = found
        Self.cachedProjects = found
        isScanning = false
    }

    private func scanDirectory(path: String, depth: Int, results: inout [Project]) async {
        guard depth < maxDepth else { return }
        let fm = FileManager.default

        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return }

        for item in contents {
            guard !item.hasPrefix(".") || item == ".xcodeproj" || item == ".xcworkspace" else { continue }
            guard !ignoredDirectories.contains(item) else { continue }

            let fullPath = (path as NSString).appendingPathComponent(item)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else { continue }

            // Vérifier si c'est un projet
            if let type = detectProjectType(at: fullPath) {
                let attrs = try? fm.attributesOfItem(atPath: fullPath)
                let lastModified = (attrs?[.modificationDate] as? Date) ?? Date.distantPast

                var project = Project(
                    name: item,
                    path: fullPath,
                    type: type,
                    lastModified: lastModified
                )

                // Git info
                let gitInfo = await fetchGitInfo(at: fullPath)
                project.gitBranch = gitInfo.branch
                project.gitDirty = gitInfo.dirty

                results.append(project)
            } else {
                // Pas un projet → continuer à scanner en profondeur
                await scanDirectory(path: fullPath, depth: depth + 1, results: &results)
            }
        }
    }

    private func detectProjectType(at path: String) -> ProjectType? {
        let fm = FileManager.default

        for type in ProjectType.allCases where type != .unknown {
            // Fichiers marqueurs exacts
            for marker in type.markerFiles {
                let markerPath = (path as NSString).appendingPathComponent(marker)
                if fm.fileExists(atPath: markerPath) {
                    return type
                }
            }

            // Patterns (ex: .xcodeproj)
            for pattern in type.markerPatterns {
                if let contents = try? fm.contentsOfDirectory(atPath: path) {
                    if contents.contains(where: { $0.hasSuffix(pattern) }) {
                        return type
                    }
                }
            }
        }

        return nil
    }

    private func fetchGitInfo(at path: String) async -> (branch: String?, dirty: Bool) {
        let branch: String?
        let dirty: Bool

        do {
            let branchResult = try await ShellService.shared.run(
                "cd \(path.shellEscaped) && git branch --show-current 2>/dev/null",
                timeout: 5
            )
            branch = branchResult.success && !branchResult.output.isEmpty ? branchResult.output : nil

            let statusResult = try await ShellService.shared.run(
                "cd \(path.shellEscaped) && git status --porcelain 2>/dev/null",
                timeout: 5
            )
            dirty = statusResult.success && !statusResult.output.isEmpty
        } catch {
            return (nil, false)
        }

        return (branch, dirty)
    }

    // MARK: - Actions

    func openInVSCode(_ project: Project) {
        Task {
            _ = try? await ShellService.shared.run("open -a 'Visual Studio Code' \(project.path.shellEscaped)")
        }
    }

    func openInTerminal(_ project: Project) {
        Task {
            _ = try? await ShellService.shared.run("open -a Terminal \(project.path.shellEscaped)")
        }
    }

    func openInFinder(_ project: Project) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
    }

    func openInXcode(_ project: Project) {
        Task {
            // Chercher .xcodeproj ou .xcworkspace
            let fm = FileManager.default
            if let contents = try? fm.contentsOfDirectory(atPath: project.path) {
                if let workspace = contents.first(where: { $0.hasSuffix(".xcworkspace") }) {
                    _ = try? await ShellService.shared.run("open \((project.path as NSString).appendingPathComponent(workspace).shellEscaped)")
                    return
                }
                if let xcodeproj = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
                    _ = try? await ShellService.shared.run("open \((project.path as NSString).appendingPathComponent(xcodeproj).shellEscaped)")
                    return
                }
            }
            // Fallback: ouvrir le dossier dans Xcode
            _ = try? await ShellService.shared.run("open -a Xcode \(project.path.shellEscaped)")
        }
    }

    func launchCommand(_ command: LaunchCommand, for project: Project) {
        ProcessManager.shared.start(
            command: command,
            projectName: project.name,
            projectPath: project.path
        )
    }

    // MARK: - Launch Commands persistence

    func saveLaunchCommands(for project: Project) {
        persistence.updateLaunchCommands(for: project.path, commands: project.launchCommands)

        // Mettre à jour le projet en mémoire + cache
        if let index = projects.firstIndex(where: { $0.path == project.path }) {
            projects[index].launchCommands = project.launchCommands
            Self.cachedProjects = projects
        }
    }

    func addLaunchCommand(_ command: LaunchCommand, to project: Project) {
        guard let index = projects.firstIndex(where: { $0.path == project.path }) else { return }
        projects[index].launchCommands.append(command)
        saveLaunchCommands(for: projects[index])
    }

    func removeLaunchCommand(_ command: LaunchCommand, from project: Project) {
        guard let index = projects.firstIndex(where: { $0.path == project.path }) else { return }
        projects[index].launchCommands.removeAll { $0.id == command.id }
        saveLaunchCommands(for: projects[index])
    }

    private func loadLaunchCommands() -> [String: [LaunchCommand]] {
        persistence.loadLaunchCommands()
    }
}

// MARK: - Grouping models

struct ProjectSubgroup: Identifiable {
    let name: String
    let projects: [Project]
    var id: String { name }
}

struct ProjectSection: Identifiable {
    let name: String
    let subgroups: [ProjectSubgroup]
    var id: String { name }
}

// MARK: - String extension for shell escaping

extension String {
    var shellEscaped: String {
        "'" + self.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
