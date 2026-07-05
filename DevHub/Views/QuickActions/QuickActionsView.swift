import SwiftUI

struct QuickActionsView: View {
    @StateObject private var viewModel = QuickActionsViewModel()
    @State private var showAddSheet = false

    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Text("$")
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundStyle(HackerColors.accent)
                        Text("quick_actions --list")
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundStyle(HackerColors.text)
                        BlinkingCursor()
                    }

                    Spacer()

                    Button {
                        showAddSheet = true
                    } label: {
                        Text("+ add")
                            .font(.system(.body, design: .monospaced, weight: .medium))
                    }
                    .hackerButton(color: HackerColors.accentOrange)
                }
                .padding(.horizontal, 4)

                // Grouped actions
                ForEach(viewModel.groupedActions, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text("// --- \(group.category.rawValue.lowercased()) ---")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(HackerColors.textSecondary)

                        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                            ForEach(group.actions) { action in
                                ActionButton(
                                    action: action,
                                    isRunning: viewModel.runningActionID == action.id,
                                    onRun: { input in
                                        Task { await viewModel.run(action, input: input) }
                                    },
                                    onDelete: action.isCustom ? {
                                        withAnimation { viewModel.deleteCustomAction(action) }
                                    } : nil
                                )
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .hackerBackground()
        .sheet(isPresented: $showAddSheet) {
            AddActionSheet { name, icon, command, needsSudo in
                withAnimation {
                    viewModel.addCustomAction(name: name, icon: icon, command: command, needsSudo: needsSudo)
                }
            }
        }
    }
}

#Preview {
    QuickActionsView()
}
