import SwiftUI

struct MainView: View {
    @State private var selectedModule: Module? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            navBar

            // Content
            if let module = selectedModule {
                moduleView(module)
            } else {
                DashboardView(onSelectModule: { module in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedModule = module
                    }
                })
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .hackerBackground()
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedModule = nil
                }
            } label: {
                Text("~/devhub")
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(selectedModule == nil ? HackerColors.accent : HackerColors.accentBlue)
            }
            .buttonStyle(.plain)

            if let module = selectedModule {
                Text(">")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(HackerColors.textSecondary)

                Text(module.terminalName)
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(HackerColors.accent)
            }

            Spacer()

            // Module quick-nav
            if selectedModule != nil {
                HStack(spacing: 8) {
                    ForEach(Module.allCases) { module in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedModule = module
                            }
                        } label: {
                            Image(systemName: module.icon)
                                .font(.body)
                                .foregroundStyle(selectedModule == module ? module.color : HackerColors.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(selectedModule == module ? module.color.opacity(0.1) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(module.rawValue)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(HackerColors.cardBackground)
        .overlay(
            Rectangle()
                .fill(HackerColors.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Module routing

    @ViewBuilder
    private func moduleView(_ module: Module) -> some View {
        switch module {
        case .cleaner:
            CleanerView()
        case .quickActions:
            QuickActionsView()
        case .projects:
            ProjectsView()
        case .processes:
            ProcessManagerView()
        case .ports:
            PortsView()
        case .devEnv:
            DevEnvView()
        case .system:
            SystemView()
        }
    }
}

#Preview {
    MainView()
}
