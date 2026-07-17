import SwiftUI
import SwiftData
import Charts

// Progress: streak, accuracy trend per sound, mastery badges, SLP report.

struct ProgressTabView: View {
    @Environment(ProStore.self) private var pro
    @Query(sort: \Kid.createdAt) private var kids: [Kid]
    @AppStorage("selectedKidID") private var selectedKidID = ""
    @AppStorage("seenMasteryBadges") private var seenMasteryBadgesRaw = ""

    @State private var selectedSoundLabel: String?
    @State private var showReport = false
    @State private var showPaywall = false

    private var selectedKid: Kid? {
        kids.first { $0.uuid.uuidString == selectedKidID } ?? kids.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClassroomBackground()
                if let kid = selectedKid, !kid.sessions.isEmpty {
                    content(kid)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showReport) {
                if let kid = selectedKid {
                    ReportView(kid: kid)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.sky)
                .padding(22)
                .glassCard(corner: 30)
            Text("No sessions yet")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.ink)
            Text("Finish your first practice session and the trends will bloom here.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
    }

    private func content(_ kid: Kid) -> some View {
        let records = kid.sessionRecords
        return ScrollView {
            VStack(spacing: 18) {
                streakCard(kid, records: records)
                trendCard(kid, records: records)
                masteryCard(kid, records: records)
                reportCard
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Streak

    private func streakCard(_ kid: Kid, records: [SessionRecord]) -> some View {
        let dates = records.map(\.date)
        let streak = Streaks.weeklyStreak(sessionDates: dates)
        let thisWeek = Streaks.sessionsThisWeek(sessionDates: dates)
        return HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Theme.coral.opacity(0.14))
                Image(systemName: "flame.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.coral)
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(streak == 1 ? "1 week streak" : "\(streak) week streak")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.ink)
                Text(thisWeek == 1 ? "1 session this week" : "\(thisWeek) sessions this week")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(18)
        .glassCard()
    }

    // MARK: - Trend chart

    private struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let accuracy: Double
    }

    private func trendCard(_ kid: Kid, records: [SessionRecord]) -> some View {
        let soundLabels = kid.sortedSounds.map(\.label)
        let currentLabel = selectedSoundLabel ?? soundLabels.first
        let points: [TrendPoint] = records.compactMap { record in
            guard let label = currentLabel,
                  let accuracy = Mastery.sessionAccuracy(sound: label, session: record) else { return nil }
            return TrendPoint(date: record.date, accuracy: accuracy * 100)
        }

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Accuracy Trend")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if soundLabels.count > 1 {
                    Menu {
                        ForEach(soundLabels, id: \.self) { label in
                            Button(label) {
                                withAnimation(Theme.springSoft) {
                                    selectedSoundLabel = label
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentLabel ?? "")
                                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .heavy))
                        }
                        .foregroundStyle(Theme.sky)
                    }
                } else if let label = currentLabel {
                    Text(label)
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.sky)
                }
            }
            if points.count < 2 {
                Text("Two or more sessions with this sound will draw the trend line.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Accuracy", point.accuracy)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.sky)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Accuracy", point.accuracy)
                    )
                    .foregroundStyle(point.accuracy >= Mastery.threshold * 100 ? Theme.leaf : Theme.sky)
                    RuleMark(y: .value("Mastery", Mastery.threshold * 100))
                        .foregroundStyle(Theme.leaf.opacity(0.35))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)%")
                                    .font(.system(.caption2, design: .rounded))
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(18)
        .glassCard()
    }

    // MARK: - Mastery

    private func masteryCard(_ kid: Kid, records: [SessionRecord]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mastery")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.ink)
            Text("A sound is mastered after 3 sessions in a row at 80% or better.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
            ForEach(kid.sortedSounds) { sound in
                let mastered = Mastery.isMastered(sound: sound.label, sessions: records)
                let strong = Mastery.strongRecentSessionCount(sound: sound.label, sessions: records)
                MasteryRow(
                    label: sound.label,
                    mastered: mastered,
                    strongCount: strong,
                    isNew: mastered && !seenBadges.contains(badgeKey(kid, sound)),
                    onSeen: { markBadgeSeen(kid, sound) }
                )
            }
        }
        .padding(18)
        .glassCard()
    }

    private var seenBadges: Set<String> {
        Set(seenMasteryBadgesRaw.split(separator: ",").map(String.init))
    }

    private func badgeKey(_ kid: Kid, _ sound: TargetSound) -> String {
        "\(kid.uuid.uuidString)-\(sound.label)"
    }

    private func markBadgeSeen(_ kid: Kid, _ sound: TargetSound) {
        var badges = seenBadges
        badges.insert(badgeKey(kid, sound))
        seenMasteryBadgesRaw = badges.sorted().joined(separator: ",")
    }

    // MARK: - Report

    private var reportCard: some View {
        Button {
            if pro.isPro {
                showReport = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.sky)
                VStack(alignment: .leading, spacing: 3) {
                    Text("SLP Report")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.ink)
                    Text("One-tap PDF summary to hand to the therapist")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: pro.isPro ? "chevron.right" : "lock.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(18)
            .glassCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("slpReportButton")
    }
}

// MARK: - Mastery row with one-time pop

private struct MasteryRow: View {
    let label: String
    let mastered: Bool
    let strongCount: Int
    let isNew: Bool
    let onSeen: () -> Void

    @State private var popped = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.ink)
                .frame(width: 52, alignment: .leading)
            if mastered {
                Label("Mastered", systemImage: "rosette")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.amber)
                    .scaleEffect(isNew && !popped ? 0.2 : 1.0)
            } else {
                HStack(spacing: 5) {
                    ForEach(0..<Mastery.sessionsNeeded, id: \.self) { i in
                        Circle()
                            .fill(i < strongCount ? Theme.leaf : Theme.ink.opacity(0.12))
                            .frame(width: 12, height: 12)
                    }
                    Text("\(strongCount) of \(Mastery.sessionsNeeded) strong sessions")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.inkSoft)
                        .padding(.leading, 4)
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .onAppear {
            if isNew {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.2)) {
                    popped = true
                }
                onSeen()
            } else {
                popped = true
            }
        }
    }
}
