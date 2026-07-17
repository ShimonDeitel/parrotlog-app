import SwiftUI

// End-of-session review: big accuracy dial, tallies, per-sound breakdown,
// and a quick note. Text input screen, so keyboard dismisses on tap outside.

struct SessionSummaryView: View {
    let kid: Kid
    let recorded: [(SessionItem, AttemptResult)]
    let startDate: Date
    @Binding var note: String
    let onSave: () -> Void
    let onDiscard: () -> Void

    @State private var appeared = false

    private var results: [AttemptResult] { recorded.map(\.1) }
    private var accuracy: Double { Scoring.accuracy(results: results) }

    private func count(_ result: AttemptResult) -> Int {
        results.filter { $0 == result }.count
    }

    private var soundBreakdown: [(String, Double, Int)] {
        let attempts = recorded.map { AttemptRecord(sound: $0.0.sound, word: $0.0.word, position: $0.0.position, result: $0.1) }
        let grouped = Dictionary(grouping: attempts, by: \.sound)
        return grouped
            .map { ($0.key, Scoring.accuracy(of: $0.value), $0.value.count) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Session Complete")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 24)
                    .accessibilityIdentifier("sessionCompleteTitle")

                AccuracyDial(accuracy: appeared ? accuracy : 0, size: 140, lineWidth: 14)
                    .padding(.vertical, 8)

                HStack(spacing: 12) {
                    tallyCard(count(.correct), label: "Correct", tint: Theme.leaf)
                    tallyCard(count(.almost), label: "Almost", tint: Theme.amber)
                    tallyCard(count(.missed), label: "Missed", tint: Theme.coral)
                }

                if soundBreakdown.count > 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("By sound")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.ink)
                        ForEach(soundBreakdown, id: \.0) { entry in
                            HStack {
                                Text(entry.0)
                                    .font(.system(.body, design: .rounded).weight(.heavy))
                                    .foregroundStyle(Theme.ink)
                                Text("\(entry.2) words")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(Theme.inkSoft)
                                Spacer()
                                Text(entry.1.percentText)
                                    .font(.system(.body, design: .rounded).weight(.heavy))
                                    .foregroundStyle(entry.1 >= Mastery.threshold ? Theme.leaf : Theme.ink)
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(corner: 22)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Session note")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.ink)
                    TextField("What worked? Any struggles?", text: $note, axis: .vertical)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.ink.opacity(0.06))
                        )
                        .accessibilityIdentifier("sessionNoteField")
                }
                .padding(18)
                .glassCard(corner: 22)

                Button(action: onSave) {
                    Text("Save Session")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(Theme.leaf))
                }
                .buttonStyle(SpringButtonStyle())
                .accessibilityIdentifier("saveSessionButton")

                Button("Discard", role: .destructive, action: onDiscard)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.coral)
                    .padding(.bottom, 16)
            }
            .padding(20)
        }
        .dismissKeyboardOnTap()
        .onAppear {
            withAnimation(Theme.springSoft.delay(0.15)) {
                appeared = true
            }
        }
    }

    private func tallyCard(_ value: Int, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard(corner: 20)
    }
}
