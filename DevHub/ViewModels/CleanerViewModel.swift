import Foundation
import SwiftUI

@MainActor
class CleanerViewModel: ObservableObject {
    @Published var tasks: [CleaningTask] = CleaningTask.allTasks
    @Published var isScanning = false
    @Published var totalFreed: UInt64 = 0

    var totalScanned: UInt64 {
        tasks.reduce(0) { $0 + $1.scannedSize }
    }

    func scanAll() async {
        isScanning = true
        for i in tasks.indices {
            tasks[i].status = .scanning
            var size: UInt64 = 0
            for path in tasks[i].targetPaths {
                size += await DiskSizeCalculator.sizeOfDirectory(at: path)
            }
            tasks[i].scannedSize = size
            tasks[i].status = size > 0 ? .ready : .idle
        }
        isScanning = false
    }

    func clean(_ task: CleaningTask) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let sizeBefore = tasks[index].scannedSize
        tasks[index].status = .cleaning

        do {
            let result = try await ShellService.shared.run(tasks[index].command, timeout: 120)
            if result.success || tasks[index].targetPaths.isEmpty {
                // Recalculate size after cleaning
                var sizeAfter: UInt64 = 0
                for path in tasks[index].targetPaths {
                    sizeAfter += await DiskSizeCalculator.sizeOfDirectory(at: path)
                }
                let freed = sizeBefore > sizeAfter ? sizeBefore - sizeAfter : sizeBefore
                tasks[index].freedSize = freed
                withAnimation(.spring(duration: 0.4)) {
                    totalFreed += freed
                }
                tasks[index].scannedSize = sizeAfter
                tasks[index].status = .done
            } else {
                tasks[index].status = .error(result.error.isEmpty ? "Échec (code \(result.exitCode))" : result.error)
            }
        } catch {
            tasks[index].status = .error(error.localizedDescription)
        }
    }

    func cleanAll() async {
        for task in tasks where task.status == .ready {
            await clean(task)
        }
    }
}
