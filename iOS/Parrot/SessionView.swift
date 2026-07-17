import SwiftUI
import SwiftData

// The heart of Parrot: big flashcard words, three huge honest buttons,
// live accuracy dial, spring card advances. Ends in a summary with a note.

private struct RecordedAttempt {
    let item: SessionItem
    let result: AttemptResult
}

struct SessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let kid: Kid
    let items: [SessionItem]

    @State private var index = 0
    @State private var recorded: [RecordedAttempt] = []
    @State private var startDate = Date.now
    @State private var finished = false
    @State private var note = ""
    @State private var burstCount = 0
    @State private var showQuitConfirm = false

    private var results: [AttemptResult] { recorded.map(\.result) }
    private var accuracy: Double { Scoring.accuracy(results: results) }

    var body: some View {
        ZStack {
            ClassroomBackground()
            if finished {
                SessionSummaryView(
                    kid: kid,
                    recorded: recorded.map { ($0.item, $0.result) },
                    startDate: startDate,
                    note: $note,
                    onSave: save,
                    onDiscard: { dismiss() }
                )
            } else {
                sessionBody
            }
        }
        .confirmationDialog("End this session?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
            if !recorded.isEmpty {
                Button("Finish and review") {
                    withAnimation(Theme.spring) { finished = true }
                }
            }
            Button("Discard session", role: .destructive) { dismiss() }
        }
    }

    // MARK: - Live session

    private var sessionBody: some View {
        VStack(spacing: 18) {
            topBar
            Spacer(minLength: 0)
            flashcard
            Spacer(minLength: 0)
            resultButtons
        }
        .padding(20)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                showQuitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .accessibilityIdentifier("endSessionButton")

            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                Text(startDate, style: .timer)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(.ultraThinMaterial))

            Spacer()

            AccuracyDial(accuracy: accuracy, size: 52, lineWidth: 6)
        }
    }

    private var flashcard: some View {
        VStack(spacing: 14) {
            Text("\(index + 1) of \(items.count)")
                .font(.system(.caption, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.inkSoft)

            ZStack {
                if index < items.count {
                    let item = items[index]
                    VStack(spacing: 18) {
                        HStack(spacing: 8) {
                            Text(item.sound)
                                .font(.system(.caption, design: .rounded).weight(.heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Theme.sky))
                            PositionChip(position: item.position)
                        }
                        Text(item.word)
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .accessibilityIdentifier("flashcardWord")
                        Text("Say it together, then tap how it went")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                    .glassCard(corner: 36)
                    .id(index)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .animation(Theme.spring, value: index)
        }
    }

    private var resultButtons: some View {
        HStack(spacing: 12) {
            resultButton(.missed, symbol: "xmark", tint: Theme.coral, identifier: "missedButton")
            resultButton(.almost, symbol: "circle.bottomhalf.filled", tint: Theme.amber, identifier: "almostButton")
            ZStack {
                BurstRing(trigger: burstCount, color: Theme.leaf)
                resultButton(.correct, symbol: "checkmark", tint: Theme.leaf, identifier: "correctButton")
            }
        }
    }

    private func resultButton(_ result: AttemptResult, symbol: String, tint: Color, identifier: String) -> some View {
        Button {
            record(result)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .heavy))
                Text(result.label)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(tint))
            .shadow(color: tint.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(SpringButtonStyle())
        .accessibilityIdentifier(identifier)
    }

    private func record(_ result: AttemptResult) {
        guard index < items.count else { return }
        recorded.append(RecordedAttempt(item: items[index], result: result))
        if result == .correct {
            burstCount += 1
        }
        withAnimation(Theme.spring) {
            if index + 1 < items.count {
                index += 1
            } else {
                finished = true
            }
        }
    }

    private func save() {
        let duration = max(1, Int(Date.now.timeIntervalSince(startDate)))
        let session = PracticeSession(date: startDate, durationSeconds: duration, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(session)
        session.kid = kid
        for (order, entry) in recorded.enumerated() {
            let attempt = WordAttempt(
                word: entry.item.word,
                soundLabel: entry.item.sound,
                position: entry.item.position,
                result: entry.result,
                order: order
            )
            context.insert(attempt)
            attempt.session = session
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - Spring press feedback

struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Correct burst ring

struct BurstRing: View {
    let trigger: Int
    let color: Color

    @State private var animating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(color.opacity(animating ? 0 : 0.65), lineWidth: 3)
            .scaleEffect(animating ? 1.35 : 1.0)
            .allowsHitTesting(false)
            .onChange(of: trigger) {
                animating = false
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 16_000_000)
                    withAnimation(.easeOut(duration: 0.45)) {
                        animating = true
                    }
                }
            }
    }
}
