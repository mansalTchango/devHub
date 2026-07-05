import SwiftUI

struct ProcessManagerView: View {
    @StateObject private var viewModel = ProcessManagerViewModel()
    @State private var showStopAllConfirmation = false
    @State private var selectedParentFolder: String?
    @State private var listHeight: CGFloat = 200
    @State private var isTerminalFullscreen = false

    private var availableFolders: [String] {
        viewModel.parentFolders
    }

    private var currentFolder: String? {
        if let selected = selectedParentFolder, availableFolders.contains(selected) {
            return selected
        }
        return availableFolders.first
    }

    private var currentProcesses: [RunningProcess] {
        guard let folder = currentFolder else { return [] }
        return viewModel.groupedByParent.first { $0.parentFolder == folder }?.processes ?? []
    }

    private func runningCount(for folder: String) -> Int {
        viewModel.groupedByParent.first { $0.parentFolder == folder }?.processes.filter { $0.status == .running }.count ?? 0
    }

    private func processCount(for folder: String) -> Int {
        viewModel.groupedByParent.first { $0.parentFolder == folder }?.processes.count ?? 0
    }

    private var currentExpandedProcesses: [RunningProcess] {
        let currentIds = Set(currentProcesses.map(\.id))
        return viewModel.expandedProcesses.filter { currentIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isTerminalFullscreen {
                fullscreenTerminalView
            } else {
                normalView
            }
        }
        .hackerBackground()
        .alert("Tout arrêter ?", isPresented: $showStopAllConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Arrêter tout", role: .destructive) {
                viewModel.stopAll()
            }
        } message: {
            Text("Tous les process en cours seront terminés.")
        }
        .onChange(of: availableFolders) { _, folders in
            if let current = selectedParentFolder, !folders.contains(current) {
                selectedParentFolder = folders.first
            }
        }
    }

    // MARK: - Normal view

    private var normalView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Text("$")
                            .font(.system(.title2, design: .monospaced, weight: .bold))
                            .foregroundStyle(HackerColors.accent)
                        Text("ps aux")
                            .font(.system(.title2, design: .monospaced, weight: .bold))
                            .foregroundStyle(HackerColors.text)
                    }

                    if viewModel.runningCount > 0 {
                        StatusBadge(type: .run, customLabel: "\(viewModel.runningCount) ACTIVE")
                    }

                    Spacer()

                    if !viewModel.isEmpty {
                        HStack(spacing: 8) {
                            if !currentExpandedProcesses.isEmpty {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isTerminalFullscreen = true
                                    }
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.caption)
                                        .foregroundStyle(HackerColors.text)
                                }
                                .buttonStyle(.plain)
                                .help("Plein écran terminaux")
                            }

                            if viewModel.processes.contains(where: { $0.status != .running }) {
                                Button {
                                    viewModel.removeAllStopped()
                                } label: {
                                    Text("> clean")
                                        .font(.system(.caption, design: .monospaced))
                                }
                                .hackerButton(color: HackerColors.textSecondary)
                            }

                            if viewModel.runningCount > 0 {
                                Button {
                                    showStopAllConfirmation = true
                                } label: {
                                    Text("> kill -9 *")
                                        .font(.system(.caption, design: .monospaced))
                                }
                                .hackerButton(color: HackerColors.accentRed)
                            }
                        }
                    }
                }

                // Tabs par projet parent
                if availableFolders.count > 1 {
                    HStack(spacing: 0) {
                        ForEach(availableFolders, id: \.self) { folder in
                            parentTab(folder)
                        }
                    }
                    .background(HackerColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(HackerColors.border, lineWidth: 1)
                    )
                }
            }
            .padding()

            TerminalSeparator()
                .padding(.horizontal)

            // Content
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "no processes",
                    systemImage: "terminal",
                    description: Text("Launch a command from a project to see it here")
                )
                .foregroundStyle(HackerColors.textSecondary)
            } else {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(currentProcesses) { process in
                                    ProcessCard(
                                        process: process,
                                        isExpanded: viewModel.expandedProcessIds.contains(process.id),
                                        onToggle: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.toggleExpanded(process.id)
                                            }
                                        },
                                        onStop: { viewModel.stop(id: process.id) },
                                        onRestart: { viewModel.restart(id: process.id) },
                                        onRemove: { viewModel.remove(id: process.id) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .frame(height: currentExpandedProcesses.isEmpty ? nil : min(listHeight, geo.size.height * 0.5))

                        if !currentExpandedProcesses.isEmpty {
                            listTerminalDivider(totalHeight: geo.size.height)

                            ResizableTerminalGrid(
                                processes: currentExpandedProcesses,
                                onClose: { id in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.toggleExpanded(id)
                                    }
                                }
                            )
                            .padding(4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Fullscreen terminal view

    private var fullscreenTerminalView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isTerminalFullscreen = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.caption)
                        Text("exit fullscreen")
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                    }
                    .foregroundStyle(HackerColors.text)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(currentExpandedProcesses.count) terminal\(currentExpandedProcesses.count > 1 ? "s" : "")")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(HackerColors.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(HackerColors.cardBackground)

            ResizableTerminalGrid(
                processes: currentExpandedProcesses,
                onClose: { id in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleExpanded(id)
                    }
                    if currentExpandedProcesses.count <= 1 {
                        isTerminalFullscreen = false
                    }
                }
            )
            .padding(2)
        }
    }

    // MARK: - List/Terminal divider

    private func listTerminalDivider(totalHeight: CGFloat) -> some View {
        Rectangle()
            .fill(HackerColors.border)
            .frame(height: 6)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newHeight = listHeight + value.translation.height
                        listHeight = min(max(newHeight, 80), totalHeight * 0.6)
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
    }

    // MARK: - Parent folder tab

    private func parentTab(_ folder: String) -> some View {
        let isSelected = currentFolder == folder
        let running = runningCount(for: folder)
        let total = processCount(for: folder)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedParentFolder = folder
            }
        } label: {
            HStack(spacing: 6) {
                Text("[\(folder.lowercased())]")
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))

                HStack(spacing: 4) {
                    if running > 0 {
                        Text("\u{25CF}")
                            .font(.system(size: 8))
                            .foregroundStyle(HackerColors.accent)
                    }
                    Text("\(total)")
                        .font(.system(.caption2, design: .monospaced, weight: .medium))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? HackerColors.accentPurple.opacity(0.2) : HackerColors.border.opacity(0.5))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? HackerColors.accentPurple.opacity(0.08) : .clear)
            .foregroundStyle(isSelected ? HackerColors.accentPurple : HackerColors.textSecondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProcessManagerView()
}
