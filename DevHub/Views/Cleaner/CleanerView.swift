import SwiftUI

struct CleanerView: View {
    @StateObject private var viewModel = CleanerViewModel()
    @State private var showCleanAllConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("$")
                                .font(.system(.title, design: .monospaced, weight: .bold))
                                .foregroundStyle(HackerColors.accent)
                            Text("mac_cleaner --scan")
                                .font(.system(.title, design: .monospaced, weight: .bold))
                                .foregroundStyle(HackerColors.text)
                            BlinkingCursor()
                        }

                        if viewModel.isScanning {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("scanning...")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundStyle(HackerColors.textSecondary)
                            }
                        } else {
                            Text("total_reclaimable: \(DiskSizeCalculator.formatBytes(viewModel.totalScanned))")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(HackerColors.textSecondary)
                        }

                        if viewModel.totalFreed > 0 {
                            Text("freed: \(DiskSizeCalculator.formatBytes(viewModel.totalFreed))")
                                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                                .foregroundStyle(HackerColors.accent)
                        }
                    }

                    Spacer()

                    Button {
                        showCleanAllConfirmation = true
                    } label: {
                        Text("> clean --all")
                            .font(.system(.body, design: .monospaced, weight: .medium))
                    }
                    .hackerButton(color: HackerColors.accentRed)
                    .disabled(viewModel.isScanning || viewModel.totalScanned == 0)
                    .confirmationDialog(
                        "Nettoyer tous les caches ?",
                        isPresented: $showCleanAllConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Tout nettoyer", role: .destructive) {
                            Task { await viewModel.cleanAll() }
                        }
                        Button("Annuler", role: .cancel) {}
                    } message: {
                        Text("Cette action va supprimer \(DiskSizeCalculator.formatBytes(viewModel.totalScanned)) de caches. Cette opération est irréversible.")
                    }
                }
                .padding(.horizontal, 4)

                // Task cards
                ForEach(viewModel.tasks) { task in
                    CleaningTaskCard(task: task) {
                        Task { await viewModel.clean(task) }
                    }
                }
            }
            .padding(20)
        }
        .hackerBackground()
        .task {
            await viewModel.scanAll()
        }
    }
}

#Preview {
    CleanerView()
}
