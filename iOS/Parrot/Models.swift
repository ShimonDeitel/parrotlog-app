import Foundation
import SwiftData
import SwiftUI

// MARK: - Value enums

enum WordPosition: String, Codable, CaseIterable, Identifiable {
    case initial
    case medial
    case final

    var id: String { rawValue }

    var label: String {
        switch self {
        case .initial: return "Initial"
        case .medial: return "Medial"
        case .final: return "Final"
        }
    }
}

enum AttemptResult: String, Codable, CaseIterable, Identifiable {
    case correct
    case almost
    case missed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .correct: return "Correct"
        case .almost: return "Almost"
        case .missed: return "Missed"
        }
    }
}

enum KidColor: String, Codable, CaseIterable, Identifiable {
    case coral
    case leaf
    case sky
    case sun
    case plum
    case tide

    var id: String { rawValue }

    var label: String {
        switch self {
        case .coral: return "Coral"
        case .leaf: return "Leaf"
        case .sky: return "Sky"
        case .sun: return "Sun"
        case .plum: return "Plum"
        case .tide: return "Tide"
        }
    }

    var color: Color {
        switch self {
        case .coral: return Theme.coral
        case .leaf: return Theme.leaf
        case .sky: return Theme.sky
        case .sun: return Theme.dynamic(light: UIColor(red: 0.95, green: 0.71, blue: 0.22, alpha: 1),
                                        dark: UIColor(red: 0.89, green: 0.70, blue: 0.35, alpha: 1))
        case .plum: return Theme.dynamic(light: UIColor(red: 0.60, green: 0.44, blue: 0.80, alpha: 1),
                                         dark: UIColor(red: 0.66, green: 0.55, blue: 0.82, alpha: 1))
        case .tide: return Theme.dynamic(light: UIColor(red: 0.20, green: 0.62, blue: 0.66, alpha: 1),
                                         dark: UIColor(red: 0.36, green: 0.68, blue: 0.71, alpha: 1))
        }
    }
}

// MARK: - SwiftData models

@Model
final class Kid {
    var uuid: UUID
    var name: String
    var colorRaw: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \TargetSound.kid)
    var sounds: [TargetSound] = []
    @Relationship(deleteRule: .cascade, inverse: \PracticeSession.kid)
    var sessions: [PracticeSession] = []

    init(name: String, color: KidColor, createdAt: Date = .now) {
        self.uuid = UUID()
        self.name = name
        self.colorRaw = color.rawValue
        self.createdAt = createdAt
    }

    var color: KidColor {
        get { KidColor(rawValue: colorRaw) ?? .coral }
        set { colorRaw = newValue.rawValue }
    }

    var initialLetter: String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }
}

@Model
final class TargetSound {
    var label: String
    var createdAt: Date
    var kid: Kid?
    @Relationship(deleteRule: .cascade, inverse: \TargetWord.sound)
    var words: [TargetWord] = []

    init(label: String, createdAt: Date = .now) {
        self.label = label
        self.createdAt = createdAt
    }

    func words(at position: WordPosition) -> [TargetWord] {
        words
            .filter { $0.position == position }
            .sorted { $0.createdAt < $1.createdAt }
    }
}

@Model
final class TargetWord {
    var text: String
    var positionRaw: String
    var createdAt: Date
    var sound: TargetSound?

    init(text: String, position: WordPosition, createdAt: Date = .now) {
        self.text = text
        self.positionRaw = position.rawValue
        self.createdAt = createdAt
    }

    var position: WordPosition {
        get { WordPosition(rawValue: positionRaw) ?? .initial }
        set { positionRaw = newValue.rawValue }
    }
}

@Model
final class PracticeSession {
    var date: Date
    var durationSeconds: Int
    var note: String
    var kid: Kid?
    @Relationship(deleteRule: .cascade, inverse: \WordAttempt.session)
    var attempts: [WordAttempt] = []

    init(date: Date = .now, durationSeconds: Int = 0, note: String = "") {
        self.date = date
        self.durationSeconds = durationSeconds
        self.note = note
    }
}

@Model
final class WordAttempt {
    var word: String
    var soundLabel: String
    var positionRaw: String
    var resultRaw: String
    var order: Int
    var session: PracticeSession?

    init(word: String, soundLabel: String, position: WordPosition, result: AttemptResult, order: Int) {
        self.word = word
        self.soundLabel = soundLabel
        self.positionRaw = position.rawValue
        self.resultRaw = result.rawValue
        self.order = order
    }

    var position: WordPosition { WordPosition(rawValue: positionRaw) ?? .initial }
    var result: AttemptResult { AttemptResult(rawValue: resultRaw) ?? .missed }
}

// MARK: - Bridging into pure stats types

extension PracticeSession {
    var record: SessionRecord {
        SessionRecord(
            date: date,
            note: note,
            durationSeconds: durationSeconds,
            attempts: attempts
                .sorted { $0.order < $1.order }
                .map { AttemptRecord(sound: $0.soundLabel, word: $0.word, position: $0.position, result: $0.result) }
        )
    }
}

extension Kid {
    var sessionRecords: [SessionRecord] {
        sessions.map(\.record).sorted { $0.date < $1.date }
    }

    var sortedSounds: [TargetSound] {
        sounds.sorted { $0.createdAt < $1.createdAt }
    }
}
