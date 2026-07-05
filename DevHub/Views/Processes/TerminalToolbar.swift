import SwiftUI

struct TerminalToolbar: View {
    @ObservedObject var paneState: TerminalPaneState
    let onSearch: (String, Bool) -> Void  // (query, forward)
    let onClearSearch: () -> Void
    let onClear: () -> Void
    let onCopyAll: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            // Search toggle
            toolbarButton(icon: "magnifyingglass", help: "Recherche (Cmd+F)") {
                withAnimation(.easeInOut(duration: 0.15)) {
                    paneState.isSearchVisible.toggle()
                    if !paneState.isSearchVisible {
                        paneState.searchText = ""
                        onClearSearch()
                    }
                }
            }

            // Clear buffer
            toolbarButton(icon: "trash", help: "Vider le terminal") {
                onClear()
            }

            // Copy all
            toolbarButton(icon: "doc.on.doc", help: "Copier tout") {
                onCopyAll()
            }

            // Scroll lock indicator
            if paneState.isScrollLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.orange)
                    .help("Scroll verrouillé")
            }

            Spacer()

            // Font size controls
            toolbarButton(icon: "minus", help: "Réduire police") {
                paneState.fontSize = max(8, paneState.fontSize - 1)
            }

            Text("\(Int(paneState.fontSize))pt")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            toolbarButton(icon: "plus", help: "Agrandir police") {
                paneState.fontSize = min(24, paneState.fontSize + 1)
            }

            // Search field (inline, when visible)
            if paneState.isSearchVisible {
                Divider()
                    .frame(height: 14)

                TextField("Rechercher...", text: $paneState.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .frame(width: 120)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.black.opacity(0.3))
                    )
                    .onSubmit {
                        if !paneState.searchText.isEmpty {
                            onSearch(paneState.searchText, true)
                        }
                    }

                toolbarButton(icon: "chevron.left", help: "Précédent") {
                    if !paneState.searchText.isEmpty {
                        onSearch(paneState.searchText, false)
                    }
                }

                toolbarButton(icon: "chevron.right", help: "Suivant") {
                    if !paneState.searchText.isEmpty {
                        onSearch(paneState.searchText, true)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }

    private func toolbarButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
