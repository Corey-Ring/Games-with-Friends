import SwiftUI

struct CompetitionHomeView: View {
    var viewModel: CompetitionVibeCheckViewModel
    @State private var showHowToPlay = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                headerSection

                // Player count
                playerCountSection

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
                }
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            LinearGradient(
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showHowToPlay) {
            CompetitionHowToPlayView()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [GameTheme.vibeCheck.accentColor, GameTheme.vibeCheck.accentColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("COMPETITION MODE")
                .font(AppTheme.Typography.hero)

            Text("Every player for themselves!")
                .font(AppTheme.Typography.secondary)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Players", systemImage: "person.fill")
                .font(AppTheme.Typography.cardTitle)

            HStack {
                Button {
                    if viewModel.settings.playerCount > 2 {
                        viewModel.settings.playerCount -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundStyle(viewModel.settings.playerCount > 2 ? .primary : .secondary)
                }
                .disabled(viewModel.settings.playerCount <= 2)

                Spacer()

                Text("\(viewModel.settings.playerCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Spacer()

                Button {
                    if viewModel.settings.playerCount < 10 {
                        viewModel.settings.playerCount += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundStyle(viewModel.settings.playerCount < 10 ? .primary : .secondary)
                }
                .disabled(viewModel.settings.playerCount >= 10)
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

    private var targetScoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Target Score", systemImage: "flag.checkered")
                .font(AppTheme.Typography.cardTitle)

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach([300, 500, 750, 1000], id: \.self) { score in
                    Button {
                        viewModel.settings.targetScore = score
                    } label: {
                        Text("\(score)")
                            .font(AppTheme.Typography.secondary.weight(.medium))
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(viewModel.settings.targetScore == score ? GameTheme.vibeCheck.accentColor : AppTheme.warmLinen)
                            }
                            .foregroundStyle(viewModel.settings.targetScore == score ? .white : .primary)
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
            viewModel.proceedToPlayerSetup()
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text("SET UP PLAYERS")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                LinearGradient(
                    colors: [GameTheme.vibeCheck.accentColor, GameTheme.vibeCheck.accentColor],
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

// MARK: - Player Setup View

struct CompetitionPlayerSetupView: View {
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                Text("Enter Player Names")
                    .font(AppTheme.Typography.screenTitle)

                // Player name fields
                ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                    PlayerNameCard(
                        playerIndex: index,
                        player: player,
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
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.1)],
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
                    colors: [GameTheme.vibeCheck.accentColor, GameTheme.vibeCheck.accentColor],
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

struct PlayerNameCard: View {
    let playerIndex: Int
    let player: CompetitionPlayer
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Player number badge
            ZStack {
                Circle()
                    .fill(GameTheme.vibeCheck.accentColor)
                    .frame(width: 36, height: 36)

                Text("\(playerIndex + 1)")
                    .font(AppTheme.Typography.cardTitle.weight(.bold))
                    .foregroundStyle(.white)
            }

            TextField("Player \(playerIndex + 1)", text: Binding(
                get: { player.name },
                set: { viewModel.updatePlayerName(at: playerIndex, name: $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(AppTheme.Typography.body)
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

struct CompetitionHowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Overview
                    section(title: "Overview", icon: "info.circle.fill") {
                        Text("Competition Mode is a free-for-all version of Vibe Check where every player competes individually. Pass the device around and try to match the Vibe Setter's target position!")
                    }

                    // Vibe Setter
                    section(title: "Vibe Setter", icon: "person.fill.questionmark") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("1. A random player becomes the Vibe Setter each round")
                            Text("2. They see the spectrum and target position")
                            Text("3. They create a prompt that matches the target")
                            Text("4. The Vibe Setter does NOT earn points")
                        }
                    }

                    // Guessing
                    section(title: "Guessing", icon: "hand.tap.fill") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("1. Each player takes a turn with the device")
                            Text("2. See the spectrum and prompt")
                            Text("3. Slide to where YOU think it belongs")
                            Text("4. Pass to the next player (no peeking!)")
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

                    // Winning
                    section(title: "Winning", icon: "trophy.fill") {
                        Text("First player to reach the target score wins! The player with the worst guess each round gets a fun tease.")
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
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(GameTheme.vibeCheck.accentColor)

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
    CompetitionHomeView(viewModel: CompetitionVibeCheckViewModel())
}
