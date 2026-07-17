import SwiftUI
import SwiftData

struct PracticeHomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @Query(sort: \Kid.createdAt) private var kids: [Kid]
    @AppStorage("selectedKidID") private var selectedKidID = ""

    @State private var showSettings = false
    @State private var showAddKid = false
    @State private var showAddSound = false
    @State private var showPaywall = false
    @State private var showSessionSetup = false

    private var selectedKid: Kid? {
        kids.first { $0.uuid.uuidString == selectedKidID } ?? kids.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClassroomBackground()
                if kids.isEmpty {
                    emptyState
                } else if let kid = selectedKid {
                    kidContent(kid)
                }
            }
            .navigationTitle("Parrot")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.ink)
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showAddKid) {
                KidEditorView(kid: nil) { newKid in
                    selectedKidID = newKid.uuid.uuidString
                }
            }
            .sheet(isPresented: $showAddSound) {
                if let kid = selectedKid {
                    AddSoundSheet(kid: kid)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSessionSetup) {
                if let kid = selectedKid {
                    SessionSetupView(kid: kid)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bird.fill")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(Theme.coral)
                .padding(24)
                .glassCard(corner: 36)
            Text("Who is practicing?")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.ink)
            Text("Add your child to start logging speech practice at home.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showAddKid = true
            } label: {
                Label("Add a Kid", systemImage: "plus")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Theme.sky))
            }
            .accessibilityIdentifier("addKidButton")
        }
    }

    // MARK: - Main content

    private func kidContent(_ kid: Kid) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                kidPicker
                startCard(kid)
                soundsSection(kid)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    private var kidPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(kids) { kid in
                    let isSelected = kid.uuid.uuidString == selectedKid?.uuid.uuidString
                    Button {
                        withAnimation(Theme.springFast) {
                            selectedKidID = kid.uuid.uuidString
                        }
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle().fill(kid.color.color)
                                Text(kid.initialLetter)
                                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 30, height: 30)
                            Text(kid.name)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.ink)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule().strokeBorder(
                                        isSelected ? kid.color.color : Color.white.opacity(0.25),
                                        lineWidth: isSelected ? 2 : 1
                                    )
                                )
                        )
                        .scaleEffect(isSelected ? 1.0 : 0.96)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    showAddKid = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.sky)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .accessibilityIdentifier("addKidButton")
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func startCard(_ kid: Kid) -> some View {
        let wordCount = kid.sounds.reduce(0) { $0 + $1.words.count }
        let streak = Streaks.weeklyStreak(sessionDates: kid.sessions.map(\.date))
        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(kid.name)'s practice")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.ink)
                    Text(wordCount == 0
                         ? "Add a target sound below to begin"
                         : "\(kid.sounds.count) sounds, \(wordCount) words ready")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if streak > 0 {
                    VStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Theme.coral)
                        Text("\(streak)w")
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
            Button {
                showSessionSetup = true
            } label: {
                Label("Start Practice", systemImage: "play.fill")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule().fill(wordCount == 0 ? Theme.inkSoft : Theme.coral)
                    )
            }
            .disabled(wordCount == 0)
            .accessibilityIdentifier("startPracticeButton")
        }
        .padding(20)
        .glassCard()
    }

    private func soundsSection(_ kid: Kid) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Target Sounds")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    if pro.canAddSound(to: kid) {
                        showAddSound = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("Add", systemImage: pro.canAddSound(to: kid) ? "plus" : "lock.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.sky)
                }
                .accessibilityIdentifier("addSoundButton")
            }
            if kid.sounds.isEmpty {
                Text("No sounds yet. Add the sound your SLP assigned, like R or S, and Parrot fills in starter words.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .glassCard(corner: 22)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                    ForEach(kid.sortedSounds) { sound in
                        NavigationLink {
                            SoundDetailView(sound: sound)
                        } label: {
                            SoundCardView(sound: sound, kid: kid)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Sound card

struct SoundCardView: View {
    let sound: TargetSound
    let kid: Kid

    var body: some View {
        let records = kid.sessionRecords
        let mastered = Mastery.isMastered(sound: sound.label, sessions: records)
        let recentAccuracy = records
            .compactMap { Mastery.sessionAccuracy(sound: sound.label, session: $0) }
            .last

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(sound.label)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if mastered {
                    Image(systemName: "rosette")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.amber)
                }
            }
            Text("\(sound.words.count) words")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.inkSoft)
            if let accuracy = recentAccuracy {
                HStack(spacing: 6) {
                    Circle()
                        .fill(accuracy >= Mastery.threshold ? Theme.leaf : Theme.sky)
                        .frame(width: 8, height: 8)
                    Text("Last: \(accuracy.percentText)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Text("Not practiced yet")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(corner: 22)
    }
}
