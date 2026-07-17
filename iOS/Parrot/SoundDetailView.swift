import SwiftUI
import SwiftData

// Manage one target sound: word lists grouped by position, add custom
// words, delete words, delete the sound. Text input screen, so keyboard
// dismisses on tap outside.

struct SoundDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let sound: TargetSound

    @State private var newWord = ""
    @State private var newPosition: WordPosition = .initial
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            ClassroomBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    addWordCard
                    ForEach(WordPosition.allCases) { position in
                        positionSection(position)
                    }
                    deleteButton
                }
                .padding(20)
            }
            .dismissKeyboardOnTap()
        }
        .navigationTitle("\(sound.label) Sound")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete the \(sound.label) sound and all its words?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Sound", role: .destructive) {
                context.delete(sound)
                try? context.save()
                dismiss()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text(sound.label)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(sound.words.count) words")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                if let kid = sound.kid {
                    let mastered = Mastery.isMastered(sound: sound.label, sessions: kid.sessionRecords)
                    HStack(spacing: 5) {
                        Image(systemName: mastered ? "rosette" : "target")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(mastered ? Theme.amber : Theme.inkSoft)
                        Text(mastered ? "Mastered" : "In practice")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            Spacer()
        }
        .padding(18)
        .glassCard(corner: 22)
    }

    private var addWordCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a word")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 10) {
                TextField("Word from the homework sheet", text: $newWord)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.ink.opacity(0.06))
                    )
                    .accessibilityIdentifier("newWordField")
                Button {
                    addWord()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Theme.leaf))
                }
                .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("addWordButton")
            }
            Picker("Position", selection: $newPosition) {
                ForEach(WordPosition.allCases) { position in
                    Text(position.label).tag(position)
                }
            }
            .pickerStyle(.segmented)
            Text("Position is where the sound sits in the word: RRRabbit is initial, caRRRot is medial, caRRR is final.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(18)
        .glassCard(corner: 22)
    }

    private func positionSection(_ position: WordPosition) -> some View {
        let words = sound.words(at: position)
        return Group {
            if !words.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(position.label)
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.ink)
                        Text("\(words.count)")
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    FlowWordList(words: words) { word in
                        context.delete(word)
                        try? context.save()
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(corner: 22)
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete this sound", systemImage: "trash")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.coral)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .glassCard(corner: 18)
        }
    }

    private func addWord() {
        let text = newWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return }
        let word = TargetWord(text: text, position: newPosition)
        context.insert(word)
        word.sound = sound
        try? context.save()
        withAnimation(Theme.springFast) {
            newWord = ""
        }
    }
}

// Simple wrapping chip list for words with a delete tap.
private struct FlowWordList: View {
    let words: [TargetWord]
    let onDelete: (TargetWord) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(words) { word in
                HStack(spacing: 6) {
                    Text(word.text)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Button {
                        withAnimation(Theme.springFast) {
                            onDelete(word)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.ink.opacity(0.06)))
            }
        }
    }
}
