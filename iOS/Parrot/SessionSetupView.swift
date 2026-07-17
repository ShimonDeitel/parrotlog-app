import SwiftUI
import SwiftData

// Pick which sounds and positions go into this session, then begin.

struct SessionItem: Identifiable, Equatable {
    let id = UUID()
    let word: String
    let sound: String
    let position: WordPosition
}

struct SessionSetupView: View {
    @Environment(\.dismiss) private var dismiss

    let kid: Kid

    @State private var enabledSoundLabels: Set<String> = []
    @State private var positionFilter: WordPosition? = nil
    @State private var runSession = false

    private var items: [SessionItem] {
        kid.sortedSounds
            .filter { enabledSoundLabels.contains($0.label) }
            .flatMap { sound in
                sound.words
                    .filter { positionFilter == nil || $0.position == positionFilter }
                    .map { SessionItem(word: $0.text, sound: sound.label, position: $0.position) }
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClassroomBackground()
                VStack(spacing: 18) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            soundToggles
                            positionPicker
                        }
                        .padding(20)
                    }
                    .scrollIndicators(.hidden)
                    beginButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if enabledSoundLabels.isEmpty {
                    enabledSoundLabels = Set(kid.sounds.filter { !$0.words.isEmpty }.map(\.label))
                }
            }
            .fullScreenCover(isPresented: $runSession, onDismiss: { dismiss() }) {
                SessionView(kid: kid, items: items.shuffled())
            }
        }
    }

    private var soundToggles: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sounds in this session")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.ink)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                ForEach(kid.sortedSounds.filter { !$0.words.isEmpty }) { sound in
                    let on = enabledSoundLabels.contains(sound.label)
                    Button {
                        withAnimation(Theme.springFast) {
                            if on {
                                enabledSoundLabels.remove(sound.label)
                            } else {
                                enabledSoundLabels.insert(sound.label)
                            }
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(sound.label)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                            Text("\(sound.words.count)")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                        }
                        .foregroundStyle(on ? Color.white : Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(on ? AnyShapeStyle(Theme.sky) : AnyShapeStyle(.ultraThinMaterial))
                        )
                        .scaleEffect(on ? 1.0 : 0.97)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .glassCard(corner: 22)
    }

    private var positionPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Positions")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                positionButton(nil, label: "All")
                ForEach(WordPosition.allCases) { position in
                    positionButton(position, label: position.label)
                }
            }
        }
        .padding(18)
        .glassCard(corner: 22)
    }

    private func positionButton(_ position: WordPosition?, label: String) -> some View {
        let on = positionFilter == position
        return Button {
            withAnimation(Theme.springFast) {
                positionFilter = position
            }
        } label: {
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(on ? Color.white : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(on ? AnyShapeStyle(Theme.sky) : AnyShapeStyle(.ultraThinMaterial))
                )
        }
        .buttonStyle(.plain)
    }

    private var beginButton: some View {
        Button {
            runSession = true
        } label: {
            Text(items.isEmpty ? "No words selected" : "Begin with \(items.count) words")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Capsule().fill(items.isEmpty ? Theme.inkSoft : Theme.coral))
        }
        .disabled(items.isEmpty)
        .accessibilityIdentifier("beginSessionButton")
    }
}
