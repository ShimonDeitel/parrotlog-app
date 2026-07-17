import SwiftUI
import SwiftData

@main
struct ParrotApp: App {
    let container: ModelContainer
    @State private var proStore = ProStore()

    init() {
        let isUITest = CommandLine.arguments.contains("-uitest")
        let schema = Schema([
            Kid.self,
            TargetSound.self,
            TargetWord.self,
            PracticeSession.self,
            WordAttempt.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITest)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create model container: \(error)")
        }
        if isUITest {
            Self.seedForUITests(container: container)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(proStore)
        }
        .modelContainer(container)
    }

    @MainActor
    private static func seedForUITests(container: ModelContainer) {
        UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
        let context = container.mainContext
        let kid = Kid(name: "Milo", color: .coral)
        context.insert(kid)
        let sound = TargetSound(label: "R")
        context.insert(sound)
        sound.kid = kid
        let seedWords: [(String, WordPosition)] = [
            ("rabbit", .initial),
            ("rain", .initial),
            ("carrot", .medial),
            ("car", .final)
        ]
        for (text, position) in seedWords {
            let word = TargetWord(text: text, position: position)
            context.insert(word)
            word.sound = sound
        }
        try? context.save()
        UserDefaults.standard.set(kid.uuid.uuidString, forKey: "selectedKidID")
    }
}
