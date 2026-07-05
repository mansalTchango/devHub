import SwiftUI

struct DevEnvView: View {
    @StateObject private var viewModel = DevEnvViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text("$")
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.accent)
                    Text("brew list --versions")
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.text)
                    BlinkingCursor()
                }

                Spacer()

                Button {
                    Task { await viewModel.updateAll() }
                } label: {
                    Text("> update --all")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .hackerButton(color: HackerColors.accentOrange)
                .disabled(viewModel.updatableTools.isEmpty || viewModel.isScanning)

                Button {
                    Task { await viewModel.scanAll() }
                } label: {
                    Text("> scan")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .hackerButton(color: HackerColors.accent)
                .disabled(viewModel.isScanning)
            }
            .padding(20)

            TerminalSeparator()
                .padding(.horizontal, 20)

            // List
            if viewModel.tools.allSatisfy({ !$0.isInstalled }) && !viewModel.isScanning {
                ContentUnavailableView(
                    "no tools detected",
                    systemImage: "wrench.and.screwdriver",
                    description: Text("Run a scan to detect your development tools")
                )
                .foregroundStyle(HackerColors.textSecondary)
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.tools) { tool in
                            ToolRow(tool: tool) {
                                Task { await viewModel.update(tool) }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }

            if viewModel.isScanning {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("detecting tools...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(HackerColors.textSecondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
            }
        }
        .hackerBackground()
        .task {
            await viewModel.scanAll()
        }
    }
}

// MARK: - ToolRow

private struct ToolRow: View {
    let tool: DevTool
    let onUpdate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tool.icon)
                .font(.title3)
                .foregroundStyle(tool.isInstalled ? HackerColors.accent : HackerColors.textSecondary)
                .frame(width: 28)

            Text(tool.name)
                .font(.system(.body, design: .monospaced, weight: .medium))
                .foregroundStyle(HackerColors.text)
                .frame(minWidth: 100, alignment: .leading)

            versionBadge
                .frame(minWidth: 120, alignment: .leading)

            Spacer()

            if tool.isUpdating {
                ProgressView()
                    .controlSize(.small)
            } else if let error = tool.updateError {
                StatusBadge(type: .err)
                    .help(error)
            }

            updateAction
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(HackerColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private var versionBadge: some View {
        if tool.isInstalled, let version = tool.installedVersion {
            Text("v\(version)")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(HackerColors.accent)
        } else {
            Text("-- not found --")
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(HackerColors.textSecondary)
        }
    }

    @ViewBuilder
    private var updateAction: some View {
        if tool.updateCommand != nil && tool.isInstalled {
            Button {
                onUpdate()
            } label: {
                Text("> update")
                    .font(.system(.caption, design: .monospaced, weight: .medium))
            }
            .hackerButton(color: HackerColors.accentBlue)
            .disabled(tool.isUpdating)
        } else if let note = tool.updateNote {
            Text(note)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
                .padding(.horizontal, 8)
        }
    }
}

#Preview {
    DevEnvView()
}
