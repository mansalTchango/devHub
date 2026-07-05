import Foundation
import Combine

@MainActor
class SystemViewModel: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var ramUsed: Double = 0
    @Published var ramTotal: Double = 0
    @Published var diskUsed: Double = 0
    @Published var diskTotal: Double = 0
    @Published var batteryLevel: Double = 100
    @Published var isCharging: Bool = false
    @Published var isMonitoring: Bool = false
    @Published var isRefreshing: Bool = false

    var ramPercentage: Double {
        guard ramTotal > 0 else { return 0 }
        return (ramUsed / ramTotal) * 100
    }

    var diskPercentage: Double {
        guard diskTotal > 0 else { return 0 }
        return (diskUsed / diskTotal) * 100
    }

    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init() {
        $isMonitoring
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    self.timerCancellable = Timer.publish(every: 2, on: .main, in: .common)
                        .autoconnect()
                        .sink { [weak self] _ in
                            guard let self else { return }
                            Task { await self.refresh() }
                        }
                } else {
                    self.timerCancellable?.cancel()
                    self.timerCancellable = nil
                }
            }
            .store(in: &cancellables)
    }

    func startMonitoring() {
        Task { await refresh() }
        isMonitoring = true
    }

    func stopMonitoring() {
        isMonitoring = false
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchCPU() }
            group.addTask { await self.fetchRAM() }
            group.addTask { await self.fetchDisk() }
            group.addTask { await self.fetchBattery() }
        }
    }

    private func fetchCPU() async {
        do {
            let result = try await ShellService.shared.run("top -l 1 -n 0 | grep 'CPU usage'", timeout: 10)
            guard result.success else { return }
            cpuUsage = Self.parseCPU(result.output)
        } catch {}
    }

    private func fetchRAM() async {
        do {
            let result = try await ShellService.shared.run("vm_stat", timeout: 10)
            guard result.success else { return }
            let (used, total) = Self.parseRAM(result.output)
            ramUsed = used
            ramTotal = total
        } catch {}
    }

    private func fetchDisk() async {
        do {
            let result = try await ShellService.shared.run("df -h /", timeout: 10)
            guard result.success else { return }
            let (used, total) = Self.parseDisk(result.output)
            diskUsed = used
            diskTotal = total
        } catch {}
    }

    private func fetchBattery() async {
        do {
            let result = try await ShellService.shared.run("pmset -g batt", timeout: 10)
            guard result.success else { return }
            let (level, charging) = Self.parseBattery(result.output)
            batteryLevel = level
            isCharging = charging
        } catch {}
    }

    // MARK: - Parsers

    nonisolated static func parseCPU(_ output: String) -> Double {
        // Format: "CPU usage: 5.26% user, 10.52% sys, 84.21% idle"
        guard let idleRange = output.range(of: #"(\d+\.?\d*)\% idle"#, options: .regularExpression) else {
            return 0
        }
        let idleStr = output[idleRange].replacingOccurrences(of: "% idle", with: "")
        let idle = Double(idleStr) ?? 0
        return max(0, min(100, 100 - idle))
    }

    nonisolated static func parseRAM(_ output: String) -> (used: Double, total: Double) {
        let lines = output.components(separatedBy: "\n")

        // Get page size from first line
        var pageSize: Double = 16384
        if let firstLine = lines.first,
           let sizeRange = firstLine.range(of: #"page size of (\d+)"#, options: .regularExpression) {
            let sizeStr = firstLine[sizeRange]
                .replacingOccurrences(of: "page size of ", with: "")
            pageSize = Double(sizeStr) ?? 16384
        }

        func pageCount(for key: String) -> Double {
            for line in lines {
                if line.contains(key) {
                    let parts = line.components(separatedBy: ":")
                    if parts.count >= 2 {
                        let value = parts[1].trimmingCharacters(in: .whitespaces)
                            .replacingOccurrences(of: ".", with: "")
                        return Double(value) ?? 0
                    }
                }
            }
            return 0
        }

        let free = pageCount(for: "Pages free")
        let active = pageCount(for: "Pages active")
        let inactive = pageCount(for: "Pages inactive")
        let speculative = pageCount(for: "Pages speculative")
        let wired = pageCount(for: "Pages wired down")
        let compressed = pageCount(for: "Pages occupied by compressor")

        let totalPages = free + active + inactive + speculative + wired + compressed
        let usedPages = active + wired + compressed

        let totalGB = (totalPages * pageSize) / (1024 * 1024 * 1024)
        let usedGB = (usedPages * pageSize) / (1024 * 1024 * 1024)

        return (usedGB, totalGB)
    }

    nonisolated static func parseDisk(_ output: String) -> (used: Double, total: Double) {
        // Format: "Filesystem  Size  Used  Avail  Capacity  iused  ifree  %iused  Mounted on"
        let lines = output.components(separatedBy: "\n")
        guard lines.count >= 2 else { return (0, 0) }

        let parts = lines[1].split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 4 else { return (0, 0) }

        func parseSize(_ str: String) -> Double {
            var value = str
            var multiplier: Double = 1
            if value.hasSuffix("Ti") { multiplier = 1024; value = String(value.dropLast(2)) }
            else if value.hasSuffix("Gi") { multiplier = 1; value = String(value.dropLast(2)) }
            else if value.hasSuffix("Mi") { multiplier = 1.0 / 1024; value = String(value.dropLast(2)) }
            else if value.hasSuffix("T") { multiplier = 1024; value = String(value.dropLast()) }
            else if value.hasSuffix("G") { multiplier = 1; value = String(value.dropLast()) }
            else if value.hasSuffix("M") { multiplier = 1.0 / 1024; value = String(value.dropLast()) }
            return (Double(value) ?? 0) * multiplier
        }

        let total = parseSize(String(parts[1]))
        let used = parseSize(String(parts[2]))
        return (used, total)
    }

    nonisolated static func parseBattery(_ output: String) -> (level: Double, charging: Bool) {
        // Format: "-InternalBattery-0 (id=...)	85%; charging; ..."
        var level: Double = 100
        var charging = false

        if let percentRange = output.range(of: #"(\d+)%"#, options: .regularExpression) {
            let percentStr = output[percentRange].replacingOccurrences(of: "%", with: "")
            level = Double(percentStr) ?? 100
        }

        charging = output.contains("charging") && !output.contains("discharging")
            && !output.contains("not charging")

        return (level, charging)
    }
}
