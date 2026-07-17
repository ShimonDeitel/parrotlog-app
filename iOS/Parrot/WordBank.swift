import Foundation

// Built-in starter word lists for the sounds SLPs most often assign.
// Three words per position keeps the free experience instantly useful;
// parents add the exact words from their therapist's homework sheet.

enum WordBank {
    struct StarterSound: Identifiable {
        let label: String
        let words: [(String, WordPosition)]
        var id: String { label }
    }

    static let suggestedOrder = ["R", "S", "L", "TH", "K", "G", "F", "V", "SH", "CH"]

    static let starters: [String: [(String, WordPosition)]] = [
        "R": [
            ("rabbit", .initial), ("rain", .initial), ("rocket", .initial),
            ("carrot", .medial), ("pirate", .medial), ("arrow", .medial),
            ("car", .final), ("door", .final), ("star", .final)
        ],
        "S": [
            ("sun", .initial), ("soap", .initial), ("seal", .initial),
            ("messy", .medial), ("dinosaur", .medial), ("glasses", .medial),
            ("bus", .final), ("house", .final), ("grass", .final)
        ],
        "L": [
            ("lion", .initial), ("leaf", .initial), ("lamp", .initial),
            ("balloon", .medial), ("yellow", .medial), ("jelly", .medial),
            ("ball", .final), ("bell", .final), ("owl", .final)
        ],
        "TH": [
            ("thumb", .initial), ("think", .initial), ("three", .initial),
            ("toothbrush", .medial), ("birthday", .medial), ("bathtub", .medial),
            ("bath", .final), ("teeth", .final), ("mouth", .final)
        ],
        "K": [
            ("kite", .initial), ("key", .initial), ("cow", .initial),
            ("cookie", .medial), ("monkey", .medial), ("pocket", .medial),
            ("book", .final), ("duck", .final), ("cake", .final)
        ],
        "G": [
            ("goat", .initial), ("game", .initial), ("gum", .initial),
            ("wagon", .medial), ("tiger", .medial), ("dragon", .medial),
            ("bug", .final), ("dog", .final), ("frog", .final)
        ],
        "F": [
            ("fish", .initial), ("fan", .initial), ("foot", .initial),
            ("muffin", .medial), ("dolphin", .medial), ("elephant", .medial),
            ("leaf", .final), ("giraffe", .final), ("roof", .final)
        ],
        "V": [
            ("van", .initial), ("vine", .initial), ("vest", .initial),
            ("oven", .medial), ("river", .medial), ("seven", .medial),
            ("five", .final), ("glove", .final), ("wave", .final)
        ],
        "SH": [
            ("shoe", .initial), ("ship", .initial), ("sheep", .initial),
            ("milkshake", .medial), ("dishes", .medial), ("sunshine", .medial),
            ("fish", .final), ("brush", .final), ("splash", .final)
        ],
        "CH": [
            ("chair", .initial), ("cheese", .initial), ("chicken", .initial),
            ("teacher", .medial), ("ketchup", .medial), ("matches", .medial),
            ("beach", .final), ("watch", .final), ("lunch", .final)
        ]
    ]

    static func starterWords(for label: String) -> [(String, WordPosition)] {
        starters[label.uppercased()] ?? []
    }
}
