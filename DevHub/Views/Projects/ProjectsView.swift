import SwiftUI

struct ProjectsView: View {
    @StateObject private var viewModel = ProjectsViewModel()
    @ObservedObject private var processManager = ProcessManager.shared
    @State private var configuringProject: Project? = nil
    @State private var selectedSection: String = ProjectsView.cachedSection ?? ""
    @State private var expandedSubgroups: Set<String> = ProjectsView.cachedExpandedSubgroups ?? []
    @State private var hasInitializedExpansion = ProjectsView.cachedExpandedSubgroups != nil

    private static var cachedSection: String?
    private static var cachedExpandedSubgroups: Set<String>?

    private var availableSections: [String] {
        viewModel.sectionedProjects.map(\.name)
    }

    private var currentSection: ProjectSection? {
        viewModel.sectionedProjects.first { $0.name == selectedSection }
    }

    private var currentProjectCount: Int {
        currentSection?.subgroups.reduce(0) { $0 + $1.projects.count } ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header fixe
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("$")
                                .font(.system(.title, design: .monospaced, weight: .bold))
                                .foregroundStyle(HackerColors.accent)
                            Text("projects --scan")
                                .font(.system(.title, design: .monospaced, weight: .bold))
                                .foregroundStyle(HackerColors.text)
                            BlinkingCursor()
                        }

                        if viewModel.isScanning {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("scanning...")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundStyle(HackerColors.textSecondary)
                            }
                        } else {
                            Text("\(currentProjectCount) repos found")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(HackerColors.textSecondary)
                        }
                    }

                    Spacer()

                    Button {
                        Task { await viewModel.scan() }
                    } label: {
                        Text("> rescan")
                            .font(.system(.body, design: .monospaced, weight: .medium))
                    }
                    .hackerButton(color: HackerColors.accentBlue)
                    .disabled(viewModel.isScanning)
                }

                // Tabs style git branch
                HStack(spacing: 0) {
                    ForEach(availableSections, id: \.self) { section in
                        sectionTab(section)
                    }
                }
                .background(HackerColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(HackerColors.border, lineWidth: 1)
                )

                // Recherche + filtres
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(HackerColors.textSecondary)
                        TextField("grep...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(HackerColors.text)
                    }
                    .padding(8)
                    .background(HackerColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(HackerColors.border, lineWidth: 1)
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            filterChip(label: "all", type: nil)
                            ForEach(ProjectType.allCases.filter { $0 != .unknown }, id: \.self) { type in
                                filterChip(label: type.rawValue.lowercased(), type: type)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            TerminalSeparator()
                .padding(.horizontal, 20)

            // Contenu scrollable
            ScrollView {
                if let section = currentSection {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(section.subgroups) { subgroup in
                            subgroupView(subgroup)
                        }
                    }
                    .padding(20)
                } else if !viewModel.isScanning {
                    ContentUnavailableView(
                        "Aucun projet trouvé",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Lancez un scan ou ajustez vos filtres")
                    )
                    .padding(.top, 40)
                }
            }
        }
        .hackerBackground()
        .task {
            if viewModel.projects.isEmpty {
                await viewModel.scan()
            }
        }
        .sheet(item: $configuringProject) { project in
            LaunchCommandsSheet(project: project) { updatedProject in
                viewModel.saveLaunchCommands(for: updatedProject)
            }
        }
        .onChange(of: availableSections) { _, sections in
            if selectedSection.isEmpty || !sections.contains(selectedSection), let first = sections.first {
                selectedSection = first
            }
        }
        .onChange(of: selectedSection) { _, newValue in
            Self.cachedSection = newValue
            updateExpandedSubgroups()
        }
        .onChange(of: expandedSubgroups) { _, newValue in
            Self.cachedExpandedSubgroups = newValue
        }
        .onChange(of: viewModel.isScanning) { _, scanning in
            if !scanning && !hasInitializedExpansion {
                updateExpandedSubgroups()
            }
        }
    }

    private func updateExpandedSubgroups() {
        guard let section = currentSection else { return }
        let top3 = section.subgroups.prefix(3).map(\.name)
        expandedSubgroups = Set(top3)
    }

    // MARK: - Section tab

    private func sectionTab(_ name: String) -> some View {
        let isSelected = selectedSection == name
        let count = viewModel.sectionedProjects.first { $0.name == name }?
            .subgroups.reduce(0) { $0 + $1.projects.count } ?? 0

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = name
            }
        } label: {
            HStack(spacing: 6) {
                Text("[\(name.lowercased())]")
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                Text("\(count)")
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? HackerColors.accent.opacity(0.2) : HackerColors.border.opacity(0.5))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? HackerColors.accent.opacity(0.08) : .clear)
            .foregroundStyle(isSelected ? HackerColors.accent : HackerColors.textSecondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subgroup

    private func subgroupView(_ subgroup: ProjectSubgroup) -> some View {
        let isExpanded = subgroup.name.isEmpty || expandedSubgroups.contains(subgroup.name)

        return VStack(alignment: .leading, spacing: 6) {
            if !subgroup.name.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedSubgroups.remove(subgroup.name)
                        } else {
                            expandedSubgroups.insert(subgroup.name)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(isExpanded ? "v" : ">")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(HackerColors.accent)
                            .frame(width: 10)

                        Text(subgroup.name)
                            .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                            .foregroundStyle(HackerColors.text)

                        Text("(\(subgroup.projects.count))")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(HackerColors.textSecondary)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                ForEach(subgroup.projects) { project in
                    ProjectCard(
                        project: project,
                        runningProcessCount: processManager.processes.filter { $0.projectPath == project.path && $0.status == .running }.count,
                        onOpenVSCode: { viewModel.openInVSCode(project) },
                        onOpenTerminal: { viewModel.openInTerminal(project) },
                        onOpenFinder: { viewModel.openInFinder(project) },
                        onOpenXcode: project.type == .swift ? { viewModel.openInXcode(project) } : nil,
                        onLaunch: { command in viewModel.launchCommand(command, for: project) },
                        onConfigureCommands: { configuringProject = project }
                    )
                }
                .padding(.leading, subgroup.name.isEmpty ? 0 : 12)
            }
        }
    }

    // MARK: - Filter chip

    private func filterChip(label: String, type: ProjectType?) -> some View {
        let isSelected = viewModel.filterType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.filterType = type
            }
        } label: {
            Text(label)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? HackerColors.accent : Color.clear)
                .foregroundStyle(isSelected ? HackerColors.background : HackerColors.text)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : HackerColors.border, lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Launch Commands Configuration Sheet

struct LaunchCommandsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var commands: [LaunchCommand]
    @State private var newLabel = ""
    @State private var newCommand = ""
    @State private var newEnvironment: LaunchEnvironment = .dev
    @State private var editingCommandId: UUID? = nil
    @State private var draggingCommandId: UUID? = nil
    @State private var packageScripts: [(key: String, value: String)] = []

    let project: Project
    let onSave: (Project) -> Void

    init(project: Project, onSave: @escaping (Project) -> Void) {
        self.project = project
        self.onSave = onSave
        _commands = State(initialValue: project.launchCommands)
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("launch_commands")
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(HackerColors.text)
                    Text(project.name)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(HackerColors.textSecondary)
                }
                Spacer()
            }

            if !commands.isEmpty {
                VStack(spacing: 8) {
                    ForEach(commands) { command in
                        HStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal")
                                .font(.caption)
                                .foregroundStyle(HackerColors.textSecondary.opacity(0.5))

                            Image(systemName: command.environment.icon)
                                .foregroundStyle(command.environment.color)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(command.label)
                                    .font(.system(.body, design: .monospaced, weight: .medium))
                                    .foregroundStyle(HackerColors.text)
                                Text(command.command)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(HackerColors.textSecondary)
                            }

                            Spacer()

                            Button {
                                editingCommandId = command.id
                                newLabel = command.label
                                newCommand = command.command
                                newEnvironment = command.environment
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundStyle(HackerColors.accentBlue)
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                withAnimation {
                                    commands.removeAll { $0.id == command.id }
                                    if editingCommandId == command.id {
                                        cancelEditing()
                                    }
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(HackerColors.accentRed)
                            }
                            .buttonStyle(.borderless)
                        }
                        .hackerCard(padding: 12)
                        .opacity(draggingCommandId == command.id ? 0.5 : 1)
                        .draggable(command.id.uuidString) {
                            HStack(spacing: 8) {
                                Image(systemName: command.environment.icon)
                                    .foregroundStyle(command.environment.color)
                                Text(command.label)
                                    .font(.system(.body, design: .monospaced, weight: .medium))
                                    .foregroundStyle(HackerColors.text)
                            }
                            .padding(8)
                            .background(HackerColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .onAppear { draggingCommandId = command.id }
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let droppedIdString = items.first,
                                  let droppedId = UUID(uuidString: droppedIdString),
                                  let fromIndex = commands.firstIndex(where: { $0.id == droppedId }),
                                  let toIndex = commands.firstIndex(where: { $0.id == command.id }),
                                  fromIndex != toIndex else { return false }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                commands.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                            }
                            return true
                        } isTargeted: { targeted in
                            if !targeted { draggingCommandId = nil }
                        }
                    }
                }
            }

            TerminalSeparator()

            VStack(alignment: .leading, spacing: 12) {
                Text(editingCommandId != nil ? "// edit command" : "// new command")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(HackerColors.textSecondary)

                HStack(spacing: 12) {
                    Picker("Env", selection: $newEnvironment) {
                        ForEach(LaunchEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                    .frame(width: 100)

                    TextField("Label (ex: Dev)", text: $newLabel)
                        .textFieldStyle(HackerTextFieldStyle())
                        .frame(width: 120)
                }

                TextField("Command (ex: yarn start:dev)", text: $newCommand)
                    .textFieldStyle(HackerTextFieldStyle())

                HStack(spacing: 12) {
                    if editingCommandId != nil {
                        Button {
                            cancelEditing()
                        } label: {
                            Text("x cancel")
                                .font(.system(.body, design: .monospaced, weight: .medium))
                        }
                        .hackerButton(color: HackerColors.textSecondary)
                    }

                    Button {
                        let label = newLabel.isEmpty ? newEnvironment.rawValue : newLabel
                        if let editId = editingCommandId,
                           let idx = commands.firstIndex(where: { $0.id == editId }) {
                            commands[idx] = LaunchCommand(
                                id: editId,
                                label: label,
                                command: newCommand,
                                environment: newEnvironment
                            )
                        } else {
                            let command = LaunchCommand(
                                label: label,
                                command: newCommand,
                                environment: newEnvironment
                            )
                            withAnimation {
                                commands.append(command)
                            }
                        }
                        cancelEditing()
                    } label: {
                        Text(editingCommandId != nil ? "> update" : "+ add")
                            .font(.system(.body, design: .monospaced, weight: .medium))
                    }
                    .hackerButton(color: HackerColors.accent)
                    .disabled(newCommand.isEmpty)
                }
            }

            // package.json scripts
            if project.type == .node && !filteredScripts.isEmpty {
                TerminalSeparator()

                VStack(alignment: .leading, spacing: 8) {
                    Text("// package.json scripts")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(HackerColors.textSecondary)

                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(filteredScripts, id: \.key) { script in
                                HStack(spacing: 12) {
                                    Text(script.key)
                                        .font(.system(.body, design: .monospaced, weight: .bold))
                                        .foregroundStyle(HackerColors.text)

                                    Text(script.value)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(HackerColors.textSecondary)
                                        .lineLimit(1)

                                    Spacer()

                                    Button {
                                        let command = LaunchCommand(
                                            label: script.key,
                                            command: script.value,
                                            environment: .dev
                                        )
                                        withAnimation {
                                            commands.append(command)
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(HackerColors.accent)
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
            }

            Spacer()

            HStack {
                Button("Annuler") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    var updated = project
                    updated.launchCommands = commands
                    onSave(updated)
                    dismiss()
                } label: {
                    Text("> save")
                        .font(.system(.body, design: .monospaced, weight: .medium))
                }
                .hackerButton(color: HackerColors.accent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 520)
        .background(HackerColors.background)
        .onAppear {
            loadPackageScripts()
        }
    }

    private func cancelEditing() {
        editingCommandId = nil
        newLabel = ""
        newCommand = ""
        newEnvironment = .dev
    }

    private var filteredScripts: [(key: String, value: String)] {
        let existingCommands = Set(commands.map(\.command))
        return packageScripts.filter { !existingCommands.contains($0.value) }
    }

    private func loadPackageScripts() {
        guard project.type == .node else { return }
        let url = URL(fileURLWithPath: project.path).appendingPathComponent("package.json")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let scripts = json["scripts"] as? [String: String] else { return }
        packageScripts = scripts.sorted { $0.key < $1.key }
    }
}

#Preview {
    ProjectsView()
}
