import SwiftUI
import SwiftTerm
import UniformTypeIdentifiers

struct ResizableTerminalGrid: View {
    let processes: [RunningProcess]
    let onClose: (UUID) -> Void

    // Proportions for column widths (normalized 0-1)
    @State private var columnSplit: CGFloat = 0.5
    // Proportions for row heights per column (normalized 0-1 within each column)
    @State private var rowSplits: [Int: [CGFloat]] = [:]
    // Custom process order (array of IDs)
    @State private var processOrder: [UUID] = []
    // Currently dragged process
    @State private var draggedProcessId: UUID?

    /// Processes sorted by custom order
    private var orderedProcesses: [RunningProcess] {
        if processOrder.isEmpty {
            return processes
        }
        let processMap = Dictionary(uniqueKeysWithValues: processes.map { ($0.id, $0) })
        var ordered: [RunningProcess] = []
        for id in processOrder {
            if let p = processMap[id] {
                ordered.append(p)
            }
        }
        // Append any new processes not yet in order
        for p in processes where !processOrder.contains(p.id) {
            ordered.append(p)
        }
        return ordered
    }

    /// Sync processOrder when processes change
    private func syncOrder() {
        let currentIds = Set(processes.map(\.id))
        let orderedIds = Set(processOrder)
        // Remove stale IDs
        processOrder = processOrder.filter { currentIds.contains($0) }
        // Add new IDs
        for p in processes where !orderedIds.contains(p.id) {
            processOrder.append(p.id)
        }
    }

    var body: some View {
        GeometryReader { geo in
            if processes.isEmpty {
                EmptyView()
            } else if processes.count == 1 {
                terminalPane(process: processes[0], size: geo.size)
            } else {
                let sorted = orderedProcesses
                let (leftCol, rightCol) = splitIntoColumns(sorted)
                HStack(spacing: 0) {
                    // Left column
                    columnView(processes: leftCol, columnIndex: 0, size: CGSize(
                        width: geo.size.width * columnSplit,
                        height: geo.size.height
                    ))
                    .frame(width: geo.size.width * columnSplit)

                    // Vertical divider (draggable)
                    if !rightCol.isEmpty {
                        verticalDivider(totalWidth: geo.size.width)

                        // Right column
                        columnView(processes: rightCol, columnIndex: 1, size: CGSize(
                            width: geo.size.width * (1 - columnSplit),
                            height: geo.size.height
                        ))
                        .frame(width: geo.size.width * (1 - columnSplit) - 6)
                    }
                }
            }
        }
        .onAppear { syncOrder() }
        .onChange(of: processes.map(\.id)) { _, _ in syncOrder() }
    }

    // MARK: - Column layout

    private func splitIntoColumns(_ items: [RunningProcess]) -> ([RunningProcess], [RunningProcess]) {
        if items.count <= 1 {
            return (items, [])
        }
        let mid = (items.count + 1) / 2
        return (Array(items.prefix(mid)), Array(items.suffix(from: mid)))
    }

    private func columnView(processes: [RunningProcess], columnIndex: Int, size: CGSize) -> some View {
        let splits = effectiveRowSplits(count: processes.count, columnIndex: columnIndex)

        return VStack(spacing: 0) {
            ForEach(Array(processes.enumerated()), id: \.element.id) { index, process in
                let height = size.height * splits[index]

                terminalPane(process: process, size: CGSize(width: size.width, height: height))
                    .frame(height: height)

                if index < processes.count - 1 {
                    horizontalDivider(columnIndex: columnIndex, rowIndex: index, totalCount: processes.count, totalHeight: size.height)
                }
            }
        }
    }

    // MARK: - Terminal pane

    private func terminalPane(process: RunningProcess, size: CGSize) -> some View {
        VStack(spacing: 0) {
            // Mini header (draggable for reordering)
            HStack(spacing: 6) {
                // Drag handle
                if processes.count > 1 {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 12)
                }

                Circle()
                    .fill(process.status == .running ? .green : .gray)
                    .frame(width: 6, height: 6)

                Text(process.projectName)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .lineLimit(1)

                Text(process.command.label)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Button {
                    onClose(process.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .help("Fermer")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                draggedProcessId == process.id
                    ? Color.accentColor.opacity(0.15)
                    : Color(nsColor: .controlBackgroundColor).opacity(0.5)
            )
            .onDrag {
                draggedProcessId = process.id
                return NSItemProvider(object: process.id.uuidString as NSString)
            }
            .onDrop(of: [UTType.text], delegate: TerminalDropDelegate(
                targetId: process.id,
                processOrder: $processOrder,
                draggedId: $draggedProcessId,
                rowSplits: $rowSplits
            ))

            TerminalContentView(process: process)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    draggedProcessId == process.id
                        ? Color.accentColor.opacity(0.5)
                        : Color.secondary.opacity(0.2),
                    lineWidth: draggedProcessId == process.id ? 2 : 1
                )
        )
    }

    // MARK: - Draggable dividers

    private func verticalDivider(totalWidth: CGFloat) -> some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 6)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newSplit = columnSplit + value.translation.width / totalWidth
                        columnSplit = min(max(newSplit, 0.2), 0.8)
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }

    private func horizontalDivider(columnIndex: Int, rowIndex: Int, totalCount: Int, totalHeight: CGFloat) -> some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 6)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        var splits = effectiveRowSplits(count: totalCount, columnIndex: columnIndex)
                        let delta = value.translation.height / totalHeight

                        let newTop = splits[rowIndex] + delta
                        let newBottom = splits[rowIndex + 1] - delta

                        if newTop >= 0.1 && newBottom >= 0.1 {
                            splits[rowIndex] = newTop
                            splits[rowIndex + 1] = newBottom
                            rowSplits[columnIndex] = splits
                        }
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

    // MARK: - Row splits management

    private func effectiveRowSplits(count: Int, columnIndex: Int) -> [CGFloat] {
        if let existing = rowSplits[columnIndex], existing.count == count {
            return existing
        }
        // Equal distribution
        let equal = 1.0 / CGFloat(count)
        return Array(repeating: equal, count: count)
    }
}

// MARK: - Terminal content (observes paneState for live updates)

private struct TerminalContentView: View {
    let process: RunningProcess
    @ObservedObject var paneState: TerminalPaneState

    init(process: RunningProcess) {
        self.process = process
        self.paneState = process.paneState
    }

    var body: some View {
        VStack(spacing: 0) {
            TerminalToolbar(
                paneState: paneState,
                onSearch: { query, forward in
                    if forward {
                        process.terminalView.findNext(query)
                    } else {
                        process.terminalView.findPrevious(query)
                    }
                },
                onClearSearch: {
                    process.terminalView.clearSearch()
                },
                onClear: {
                    process.terminalView.clearBuffer()
                },
                onCopyAll: {
                    process.terminalView.copyAllOutput()
                }
            )

            ZStack(alignment: .bottomTrailing) {
                TerminalViewWrapper(
                    terminalView: process.terminalView,
                    fontSize: paneState.fontSize
                )

                if paneState.isScrollLocked {
                    ScrollToBottomButton {
                        process.terminalView.scrollToBottom()
                    }
                    .padding(8)
                }
            }
        }
    }
}

// MARK: - Drop delegate for terminal reordering

struct TerminalDropDelegate: DropDelegate {
    let targetId: UUID
    @Binding var processOrder: [UUID]
    @Binding var draggedId: UUID?
    @Binding var rowSplits: [Int: [CGFloat]]

    func performDrop(info: DropInfo) -> Bool {
        draggedId = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedId, dragged != targetId else { return }
        guard let fromIndex = processOrder.firstIndex(of: dragged),
              let toIndex = processOrder.firstIndex(of: targetId) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            processOrder.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            // Reset row splits since layout changed
            rowSplits = [:]
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        draggedId != nil
    }
}
