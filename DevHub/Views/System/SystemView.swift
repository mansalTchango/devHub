import SwiftUI

struct SystemView: View {
    @StateObject private var viewModel = SystemViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text("$")
                        .font(.system(.title2, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.accent)
                    Text("system_monitor --live")
                        .font(.system(.title2, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.text)
                    BlinkingCursor()
                }

                Spacer()

                if viewModel.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }

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

            TerminalSeparator()
                .padding(.horizontal, 20)

            // Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    MetricCard(
                        value: viewModel.cpuUsage,
                        label: "CPU",
                        detail: String(format: "%.1f%% usage", viewModel.cpuUsage),
                        icon: "cpu",
                        isAlert: viewModel.cpuUsage > 80
                    )

                    MetricCard(
                        value: viewModel.ramPercentage,
                        label: "RAM",
                        detail: String(format: "%.1f / %.1f Go", viewModel.ramUsed, viewModel.ramTotal),
                        icon: "memorychip",
                        isAlert: viewModel.ramPercentage > 90
                    )

                    MetricCard(
                        value: viewModel.diskPercentage,
                        label: "DISK",
                        detail: String(format: "%.0f / %.0f Go", viewModel.diskUsed, viewModel.diskTotal),
                        icon: "internaldrive",
                        isAlert: viewModel.diskPercentage > 90
                    )

                    MetricCard(
                        value: viewModel.batteryLevel,
                        label: "BATTERY",
                        detail: viewModel.isCharging ? "charging" : "on_battery",
                        icon: viewModel.isCharging ? "battery.100.bolt" : "battery.100",
                        isAlert: viewModel.batteryLevel < 20 && !viewModel.isCharging
                    )
                }
                .padding(20)
            }
        }
        .hackerBackground()
        .task {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}
