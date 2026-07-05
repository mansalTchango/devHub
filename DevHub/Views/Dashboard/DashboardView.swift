import SwiftUI

struct DashboardView: View {
    let onSelectModule: (Module) -> Void

    @StateObject private var portsVM = PortsViewModel()
    @StateObject private var systemVM = SystemViewModel()
    @StateObject private var projectsVM = ProjectsViewModel()
    @ObservedObject private var processManager = ProcessManager.shared

    @State private var sessionStart = Date()
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 8) {
                    Text(">")
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.accent)
                    Text("devhub")
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.text)
                    BlinkingCursor()
                    Spacer()
                }

                // Quick Stats
                quickStatsBar

                TerminalSeparator()

                // Module Grid
                Text("// modules")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(HackerColors.textSecondary)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Module.allCases) { module in
                        ModuleCard(module: module, stat: statFor(module)) {
                            onSelectModule(module)
                        }
                    }
                }

                TerminalSeparator()

                // Footer
                footerBar
            }
            .padding(20)
        }
        .hackerBackground()
        .task {
            await portsVM.refresh()
            if projectsVM.projects.isEmpty {
                await projectsVM.scan()
            }
            systemVM.startMonitoring()
        }
        .onDisappear {
            systemVM.stopMonitoring()
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }

    // MARK: - Quick Stats

    private var quickStatsBar: some View {
        HStack(spacing: 16) {
            statItem(label: "uptime", value: formatUptime())
            statItem(label: "projects", value: "\(projectsVM.projects.count)")
            statItem(label: "ports", value: "\(portsVM.filteredPorts.count)")
            statItem(label: "processes", value: "\(processManager.processes.filter { $0.status == .running }.count)")
            statItem(label: "cpu", value: String(format: "%.0f%%", systemVM.cpuUsage))
            statItem(label: "ram", value: String(format: "%.0f%%", systemVM.ramPercentage))
        }
        .hackerCard(padding: 12)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .monospaced, weight: .bold))
                .foregroundStyle(HackerColors.accent)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Module stat

    private func statFor(_ module: Module) -> String {
        switch module {
        case .cleaner: return "cache scan"
        case .quickActions: return "12 actions"
        case .projects: return "\(projectsVM.projects.count) repos"
        case .processes:
            let running = processManager.processes.filter { $0.status == .running }.count
            return "\(running) running"
        case .ports: return "\(portsVM.filteredPorts.count) ports"
        case .devEnv: return "13 tools"
        case .system: return String(format: "cpu %.0f%%", systemVM.cpuUsage)
        }
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Text(hostInfo())
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
            Spacer()
            Text(timeString())
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(HackerColors.textSecondary)
        }
    }

    // MARK: - Helpers

    private func formatUptime() -> String {
        let interval = now.timeIntervalSince(sessionStart)
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func hostInfo() -> String {
        let host = Host.current().localizedName ?? "mac"
        let version = ProcessInfo.processInfo.operatingSystemVersionString
        return "\(host) | macOS \(version)"
    }

    private func timeString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: now)
    }
}

// MARK: - Module Card

private struct ModuleCard: View {
    let module: Module
    let stat: String
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: module.icon)
                    .font(.title2)
                    .foregroundStyle(module.color)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(module.terminalName)
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                        .foregroundStyle(HackerColors.text)

                    Text(stat)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(HackerColors.textSecondary)
                }

                Spacer()

                Text(">")
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundStyle(isHovered ? module.color : HackerColors.border)
            }
            .hackerCard(borderColor: isHovered ? module.color : HackerColors.border)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    DashboardView(onSelectModule: { _ in })
}
