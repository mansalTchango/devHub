import SwiftUI
import AppKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scanPaths: [String] = []
    var onSave: (([String]) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Text("$")
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(HackerColors.accent)
                Text("settings --scan-paths")
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(HackerColors.text)
                BlinkingCursor()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            TerminalSeparator()
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            // Scan paths list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("// dossiers scannés")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(HackerColors.textSecondary)

                    if scanPaths.isEmpty {
                        Text("Aucun dossier configuré (défauts ~/Documents/* utilisés)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(HackerColors.textSecondary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(scanPaths, id: \.self) { path in
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(HackerColors.accentBlue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text((path as NSString).lastPathComponent)
                                        .font(.system(.body, design: .monospaced, weight: .medium))
                                        .foregroundStyle(HackerColors.text)
                                    Text(displayPath(path))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(HackerColors.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button(role: .destructive) {
                                    withAnimation {
                                        scanPaths.removeAll { $0 == path }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(HackerColors.accentRed)
                                }
                                .buttonStyle(.borderless)
                            }
                            .hackerCard(padding: 12)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            TerminalSeparator()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            // Actions
            HStack(spacing: 12) {
                Button {
                    addFolder()
                } label: {
                    Text("+ ajouter dossier")
                        .font(.system(.body, design: .monospaced, weight: .medium))
                }
                .hackerButton(color: HackerColors.accentBlue)

                Button {
                    withAnimation {
                        scanPaths = PersistenceManager.defaultScanPaths()
                    }
                } label: {
                    Text("> reset défauts")
                        .font(.system(.body, design: .monospaced, weight: .medium))
                }
                .hackerButton(color: HackerColors.accentOrange)

                Spacer()

                Button("Annuler") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    onSave?(scanPaths)
                    dismiss()
                } label: {
                    Text("> save")
                        .font(.system(.body, design: .monospaced, weight: .medium))
                }
                .hackerButton(color: HackerColors.accent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(minWidth: 550, minHeight: 400)
        .background(HackerColors.background)
        .onAppear {
            let stored = PersistenceManager.shared.load().scanPaths
            scanPaths = stored ?? PersistenceManager.defaultScanPaths()
        }
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.message = "Sélectionnez un ou plusieurs dossiers à scanner"
        panel.prompt = "Ajouter"

        if panel.runModal() == .OK {
            for url in panel.urls {
                let path = url.path
                if !scanPaths.contains(path) {
                    withAnimation {
                        scanPaths.append(path)
                    }
                }
            }
        }
    }

    private func displayPath(_ path: String) -> String {
        path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path(),
            with: "~"
        )
    }
}
