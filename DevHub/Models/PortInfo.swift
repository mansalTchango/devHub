import Foundation

struct PortInfo: Identifiable, Equatable {
    let id = UUID()
    let port: Int
    let pid: Int
    let processName: String
    let user: String
    let type: String       // TCP/UDP
    let state: String      // LISTEN, ESTABLISHED, etc.

    static func == (lhs: PortInfo, rhs: PortInfo) -> Bool {
        lhs.port == rhs.port && lhs.pid == rhs.pid && lhs.processName == rhs.processName
    }
}
