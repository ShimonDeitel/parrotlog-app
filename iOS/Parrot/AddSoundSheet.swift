import SwiftUI
import SwiftData

// Add a target sound to a kid. Picking a suggested sound also loads its
// starter words. A custom sound starts empty and words are added in detail.

struct AddSoundSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let kid: Kid

    @State private var customLabel = ""
    @State private var includeStarterWords = true

    private var existingLabels: Set<String> {
        Set(kid.sounds.map { $0.label.uppercased() })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClassroomBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Common sounds")
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.ink)
                            Text("Tap the sound your SLP assigned. Starter words come included.")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                                ForEach(WordBank.suggestedOrder, id: \.self) { label in
                                    let taken = existingLabels.contains(label)
                                    Button {
                                        addSound(label: label, withStarters: includeStarterWords)
                                    } label: {
                                        Text(label)
                                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                                            .foregroundStyle(taken ? Theme.inkSoft : Theme.ink)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .glassCard(corner: 16)
                                            .opacity(taken ? 0.45 : 1)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(taken)
                                }
                            }
                            Toggle(isOn: $includeStarterWords) {
                                Text("Include starter words")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.ink)
                            }
                            .tint(Theme.leaf)
                            .padding(14)
                            .glassCard(corner: 16)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom sound")
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.ink)
                            HStack(spacing: 10) {
                                TextField("Like BL or ST", text: $customLabel)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.ink)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .padding(14)
                                    .glassCard(corner: 16)
                                    .accessibilityIdentifier("customSoundField")
                                Button {
                                    let label = customLabel.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                                    guard !label.isEmpty, !existingLabels.contains(label) else { return }
                                    addSound(label: label, withStarters: includeStarterWords)
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .frame(width: 48, height: 48)
                                        .background(Circle().fill(Theme.sky))
                                }
                                .disabled(customLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .accessibilityIdentifier("addCustomSoundButton")
                            }
                        }
                    }
                    .padding(20)
                }
                .dismissKeyboardOnTap()
            }
            .navigationTitle("Add a Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addSound(label: String, withStarters: Bool) {
        let sound = TargetSound(label: label)
        context.insert(sound)
        sound.kid = kid
        if withStarters {
            for (text, position) in WordBank.starterWords(for: label) {
                let word = TargetWord(text: text, position: position)
                context.insert(word)
                word.sound = sound
            }
        }
        try? context.save()
        dismiss()
    }
}
