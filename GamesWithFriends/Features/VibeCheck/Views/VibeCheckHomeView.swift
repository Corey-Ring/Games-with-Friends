import SwiftUI

struct VibeCheckHomeView: View {
    var viewModel: VibeCheckViewModel
    @Binding var selectedMode: VibeCheckGameMode
    @State private var showHowToPlay = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                // Compact header with back button
                compactHeaderRow

                // Game Mode Selection
                gameModeSection

                // Mode-specific settings
                if selectedMode == .classic {
                    // Teams + Players per Team side-by-side
                    teamsAndPlayersSection
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
                        .font(AppTheme.Typography.secondary)
                        .foregroundStyle(GameTheme.vibeCheck.accentColor)
                }
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView(gameMode: selectedMode)
        }
    }

    // MARK: - Sections

    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Game Mode")
                .font(AppTheme.Typography.cardTitle)

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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label("Players", systemImage: "person.fill")
                .font(AppTheme.Typography.cardTitle)

            HStack {
                Button {
                    if viewModel.competitionSettings.playerCount > 2 {
                        viewModel.competitionSettings.playerCount -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundStyle(viewModel.competitionSettings.playerCount > 2 ? GameTheme.vibeCheck.accentColor : AppTheme.mediumGray)
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
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundStyle(viewModel.competitionSettings.playerCount < 10 ? GameTheme.vibeCheck.accentColor : AppTheme.mediumGray)
                }
                .disabled(viewModel.competitionSettings.playerCount >= 10)
            }
            .padding(.horizontal)

            Text("Minimum 2 players")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.pureWhite)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    private var compactHeaderRow: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.deepCharcoal)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.pureWhite)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
            }

            Spacer()

            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 24))
                    .foregroundStyle(GameTheme.vibeCheck.accentColor)

                Text("Vibe Check")
                    .font(AppTheme.Typography.sectionHeader)
            }

            Spacer()

            // Balance spacer — keeps title visually centered
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.top, AppTheme.Spacing.xs)
    }

    private var teamsAndPlayersSection: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            compactStepperCard(
                label: "Teams", icon: "person.3.fill",
                value: viewModel.settings.teamCount,
                minValue: 1, maxValue: 4,
                onDecrement: { if viewModel.settings.teamCount > 1 { viewModel.settings.teamCount -= 1 } },
                onIncrement: { if viewModel.settings.teamCount < 4 { viewModel.settings.teamCount += 1 } }
            )
            compactStepperCard(
                label: "Players Per Team", icon: "person.2.fill",
                value: viewModel.settings.playersPerTeam,
                minValue: 2, maxValue: 8,
                onDecrement: { if viewModel.settings.playersPerTeam > 2 { viewModel.settings.playersPerTeam -= 1 } },
                onIncrement: { if viewModel.settings.playersPerTeam < 8 { viewModel.settings.playersPerTeam += 1 } }
            )
        }
    }

    private func compactStepperCard(
        label: String, icon: String,
        value: Int, minValue: Int, maxValue: Int,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(GameTheme.vibeCheck.accentColor)
                Text(label)
                    .font(AppTheme.Typography.secondary.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: onDecrement) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(value > minValue ? GameTheme.vibeCheck.accentColor : AppTheme.mediumGray)
                }
                .disabled(value <= minValue)

                Spacer()

                Text("\(value)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                Button(action: onIncrement) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(value < maxValue ? GameTheme.vibeCheck.accentColor : AppTheme.mediumGray)
                }
                .disabled(value >= maxValue)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.pureWhite)
                .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
        }
    }

    private var targetScoreSection: some View {
        let currentScore = selectedMode == .classic ? viewModel.settings.targetScore : viewModel.competitionSettings.targetScore

        return VStack(alignment: .leading, spacing: 12) {
            Label("Target Score", systemImage: "flag.checkered")
                .font(AppTheme.Typography.cardTitle)

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach([300, 500, 750, 1000], id: \.self) { score in
                    Button {
                        if selectedMode == .classic {
                            viewModel.settings.targetScore = score
                        } else {
                            viewModel.competitionSettings.targetScore = score
                        }
                    } label: {
                        Text("\(score)")
                            .font(AppTheme.Typography.secondary.weight(.medium))
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(currentScore == score ? GameTheme.vibeCheck.accentColor : AppTheme.warmLinen)
                            }
                            .foregroundStyle(currentScore == score ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.pureWhite)
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
                Text(selectedMode == .classic ? "Set Up Teams" : "Set Up Players")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(GameTheme.vibeCheck.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
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
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: mode.iconName)
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundStyle(isSelected ? .white : GameTheme.vibeCheck.accentColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(mode.name)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(isSelected ? .white : .primary)

                    Text(mode.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? GameTheme.vibeCheck.accentColor : Color.clear)
            .background(AppTheme.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(isSelected ? Color.clear : AppTheme.mediumGray.opacity(0.3), lineWidth: 1)
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
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                Text("Set Up Teams")
                    .font(AppTheme.Typography.screenTitle)

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
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.05)],
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
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .buttonStyle(.plain)
    }
}

struct TeamSetupCard: View {
    let teamIndex: Int
    let team: VibeCheckTeam
    var viewModel: VibeCheckViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Team name
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.purple)
                TextField("Enter team name", text: Binding(
                    get: { team.name },
                    set: { viewModel.updateTeamName(at: teamIndex, name: $0) }
                ))
                .font(AppTheme.Typography.cardTitle)
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
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.pureWhite)
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
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
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
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label(title, systemImage: icon)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.purple)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(AppTheme.warmLinen)
        }
    }

    private func scoringRow(_ zone: ScoringZone) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zone.color)
                .frame(width: 16, height: 16)

            Text("\(zone.points) points")
                .font(AppTheme.Typography.secondary.weight(.medium))

            Text("(within \(Int(zone.threshold * 100))%)")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VibeCheckHomeView(viewModel: VibeCheckViewModel(), selectedMode: .constant(.classic))
}
