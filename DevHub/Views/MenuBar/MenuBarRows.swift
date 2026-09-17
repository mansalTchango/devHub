import SwiftUI

// MARK: - Projet (épinglé / récent)

struct MenuBarProjectRow: View {
    let project: Project
    let isPinned: Bool
    let isRunning: Bool
    let defaultCommand: LaunchCommand?
    let onRun: (LaunchCommand) -> Void
    let onTogglePin: () -> Void
    let onConfigure: () -> Void
    let onOpenVSCode: () -> Void
    let onOpenTerminal: () -> Void
    let onOpenFinder: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: project.type.icon)
                .font(.caption)
                .foregroundStyle(project.type.color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(project.name)
                        .font(.system(.callout, weight: .medium))
                        .lineLimit(1)
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    if isRunning {
                        Circle()
                            .fill(HackerColors.accent)
                            .frame(width: 6, height: 6)
                    }
                }
                if let branch = project.gitBranch {
                    Text(branch + (project.gitDirty ? " ●" : ""))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if isHovered {
                Button(action: onTogglePin) {
                    Image(systemName: isPinned ? "pin.slash" : "pin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(isPinned ? "Désépingler" : "Épingler")
            }

            runControl
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.primary.opacity(isHovered ? 0.08 : 0))
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Ouvrir dans VS Code", action: onOpenVSCode)
            Button("Ouvrir dans Terminal", action: onOpenTerminal)
            Button("Afficher dans Finder", action: onOpenFinder)
            Divider()
            Button(isPinned ? "Désépingler" : "Épingler", action: onTogglePin)
            Button("Configurer les commandes…", action: onConfigure)
        }
    }

    @ViewBuilder
    private var runControl: some View {
        if let command = defaultCommand {
            HStack(spacing: 0) {
                Button {
                    onRun(command)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                        Text(command.label)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, project.launchCommands.count > 1 ? 4 : 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(command.command)

                if project.launchCommands.count > 1 {
                    Menu {
                        ForEach(project.launchCommands) { other in
                            Button("\(other.label) — \(other.environment.rawValue)") {
                                onRun(other)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .padding(.trailing, 6)
                }
            }
            .foregroundStyle(HackerColors.accent)
            .background(HackerColors.accent.opacity(0.14), in: Capsule())
        } else {
            Button(action: onConfigure) {
                Text("Configurer")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.primary.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
            .help("Aucune commande de lancement — configurer dans DevHub")
        }
    }
}

// MARK: - Process en cours

struct MenuBarRunningRow: View {
    @ObservedObject var process: RunningProcess
    let onOpen: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(HackerColors.accent)
                .frame(width: 7, height: 7)
                .frame(width: 18)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(process.projectName)
                        .font(.system(.callout, weight: .medium))
                        .lineLimit(1)
                    // TimelineView : durée rafraîchie sans timer manuel
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text("\(process.command.label) · \(process.formattedDuration)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Voir le terminal dans DevHub")

            Button {
                ProcessManager.shared.restart(id: process.id)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Redémarrer")

            Button {
                ProcessManager.shared.stop(id: process.id)
            } label: {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(HackerColors.accentRed)
            .help("Arrêter")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.primary.opacity(isHovered ? 0.08 : 0))
        )
        .onHover { isHovered = $0 }
    }
}
