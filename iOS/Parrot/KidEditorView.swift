import SwiftUI
import SwiftData

// Add or edit a kid: name plus color identity.
// Text input screen: keyboard dismisses on tap anywhere outside the field.

struct KidEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let kid: Kid?
    var onSave: ((Kid) -> Void)? = nil

    @State private var name: String
    @State private var color: KidColor

    init(kid: Kid?, onSave: ((Kid) -> Void)? = nil) {
        self.kid = kid
        self.onSave = onSave
        _name = State(initialValue: kid?.name ?? "")
        _color = State(initialValue: kid?.color ?? .coral)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClassroomBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ZStack {
                            Circle().fill(color.color)
                            Text(trimmedName.isEmpty ? "?" : String(trimmedName.prefix(1)).uppercased())
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 96, height: 96)
                        .frame(maxWidth: .infinity)
                        .animation(Theme.springFast, value: color)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.ink)
                            TextField("First name", text: $name)
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.ink)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(16)
                                .glassCard(corner: 18)
                                .accessibilityIdentifier("kidNameField")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.ink)
                            HStack(spacing: 14) {
                                ForEach(KidColor.allCases) { option in
                                    Button {
                                        withAnimation(Theme.springFast) {
                                            color = option
                                        }
                                    } label: {
                                        ZStack {
                                            Circle().fill(option.color)
                                            if option == color {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .heavy))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .frame(width: 42, height: 42)
                                        .scaleEffect(option == color ? 1.12 : 1.0)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard(corner: 18)
                        }
                    }
                    .padding(20)
                }
                .dismissKeyboardOnTap()
            }
            .navigationTitle(kid == nil ? "Add a Kid" : "Edit Kid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.headline)
                        .disabled(trimmedName.isEmpty)
                        .accessibilityIdentifier("saveKidButton")
                }
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        if let kid {
            kid.name = trimmedName
            kid.color = color
            try? context.save()
            onSave?(kid)
        } else {
            let newKid = Kid(name: trimmedName, color: color)
            context.insert(newKid)
            try? context.save()
            onSave?(newKid)
        }
        dismiss()
    }
}
