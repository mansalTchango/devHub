import Foundation
import SwiftUI

@MainActor
class QuickActionsViewModel: ObservableObject {
    @Published var actions: [QuickAction] = []
    @Published var runningActionID: UUID?

    init() {
        actions = QuickAction.allActions + CustomActionsStorage.load()
    }

    var groupedActions: [(category: ActionCategory, actions: [QuickAction])] {
        ActionCategory.allCases.compactMap { category in
            let filtered = actions.filter { $0.category == category }
            return filtered.isEmpty ? nil : (category, filtered)
        }
    }

    func addCustomAction(name: String, icon: String, command: String, needsSudo: Bool) {
        let action = QuickAction(
            id: UUID(), name: name, icon: icon, command: command,
            needsSudo: needsSudo, needsInput: false, inputPlaceholder: nil,
            category: .custom, isCustom: true
        )
        actions.append(action)
        CustomActionsStorage.save(actions)
    }

    func deleteCustomAction(_ action: QuickAction) {
        guard action.isCustom else { return }
        actions.removeAll { $0.id == action.id }
        CustomActionsStorage.save(actions)
    }

    func run(_ action: QuickAction, input: String? = nil) async {
        guard let index = actions.firstIndex(where: { $0.id == action.id }) else { return }

        runningActionID = action.id
        actions[index].status = .running

        var command = action.command
        if action.needsInput, let input = input, !input.isEmpty {
            command = command.replacingOccurrences(of: "{input}", with: input)
        }

        do {
            let result: ShellResult
            if action.needsSudo {
                let escaped = command.replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                let script = "do shell script \"\(escaped)\" with administrator privileges"
                result = try await ShellService.shared.run(
                    executable: "/usr/bin/osascript",
                    arguments: ["-e", script],
                    timeout: 60
                )
            } else {
                result = try await ShellService.shared.run(command, timeout: 30)
            }

            if result.success {
                actions[index].status = .success
            } else {
                actions[index].status = .error(result.error.isEmpty ? "Échec (code \(result.exitCode))" : result.error)
            }
        } catch {
            actions[index].status = .error(error.localizedDescription)
        }

        runningActionID = nil

        // Reset status after 2s
        let actionID = action.id
        try? await Task.sleep(for: .seconds(2))
        if let idx = actions.firstIndex(where: { $0.id == actionID }),
           actions[idx].status != .idle {
            withAnimation(.easeOut(duration: 0.3)) {
                actions[idx].status = .idle
            }
        }
    }
}
