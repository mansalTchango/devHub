import SwiftUI

/// Icône barre menus + compteur de process actifs
struct MenuBarLabel: View {
    @ObservedObject private var processManager = ProcessManager.shared

    var body: some View {
        let count = processManager.runningCount
        HStack(spacing: 3) {
            Image(systemName: count > 0 ? "terminal.fill" : "terminal")
            if count > 0 {
                Text("\(count)")
            }
        }
    }
}

/// Panneau flottant style Centre de contrôle
struct MenuBarPanel: View {
    @ObservedObject private var projectsVM = ProjectsViewModel.shared
    @ObservedObject private var processManager = ProcessManager.shared
    @Environment(\.openWindow) private var openWindow

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private let maxVisibleProjects = 8

    private var runningProcesses: [RunningProcess] {
        processManager.processes.filter { $0.status == .running }
    }

    private var visibleProjects: [Project] {
        Array(projectsVM.menuBarProjects(matching: query).prefix(maxVisibleProjects))
    }

    var body: some View {
        VStack(spacing: 10) {
            searchField

            if !runningProcesses.isEmpty {
                section(title: "EN COURS (\(runningProcesses.count))") {
                    ForEach(runningProcesses) { process in
                        MenuBarRunningRow(process: process) {
                            openMainWindow(on: .processes)
                        }
                    }
                }
            }

            section(title: query.isEmpty ? "ÉPINGLÉS / RÉCENTS" : "RÉSULTATS") {
                if projectsVM.isScanning && projectsVM.projects.isEmpty {
                    placeholder("Scan des projets…")
                } else if visibleProjects.isEmpty {
                    placeholder(query.isEmpty ? "Aucun projet trouvé" : "Aucun résultat")
                } else {
                    ForEach(visibleProjects) { project in
                        MenuBarProjectRow(
                            project: project,
                            isPinned: projectsVM.isPinned(project),
                            isRunning: runningProcesses.contains { $0.projectPath == project.path },
                            defaultCommand: projectsVM.defaultCommand(for: project),
                            onRun: { projectsVM.launchCommand($0, for: project) },
                            onTogglePin: { projectsVM.togglePin(project) },
                            onConfigure: { openMainWindow(on: .projects) },
                            onOpenVSCode: { projectsVM.openInVSCode(project) },
                            onOpenTerminal: { projectsVM.openInTerminal(project) },
                            onOpenFinder: { projectsVM.openInFinder(project) }
                        )
                    }
                }
            }

            footer
        }
        .padding(12)
        .frame(width: 340)
        .task {
            if projectsVM.projects.isEmpty {
                await projectsVM.scan()
            }
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Rechercher un projet…", text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit(runFirstResult)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .menuBarTile()
    }

    /// Entrée = lance la commande par défaut du premier résultat
    private func runFirstResult() {
        guard let project = visibleProjects.first,
              let command = projectsVM.defaultCommand(for: project) else { return }
        projectsVM.launchCommand(command, for: project)
        query = ""
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                processManager.stopAll()
            } label: {
                Label("Stop all", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(runningProcesses.isEmpty)

            Button {
                openMainWindow(on: nil)
            } label: {
                Label("Ouvrir DevHub", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .help("Quitter DevHub (arrête tous les process)")
        }
        .buttonStyle(MenuBarTileButtonStyle())
        .font(.caption.weight(.medium))
    }

    // MARK: - Helpers

    private func openMainWindow(on module: Module?) {
        if let module {
            AppRouter.shared.requestedModule = module
        }
        openWindow(id: AppRouter.mainWindowID)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 2)
            content()
        }
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .menuBarTile()
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
    }
}

// MARK: - Style tuiles

private struct MenuBarTileModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
            )
    }
}

extension View {
    func menuBarTile() -> some View {
        modifier(MenuBarTileModifier())
    }
}

struct MenuBarTileButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
            .menuBarTile()
    }
}
