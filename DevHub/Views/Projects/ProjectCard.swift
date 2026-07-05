import SwiftUI

struct ProjectCard: View {
    let project: Project
    var runningProcessCount: Int = 0
    let onOpenVSCode: () -> Void
    let onOpenTerminal: () -> Void
    let onOpenFinder: () -> Void
    let onOpenXcode: (() -> Void)?
    let onLaunch: (LaunchCommand) -> Void
    let onConfigureCommands: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Type icon
            Image(systemName: project.type.icon)
                .font(.subheadline)
                .foregroundStyle(project.type.color)
                .frame(width: 24, height: 24)

            // Name + path + meta
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(project.name)
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                        .foregroundStyle(HackerColors.text)
                        .lineLimit(1)

                    if runningProcessCount > 0 {
                        StatusBadge(type: .run, customLabel: "\(runningProcessCount) RUN")
                    }

                    Text(project.type.rawValue.lowercased())
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(HackerColors.textSecondary)

                    if let branch = project.gitBranch {
                        HStack(spacing: 3) {
                            Text("\u{2387}")
                                .font(.system(.caption2, design: .monospaced))
                            Text(branch)
                                .font(.system(.caption2, design: .monospaced))
                            Text(project.gitDirty ? "\u{25CF}" : "\u{25CB}")
                                .font(.system(size: 8))
                                .foregroundStyle(project.gitDirty ? HackerColors.accentOrange : HackerColors.accent)
                        }
                        .foregroundStyle(HackerColors.textSecondary)
                    }

                    Text(project.relativeDate)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(HackerColors.textSecondary)
                }

                Text(project.displayPath)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(HackerColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Launch commands
            if !project.launchCommands.isEmpty {
                HStack(spacing: 4) {
                    ForEach(project.launchCommands) { command in
                        Button {
                            onLaunch(command)
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: command.environment.icon)
                                    .font(.system(size: 9))
                                Text(command.label)
                                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(command.environment.color.opacity(0.15))
                            .foregroundStyle(command.environment.color)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(command.command)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 4) {
                iconButton("chevron.left.forwardslash.chevron.right", action: onOpenVSCode, help: "VS Code")
                iconButton("terminal", action: onOpenTerminal, help: "Terminal")
                iconButton("folder", action: onOpenFinder, help: "Finder")

                if let onXcode = onOpenXcode {
                    iconButton("hammer", action: onXcode, help: "Xcode")
                }

                iconButton("gearshape", action: onConfigureCommands, help: "Commandes")
                    .foregroundStyle(HackerColors.textSecondary)
            }
        }
        .hackerCard(borderColor: isHovered ? project.type.color.opacity(0.5) : HackerColors.border, padding: 10)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private func iconButton(_ icon: String, action: @escaping () -> Void, help: String) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(isHovered ? HackerColors.accent : HackerColors.textSecondary)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
