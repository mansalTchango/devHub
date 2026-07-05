import SwiftUI

struct ActionButton: View {
    let action: QuickAction
    let isRunning: Bool
    let onRun: (String?) -> Void
    var onDelete: (() -> Void)?

    @State private var isHovered = false
    @State private var showInput = false
    @State private var inputText = ""

    var body: some View {
        Button {
            if action.needsInput {
                showInput = true
            } else {
                onRun(nil)
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    switch action.status {
                    case .running:
                        ProgressView()
                            .controlSize(.regular)
                    case .success:
                        StatusBadge(type: .ok)
                            .transition(.scale.combined(with: .opacity))
                    case .error:
                        StatusBadge(type: .err)
                            .transition(.scale.combined(with: .opacity))
                    case .idle:
                        Image(systemName: action.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(isHovered ? HackerColors.accent : HackerColors.text)
                    }
                }
                .frame(height: 32)

                Text(action.name)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundStyle(HackerColors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if action.needsSudo {
                    Image(systemName: "lock.shield")
                        .font(.caption2)
                        .foregroundStyle(HackerColors.accentOrange)
                }
            }
            .frame(width: 110, height: 95)
            .padding(8)
            .background(HackerColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(color: isHovered ? HackerColors.accent.opacity(0.15) : .clear, radius: 8, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.spring(duration: 0.3), value: action.status)
        .contextMenu {
            if action.isCustom, let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        }
        .popover(isPresented: $showInput, arrowEdge: .bottom) {
            VStack(spacing: 12) {
                Text(action.name)
                    .font(.system(.headline, design: .monospaced))

                TextField(action.inputPlaceholder ?? "Valeur", text: $inputText)
                    .textFieldStyle(HackerTextFieldStyle())
                    .frame(width: 200)
                    .onSubmit {
                        showInput = false
                        onRun(inputText)
                        inputText = ""
                    }

                HStack {
                    Button("Annuler") {
                        showInput = false
                        inputText = ""
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Exécuter") {
                        showInput = false
                        onRun(inputText)
                        inputText = ""
                    }
                    .hackerButton(color: HackerColors.accent)
                    .disabled(inputText.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
            .background(HackerColors.cardBackground)
        }
    }

    private var borderColor: Color {
        switch action.status {
        case .success: return HackerColors.accent
        case .error: return HackerColors.accentRed
        case .running: return HackerColors.accentOrange
        case .idle: return isHovered ? HackerColors.accent.opacity(0.4) : HackerColors.border
        }
    }

    private var borderWidth: CGFloat {
        action.status == .idle ? 1 : 2
    }
}
