import SwiftUI

struct VibeCheckHomeView: View {
    var viewModel: VibeCheckViewModel
    @Binding var selectedMode: VibeCheckGameMode
    @State private var showHowToPlay = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Game Mode Selection
                gameModeSection

                // Mode-specific settings
                if selectedMode == .classic {
                    // Team count
                    teamCountSection

                    // Players per team
                    playersPerTeamSection
                } else {
                    // Player count for competition mode
                    playerCountSection
                }

                // Target score
                targetScoreSection

                // Continue button
                continueButton

                // How to play
                Button {
                    showHowToPlay = true
                } label: {
                    Label("How to Play", systemImage: "book.fill")
                        .font(.subheadline)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView(gameMode: selectedMode)
        }
    }

    // MARK: - Sections

    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Mode")
                .font(.headline)

            ForEach(VibeCheckGameMode.allCases) { mode in
                VibeCheckGameModeCard(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    action: { selectedMode = mode }
                )
            }
        }
    }

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Players", systemImage: "person.fill")
                .font(.headline)

            HStack {
                Button {
                    if viewModel.competitionSettings.playerCount > 2 {
                        viewModel.competitionSettings.playerCount -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.competitionSettings.playerCount > 2 ? .primary : .secondary)
                }
                .disabled(viewModel.competitionSettings.playerCount <= 2)

                Spacer()

                Text("\(viewModel.competitionSettings.playerCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                Button {
                    if viewModel.competitionSettings.playerCount < 10 {
                        viewModel.competitionSettings.playerCount += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.competitionSettings.playerCount < 10 ? .primary : .secondary)
                }
                .disabled(viewModel.competitionSettings.playerCount >= 10)
            }
            .padding(.horizontal)

            Text("Minimum 2 players")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("VIBE CHECK")
                .font(.largeTitle.weight(.bold))

            Text("Get on the same wavelength")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    private var teamCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Teams", systemImage: "person.3.fill")
                .font(.headline)

            HStack {
                Button {
                    if viewModel.settings.teamCount > 1 {
                        viewModel.settings.teamCount -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.settings.teamCount > 1 ? .primary : .secondary)
                }
                .disabled(viewModel.settings.teamCount <= 1)

                Spacer()

                Text("\(viewModel.settings.teamCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                Button {
                    if viewModel.settings.teamCount < 4 {
                        viewModel.settings.teamCount += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.settings.teamCount < 4 ? .primary : .secondary)
                }
                .disabled(viewModel.settings.teamCount >= 4)
            }
            .padding(.horizontal)

            Text(viewModel.settings.teamCount == 1 ? "Single team mode" : "1-4 teams")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    private var playersPerTeamSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Players per Team", systemImage: "person.2.fill")
                .font(.headline)

            HStack {
                Button {
                    if viewModel.settings.playersPerTeam > 2 {
                        viewModel.settings.playersPerTeam -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.settings.playersPerTeam > 2 ? .primary : .secondary)
                }
                .disabled(viewModel.settings.playersPerTeam <= 2)

                Spacer()

                Text("\(viewModel.settings.playersPerTeam)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                Button {
                    if viewModel.settings.playersPerTeam < 8 {
                        viewModel.settings.playersPerTeam += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.settings.playersPerTeam < 8 ? .primary : .secondary)
                }
                .disabled(viewModel.settings.playersPerTeam >= 8)
            }
            .padding(.horizontal)

            Text("Minimum 2 players per team")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    private var targetScoreSection: some View {
        let currentScore = selectedMode == .classic ? viewModel.settings.targetScore : viewModel.competitionSettings.targetScore

        return VStack(alignment: .leading, spacing: 12) {
            Label("Target Score", systemImage: "flag.checkered")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach([300, 500, 750, 1000], id: \.self) { score in
                    Button {
                        if selectedMode == .classic {
                            viewModel.settings.targetScore = score
                        } else {
                            viewModel.competitionSettings.targetScore = score
                        }
                    } label: {
                        Text("\(score)")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(currentScore == score ? Color.purple : Color(.systemGray5))
                            }
                            .foregroundStyle(currentScore == score ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    private var continueButton: some View {
        Button {
            if selectedMode == .classic {
                viewModel.proceedToTeamSetup()
            } else {
                viewModel.proceedToCompetitionPlayerSetup()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text(selectedMode == .classic ? "SET UP TEAMS" : "SET UP PLAYERS")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game Mode Card

struct VibeCheckGameModeCard: View {
    let mode: VibeCheckGameMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: mode.iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .purple)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.name)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.purple : Color.clear)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Team Setup View

struct TeamSetupView: View {
    var viewModel: VibeCheckViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Set Up Teams")
                    .font(.title.weight(.bold))

                // Team cards
                ForEach(Array(viewModel.teams.enumerated()), id: \.element.id) { teamIndex, team in
                    TeamSetupCard(
                        teamIndex: teamIndex,
                        team: team,
                        viewModel: viewModel
                    )
                }

                // Start button
                startButton
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var startButton: some View {
        Button {
            viewModel.startGame()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("START GAME")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct TeamSetupCard: View {
    let teamIndex: Int
    let team: VibeCheckTeam
    var viewModel: VibeCheckViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Team name
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.purple)
                TextField("Enter team name", text: Binding(
                    get: { team.name },
                    set: { viewModel.updateTeamName(at: teamIndex, name: $0) }
                ))
                .font(.headline)
                .foregroundStyle(.primary)
            }

            Divider()

            // Player names
            ForEach(Array(team.playerNames.enumerated()), id: \.offset) { playerIndex, playerName in
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    TextField("Player \(playerIndex + 1)", text: Binding(
                        get: { playerName },
                        set: { viewModel.updatePlayerName(teamIndex: teamIndex, playerIndex: playerIndex, name: $0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }
}

// MARK: - How To Play

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    var gameMode: VibeCheckGameMode = .classic

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Overview
                    section(title: "Overview", icon: "info.circle.fill") {
                        if gameMode == .classic {
                            Text("A spectrum with polar opposites is shown (e.g., Trashy ↔ Classy). One player sees a target position and creates a prompt that matches it. The team then tries to guess where the prompt falls on the spectrum.")
                        } else {
                            Text("Competition Mode is a free-for-all version where every player competes individually. Pass the device around and try to match the Vibe Setter's target position!")
                        }
                    }

                    // Vibe Setter
                    section(title: "Vibe Setter", icon: "person.fill.questionmark") {
                        VStack(alignment: .leading, spacing: 8) {
                            if gameMode == .competition {
                                Text("1. A random player becomes the Vibe Setter each round")
                            }
                            Text(gameMode == .competition ? "2. They see the spectrum and target position" : "1. See the spectrum and target position")
                            Text(gameMode == .competition ? "3. They create a prompt that matches the target" : "2. Think of something that matches that position")
                            Text(gameMode == .competition ? "4. The Vibe Setter does NOT earn points" : "3. Example: Target is near 'Trashy' → 'Clipping your nails in a movie theater'")
                        }
                    }

                    // Guessing
                    section(title: gameMode == .classic ? "Guessing Team" : "Guessing", icon: "hand.tap.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            if gameMode == .classic {
                                Text("1. See the spectrum and the prompt")
                                Text("2. Discuss as a team")
                                Text("3. Slide to where you think it belongs")
                                Text("4. Lock in your guess!")
                            } else {
                                Text("1. Each player takes a turn with the device")
                                Text("2. See the spectrum and prompt")
                                Text("3. Slide to where YOU think it belongs")
                                Text("4. Pass to the next player (no peeking!)")
                            }
                        }
                    }

                    // Scoring
                    section(title: "Scoring Zones", icon: "target") {
                        VStack(alignment: .leading, spacing: 12) {
                            scoringRow(.perfect)
                            scoringRow(.great)
                            scoringRow(.good)
                            scoringRow(.okay)
                            scoringRow(.miss)
                        }
                    }

                    // Winning (competition mode only)
                    if gameMode == .competition {
                        section(title: "Winning", icon: "trophy.fill") {
                            Text("First player to reach the target score wins! The player with the worst guess each round gets a fun tease.")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.purple)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        }
    }

    private func scoringRow(_ zone: ScoringZone) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zone.color)
                .frame(width: 16, height: 16)

            Text("\(zone.points) points")
                .font(.subheadline.weight(.medium))

            Text("(within \(Int(zone.threshold * 100))%)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VibeCheckHomeView(viewModel: VibeCheckViewModel(), selectedMode: .constant(.classic))
}
