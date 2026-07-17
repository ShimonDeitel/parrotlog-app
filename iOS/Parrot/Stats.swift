import Foundation

// Pure value types and math used by the app and covered by unit tests.
// No SwiftData, no UI. Scoring: correct = 1 point, almost = 0.5, missed = 0.

struct AttemptRecord: Equatable {
    var sound: String
    var word: String
    var position: WordPosition
    var result: AttemptResult
}

struct SessionRecord: Equatable {
    var date: Date
    var note: String
    var durationSeconds: Int
    var attempts: [AttemptRecord]
}

enum Scoring {
    static func points(for result: AttemptResult) -> Double {
        switch result {
        case .correct: return 1.0
        case .almost: return 0.5
        case .missed: return 0.0
        }
    }

    static func accuracy(results: [AttemptResult]) -> Double {
        guard !results.isEmpty else { return 0 }
        let earned = results.reduce(0.0) { $0 + points(for: $1) }
        return earned / Double(results.count)
    }

    static func accuracy(of attempts: [AttemptRecord]) -> Double {
        accuracy(results: attempts.map(\.result))
    }
}

enum Mastery {
    static let threshold = 0.8
    static let sessionsNeeded = 3

    /// A sound is mastered when its 3 most recent sessions that included the
    /// sound each scored at or above 80 percent accuracy for that sound.
    static func isMastered(sound: String, sessions: [SessionRecord]) -> Bool {
        strongRecentSessionCount(sound: sound, sessions: sessions) >= sessionsNeeded
    }

    /// How many of the most recent qualifying sessions in a row (up to 3)
    /// were at or above the threshold. Drives "2 of 3" progress copy.
    static func strongRecentSessionCount(sound: String, sessions: [SessionRecord]) -> Int {
        let relevant = sessions
            .map { session in (session.date, session.attempts.filter { $0.sound == sound }) }
            .filter { !$0.1.isEmpty }
            .sorted { $0.0 < $1.0 }
        let recent = relevant.suffix(sessionsNeeded)
        guard !recent.isEmpty else { return 0 }
        var count = 0
        for (_, attempts) in recent.reversed() {
            if Scoring.accuracy(of: attempts) >= threshold {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    /// Accuracy for one sound within one session, nil when the session did not include it.
    static func sessionAccuracy(sound: String, session: SessionRecord) -> Double? {
        let attempts = session.attempts.filter { $0.sound == sound }
        guard !attempts.isEmpty else { return nil }
        return Scoring.accuracy(of: attempts)
    }
}

enum Streaks {
    /// Consecutive calendar weeks with at least one session, counting back
    /// from the week containing `now`. A quiet current week does not break
    /// the streak, it just does not extend it yet.
    static func weeklyStreak(sessionDates: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard !sessionDates.isEmpty else { return 0 }
        let weekStarts = Set(sessionDates.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0)?.start })
        guard var cursor = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        if !weekStarts.contains(cursor) {
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }
        var streak = 0
        while weekStarts.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func sessionsThisWeek(sessionDates: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return sessionDates.filter { week.contains($0) }.count
    }
}

// MARK: - SLP report assembly

struct SoundStat: Equatable {
    var sound: String
    var attempts: Int
    var accuracy: Double
}

struct PositionStat: Equatable {
    var position: WordPosition
    var attempts: Int
    var accuracy: Double
}

struct NoteEntry: Equatable {
    var date: Date
    var text: String
}

struct ReportSummary: Equatable {
    var start: Date
    var end: Date
    var sessionCount: Int
    var attemptCount: Int
    var overallAccuracy: Double
    var totalMinutes: Int
    var soundStats: [SoundStat]
    var positionStats: [PositionStat]
    var notes: [NoteEntry]

    static func assemble(sessions: [SessionRecord], from start: Date, to end: Date) -> ReportSummary {
        let inRange = sessions
            .filter { $0.date >= start && $0.date <= end }
            .sorted { $0.date < $1.date }
        let attempts = inRange.flatMap(\.attempts)

        let bySound = Dictionary(grouping: attempts, by: \.sound)
        let soundStats = bySound
            .map { SoundStat(sound: $0.key, attempts: $0.value.count, accuracy: Scoring.accuracy(of: $0.value)) }
            .sorted { lhs, rhs in
                lhs.attempts == rhs.attempts ? lhs.sound < rhs.sound : lhs.attempts > rhs.attempts
            }

        let positionStats = WordPosition.allCases.compactMap { position -> PositionStat? in
            let matching = attempts.filter { $0.position == position }
            guard !matching.isEmpty else { return nil }
            return PositionStat(position: position, attempts: matching.count, accuracy: Scoring.accuracy(of: matching))
        }

        let notes = inRange
            .filter { !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { NoteEntry(date: $0.date, text: $0.note) }

        let totalSeconds = inRange.reduce(0) { $0 + $1.durationSeconds }

        return ReportSummary(
            start: start,
            end: end,
            sessionCount: inRange.count,
            attemptCount: attempts.count,
            overallAccuracy: Scoring.accuracy(of: attempts),
            totalMinutes: Int((Double(totalSeconds) / 60.0).rounded()),
            soundStats: soundStats,
            positionStats: positionStats,
            notes: notes
        )
    }
}

extension Double {
    var percentText: String {
        "\(Int((self * 100).rounded()))%"
    }
}
