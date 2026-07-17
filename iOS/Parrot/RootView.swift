import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        TabView {
            PracticeHomeView()
                .tabItem {
                    Label("Practice", systemImage: "rectangle.stack.fill")
                }
            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(Theme.sky)
        .sheet(isPresented: welcomeBinding) {
            WelcomeView {
                hasSeenWelcome = true
            }
            .interactiveDismissDisabled()
        }
    }

    private var welcomeBinding: Binding<Bool> {
        Binding(
            get: { !hasSeenWelcome },
            set: { newValue in hasSeenWelcome = !newValue }
        )
    }
}

// MARK: - First launch welcome

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            ClassroomBackground()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "bird.fill")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Theme.coral)
                    .padding(28)
                    .glassCard(corner: 40)
                Text("Welcome to Parrot")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.ink)
                VStack(alignment: .leading, spacing: 18) {
                    WelcomeRow(symbol: "hand.tap.fill", tint: Theme.sky,
                               title: "Tap to log practice",
                               text: "Run quick flashcard sessions and tap Correct, Almost, or Missed for each word.")
                    WelcomeRow(symbol: "chart.line.uptrend.xyaxis", tint: Theme.leaf,
                               title: "Watch progress grow",
                               text: "Accuracy trends, weekly streaks, and mastery badges for every sound.")
                    WelcomeRow(symbol: "doc.text.fill", tint: Theme.coral,
                               title: "Share with your SLP",
                               text: "One tap builds a clean PDF summary to hand to the therapist.")
                }
                .padding(24)
                .glassCard()
                .padding(.horizontal, 4)

                Text("Parrot is a personal practice logbook. It supports the guidance of a speech-language professional and does not replace therapy or medical advice.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Spacer()

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(Theme.sky))
                }
                .accessibilityIdentifier("welcomeContinueButton")
            }
            .padding(24)
        }
    }
}

private struct WelcomeRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(text)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }
}
