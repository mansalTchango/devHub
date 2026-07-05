import SwiftUI

struct PortsView: View {
    @StateObject private var viewModel = PortsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text("$")
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.accent)
                    Text("lsof -i -P | grep LISTEN")
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.text)
                    BlinkingCursor()
                }

                Spacer()

                Toggle("auto_refresh", isOn: $viewModel.autoRefresh)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(HackerColors.textSecondary)

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Text("> refresh")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .hackerButton(color: HackerColors.accent)
                .disabled(viewModel.isRefreshing)
            }
            .padding(20)

            // Search
            HStack {
                Text(">")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(HackerColors.accent)
                TextField("grep...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(HackerColors.text)
            }
            .padding(8)
            .background(HackerColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(HackerColors.border, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Table header — netstat style
            HStack(spacing: 0) {
                Text("PORT")
                    .frame(width: 80, alignment: .leading)
                Text("PROCESS")
                    .frame(minWidth: 120, alignment: .leading)
                Text("PID")
                    .frame(width: 70, alignment: .leading)
                Text("USER")
                    .frame(width: 80, alignment: .leading)
                Text("TYPE")
                    .frame(width: 60, alignment: .leading)
                Text("STATE")
                    .frame(width: 100, alignment: .leading)
                Spacer()
                Text("ACTION")
                    .frame(width: 70, alignment: .center)
            }
            .font(.system(.caption, design: .monospaced, weight: .bold))
            .foregroundStyle(HackerColors.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(HackerColors.cardBackground)

            // List
            if viewModel.filteredPorts.isEmpty && !viewModel.isRefreshing {
                ContentUnavailableView(
                    viewModel.searchText.isEmpty ? "no ports listening" : "no results",
                    systemImage: viewModel.searchText.isEmpty ? "network.slash" : "magnifyingglass",
                    description: Text(viewModel.searchText.isEmpty
                        ? "No TCP ports in LISTEN state detected"
                        : "Try another filter")
                )
                .foregroundStyle(HackerColors.textSecondary)
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.filteredPorts) { portInfo in
                            PortRow(portInfo: portInfo) {
                                viewModel.portToKill = portInfo
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }

            if viewModel.isRefreshing {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("scanning ports...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(HackerColors.textSecondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
            }
        }
        .hackerBackground()
        .task {
            await viewModel.refresh()
        }
        .confirmationDialog(
            "Terminer le processus ?",
            isPresented: Binding(
                get: { viewModel.portToKill != nil },
                set: { if !$0 { viewModel.portToKill = nil } }
            ),
            presenting: viewModel.portToKill
        ) { portInfo in
            Button("Kill \(portInfo.processName) (PID \(portInfo.pid))", role: .destructive) {
                Task { await viewModel.kill(portInfo) }
            }
            Button("Annuler", role: .cancel) {}
        } message: { portInfo in
            Text("Le process \(portInfo.processName) sur le port \(portInfo.port) sera terminé (kill -9).")
        }
        .animation(.default, value: viewModel.filteredPorts)
    }
}

// MARK: - PortRow

private struct PortRow: View {
    let portInfo: PortInfo
    let onKill: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("\(portInfo.port)")
                .font(.system(.body, design: .monospaced, weight: .bold))
                .foregroundStyle(HackerColors.accent)
                .frame(width: 80, alignment: .leading)

            Text(portInfo.processName)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(HackerColors.text)
                .frame(minWidth: 120, alignment: .leading)
                .lineLimit(1)

            Text("\(portInfo.pid)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
                .frame(width: 70, alignment: .leading)

            Text(portInfo.user)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
                .frame(width: 80, alignment: .leading)
                .lineLimit(1)

            Text(portInfo.type)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
                .frame(width: 60, alignment: .leading)

            stateBadge
                .frame(width: 100, alignment: .leading)

            Spacer()

            Button {
                onKill()
            } label: {
                Text("[KILL]")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(HackerColors.accentRed)
            }
            .buttonStyle(.plain)
            .frame(width: 70)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(HackerColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private var stateBadge: some View {
        let badgeType: BadgeType = switch portInfo.state {
        case "LISTEN": .listen
        case "ESTABLISHED": .ok
        default: .info
        }

        StatusBadge(type: badgeType, customLabel: portInfo.state)
    }
}

#Preview {
    PortsView()
}
