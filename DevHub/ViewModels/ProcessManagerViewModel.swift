import Foundation
import Combine

@MainActor
class ProcessManagerViewModel: ObservableObject {
    private let manager = ProcessManager.shared
    private var cancellable: AnyCancellable?

    @Published var expandedProcessIds: Set<UUID> = []
    @Published var searchText: String = ""

    init() {
        cancellable = manager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    var processes: [RunningProcess] {
        manager.processes
    }

    var runningCount: Int {
        manager.runningCount
    }

    /// Groupement par dossier parent (même logique que Projects)
    var groupedByParent: [(parentFolder: String, processes: [RunningProcess])] {
        let grouped = Dictionary(grouping: manager.processes) { $0.parentFolder }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (parentFolder: $0.key, processes: $0.value) }
    }

    var parentFolders: [String] {
        groupedByParent.map(\.parentFolder)
    }

    var isEmpty: Bool {
        manager.processes.isEmpty
    }

    func stop(id: UUID) {
        manager.stop(id: id)
    }

    func restart(id: UUID) {
        manager.restart(id: id)
    }

    func stopAll() {
        manager.stopAll()
    }

    func remove(id: UUID) {
        manager.removeProcess(id: id)
        expandedProcessIds.remove(id)
    }

    func removeAllStopped() {
        manager.removeAllStopped()
        let validIds = Set(manager.processes.map(\.id))
        expandedProcessIds = expandedProcessIds.intersection(validIds)
    }

    func toggleExpanded(_ id: UUID) {
        if expandedProcessIds.contains(id) {
            expandedProcessIds.remove(id)
        } else {
            expandedProcessIds.insert(id)
        }
    }

    var expandedProcesses: [RunningProcess] {
        processes.filter { expandedProcessIds.contains($0.id) }
    }
}
