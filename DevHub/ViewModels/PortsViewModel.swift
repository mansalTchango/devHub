import Foundation
import Combine
import SwiftUI

@MainActor
class PortsViewModel: ObservableObject {
    @Published var ports: [PortInfo] = []
    @Published var searchText: String = ""
    @Published var isRefreshing: Bool = false
    @Published var autoRefresh: Bool = false
    @Published var portToKill: PortInfo?

    private var timerCancellable: AnyCancellable?

    var filteredPorts: [PortInfo] {
        guard !searchText.isEmpty else { return ports }
        let query = searchText.lowercased()
        return ports.filter {
            String($0.port).contains(query) ||
            $0.processName.lowercased().contains(query) ||
            String($0.pid).contains(query)
        }
    }

    init() {
        $autoRefresh
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    self.timerCancellable = Timer.publish(every: 5, on: .main, in: .common)
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

    private var cancellables = Set<AnyCancellable>()

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let result = try await ShellService.shared.run("lsof -i -P -n -sTCP:LISTEN")
            guard result.success else { return }
            ports = parseLsof(result.output)
        } catch {
            // silently fail — ports stay as-is
        }
    }

    func kill(_ portInfo: PortInfo) async {
        do {
            let result = try await ShellService.shared.run("kill -9 \(portInfo.pid)")
            if result.success {
                withAnimation(.easeOut(duration: 0.3)) {
                    ports.removeAll { $0.pid == portInfo.pid }
                }
            }
        } catch {
            // kill failed — refresh to show current state
            await refresh()
        }
    }

    private func parseLsof(_ output: String) -> [PortInfo] {
        let lines = output.components(separatedBy: "\n")
        guard lines.count > 1 else { return [] }

        var result: [PortInfo] = []

        // Skip header line
        for line in lines.dropFirst() {
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)
            // lsof columns: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            guard columns.count >= 9 else { continue }

            let processName = String(columns[0])
            let pid = Int(String(columns[1])) ?? 0
            let user = String(columns[2])
            let type = String(columns[7]) // NODE column (TCP/UDP)

            // NAME column: *:PORT or IP:PORT
            let name = String(columns[8])
            let portString = name.components(separatedBy: ":").last ?? ""
            let port = Int(portString) ?? 0

            guard port > 0 else { continue }

            let info = PortInfo(
                port: port,
                pid: pid,
                processName: processName,
                user: user,
                type: type,
                state: "LISTEN"
            )
            result.append(info)
        }

        return result.sorted { $0.port < $1.port }
    }
}
