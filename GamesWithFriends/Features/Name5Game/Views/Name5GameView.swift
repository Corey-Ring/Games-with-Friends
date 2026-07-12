import SwiftUI

struct Name5GameView: View {
    @State private var viewModel = Name5ViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                WarmLinenBackground()

                // Content based on game phase
                switch viewModel.gamePhase {
                case .setup:
                    Name5SetupView(viewModel: viewModel)

                case .ready, .playing, .paused:
                    Name5PlayView(viewModel: viewModel)

                case .roundComplete:
                    Name5ResultsView(viewModel: viewModel)

                case .gameOver:
                    GameOverView(viewModel: viewModel)
                }
            }
            .navigationTitle(viewModel.gamePhase == .setup ? "" : "Name 5")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(viewModel.gamePhase == .setup ? .hidden : .automatic, for: .navigationBar)
            .toolbar {
                if viewModel.gamePhase != .setup {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                viewModel.resetGame()
                            }) {
                                Label("New Game", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(AppTheme.Typography.subsectionHeader)
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .inactive, .background:
                    if viewModel.gamePhase == .playing {
                        viewModel.pauseTimer()
                    }
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            GameBackground(gameTheme: .name5)
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: viewModel.playerStandings.isEmpty ? "flag.checkered" : "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(viewModel.playerStandings.isEmpty ? GameTheme.name5.accentColor : AppTheme.medalGold)

                        Text("Game Over!")
                            .font(AppTheme.Typography.hero)
                            .fontWeight(.bold)

                        Text(winnerText)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Standings (pass-and-play only)
                    if !viewModel.playerStandings.isEmpty {
                        StandingsCard(
                            standings: viewModel.playerStandings,
                            winners: viewModel.winningPlayerNumbers
                        )
                    }

                    // Final Stats
                    FinalStatsCard(stats: viewModel.stats)

                    // Recent Rounds
                    if !viewModel.roundResults.isEmpty {
                        RecentRoundsCard(results: viewModel.roundResults)
                    }

                    // Buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        PrimaryButton(title: "Play Again", icon: "play.fill") {
                            viewModel.startGame()
                        }

                        SecondaryButton(title: "Back to Setup", icon: "gearshape") {
                            viewModel.resetGame()
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
    }

    private var winnerText: String {
        let winners = viewModel.winningPlayerNumbers
        if winners.isEmpty {
            return "Great job playing!"
        } else if winners.count == 1 {
            return "Player \(winners[0]) wins!"
        } else {
            let names = winners.map { "Player \($0)" }.joined(separator: " & ")
            return "It's a tie — \(names)!"
        }
    }
}

// MARK: - Standings Card
struct StandingsCard: View {
    let standings: [Name5PlayerStanding]
    let winners: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Standings")
                .font(AppTheme.Typography.sectionHeader)
                .fontWeight(.bold)

            ForEach(standings) { standing in
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: winners.contains(standing.playerNumber) ? "crown.fill" : "person.fill")
                        .foregroundColor(winners.contains(standing.playerNumber) ? AppTheme.medalGold : .secondary)
                        .frame(width: 24)

                    Text("Player \(standing.playerNumber)")
                        .font(AppTheme.Typography.cardTitle)
                        .fontWeight(winners.contains(standing.playerNumber) ? .bold : .regular)

                    Spacer()

                    Text("\(standing.successes) of \(standing.attempts)")
                        .font(AppTheme.Typography.cardTitle)
                        .monospacedDigit()
                        .foregroundColor(winners.contains(standing.playerNumber) ? GameTheme.name5.accentColor : .secondary)
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Final Stats Card
struct FinalStatsCard: View {
    let stats: GameStats

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Final Stats")
                .font(AppTheme.Typography.sectionHeader)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                FinalStatItem(
                    icon: "target",
                    label: "Total Rounds",
                    value: "\(stats.roundsPlayed)",
                    color: GameTheme.name5.accentColor
                )

                FinalStatItem(
                    icon: "checkmark.circle.fill",
                    label: "Successful",
                    value: "\(stats.roundsWon)",
                    color: AppTheme.success
                )

                FinalStatItem(
                    icon: "flame.fill",
                    label: "Best Streak",
                    value: "\(stats.bestStreak)",
                    color: AppTheme.warning
                )

                FinalStatItem(
                    icon: "percent",
                    label: "Success Rate",
                    value: "\(Int(stats.successRate * 100))%",
                    color: GameTheme.name5.accentColor
                )
            }
        }
        .gameCard()
    }
}

struct FinalStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(AppTheme.Typography.screenTitle)
                .foregroundColor(color)

            Text(value)
                .font(AppTheme.Typography.screenTitle)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.mediumGray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Recent Rounds Card
struct RecentRoundsCard: View {
    let results: [RoundResult]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Recent Rounds")
                .font(AppTheme.Typography.cardTitle)

            ForEach(results.suffix(5).reversed()) { result in
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.success ? AppTheme.success : AppTheme.warning)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(result.promptText)
                            .font(AppTheme.Typography.body)
                            .lineLimit(1)

                        if let time = result.timeUsed {
                            Text("\(time)s")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.mediumGray)
                        }
                    }

                    Spacer()

                    if let playerNum = result.playerNumber {
                        Text("P\(playerNum)")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.mediumGray)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(AppTheme.mediumGray.opacity(0.15))
                            )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(AppTheme.mediumGray.opacity(0.05))
                )
            }
        }
        .gameCard()
    }
}
