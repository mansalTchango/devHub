import SwiftUI

struct AddActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String, String, Bool) -> Void

    @State private var name = ""
    @State private var icon = "terminal"
    @State private var command = ""
    @State private var needsSudo = false

    private let iconOptions = [
        "terminal", "gearshape", "wrench", "hammer", "bolt",
        "trash", "folder", "network", "doc", "arrow.clockwise",
        "cpu", "memorychip", "externaldrive", "globe", "star"
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !command.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Nouvelle action")
                .font(.system(.title3, design: .rounded, weight: .bold))

            Form {
                TextField("Nom", text: $name)

                LabeledContent("Icône") {
                    Picker("", selection: $icon) {
                        ForEach(iconOptions, id: \.self) { ic in
                            Label(ic, systemImage: ic).tag(ic)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }

                TextField("Commande shell", text: $command, axis: .vertical)
                    .lineLimit(1...3)
                    .font(.system(.body, design: .monospaced))

                Toggle("Nécessite sudo", isOn: $needsSudo)
            }
            .formStyle(.grouped)

            HStack {
                Button("Annuler") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Ajouter") {
                    onAdd(name.trimmingCharacters(in: .whitespaces), icon,
                          command.trimmingCharacters(in: .whitespaces), needsSudo)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
